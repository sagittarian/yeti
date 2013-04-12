#!/bin/bash

rm yeti.zip
cd ..
zip yeti yeti/yeti.{css,js,php,sass,coffee} yeti/readme.txt
mv yeti.zip yeti

