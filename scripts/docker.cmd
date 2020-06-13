docker build -t pmq . --no-cache
docker run --name pmq -v D:/Repos/PlayerMadeQuests:/pmq --rm -it pmq