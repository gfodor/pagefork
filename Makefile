.PHONY: all test clean

COFFEE = node_modules/.bin/coffee
UGLIFY = node_modules/.bin/uglifyjs -d WEB=true

all:

server:
	$(COFFEE) -c -o lib src/server

server-watch:
	$(COFFEE) -c -o -w lib src/server

client:
	$(COFFEE) -c -o assets/javascripts src/client
	cp src/client/*.js assets/javascripts

client-watch:
	$(COFFEE) -c -o -w assets/javascripts src/client

clean:
	rm -rf lib/*

test:
	node_modules/.bin/mocha --require coffee-script --compilers coffee:coffee-script --recursive ./test

