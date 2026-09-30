#!/bin/csh -ef

unlimit memoryuse
unlimit datasize

./mk_inv.pl
./mk_idx.pl
./mk_dir.pl
/bin/mv HTML.inv HTML.flist HTML.idx HTML.dir ..

cd ..
/usr/bin/gzip -9 < HTML.inv > archive/HTML.inv.gz
/usr/bin/gzip -9 < HTML.flist > archive/HTML.flist.gz
/usr/bin/gzip -9 < HTML.idx > archive/HTML.idx.gz
/usr/bin/gzip -9 < HTML.dir > archive/HTML.dir.gz

cd archive
/sbin/md5 * | /usr/bin/grep -v CHECKSUM.MD5 > CHECKSUM.MD5

exit 0
