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
# Basic Makefile, nothing to comment here
#
# -- Dmitry Nekrasov <bluebag@yandex.ru>   Sun, 07 Apr 2024 18:29:33 +0300

PROJECT = top

default:
	quartus_sh --64bit -t make.tcl | ./log_filter.sh
	#quartus_sta $(PROJECT) --do_report_timinig
	cat output_files/$(PROJECT).flow.rpt | grep -A 16 -B 1 \;\ Flow\ Summary
	quartus_cpf -c output_files/$(PROJECT).sof output_files/$(PROJECT).rbf
	md5sum output_files/$(PROJECT).rbf

clean:
	rm -rf output_files
	rm -rf db
	rm -rf incremental_db/
	rm -rf hps_isw_handoff/
	rm -rf output_files/
	rm -rf c5_pin_model_dump.txt
	rm -rf hps_sdram_p0_summary.csv
	rm -rf $(PROJECT).qws
