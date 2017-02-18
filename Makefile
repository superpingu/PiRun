pirun.js: pirun.coffee
	coffee -c pirun.coffee

install: pirun.js
	npm install
	mkdir -p /usr/local/lib/pirun
	cp -r * /usr/local/lib/pirun
	echo "#!/usr/bin/env node\n"|cat - pirun.js > /tmp/out && mv /tmp/out /usr/local/lib/pirun/pirun.js
	rm -f /usr/local/bin/pirun
	ln -s /usr/local/lib/pirun/pirun.sh /usr/local/bin/pirun
	chmod a+x /usr/local/bin/pirun

clean:
	rm -f pirun.js

.PHONY: install clean
