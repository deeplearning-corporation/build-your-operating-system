; boot.asm - 引导扇区代码（NASM语法）
; 汇编: nasm -f elf32 boot.asm -o boot.o

[BITS 16]           ; 16位实模式
global _start       ; 导出符号

section .text
_start:
    ; 设置段寄存器
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x1000

    ; 清屏（设置视频模式）
    mov ax, 0x0003
    int 0x10

    ; 打印引导消息
    mov si, message
    call print_string

    ; 启用保护模式
    call enable_protected_mode
    
    ; 跳转到内核（32位代码）
    jmp 0x08:kernel_main

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
    ; 禁用中断
    cli
    
    ; 加载GDT
    lgdt [gdt_desc]
    
    ; 启用保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; 远跳转刷新CS
    jmp 0x08:protected_mode_entry
    
protected_mode_entry:
    [BITS 32]
    ; 设置数据段寄存器
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    
    ret

; GDT（全局描述符表）
section .data
gdt:
    ; 空描述符
    dd 0, 0
    
    ; 代码段描述符（0x08）
    dw 0xFFFF        ; 段界限（0-15位）
    dw 0x0000        ; 基地址（0-15位）
    db 0x00          ; 基地址（16-23位）
    db 0x9A          ; 访问权（代码段，可读，已访问）
    db 0xCF          ; 标志位 + 段界限（16-19位）
    db 0x00          ; 基地址（24-31位）
    
    ; 数据段描述符（0x10）
    dw 0xFFFF        ; 段界限（0-15位）
    dw 0x0000        ; 基地址（0-15位）
    db 0x00          ; 基地址（16-23位）
    db 0x92          ; 访问权（数据段，可写，已访问）
    db 0xCF          ; 标志位 + 段界限（16-19位）
    db 0x00          ; 基地址（24-31位）
    
gdt_end:

gdt_desc:
    dw gdt_end - gdt - 1  ; GDT界限
    dd gdt                 ; GDT基地址

message:
    db "Hello OS world from bootloader!", 13, 10, 0
