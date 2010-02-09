#!/bin/sh
#
# swank.sh - Starts a swank instance using GNU screen.
#

# Copyright (c) 2010, Volkan YAZICI <volkan.yazici@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# Swank configurations.
PORT=5004
CODING_SYSTEM="utf-8-unix"

# Swank related directory and file paths.
SWANK_HOME="/var/swank"
PID_FILE="${SWANK_HOME}/screen-${PORT}.pid"
START_SCRIPT="${SWANK_HOME}/swank-start.lisp"

# Lisp implementation configurations.
LISP="/usr/bin/sbcl"
LISP_PARAMS="--no-userinit"

# Will be used user for the process.
USER="swank"


case "$1" in
start)
	echo -n "Starting swank server... "

	touch $PID_FILE
	chown $USER $PID_FILE

	# Don't specify an --ignore-environment (-i) argument for the
	# env command, otherwise it will cause STY environment
	# variable to get unexported. (STY will be written into
	# PID_FILE by swank-start.lisp script.) Same caution goes for
	# the su command too. (Beware --login (-, -l) arguments.)
	screen -d -m -c /dev/null -S swank.$PORT \
	su $USER -c "/usr/bin/env \
	             SWANK_PORT=$PORT \
		     SWANK_CODING_SYSTEM=$CODING_SYSTEM \
		     SWANK_PID_FILE=$PID_FILE \
		     $LISP $LISP_PARAMS --load $START_SCRIPT"
		       
	[ $? -eq 0 ] && echo "done." || echo "failed!"
	;;

stop)
	echo -n "Stopping swank server... "
	STY="`cat $PID_FILE 2>/dev/null`"
	STY="`echo ${STY%%.*}`"

	# [FIXME] There should be a more feasible way of shutting down
	# a lisp instance. We don't want to lead to a corruption by
	# killing a process unexpectedly. (Interruptions might be
	# considered but they are not so portable accross different
	# lisp implementations.)
	[ -e "/proc/${STY}" ] && \
	kill "$STY" 2>/dev/null && \
	rm -f $PID_FILE
	
	[ $? -eq 0 ] && echo "done." || echo "failed!"
	;;

restart)
	$0 stop
	$0 start
	;;

*)
	echo "Usage: $0 <start|stop|restart>"
	;;
esac
