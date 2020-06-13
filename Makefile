CoverageDir=luacov

coverage-setup:
	rm -f $(CoverageDir)/*
	mkdir -p $(CoverageDir)

test:
	busted

test-coverage: coverage-setup
	busted --coverage
	luacov-console ./src
	luacov-console --summary

test-report: coverage-setup
	busted --coverage
	luacov -r lcov
	genhtml $(CoverageDir)/luacov.report.out -o $(CoverageDir)/coverage

clean:
	rm -rf $(CoverageDir)
