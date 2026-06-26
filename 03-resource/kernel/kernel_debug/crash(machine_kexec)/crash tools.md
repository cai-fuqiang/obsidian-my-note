## vmcore保存pagecache
可以配置`/etc/kdumpctl.conf`
```sh
core_collector makedumpfile -l --message-level 7 -d 1
                                                    ^^(默认为31)
```
来保存`pagecache`, 不过vmcore文件会很大,生成很慢