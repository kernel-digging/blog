#!/bin/bash
_R1='\033[0;31m'
_Y1='\033[1;33m'
NC='\033[0m' # No Color

H1() { echo "${_R1}$@${NC}" ; }
H2() { echo "${_Y1}$@${NC}" ; }
LOG() { echo -e $@ ; }
GREP() { grep --color=always $@ ; }

reverse() {
    i=2 I_TMP=${1: -$i}
    while [ "$i" -lt ${#1} ]; do
        I_TMP+=${1:(-$[$i+2]):(-$i)}
        i=$[i+2]
    done
    echo $I_TMP
}

# Print file's Inode, Blocks
# I stands for Inode, G stands for Group
# E stands for Extent, D stands for Data
anatomy() {
    TGT=$1
    if [ ! -f "$TGT" ] && [ ! -d "$TGT" ] ; then
        LOG 'ERR: Pass existing file name'
        return 0
    elif [ -h "$TGT" ] ; then
        TGT=$(readlink -e $TGT)
    fi

    DEV=$(df $TGT | tail -1 | awk '{print $1}' )
    read I S <<< $(stat -c '%i %s' $TGT)
    __STAT=$(fsstat $DEV)
    _STAT=$(grep -A 4 'BLOCK GROUP INFORMATION' <<< $__STAT)
    _STAT_I=$(awk '{print $NF}' <<< $(grep 'Inodes' <<< $_STAT))
    _STAT_D=$(awk '{print $NF}' <<< $(grep 'Blocks' <<< $_STAT))

    # Number of Inode, Data in one EXT4 group
    LOG "Inode/Data Blks per one Grp : $_STAT_I / $_STAT_D"

    G_IDX=$[I/_STAT_I]
    # Info about EXT Group
    G_STAT=$(grep -A 8 "Group: $G_IDX:" <<< $__STAT)
    G_I_START=$(awk '{print $3}' <<< $(grep 'Inode Range' <<< $G_STAT))
    G_I_OFFSET=$[I-G_I_START]
    GREP -E "$G_I_START|$" <<< "$G_STAT"

    G_I_Nth_BLK=$[G_I_OFFSET/16]
    _TMP=$[G_I_Nth_BLK*16]
    G_I_Nth_BLK_Idx=$[G_I_OFFSET-_TMP]

    LOG "Inode: $(H1 $I) / Group: $G_IDX / Nth Inode: ($G_I_OFFSET) <=$(H1 $I)-$(H1 $G_I_START)"
    LOG "Inode BLK: $G_I_OFFSET/16=$G_I_Nth_BLK, $G_I_Nth_BLK_Idx"

    G_I_BLK_START=$(awk '{print $3}' <<< $(grep 'Inode Table' <<< $G_STAT))
    G_I_BLK_LOCATED=$[G_I_BLK_START+G_I_Nth_BLK]
    OFFSET=$((G_I_Nth_BLK_Idx*256))

    LOG "Inode located at:" $(H1 $G_I_BLK_LOCATED "+ $G_I_Nth_BLK_Idx*256 Byte")
    I_BLK=$(blkcat -h $DEV $G_I_BLK_LOCATED | grep -A 8 -w $OFFSET)
    E_TREE=$(reverse $(echo $(grep -oP "0af3[^.]*" <<< $I_BLK) | tail -c 5))

    I_D_BLK=$(istat $DEV $I)


    if [ "$E_TREE" -gt 0 ]; then
        export DEBUGFS_PAGER=cat;
        _EXT=$(debugfs -R "ex <$I>" $DEV)
        EXT=$(tail -n +2 <<< $_EXT)
        D_BLK=$(awk '{print $8}' <<< $(head -n1 <<< $EXT))
        D_BLK_HEX=$(printf "%08x" $D_BLK)
        RD_BLK_HEX=$(reverse $D_BLK_HEX)
    elif [ "$E_TREE" -eq 0 ]; then
        # strip whitespace
        # https://stackoverflow.com/a/12973694
        D_BLK=$(awk '/Direct Blocks:/{getline; print}' <<< $I_D_BLK | awk '{print $1}')
        D_BLK_HEX=$(printf "%08x\n" $D_BLK)
        RD_BLK_HEX=$(reverse $D_BLK_HEX)
    fi

    LOG "[Dumping Inode : $(H1 $G_I_BLK_LOCATED) ($(H2 $[G_I_BLK_LOCATED*8])) from $OFFSET]"
    GREP -E "0af3|$RD_BLK_HEX|$" <<< $I_BLK

    # Print Extra Lines (Extent)
    if [ "$E_TREE" -gt 0 ]; then
        LOG "[Dumping Extent Table]"
        GREP -E "$D_BLK|$" <<< $EXT | head -5
    fi

    LOG "[Dumping First Direct (Extent) Block : $(H1 $D_BLK) ($(H2 $[D_BLK*8])) 0x$D_BLK_HEX]"
    blkcat -h $DEV $D_BLK | head -5 | GREP -E "0af3|$"
}

anatomy $1 || echo "anatomy <filename>"

