// kernel.c - 内核主程序
// 函数名必须与boot.asm中的声明一致

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
    
    // 无限循环
    while(1) {
        // 使用hlt指令节省CPU
        __asm__ volatile ("hlt");
    }
}
