#!/bin/bash

FILE=/home/ubuntu/.ssh/authorized_keys.orig
if [ -f "$FILE" ]; then
    cat /home/ubuntu/.ssh/authorized_keys.orig > /home/ubuntu/.ssh/authorized_keys
else 
    cp /home/ubuntu/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys.orig
fi

BACKEND_BUCKET=SED_BUCKET
mkdir -p /home/ubuntu/.ssh/keys && rm -rf /home/ubuntu/.ssh/keys/*
aws s3 cp s3://$BACKEND_BUCKET/keys/*.pub /home/ubuntu/.ssh/keys/. --recursive

PUB_KEYS=/home/ubuntu/.ssh/keys/*.pub
for f in $PUB_KEYS
do
  echo "Processing $f file..."
  # take action on each file. $f store current file name
  cat $f >> /home/ubuntu/.ssh/authorized_keys
done