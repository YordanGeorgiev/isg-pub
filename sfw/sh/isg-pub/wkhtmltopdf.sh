#!/bin/bash

#xvfb-run -a -s "-screen 0 640x480x16" wkhtmltopdf $@
#--listen-tcp \
#--listen-tcp=1234 \
sh /usr/bin/xvfb-run \
--error-file=/dev/stdout \
--auto-servernum \
--server-args="-screen 1 1366x768x24" /usr/local/bin/wkhtmltopdf \
--page-size A4 --orientation Portrait \
--zoom 0.75 \
--page-width 800 \
--margin-bottom 15 \
--margin-left 10 \
--margin-right 1 \
--margin-top 15 $*
