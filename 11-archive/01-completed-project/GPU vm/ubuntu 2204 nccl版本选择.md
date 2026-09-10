---
share_link: https://share.note.sx/xb6h06xp#S/KQrEQ8vHiat7fCKhOoRA
share_updated: 2026-08-19T20:59:14+08:00
---
# 使用`2.18.3-1`nccl 编译 nccl-test
执行下面命令, cuda报错
```
root@nccltest08192:~/nccl-tests-master#  ./build/all_reduce_perf --minbytes 1G --maxbytes 2G -g4 -n40 -c1 -w10
# nccl-tests version 2.19.7 nccl-headers=21803 nccl-library=21803
# Collective test starting: all_reduce_perf
# nThread 1 nGpus 4 minBytes 1073741824 maxBytes 2147483648 step: 1048576(bytes) warmup iters: 10 iters: 40 agg iters: 1 validation: 1 graph: 0 unalign: 0
#
# Using devices
#  Rank  0 Group  0 Pid  93200 on nccltest08192 device  0 [0000:f9:05] NVIDIA H200
#  Rank  1 Group  0 Pid  93200 on nccltest08192 device  1 [0000:fb:05] NVIDIA H200
#  Rank  2 Group  0 Pid  93200 on nccltest08192 device  2 [0000:fd:05] NVIDIA H200
#  Rank  3 Group  0 Pid  93200 on nccltest08192 device  3 [0000:ff:05] NVIDIA H200
#
#                                                              out-of-place                       in-place          
#       size         count      type   redop    root     time   algbw   busbw  #wrong     time   algbw   busbw  #wrong 
#        (B)    (elements)                               (us)  (GB/s)  (GB/s)             (us)  (GB/s)  (GB/s)         
nccltest08192: Test CUDA failure common.cu:502 'an illegal memory access was encountered'
 .. nccltest08192 pid 93200: Test failure common.cu:632
 .. nccltest08192 pid 93200: Test failure common.cu:930
 .. nccltest08192 pid 93200: Test failure all_reduce.cu:574
 .. nccltest08192 pid 93200: Test failure common.cu:972
 .. nccltest08192 pid 93200: Test failure common.cu:1768
 .. nccltest08192 pid 93200: Test failure common.cu:1454
```


# 使用upstream nccl (`2.31.2-1`)编译测试
`nccl-test` 测试正常
```
root@nccltest08192:~/nccl-tests-master# ./build/all_reduce_perf --minbytes 1G --maxbytes 2G -g4 -n40 -c1 -w10
# nccl-tests version 2.19.7 nccl-headers=23102 nccl-library=23102
# Collective test starting: all_reduce_perf
# nThread 1 nGpus 4 minBytes 1073741824 maxBytes 2147483648 step: 1048576(bytes) warmup iters: 10 iters: 40 agg iters: 1 validation: 1 graph: 0 unalign: 0
#
# Using devices
#  Rank  0 Group  0 Pid  97166 on nccltest08192 device  0 [0000:f9:05] NVIDIA H200
#  Rank  1 Group  0 Pid  97166 on nccltest08192 device  1 [0000:fb:05] NVIDIA H200
#  Rank  2 Group  0 Pid  97166 on nccltest08192 device  2 [0000:fd:05] NVIDIA H200
#  Rank  3 Group  0 Pid  97166 on nccltest08192 device  3 [0000:ff:05] NVIDIA H200
#
#                                                              out-of-place                       in-place          
#       size         count      type   redop    root     time   algbw   busbw  #wrong     time   algbw   busbw  #wrong 
#        (B)    (elements)                               (us)  (GB/s)  (GB/s)             (us)  (GB/s)  (GB/s)         
  1073741824     268435456     float     sum      -1  4523.62  237.36  356.04       0  4539.85  236.51  354.77       0
  1074790400     268697600     float     sum      -1  4562.52  235.57  353.35       0  4542.38  236.61  354.92       0
```

# 附录
## nccl-test编译命令
```
make MPI=1 MPI_HOME=/usr/lib/x86_64-linux-gnu/openmpi  CUDA_HOME=/usr/local/cuda-12.8 NCCL_HOME=/usr/lib/x86_64-linux-gnu -j 70
```

