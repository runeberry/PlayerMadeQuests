package = "pmq"
version = "dev-1"
source = { url = "git+https://github.com/dolphinspired/PlayerMadeQuests.git" }
build = { type = "builtin" }
dependencies = {
  "busted",
  "luacov",
  "luacov-reporter-lcov",
  "luacov-console",
}