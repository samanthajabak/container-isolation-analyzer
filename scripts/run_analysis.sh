#!/bin/bash

set -e

echo "[ANALYZER] Starting container isolation analysis..."

cd /scripts/escape_tests

echo "[*] Checking filesystem mounts..."
./check_mounts.sh

echo "[*] Checking namespace isolation..."
./check_namespaces.sh

echo "[*] Checking Linux capabilities..."
./check_capabilities.sh

echo "[*] Checking device exposure..."
./check_devices.sh

echo "[*] Checking kernel log access..."
./check_kernel_logs.sh

echo "[ANALYZER] Analysis complete."
