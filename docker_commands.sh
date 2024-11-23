#!/usr/bin/env bash

sudo docker build -t mchavinda/blog .
sudo docker tag mchavinda/blog mchavinda/blog:latest
sudo docker push mchavinda/blog:latest

