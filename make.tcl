# Copyright (C) 2021 Dmitriy Nekrasov
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#
# XXX: add annotation
#

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
      {.qip} {
               puts "set_global_assignment -name QIP_FILE $file"
               set_global_assignment -name QIP_FILE $file
             }
    }
  }
}

execute_flow -compile
# report_timing -npaths 10 -to_clock clk_25
project_close
