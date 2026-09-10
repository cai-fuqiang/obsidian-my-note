---
share_link: https://share.note.sx/oklyhv26#6wsV8niuPOutpvNohBsoQw
share_updated: 2026-09-01T11:19:52+08:00
---
# 测试项
* netperf
* redis
* apache-tomcat
* wrk

<!-- * nginx-->
# netperf

| test_item                     | throughput_avg |
| :---------------------------- | :------------- |
| netperf-test_w-TCP_STREAM     | 31598.99       |
| netperf-test_w-TCP_RR         | 93055.48       |
| netperf-pvm-on-kvm-TCP_STREAM | 20643.363      |
| netperf-pvm-on-kvm-TCP_RR     | 33706.447      |
| netperf-kvm-on-kvm-TCP_STREAM | 19365.637      |
| netperf-kvm-on-kvm-TCP_RR     | 79164.393      |
# redis

| test_item                                                   | avg_rps_avg | min_rps_avg | max_rps_avg |
| :---------------------------------------------------------- | :---------- | :---------- | :---------- |
| redis-benchmark-bare-clients-50-pipeline-1-threads-1        | 58241.593   | 57473.92    | 59009.267   |
| redis-benchmark-bare-clients-50-pipeline-1-threads-4        | 49562.833   | 49513.587   | 49612.08    |
| redis-benchmark-bare-clients-50-pipeline-16-threads-1       | 564454.003  | 526325.53   | 602582.477  |
| redis-benchmark-bare-clients-50-pipeline-16-threads-4       | 394227.737  | 393186.147  | 395269.323  |
| redis-benchmark-pvm-on-kvm-clients-50-pipeline-1-threads-1  | 45616.94    | 45197.243   | 46036.637   |
| redis-benchmark-pvm-on-kvm-clients-50-pipeline-1-threads-4  | 33938.36    | 33796.207   | 34080.517   |
| redis-benchmark-pvm-on-kvm-clients-50-pipeline-16-threads-1 | 312751.647  | 293260.19   | 332243.103  |
| redis-benchmark-pvm-on-kvm-clients-50-pipeline-16-threads-4 | 197177.53   | 196465.173  | 197889.877  |
| redis-benchmark-kvm-on-kvm-clients-50-pipeline-1-threads-1  | 54650.193   | 54202.59    | 55097.803   |
| redis-benchmark-kvm-on-kvm-clients-50-pipeline-1-threads-4  | 44073.593   | 43834.047   | 44313.147   |
| redis-benchmark-kvm-on-kvm-clients-50-pipeline-16-threads-1 | 362044.227  | 340920.57   | 383167.89   |
| redis-benchmark-kvm-on-kvm-clients-50-pipeline-16-threads-4 | 197435.61   | 196980.84   | 197890.377  |

# memtier

| test_item                                           | ops_sec_avg | latency_ms_avg | kb_sec_avg |
| :-------------------------------------------------- | :---------- | :------------- | :--------- |
| memtier-bare-clients-50-pipeline-1-threads-1        | 58421.813   | 0.856          | 0.93       |
| memtier-bare-clients-50-pipeline-1-threads-4        | 61318.113   | 3.261          | 3.242      |
| memtier-bare-clients-50-pipeline-16-threads-1       | 345441.417  | 2.311          | 2.039      |
| memtier-bare-clients-50-pipeline-16-threads-4       | 384494.513  | 8.313          | 7.839      |
| memtier-pvm-on-kvm-clients-50-pipeline-1-threads-1  | 42880.1     | 1.165          | 1.234      |
| memtier-pvm-on-kvm-clients-50-pipeline-1-threads-4  | 46210.11    | 4.326          | 4.244      |
| memtier-pvm-on-kvm-clients-50-pipeline-16-threads-1 | 228659.147  | 3.493          | 3.204      |
| memtier-pvm-on-kvm-clients-50-pipeline-16-threads-4 | 258081.513  | 12.395         | 12.159     |
| memtier-kvm-on-kvm-clients-50-pipeline-1-threads-1  | 49543.68    | 1.008          | 1.076      |
| memtier-kvm-on-kvm-clients-50-pipeline-1-threads-4  | 52001.843   | 3.845          | 3.764      |
| memtier-kvm-on-kvm-clients-50-pipeline-16-threads-1 | 264584.613  | 3.018          | 2.522      |
| memtier-kvm-on-kvm-clients-50-pipeline-16-threads-4 | 283490.093  | 11.279         | 11.092     |

# wrk-tomcat

| test_item                                       | requests_sec_avg | transfer_mb_sec_avg | latency_avg_ms_avg |
| :---------------------------------------------- | :--------------- | :------------------ | :----------------- |
| wrk-tomcat-bare-connections-200-threads-4       | 4137.75          | 0.774               | 231.03             |
| wrk-tomcat-pvm-on-kvm-connections-200-threads-4 | 2838.383         | 0.531               | 235.727            |
| wrk-tomcat-kvm-on-kvm-connections-200-threads-4 | 3396.047         | 0.635               | 231.553            |
