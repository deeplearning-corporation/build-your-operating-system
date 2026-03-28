// linker.ld - 链接脚本
// 定义内核的内存布局

OUTPUT_FORMAT(elf32-i386)
ENTRY(_start)

SECTIONS
{
    /* 内核加载地址（1MB处，但我们的引导会加载到0x1000） */
    . = 0x1000;
    
    /* 代码段 */
    .text : {
        *(.text)
        *(.text.*)
    }
    
    /* 只读数据段 */
    .rodata : {
        *(.rodata)
        *(.rodata.*)
    }
    
    /* 数据段 */
    .data : {
        *(.data)
        *(.data.*)
    }
    
    /* BSS段（未初始化数据） */
    .bss : {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    }
    
    /* 调试信息（可选） */
    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
        *(.note.*)
    }
}
