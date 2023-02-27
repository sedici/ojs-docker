#!/bin/bash
echo "Deleting old containers"
docker-compose down

echo "Removing ojs docker image"
docker image rm ojs-docker_ojs

echo "Regenerating ojs docker image"
docker build .

echo "Restarting services"
docker-compose up