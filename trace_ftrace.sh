#!/bin/bash
_TS=$(date +%s)

H=/home/vault19c
C=/proc/sys/vm
T=/sys/kernel/debug/tracing
P=$H/JBD

echo 5000 > $C/dirty_writeback_centisecs
echo 3 > $C/drop_caches
sync

echo workqueue:workqueue_queue_work > $T/set_event

# Tracing On
echo 0 > $T/trace
echo 1 > $T/tracing_on

# Excute program
./write-sync $P/hello_$_TS $1_$_TS

# Tracing Off
echo 0 > $T/tracing_on
cp $T/trace_pipe /tmp/$_TS
ls $P
mv /tmp/$_TS $H/ftrace_$1_$_TS;

