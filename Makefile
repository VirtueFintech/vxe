
.PHONY: compile

compile:
	truffle compile

migrate: compile
	truffle migrate

ropsten: compile
	truffle migrate --network ropsten

test: migrate
	truffle test

clean:
	rm -rf build


