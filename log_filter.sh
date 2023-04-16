#!/bin/bash
# Copyright (C) 2021 Dmitriy Nekrasov
#
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
# for more details.
#
# Filters quartus console output and color some lines. Also won't let you
# skip some dangerous things like implicit net declaration

error=0
error_report_fname="log_filter_error_report.txt"

if [ -f "$error_report_fname" ]; then
  rm $error_report_fname
fi

print_red () {
  echo -e "\e[01;31m$1\e[0m"
  echo $1 >> $error_report_fname
}

print_yellow () {
  echo -e "\e[01;33m$1\e[0m"
}

print_blue () {
  echo -e "\e[01;34m$1\e[0m"
}

print_purple () {
  echo -e "\e[01;35m$1\e[0m"
}



while read line
do
  case $line in
    Error:*   | Error\ \(*     ) print_red    "$line" && error=1;;
    *"created implicit net"*   ) print_red    "$line" && error=2;;
    *"inferring latch"*        ) print_red    "$line" && error=3;;
    "Critical Warning"*        ) print_purple "$line";;

    *\(10665\):*               ) ;;

    Warning:* | Warning\ \(*   ) print_yellow "$line";;
    Info:*    | Info\ \(*      ) print_blue   "$line";;
    *                          ) echo          $line;;
  esac
done

if [ -f "$error_report_fname" ]; then
  echo -e "\e[01;31m"
  echo "FIX THIS:"
  cat $error_report_fname
  echo -e "\e[0m"
  rm $error_report_fname
fi

exit $error
