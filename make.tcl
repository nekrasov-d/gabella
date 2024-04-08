#!bin/pythion3
#
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
# Quartus run automatization
#
# -- Dmitry Nekrasov <bluebag@yandex.ru>   Sun, 07 Apr 2024 18:29:33 +0300

load_package flow
project_open top

exec cat top.qsf | grep -v VERILOG_FILE | grep -v SYSTEMVERILOG_FILE > top.qsf_tmp
exec cat top.qsf_tmp > top.qsf
exec rm top.qsf_tmp

set files_list {  }

lappend files_list "files"

foreach file_list $files_list {
  set FILE_LIST "[exec grep -v # $file_list]"
  foreach file $FILE_LIST {
    switch -regexp -- $file {
      {.sv}  {
               puts "set_global_assignment -name  SYSTEMVERILOG_FILE $file"
               set_global_assignment -name SYSTEMVERILOG_FILE $file
             }
      {.v}   {
               puts "set_global_assignment -name VERILOG_FILE $file"
               set_global_assignment -name VERILOG_FILE $file
             }
    }
  }
}

execute_flow -compile
# report_timing -npaths 10 -to_clock clk_25
project_close
