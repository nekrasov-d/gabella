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
