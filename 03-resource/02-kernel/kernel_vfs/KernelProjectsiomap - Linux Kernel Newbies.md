---
title: KernelProjects/iomap - Linux Kernel Newbies
source: https://kernelnewbies.org/KernelProjects/iomap
author:
published:
created: 2026-06-25
description:
tags:
  - clippings
---
## iomap

**iomap allows filesystems to ==<mark style="background:#d3f8b6">sequentially</mark> iterate== over ranges in an inode and ==apply operations== to it.**

**iomap <mark style="background:#d3f8b6">grew out of </mark> the need to provide a modern block mapping abstraction for filesystems with the ==different IO access methods== they support and assisting  the VFS with <mark style="background:#d2cbff">manipulating files into the page cache</mark>.** iomap helpers are provided for each of these mechanisms. However, **block mapping is just one of the features of iomap**, given iomap supports **==DAX==** IO for filesystems and also supports the `lseek / llseek` `SEEK_DATA / SEEK_HOLE` interfaces.

Block mapping provides a mapping between data cached in memory and the location on persistent storage where that data lives. [LWN has an <mark style="background:#d3f8b6">incredible</mark> review of the ==old buffer-heads block-mapping== and why they are ==inefficient==](https://lwn.net/Articles/930173/), since the the <mark style="background:#d3f8b6">inception</mark> of Linux. Since buffer-heads work on a 512-byte block based <mark style="background:#d3f8b6">paradigm</mark>, **it creates an ==overhead== for modern storage media which ==no longer necessarily works only on 512-blocks==**. **iomap is <mark style="background:#d3f8b6">flexible</mark> providing block ranges ==in bytes==**. iomap, with the support of **folios**, provides a modern replacement for buffer-heads.

This document <mark style="background:#d3f8b6">strives</mark> to provide a template for LSFMM for what will hopefully eventually become upstream Linux kernel documentation for iomap and guidance for developers on <mark style="background:#d3f8b6">converting</mark> a filesystem over from buffer-heads to iomap.

## A modern block abstraction

iomap allows filesystems to query storage media for data using **byte ranges**. **Since block mapping are provided for ==a byte ranges for cache data in memory==, in the page cache, naturally this implies operations on block ranges will also deal with multipage operations in the page cache**. Folios are used to help provide multipage operations in memory for the byte ranges being worked on.

## struct iomap\_ops

A filesystem is must provide a ==struct `iomap_ops`== for to deal with the beginning an IO operation, ==`iomap_begin()`==, and ending an IO operation on a block range, ==`iomap_end()`==. You would call iomap with a specialized iomap operation depending on its filesystem or the VFS needs.

For example `iomap_dio_rw()` would be used for for a filesystem when doing a block range read or write operation with direct IO. In this case your fileystems's <mark style="background:#d3f8b6">respective</mark> struct file\_operations.write\_iter() would <mark style="background:#d3f8b6">eventually</mark> <mark style="background:rgba(136, 49, 204, 0.2)">call `iomap_dio_rw()` on the filesystem's struct `file_operations.write_iter()`.</mark>

<mark style="background:rgba(136, 49, 204, 0.2)">For buffered IO a fileseystem would use iomap_file_buffered_write() on the same struct file_operations.write_iter().</mark> But that is not the only situation in which a filesystem would deal with buffered writes, you could also use buffered writes when a filesystem has to deal with ==struct `file_operations.fallocate()`==. **However fallocate() can be used for ==zeroing== or for ==truncation purposes==. A special respective `iomap_zero_range()` would be used for zeroing, and a `iomap_truncate_page()` would be used for truncation.**

**XFS was the first filesystem** to adopt iomap and experience with it has shown that the filesystem implementation of these operations can be simplified<mark style="background:#d3f8b6"> considerably </mark>if one struct iomap_ops is provided per major filesystem IO operation:

- buffered io
- direct io
- DAX io
- filemap for with extended attributes (FIEMAP\_FLAG\_XATTR)
- lseek

For example, XFS has:

- struct iomap\_ops xfs\_ **read** \_iomap\_ops\` iomap
- struct iomap\_ops xfs\_ **direct\_write** \_iomap\_ops
- struct iomap\_ops xfs\_ **dax\_write** \_iomap\_ops
- struct iomap\_ops xfs\_ **buffered\_write** \_iomap\_ops
- struct iomap\_ops xfs\_ **xattr** \_iomap\_ops
- struct iomap\_ops xfs\_ **seek** \_iomap\_ops

## struct iomap\_dio\_ops

Used for direct-IO. These will call iomap\_dio\_write().

- struct iomap\_dio\_ops.end\_io()
- struct iomap\_dio\_ops.submit\_io()

## struct iomap\_writeback\_ops

The struct iomap\_writeback\_ops is used for when dealing with a filesystem struct address\_space\_operations.writepages(), for writeback.

- struct iomap\_writeback\_ops

## Calling iomap

You call **iomap** depending on the type of filesystem operation you are working on. We detail some of these interactions below.

### Calling iomap for bufferred IO writes

You call **iomap** for buffered IO with:

- iomap\_file\_buffered\_write() - for buffered writes
- iomap\_page\_mkwrite() - when dealing callbacks for struct vm\_operations\_struct:
	- struct vm\_operations\_struct.page\_mkwrite()
		- struct vm\_operations\_struct.fault()
		- struct vm\_operations\_struct.huge\_fault()
		- struct vm\_operations\_struct.pfn\_mkwrite()\`

You **may** use buffered writes to also deal with fallocate():

- iomap\_zero\_range() on fallocate for zeroing
- iomap\_truncate\_page() on fallocate for truncation

Typically you'd also happen to use these on paths when updating an inode's size.

### Calling iomap for direct IO

You call **iomap** for direct IO with:

- iomap\_dio\_rw()

You **may** use direct IO writes to also deal with fallocate():

- iomap\_zero\_range() on fallocate for zeroing
- iomap\_truncate\_page() on fallocate for truncation

Typically you'd also happen to use these on paths when updating an inode's size.

### Calling iomap for reads

You can call into **iomap** for reading, ie, dealing with the filesystems's struct file\_operations:

- struct file\_operations.read\_iter(): note that depending on the type of read your filesystem might use iomap\_dio\_rw() for direct IO, generic\_file\_read\_iter() for buffered IO and dax\_iomap\_rw() for DAX.
- struct file\_operations.remap\_file\_range() - currently the special dax\_remap\_file\_range\_prep() helper is provided for DAX mode reads.

### Calling iomap for userspace file extent mapping

The fiemap ioctl can be used to allow userspace to get a file extent mapping. The older bmap() (aka FIBMAP) allows the VM to map logical block offset to physical block number. bmap() is a legacy block mapping operation supported only for the ioctl and two areas in the kernel which likely are broken (the default swapfile implementation and odd md bitmap code). bmap() was only useful in the days of ext2 when there were no support for delalloc or unwritten extents. Consequently, the interface reports nothing for those types of mappings. Because of this we don't want filesystems to start exporting this interface if they don't already do so.

The fiemap ioctl is supported through an inode struct inode\_operations.fiemap() callback.

You would use iomap\_fiemap() to provide the mapping. You could use two seperate struct iomap\_ops one for when requested to also map extended attributes (FIEMAP\_FLAG\_XATTR) and your another struct iomap\_ops for regular read struct iomap\_ops when there is no need for extended attributes. In the future **iomap** may provide its own dedicated ops structure for **fiemap**.

iomap\_bmap() exists and should **only be used** by filesystems that **already** supported FIBMAP. FIBMAP **should not be used** with the address\_space -- we have iomap readpages and writepages for that.

### Calling iomap for assisting the VFS

A filesystem also needs to call **iomap** when assisting the VFS manipulating a file into the page cache.

#### Calling iomap for VFS reading

A filesystem can call **iomap** to deal with the VFS reading a file into folios with:

- iomap\_bmap() - called to assist the VFS when manipulating page cache with struct address\_space\_operations.bmap(), to help the VFS map a logical block offset to physical block number.
- iomap\_read\_folio() - called to assist the page cache with struct address\_space\_operations.read\_folio()
- iomap\_readahead() - called to assist the page cache with struct address\_space\_operations.readahead()

#### Calling iomap for VFS writepages

A filesystem can call **iomap** to deal with the VFS write out of pages back to backing store, that is to help deal with a filesystems's struct address\_space\_operations.writepages(). The special iomap\_writepages() is used for this case with its own respective filestems's struct iomap\_ops for this.

#### Calling iomap for VFS llseek

A filesystem struct address\_space\_operations.llseek() is used by the VFS when it needs to move the current file offset, the file offset is in struct file.f\_pos. **iomap** has special support for the llseek SEEK\_HOLE or SEEK\_DATA interfaces:

- iomap\_seek\_hole(): for when the struct address\_space\_operations.llseek() *whence* argument is SEEK\_HOLE, when looking for the file's next hole.
- iomap\_seek\_data(): for when the struct address\_space\_operations.llseek() *whence* argument is SEEK\_DATA when looking for the file's next data area.

Your own 'struct iomap\_ops\` for this is encouraged.

### Calling iomap for DAX

You can use dax\_iomap\_rw() when calling iomap from a DAX context, this is typically from the filesystems's struct file\_operations.write\_iter() callback.

## Converting filesystems from buffer-head to iomap guide

These are generic guidelines on converting a filesystem over to **iomap** from **buffer-heads**.

### One op at at time

You may try to convert a filesystem with different clustered set of operations at time, below are a generic order you may strive to target:

- direct io
- miscellaneous helpers (seek/fiemap/bmap)
- buffered io

### Defining a simple filesystem

A simple filesystem is perhaps the easiest to convert over to **iomap**, a simple filesystem is one which:

- does not use fsverify, fscrypt, compression
- has no Copy on Write support (reflinks)

#### Converting a simple filesystem to iomap

Simple filesystems should covert to IOMAP piecemeal wise first converting over **direct IO**, then the miscellaneous helpers (seek/fiemap/bmap) and last should be buffered IO.

### iomap\_folio\_ops

A filesystem can optionally set the struct iomap it returns with the folio\_ops set if it needs to override the default iomap\_get\_folio() (which calls \_\_filemap\_get\_folio(). **iomap** uses either the default iomap\_get\_folio() or the struct iomap\_folio\_ops.get\_folio() the filesystem sets when beginning buffered writes. Since **iomap** works on byte ranges buffered writes start with iomap\_file\_buffered\_write(), which iterate over byte ranges with iomap\_write\_iter(). Prior to each write it will use iomap\_write\_begin() which in turn will use the appropriate folio ops to get / put the folio.

#### Dynamic mappings considerations

Filesystems that have dynamic mappings (e.g. anything other than zonefs) should fill out the struct iomap.validity\_cookie with a filesystem specific sequence number when doing page cache operations so that those ops can re-query the filesystem for mapping data if the mappings change out from under the operation. This is required because, for example, writeback doesn't take the vfs locks.

The validity\_cookie is filesystem specific, and the filesystem struct iomap\_folio\_ops.iomap\_valid() is used prior to a buffered write to ensure that the cached **iomap** is not stale. Memory reclaim could reclaim a previously partially written folio while **iomap** is doing buffered writes at the file offset.

### Converting shared filesystem features

Shared filesystems features such as fscrypt, compression, erasure coding, and any other data transformations need to be ported to **iomap** first, as none of the current **iomap** users require any of this functionality.

### Converting complex filesystems

If your filesystem relies on any shared filesystem features mentioned above those would need to be converted piecemeal wise. If reflinks are supported you need to first ensure proper locking sanity in order to be able to address byte ranges can be handled properly through **iomap** operations. An example filesystem where this work is taking place is btrfs.

### When to set iomap on srcmap or dstmap

The struct iomap is required to be set on iomap\_begin(), if its a **CoW** path also set srcmap when used with iomap\_begin().

This perhaps should be redesigned in the future depending on read / write requirements and it may take time to get this right.

### Removal of IOMAP\_F\_BUFFER\_HEAD

IOMAP\_F\_BUFFER\_HEAD won't be removed until we have all filesystem fully converted away from **buffer-heads**, and this could be never.

IOMAP\_F\_BUFFER\_HEAD should be avoided as a stepping stone / to port filesystems over to **iomap** as it's support for **buffer-heads** only apply to the buffered write path and nothing else including the read\_folio/readahead and writepages aops.

### Testing Direct IO

Other than fstests you can use LTP's dio, however this tests is limited as it does not test stale data.

```
./runltp -f dio -d /mnt1/scratch/tmp/
```

### Known issues and future improvements

Other than lack of documetnation there are some known issues and limitatiosn with **iomap** at this time. We try to itemize them here:

- write amplification on IOMAP when bs < ps
	- **iomap** needs improvements for large folios for dirty bitmap tracking

### Q&A

- Why does btrfs only have a few IOMAP calls:
	- the current **iomap** use case is only for direct I/O
		- converting the buffered I/O code is a lot more work
		- btrfs does a lot of really odd things in its buffered I/O path that can't work with iomap and should be fixed (Goldwyn has been working on this)

### References

---

[CategoryDocs](https://kernelnewbies.org/CategoryDocs)