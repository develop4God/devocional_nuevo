#!/bin/bash
# errors.sh - Run flutter analyze with fatal infos and grep for issues

flutter analyze --fatal-infos | grep -E 'error|warning|info' || echo "No errors, warnings, or infos found."

