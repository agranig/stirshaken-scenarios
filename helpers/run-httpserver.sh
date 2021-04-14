#!/bin/sh

PORT=$1
if [ -z "$PORT" ]; then
    PORT="80"
fi

python -m SimpleHTTPServer "$PORT"
