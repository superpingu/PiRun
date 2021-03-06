# PiRun
Small utility uploading and running project on a Raspberry Pi running RPC.

Mainly, it does 3 things :
* retrieve RaspberryPi IPv4 address from RPC.
* copy the files modified since last update to the Raspberry Pi (using scp)
* run the specified make target (or just `make` if no target is specified)

## Install instructions for Debian-based Linux (includes Ubuntu, Linux Mint, ...)

to install, clone this repository with

```bash
git clone https://github.com/superpingu/PiRun.git
```

Then go to the repository root with

```bash
cd PiRun
```

Finally install with admin rights with

```bash
chmod +x ./install.sh
sudo ./install.sh
```
**Note :** This will install NodeJS, required by PiRun. If you don't have it already, you should definitly take a look at it, it is *pretty* amazing.

## Usage

```
pirun <name of the Pi on RPC> [make target]
```

If omitted, the default make target is used (equivalent to running `make`).

### .pirunignore

You can specify files, folders and patterns not to upload to the Pi, in a .gitignore fashion.

It is advised to add .git folder to the .pirunignore, as the upload system can be slow in case of multiple subfolders (like in the .git folder).
