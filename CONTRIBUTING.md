# Guidelines for Contributing

Thank you for contributing to PlayerMadeQuests! The following instructions will help you get your environment set up to modify and test PMQ's code. These instructions assume the following:

* You're developing on Windows 10 and have Administrator access
* You have World of Warcraft: Classic installed (with an active game subscription)
* You have a Github account and you have [Git](https://gitforwindows.org/) installed on your machine

## Contribution model

You'll need to create a fork of the PlayerMadeQuests repository, commit your changes to that fork, and then submit a [pull request](https://github.com/runeberry/PlayerMadeQuests/compare) to the main repository. If you're new to Github, you can follow along with [these instructions](https://docs.github.com/en/github/getting-started-with-github/fork-a-repo) to learn about forking and cloning repositories.

## Backing up saved data

If you're worried about losing any saved data for PMQ, such as Drafts, Settings, or quest progress, you may want to first follow these steps to back up your data before doing any development:

1. Navigate to your Wow: Classic installation folder. For example: `C:\Program Files (x86)\World of Warcraft\_classic_`
2. Navigate to `WTF/Account/{your_account_id}/SavedVariables`, where `{your_account_id}` is something like: `12345678#1`
3. Copy the files `PlayerMadeQuests.lua` and `PlayerMadeQuests.lua.bak` to a safe location.
4. Go back up one folder, and navigate to `{server_name}/{character_name}/SavedVariables` for any characters with PMQ data you want to save.
5. Repeat Step 3 to copy the files to a safe location.

## Running PMQ locally

Once you've downloaded the code from Github, you'll want to run the addon in WoW: Classic in order to test any changes you make. You can do this by creating a symlink in your AddOns folder that points to the `src` folder of this repo. This is outlined in the following steps:

1. Navigate to your Wow: Classic installation folder. For example: `C:\Program Files (x86)\World of Warcraft\_classic_`
2. Open the `Interface/AddOns` folder.
3. Delete the existing `PlayerMadeQuests` addon folder if it's installed. This does not affect your saved data.
4. Open an elevated (Adminstrator) command prompt in this folder. (File > Open command prompt > ...as Administrator)
5. Use the following command to create a symlink to your repository's `src` folder

```
mklink /d PlayerMadeQuests "{your_pmq_code_folder}\src"
```

You should see a new folder called PlayerMadeQuests in the AddOns folder. Opening this will take you to your local code's `src` folder.

You can verify that this is working by opening WoW: Classic and checking your AddOns list. You should see PlayerMadeQuests installed. You're ready to start development!

## Running unit tests w/ Docker in Windows

While you do not need a Lua runtime installed on your computer in order to play with the addon (WoW takes care of this for you), you will need one installed in order to run the unit tests for PMQ.

Fortunately, I've thrown together a solution that helps you get Lua up and running as quickly as possible! Check out the [wow-addon-container](https://github.com/runeberry/wow-addon-container), which is a Docker container with all the tools you need to run Lua unit tests. If you've never used Docker before, that guide contains complete instructions for getting that installed too.

Once you have a Docker account and Docker for Windows installed, there is a helper script already available in this repo for starting up the container and making PMQ code available to it. Simply run the following line in your command prompt from the root of this repository:

```ps
.\scripts\docker-run.cmd
```

This will launch a bash shell in in the Docker container. From there, run any of the [Makefile](/Makefile) commands available to this repo:

```bash
make test           # runs unit tests
make test-coverage  # runs unit tests and prints code coverage to console
make test-report    # runs unit tests and prints code coverage as a detailed HTML report
make clean          # Cleans up any leftover files from testing
```

### Notes about the Docker container

* If you ever close the terminal interacting with the container without `exit`ing it properly, you will get an error message stating that 'The container name "/pmq" is already in use' when you next try to run it. Simply run `docker kill pmq` to kill the running container.
* Sometimes the terminal for the container will appear to stop responding to keyboard input. Simply spam Ctrl+C a few times to kill whatever process is locking up the terminal and continue as normal. If that doesn't work, open another command prompt and kill the container.