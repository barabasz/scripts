#!/bin/bash

docker volume create portainer
docker pull portainer/portainer-ce:latest
docker run -d -p 9443:9443 --name portainer \
    --restart=always \
    -h portainer --domainname=YOURDOMAIN \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer:/data \
    portainer/portainer-ce
