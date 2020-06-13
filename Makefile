setup:
	luarocks install --only-deps pmq-dev-1.rockspec

test:
	busted

test-coverage:
	busted --coverage
	# genhtml lcov.info -o coverage # todo: not working quite right
	luacov-console ./src
	luacov-console --summary

clean:
	rm luacov.stats.out
	rm lcov.info
	rm lcov.info.index
	rm -rf coverage
