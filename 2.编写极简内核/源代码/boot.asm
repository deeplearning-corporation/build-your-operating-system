; boot.asm - 引导扇区代码
[BITS 16]
extern _kernel_main
global _start

section .text
_start:
    ; 设置段寄存器
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x1000

    ; 清屏
    mov ax, 0x0003
    int 0x10

    ; 打印引导消息
    mov si, message
    call print_string

    ; 启用保护模式
    call enable_protected_mode
    
    ; 跳转到内核
    jmp 0x08:_kernel_main

print_string:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

enable_protected_mode:
    cli
    lgdt [gdt_desc]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:protected_mode_entry
    
protected_mode_entry:
    [BITS 32]
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    ret

section .data
gdt:
    dd 0, 0
    ; 代码段
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x9A
    db 0xCF
    db 0x00
    ; 数据段
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92
    db 0xCF
    db 0x00
gdt_end:

gdt_desc:
    dw gdt_end - gdt - 1
    dd gdt

message:
    db "Hello OS world from bootloader!", 13, 10, 0

times 510 - ($ - $$) db 0
dw 0xAA55
