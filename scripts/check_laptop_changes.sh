#!/bin/bash
# Quick script to check what's modified on laptop host
# Run this on LAPTOP HOST

echo "Checking uncommitted changes on laptop host..."
echo ""

cd /home/daniel/shadowhound

echo "Main repo changes:"
git status --short
echo ""

echo "Main repo diff:"
git diff
echo ""

echo "─────────────────────────────────────────────────"
echo "DIMOS submodule changes:"
cd src/dimos-unitree
git status --short
echo ""

echo "DIMOS diff:"
git diff
echo ""

echo "─────────────────────────────────────────────────"
echo "Specific file: dimos/exceptions/agent_memory_exceptions.py"
git diff dimos/exceptions/agent_memory_exceptions.py
