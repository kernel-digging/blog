#!/bin/bash


# Print file's Inode, Blocks
# I stands for Inode, G stands for Group
anatomy() {
    if [ ! -f $1 ] ; then
        echo 'ERR: Pass existing file name'
        return 0
    fi

    DEV=$(df $1 | tail -1 | awk '{print $1}' )
    I=$(ls -ali $1 | awk '{print $1}')
    __STAT=$(fsstat $DEV)
    _STAT=$(grep -A 4 'BLOCK GROUP INFORMATION' <<< $__STAT)
    _STAT_I=$(awk '{print $NF}' <<< $(grep 'Inodes' <<< $_STAT))
    _STAT_D=$(awk '{print $NF}' <<< $(grep 'Blocks' <<< $_STAT))

    # Number of Inode, Data in one EXT4 group
    echo "Inode/Data Blks per one Grp : $_STAT_I / $_STAT_D"

    G_IDX=$[I/_STAT_I]
    # Info about EXT Group
    grep -A 8 "Group: $G_IDX:" <<< $__STAT
    G_STAT=$(grep -A 8 "Group: $G_IDX:" <<< $__STAT)
    G_I_START=$(awk '{print $3}' <<< $(grep 'Inode Range' <<< $G_STAT))
    G_I_OFFSET=$((I-G_I_START))

    G_I_Nth_BLK=$((G_I_OFFSET/16))
    _TMP=$((G_I_Nth_BLK*16))
    G_I_Nth_BLK_Idx=$((G_I_OFFSET-_TMP))

    echo "Inode: $I / Group: $G_IDX / Nth Inode: $red($G_I_OFFSET) <=$I-$G_I_START"
    echo "Inode BLK: $G_I_OFFSET/12=$G_I_Nth_BLK, $G_I_Nth_BLK_Idx"

    G_I_BLK_START=$(awk '{print $3}' <<< $(grep 'Inode Table' <<< $G_STAT))
    G_I_BLK_LOCATED=$((G_I_BLK_START+G_I_Nth_BLK))

    echo "Inode located at:" $G_I_BLK_LOCATED "+ $G_I_Nth_BLK_Idx*256 Byte"

    OFFSET=$((G_I_Nth_BLK_Idx*256))
    echo "Dumping $G_I_BLK_LOCATED from $OFFSET"
    blkcat -h $DEV $G_I_BLK_LOCATED | grep -A 16 -w $OFFSET

    istat $DEV $I ;
}

echo "anatomy() function defined! -- anatomy <filename>"
echo 'To use without sudo, add "$USER" to "disk" group'

