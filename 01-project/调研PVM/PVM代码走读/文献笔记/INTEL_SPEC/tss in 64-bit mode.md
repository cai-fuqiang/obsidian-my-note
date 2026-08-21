> [!summary] 64-bit mode中不再支持基于硬件的task switch
> [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3262&selection=9,86,10,71|📖 64-bit mode中没有task switch]], [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3262&selection=10,71,11,23&color=important|📖64 bit mode中task switch 由软件负责]]

> [!note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3262&selection=24,0,24,110&color=important|📖 虽然 没有task-switch 但是仍然需要 TSS 来完成一些其他的事情]]

> [!summary] TSS 在64-bit mode 中主要用来存储完成上下文切换的必要信息
> * [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3262&selection=30,0,30,4&color=important|📖 RSPn]] : 用来存储低特权级别到高特权级切换时，高异常级别的`rsp`
> * [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3262&selection=36,0,36,4&color=important|📖 ISTn]] : 用来存储IST
> * [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3262&selection=42,0,43,1&color=important|📖 io-bitmap base address]]: #TODO

> [!tip] 所以, [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3262&selection=45,0,45,85&color=important|📖操作系统在64-bit mode 中至少需要一个 TSS]]