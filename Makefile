
.PHONY: compile

compile:
	truffle compile

migrate: compile
	truffle migrate

test: migrate
	truffle test

clean:
	rm -rf build


