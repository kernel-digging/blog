#!/bin/bash
_TS=$(date +%s)
TS=$1_$_TS

H=/home/vault19
C=/proc/sys/vm
T=/sys/kernel/debug/tracing
P=$H/no_JBD

sync
echo 3 > $C/drop_caches
echo 5000 > $C/dirty_writeback_centisecs

# If tools located at other path, modify below.
BCC_TOOLS=/usr/share/bcc/tools

start() {
    # Btrace On
    # sudo bash -c "btrace /dev/sdb > /tmp/btrace_$TS" &
    # _PID=$!

    # Start Write
    ./write-sync $P/hello_$TS $TS &
    sudo $BCC_TOOLS/offcputime -K -p $! 3 > /tmp/offcpu_$TS

    # Btrace Off (with Ctrl-C)
    # sudo kill -SIGINT $_PID

    # Copy Log
    sudo mv /tmp/*_$TS $H/
    echo "Btrace, Offcpu log written on $H/"
}

start
