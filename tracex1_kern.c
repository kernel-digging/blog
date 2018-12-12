/* Copyright (c) 2013-2015 PLUMgrid, http://plumgrid.com
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of version 2 of the GNU General Public
 * License as published by the Free Software Foundation.
 */
#include <linux/fs.h>
#include <linux/namei.h>
#include <linux/skbuff.h>
#include <linux/netdevice.h>
#include <uapi/linux/bpf.h>
#include <linux/version.h>
#include "bpf_helpers.h"

#define EMBEDDED_LEVELS 2

 struct nameidata {
     struct path path;
     struct qstr last;
     struct path root;
     struct inode    *inode; /* path.dentry.d_inode */
     unsigned int    flags;
     unsigned    seq, m_seq;
     int     last_type;
     unsigned    depth;
     int     total_link_count;
     struct saved {
         struct path link;
         struct delayed_call done;
         const char *name;
         unsigned seq;
     } *stack, internal[EMBEDDED_LEVELS];
     struct filename *name;
     struct nameidata *saved;
     struct inode    *link_inode;
     unsigned    root_seq;
     int     dfd;
 } __randomize_layout;

#define _(P) ({typeof(P) val = 0; bpf_probe_read(&val, sizeof(val), &P); val;})

/* kprobe is NOT a stable ABI
 * kernel functions can be removed, renamed or completely change semantics.
 * Number of arguments and their positions can change, etc.
 * In such case this bpf+kprobe example will no longer be meaningful
 */
SEC("kprobe/path_init")
int bpf_prog1(struct pt_regs *ctx)
{
	char fmt [] = "nd->name:%s\n";
	const char *n;
	struct filename *name;
	struct nameidata *nd = (struct nameidata *) PT_REGS_PARM1(ctx);	

	name = _(nd->name);
	n = _(name->name);
	bpf_trace_printk(fmt, sizeof(fmt), n);

	return 0;
}

SEC("kprobe/ext4_create")
int bpf_prog2(struct pt_regs *ctx)
{
	char fmt [] = "dir inode num:%lu\n";
	unsigned long i_ino;
	struct inode *inode = (struct inode *) PT_REGS_PARM1(ctx);	

	i_ino = _(inode->i_ino);
	bpf_trace_printk(fmt, sizeof(fmt), i_ino);

	return 0;
}

SEC("kprobe/ext4_add_nondir")
int bpf_prog3(struct pt_regs *ctx)
{
	char fmt [] = "new inode num:%lu\n";
	unsigned long i_ino;
	struct inode *inode = (struct inode *) PT_REGS_PARM3(ctx);	

	i_ino = _(inode->i_ino);
	bpf_trace_printk(fmt, sizeof(fmt), i_ino);

	return 0;
}

char _license[] SEC("license") = "GPL";
u32 _version SEC("version") = LINUX_VERSION_CODE;
