docker build -t pmq . --no-cache
docker run --name pmq -v D:/Repos/PlayerMadeQuests:/addon --rm -it pmq