#!/usr/bin/env bash
# Compatibility entry point for the original project.
exec bash "$(cd "$(dirname "$0")" && pwd)/bin/updateself" "$@"
