#!/bin/bash
# MIT License
#
# Copyright (c) 2024 Dmitriy Nekrasov
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ---------------------------------------------------------------------------------
#
# Filters quartus console output and color some lines. Also won't let you
# skip some dangerous things like implicit net declaration
#
# -- Dmitry Nekrasov <bluebag@yandex.ru>   Sun, 07 Apr 2024 18:29:33 +0300

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
    *\(14284\):*               ) print_purple "$line";; # Synthesizing away. Might be ok though

    # Useless INFO messages like "Elaborating entity ...."
    *\(10665\):*               ) ;;
    *\(12128\):*               ) ;;
    *\(12021\):*               ) ;;
    *\(12022\):*               ) ;;
    *\(12023\):*               ) ;;
    *\(12134\):*               ) ;; # Parameter assignments
    *\(18236\):*               ) ;; # Number of processors has not been specified...
    *\(169178\):*              ) ;; # Pin electrical standard info
    *\(176120\):*              ) ;; # ???
    *\(176121\):*              ) ;; # ???

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
