# Makefile for standalone Music service (S2)

VER=v0.8

SERVER=`docker inspect s2 --format '{{.NetworkSettings.IPAddress}}'`
PORT=30001

build-mcli:
	docker image build -f Dockerfile -t mcli:$(VER) .

run-mcli:
	docker container run -it --rm --name mcli mcli:$(VER) python3 mcli.py $(SERVER) $(PORT)
