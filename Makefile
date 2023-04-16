# Copyright (C) 2021 Dmitriy Nekrasov
#
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
# for more details.
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
