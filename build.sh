#!/bin/bash
if [ $# -eq 0 ]
  then
    tag='latest'
  else
    tag=$1
fi
if [ $tag != 'latest' ]
then
  echo 'Build from tag'
  docker build -f src/docker/${tag}/Dockerfile -t jkaninda/nginx-php-fpm:$tag .
else
 echo 'Build latest'
 docker build -f src/docker/8.2/Dockerfile -t jkaninda/nginx-php-fpm:$tag .
 
fi
