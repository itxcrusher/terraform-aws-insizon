#!/bin/bash
# Bash script to count the number of lines of code in project 
# using cloc cli tool and send results to endpoint
# https://github.com/AlDanial/cloc
# https://github.com/marketplace/actions/count-lines-of-code-cloc



cloc \
--exclude-lang="node_modules, build ,package-lock.json" . \
| awk 'NR>1 {sum += $5} END {print sum}'