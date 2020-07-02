#!/bin/bash

# Revert to orig authorized_keys files and create if for the fisrt time
if [ -f "/home/ubuntu/.ssh/authorized_keys.orig" ]; then
    cat /home/ubuntu/.ssh/authorized_keys.orig > /home/ubuntu/.ssh/authorized_keys
fi
cp /home/ubuntu/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys.orig

export BACKEND_BUCKET=SED_BUCKET
mkdir -p /home/ubuntu/.ssh/keys && rm -rf /home/ubuntu/.ssh/keys/*
aws s3 cp s3://$BACKEND_BUCKET/keys/ /home/ubuntu/.ssh/keys/. --recursive --exclude id_rsa

export PUB_KEYS=/home/ubuntu/.ssh/keys/*
for f in $PUB_KEYS
do
  echo "Processing $f file..."
  comment=$(echo "$f" | rev | cut -d "/" -f 1 | rev)
  cat $f >> /home/ubuntu/.ssh/authorized_keys
  echo " - $comment" >> /home/ubuntu/.ssh/authorized_keys
done