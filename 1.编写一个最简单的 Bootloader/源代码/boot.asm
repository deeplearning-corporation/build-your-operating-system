; boot.asm - 最简单的引导扇区程序
; 编译: nasm -f bin boot.asm -o boot.bin
; 运行: qemu-system-x86_64 boot.bin

[BITS 16]          ; 16位实模式
[ORG 0x7C00]       ; BIOS将引导扇区加载到0x7C00

start:
    ; 设置段寄存器
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00  ; 设置栈指针

    ; 设置视频模式为文本模式（清除屏幕）
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; 显示字符串
    mov si, msg     ; 字符串地址
    call print

    ; 无限循环
    jmp $

print:
    ; 打印字符串（以0结尾）
    mov ah, 0x0E    ; BIOS teletype 功能
.loop:
    lodsb           ; 加载SI指向的字符到AL
    cmp al, 0       ; 检查是否结束
    je .done
    int 0x10        ; 打印字符
    jmp .loop
.done:
    ret

msg: db "Hello OS world", 13, 10, 0  ; 13=回车, 10=换行, 0=结束符, 这个代码也就是输出 Hello OS world 这一个字符串

; 填充剩余空间并添加引导签名
times 510-($-$$) db 0  ; 填充0直到第510字节
dw 0xAA55              ; 引导扇区签名（最后两个字节）这必须是 0x55AA （BIOS 认可的签名）
