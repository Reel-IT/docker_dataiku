#!/bin/bash

docker build --build-arg dssVersion=12.1.2 -f ./Dockerfile -t local/dataiku:reelit .
