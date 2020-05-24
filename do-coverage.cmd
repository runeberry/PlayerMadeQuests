del */*.out
del */*.index.out

call busted --coverage
echo %cd%
move "./test/luacov.stats.out" "./luacov.stats.out"
REM del *.out
REM del *.index.out