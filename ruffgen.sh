#!/bin/bash

apis=$(find "./apis" -type f)
echo $apis

rm -r reference
mkdir reference
for api in $apis
do
    echo $api
    echo $(dirname $api)
    echo "$(dirname ${api#./apis/})/$(basename ${api%.*}).md"
    mkdir -p "reference/$(dirname ${api#./apis/})"
    lua extract-docs.lua $api "reference/$(dirname ${api#./apis/})/$(basename ${api%.*}).md"
done 