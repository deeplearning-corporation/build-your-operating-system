// kernel.c - 内核主程序（C语言）
// 编译: gcc -m32 -ffreestanding -nostdlib -fno-stack-protector -c kernel.c -o kernel.o

// 内核入口点 - 由boot.asm跳转至此
void kernel_main(void) {
    // 直接操作显存（文本模式，0xB8000是显存地址）
    char *video_memory = (char*)0xB8000;
    
    // 在第1行显示主消息
    const char *msg1 = "Hello OS world from C kernel!";
    int i = 0;
    int offset = 0;  // 第1行起始位置
    
    while (msg1[i] != '\0') {
        video_memory[offset + i*2] = msg1[i];     // 字符
        video_memory[offset + i*2 + 1] = 0x07;    // 属性：灰色文字，黑色背景
        i++;
    }
    
    // 在第2行显示附加消息
    const char *msg2 = "Kernel is running in 32-bit protected mode";
    i = 0;
    offset = 160;  // 第2行偏移（80*2）
    
    while (msg2[i] != '\0') {
        video_memory[offset + i*2] = msg2[i];
        video_memory[offset + i*2 + 1] = 0x0E;    // 属性：黄色文字
        i++;
    }
    
    // 在第3行显示系统信息
    const char *msg3 = "Built with NASM, GCC, and custom linker script";
    i = 0;
    offset = 320;  // 第3行偏移（160*2）
    
    while (msg3[i] != '\0') {
        video_memory[offset + i*2] = msg3[i];
        video_memory[offset + i*2 + 1] = 0x0B;    // 属性：青色文字
        i++;
    }
    
    // 无限循环，停止CPU
    while(1) {
        // 使用hlt指令节省CPU
        __asm__ volatile ("hlt");
    }
}
