#!/bin/bash

set -x

dart pub publish --dry-run --verbose > log.txt
FILE_PATH=$(grep 'MSG : Logs written to' log.txt)
if [[ ${FILE_PATH} =~ "(/[^/]*)+/" ]]; then echo ${BASH_REMATCH[1]}; fi
echo "FILE_PATH: ${FILE_PATH}"

# egrep '^\.{1,2}(/.*[^/])?$'

# ERROR=$(dart pub publish --dry-run 2> /dev/null | grep error)
# # BB=$(echo ${ERROR} | grep -e error)
# # | grep 'error'

# echo ${ERROR}

exit 0