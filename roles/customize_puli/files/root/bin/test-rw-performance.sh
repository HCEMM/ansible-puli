#!/bin/bash

# All credits to https://www.reddit.com/r/truenas/comments/1f4rp6k/comment/lkr98xs

echo "Sequential READ speed with big blocks QD32 (this should be near the number you see in the specifications for your drive)"
echo 
fio --name TESTSeqRead --eta-newline=5s --filename=fio-tempfile-RSeq1.dat --rw=read --size=350g --io_size=350g --blocksize=1024k --fsync=10000 --iodepth=32 --direct=1 --numjobs=1 --runtime=120 --group_reporting
echo
echo "Sequential WRITE speed with big blocks QD32 (this should be near the number you see in the specifications for your drive)"
echo
fio --name TESTSeqWrite --eta-newline=5s --filename=fio-tempfile-WSeq.dat --rw=write --size=500m --io_size=50g --blocksize=1024k --fsync=10000 --iodepth=32 --direct=1 --numjobs=1 --runtime=60 --group_reporting
echo
echo "Random 4K read QD1 (this is the number that really matters for real world performance unless you know better for sure)"
echo
fio --name TESTRandom4kRead --eta-newline=5s --filename=fio-tempfile-RanR4K.dat --rw=randread --size=500m --io_size=50g --blocksize=4k --fsync=1 --iodepth=1 --direct=1 --numjobs=1 --runtime=60 --group_reporting
echo
echo "Mixed random 4K read and write QD1 with sync (this is worst case performance you should ever expect from your drive, usually less than 1% of the numbers listed in the spec sheet)"
echo
fio --name TESTRandom4kRW --eta-newline=5s --filename=fio-tempfile-RanRW4k.dat --rw=randrw --size=500m --io_size=10g --blocksize=4k --fsync=1 --iodepth=1 --direct=1 --numjobs=1 --runtime=60 --group_reporting
echo