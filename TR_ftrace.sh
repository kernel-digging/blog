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

# echo workqueue:workqueue_queue_work > $T/set_event
echo "function_graph" > $T/current_tracer

# Tracing On
echo 0 > $T/trace
echo 1 > $T/tracing_on

# Excute program
./write-sync $P/hello_$TS $TS

# Tracing Off
echo 0 > $T/tracing_on
cp $T/trace_pipe /tmp/$TS
ls $P
mv /tmp/$TS $H/ftrace_$TS;

