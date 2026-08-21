---
data: 2026-08-20
问题分类: host shutdown
是否定位成功: true
目前结论: 无
is_issue: true
instance: 11.211.129.109
share_link: https://share.note.sx/8sbi57i6#LOX+ULAezNE5lh+Z0TsJgQ
share_updated: 2026-08-20T20:05:00+08:00
---

# 现象
BMC 控制台无输出:
![[Pasted image 20260820183807.png]]

串口日志最后几行也没用有用信息
```
[ 1970-09-10T08:11:17+08:00 ] [11687.042815][ C92] hrtimer: interrupt took 18709 ns
[ 1970-09-11T08:47:52+08:00 ] [100289.948552][T10866] [cbd][cbd_delete_dev.675][INFO]: delete vol-2nzvchoipt_i-me9m71jco4, cbd0
[ 1970-09-11T08:47:52+08:00 ] [100289.955069][T10817] [cbd][cbd_shadow_release.1482][INFO]: release shadow cbd0 vol-2nzvchoipt_i-me9m71jco4 cbd0
[ 1970-09-11T08:47:52+08:00 ] [100289.957161][T10866] [cbd][cbd_delete_dev.699][INFO]: delete fail, vol-2nzvchoipt_i-me9m71jco4, cbd0, mark deleting fail, ret -16
[ 1970-09-11T08:47:52+08:00 ] [100289.991972][ T4513] [cbd][cbd_delete_dev.675][INFO]: delete vol-2nzvchoipt_i-me9m71jco4, cbd0
[ 1970-09-11T08:47:52+08:00 ] [100290.001251][ T4513] [cbd][_mark_deleting.391][INFO]: vol-2nzvchoipt_i-me9m71jco4, cbd0 set disk queue dying
[ 1970-09-11T08:47:52+08:00 ] [100290.012105][ T4513] [cbd][cbd_delete_dev.705][INFO]: mark async deleting ok, vol-2nzvchoipt_i-me9m71jco4, cbd0
[ 1970-09-11T08:47:52+08:00 ] [100290.022852][T1397232] [cbd][_delete_dev.636][INFO]: do delete vol-2nzvchoipt_i-me9m71jco4, cbd0
[ 1970-09-12T06:56:55+08:00 ]
```

查看电源状态，被关机了，操作日志中没有什么特别信息:

![[4876fc04211a541287be5a4ce0adf7b8.png]]

> [!note] 在关机前，没有BMC的登陆