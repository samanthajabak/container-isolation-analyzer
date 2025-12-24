#!/bin/bash

echo "[*] Checking if we can see host processes..."
lsns | grep host || echo "No host namespaces visible."
