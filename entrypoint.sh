#!/bin/sh -l

echo "Hello there sir again $1"
time=$(date)
echo "::set-output name=time::$time"
