# PlayerMadeQuests

Create and share your own custom quests in World of Warcraft: Classic!

## Running unit tests w/ Docker in Windows

From the repo directory, run:

```bash
./scripts/docker.cmd
```

This will launch a bash shell in in the Docker container. From there, run any of the Makefile commands:

```bash
make test # runs unit tests
make test-coverage # runs unit tests and prints code coverage to console
make test-report # runs unit tests and prints code coverage as a detailed HTML report
```

## Planned Features

Check out the [Issues](issues) page for features in the works for PMQ.