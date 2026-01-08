#!/bin/bash

echo "Starting PHP local server..."
cd app
php -S localhost:8000 &

sleep 2

echo "Starting Cloudflare Tunnel..."
cd ..
./tools/cloudflared/cloudflared tunnel --url http://localhost:8000
