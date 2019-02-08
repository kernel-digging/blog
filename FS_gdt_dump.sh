#!/bin/bash

mkdir gdt
dump() {
    BLK=$(fsstat /dev/sdb1 | grep -A 6 "Group: $1:" | grep "Group Descriptor Table:" | awk '{print $4}');
    echo "$(blkcat -h /dev/sdb1 $BLK)" > gdt/blk_grp_$1_$BLK
}

#0 1 3 5 7 9 25 27 49 81
dump 0
dump 1
dump 3
dump 5
dump 7
dump 9
dump 25
dump 27
dump 49
dump 81
