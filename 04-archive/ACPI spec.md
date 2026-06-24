
### 5.2.11 Definition Blocks


> [!PDF|note] [[ACPI_Spec_6.6.pdf#page=202&selection=4,39,4,43&color=note|ACPI_Spec_6.6, p.131]]
> > AML 
> AML是一种数据的组织形式，其可以通过`ASL`编译而来。所以ASL类似于
> C语言，而AML类似于字节码。
> 在ACPI中有两个表用到了AML的数据格式
> * DSDT
> * SSDT
> [deepseek 关于 AML 的解释](https://chat.deepseek.com/share/3pur9a8m9u6uq1rk6u)

> [!PDF|note] [[ACPI_Spec_6.6.pdf#page=202&selection=6,9,7,10&color=note|ACPI_Spec_6.6, p.131]]
> > The top-level organization of this information after a definition block is loaded is name-tagged in a hierarchical namespace.
> 
> 从 **definitiion block** 下面会有一些name-tagged 的层级的 namespace

> [!PDF|yellow] [[ACPI_Spec_6.6.pdf#page=202&selection=8,71,8,86&color=yellow|ACPI_Spec_6.6, p.131]]
> >  OSPM will load
>
> 这句话的意思是 有两种方式可以操作 这个table
> * 执行 `AML Load()` `LoadTable()` 操作
> * 系统初始化: OSPM 使用从 FADT 中检索到的 DSDT 指针加载差异化系统描述表 (DSDT)

> [!PDF|yellow] [[ACPI_Spec_6.6.pdf#page=202&selection=11,71,11,110&color=yellow|ACPI_Spec_6.6, p.131]]
> > OSPM will load other definition blocks 
> 
> 这里相当于从RSDT/XSDT 中，可能会引用其他的SSDT

> [!PDF|todo] [[ACPI_Spec_6.6.pdf#page=202&selection=13,54,13,65&color=todo|ACPI_Spec_6.6, p.131]]
> >  RSDT/XSDT.
> 
> 这里还涉及两个表



单词翻译:

> [!PDF|translate] [[ACPI_Spec_6.6.pdf#page=202&selection=9,64,9,76&color=translate|ACPI_Spec_6.6, p.131]]
> > encountering
> 
> 遭遇, 遇到
# Chapter 6 Device Configuration

> [!PDF|] [[ACPI_Spec_6.6.pdf#page=431&selection=3,0,3,20|ACPI_Spec_6.6, p.360]]
> > DEVICE CONFIGURATION
>

