#!/bin/csh -ef

unlimit memoryuse
unlimit datasize

/bin/cat /usr/local/SYSTEM/mirror/logs/*.log | sed 's/^/\/usr\/local\/SYSTEM\/mirror\//' | /usr/bin/sort | /usr/bin/uniq > HTML.src

./mk_word.pl
/bin/mv HTML.word.new HTML.word
