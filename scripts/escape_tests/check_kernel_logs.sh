#!/bin/bash

echo "[*] Checking access to kernel logs..."
dmesg | head -20 || echo "Cannot read kernel logs."
