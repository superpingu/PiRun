shell = require 'shelljs'
request = require 'sync-request'
program = require 'commander'
path = require 'path'

name = ''
target = ''

program
    .version('0.0.1')
    .arguments('<piname> [target]')
    .option('-f, --force', 'Force to reupload everything')
    .option('-s, --shell', 'Log in with ssh instead of running make')
    .option('-r, --root', 'Run make (or log in if -s option is present) as root')
    .action (piname, tar) ->
        name = piname
        target = if tar then tar else ''
    .on '--help', ->
        console.log '   <piname> : name of the Raspberry Pi on RPC or an IPv4 address'
        console.log '   [target] : the target of the Makefile to execute'
        console.log ''
        shell.echo("").to('/tmp/pirun')
program.parse process.argv

# get Raspberry Pi's IP
ip = ''

# check if name is a valid IPv4
checkIP = (text) ->
    splitIP = text.split '.'
    return false if splitIP.length != 4
    for val in splitIP
        return false unless 0 <= parseInt(val) < 256
    return true

if checkIP name
    ip = name
else if name.length == 0
    program.help()
else # otherwise try to get IP from RPC
    ip = request('GET', "http://bonetti.io/rpc/api/ip/"+name).getBody().toString()
    if ip is 'not found'
        console.log "Raspberry Pi '#{name}' not found"
        shell.echo("").to('/tmp/pirun')
        process.exit -1

user = if program.root then 'root' else 'pi'

if program.shell
    shell.echo("ssh #{user}@#{ip}").to('/tmp/pirun')
    process.exit 0

dirname = shell.pwd().split('/').pop()


if program.force
    pirunTime = 0
    shell.exec "ssh #{user}@#{ip} 'rm -rf /var/pirun/#{dirname}'"
else
    # get the last time the files have been uploaded
    shell.config.silent = yes
    pirunFile = shell.ls('-l', "./.pirun.#{name}")
    pirunTime = if pirunFile.code != 0 then 0 else pirunFile[0].ctime

# load the list of files that should not be uploaded
pirunIgnore = shell.cat("./.pirunignore")
pirunIgnore = if pirunIgnore.code != 0 then [] else pirunIgnore.split '\n'
shell.config.silent = no
# turn strings into regex patterns
ignorePatterns = [/\.pirun\..*/g]
for line in pirunIgnore
    line = '^' + line.replace(/[.+?^${}()|[\]\\]/g, "\\$&").replace(/\*/g, '.*') + '$'
    ignorePatterns.push new RegExp(line) if line.trim().length > 0
# returns true if filename matches one of the patterns
matchIgnore = (filename) ->
    for pattern in ignorePatterns
        return yes if filename.match pattern
    return no


uploadFiles = (dir) ->
    files = shell.ls '-lA', dir
    output = []
    didSomething = no

    for file in files
        unless (file.mtime < pirunTime and not file.isDirectory()) or matchIgnore path.join(dir, file.name)
            if file.isDirectory()
                didSomething |= uploadFiles(path.join dir, file.name)
            else
                output.push path.join(dir, file.name)

    if output.length > 0
        shell.exec "ssh #{user}@#{ip} 'mkdir -p /var/pirun/#{path.join(dirname, dir)}'"
        shell.exec "scp #{output.join(' ')} #{user}@#{ip}:/var/pirun/#{path.join(dirname, dir)}"
        return true
    return didSomething

process.stdout.write 'Uploading files ...'
if uploadFiles '.'
    console.log ' OK\n'
else
    console.log ' already up-to-date\n'

# save the date of the last upload
shell.touch "./.pirun.#{name}"

shell.echo("ssh #{user}@#{ip} 'make #{target} -C /var/pirun/#{dirname}'").to('/tmp/pirun')
