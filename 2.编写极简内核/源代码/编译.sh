#!/bin/bash
# build.sh - 构建脚本
# 用法: ./build.sh [clean|run|debug]

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 文件名
BOOT_ASM="boot.asm"
KERNEL_C="kernel.c"
LINKER_SCRIPT="linker.ld"
BOOT_OBJ="boot.o"
KERNEL_OBJ="kernel.o"
KERNEL_ELF="kernel.elf"
KERNEL_BIN="kernel.bin"
BOOT_BIN="boot.bin"
OS_IMG="os.img"

# 工具链
NASM="nasm"
GCC="gcc"
LD="ld"
OBJCOPY="objcopy"
DD="dd"
QEMU="qemu-system-x86_64"

# 检查依赖
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    if ! command -v $NASM &> /dev/null; then
        echo -e "${RED}Error: nasm not found. Install with: sudo apt-get install nasm${NC}"
        exit 1
    fi
    
    if ! command -v $GCC &> /dev/null; then
        echo -e "${RED}Error: gcc not found. Install with: sudo apt-get install gcc${NC}"
        exit 1
    fi
    
    if ! command -v $LD &> /dev/null; then
        echo -e "${RED}Error: ld not found. Install with: sudo apt-get install binutils${NC}"
        exit 1
    fi
    
    if ! command -v $QEMU &> /dev/null; then
        echo -e "${RED}Warning: qemu not found. Install with: sudo apt-get install qemu-system-x86${NC}"
        echo -e "${YELLOW}Will continue but cannot run the OS${NC}"
    fi
    
    echo -e "${GREEN}All dependencies satisfied!${NC}"
}

# 清理
clean() {
    echo -e "${YELLOW}Cleaning...${NC}"
    rm -f $BOOT_OBJ $KERNEL_OBJ $KERNEL_ELF $KERNEL_BIN $BOOT_BIN $OS_IMG
    echo -e "${GREEN}Clean complete!${NC}"
}

# 构建
build() {
    echo -e "${YELLOW}Building kernel...${NC}"
    
    # 1. 汇编引导代码
    echo -e "  [1/5] Assembling bootloader..."
    $NASM -f elf32 $BOOT_ASM -o $BOOT_OBJ
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to assemble bootloader${NC}"
        exit 1
    fi
    
    # 2. 编译C内核
    echo -e "  [2/5] Compiling C kernel..."
    $GCC -m32 -ffreestanding -nostdlib -fno-stack-protector \
         -fno-pic -fno-pie -c $KERNEL_C -o $KERNEL_OBJ
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to compile C kernel${NC}"
        exit 1
    fi
    
    # 3. 链接内核（生成ELF）
    echo -e "  [3/5] Linking kernel..."
    $LD -m elf_i386 -T $LINKER_SCRIPT $BOOT_OBJ $KERNEL_OBJ -o $KERNEL_ELF
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to link kernel${NC}"
        exit 1
    fi
    
    # 4. 提取纯二进制内核
    echo -e "  [4/5] Extracting raw kernel binary..."
    $OBJCOPY -O binary $KERNEL_ELF $KERNEL_BIN
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to extract kernel binary${NC}"
        exit 1
    fi
    
    # 5. 创建引导扇区二进制
    echo -e "  [5/5] Creating boot sector..."
    # 从ELF中提取.text段作为引导扇区
    $OBJCOPY -O binary -j .text $BOOT_OBJ $BOOT_BIN
    # 确保引导扇区大小为512字节
    $DD if=/dev/zero of=$BOOT_BIN bs=512 count=1 2>/dev/null
    $OBJCOPY -O binary -j .text $BOOT_OBJ $BOOT_BIN.tmp
    $DD if=$BOOT_BIN.tmp of=$BOOT_BIN conv=notrunc 2>/dev/null
    rm -f $BOOT_BIN.tmp
    
    # 6. 创建磁盘镜像
    echo -e "  [6/5] Creating disk image..."
    cat $BOOT_BIN $KERNEL_BIN > $OS_IMG
    # 确保镜像大小为512字节的倍数
    $DD if=/dev/zero of=$OS_IMG bs=512 count=$$((($(stat -c%s $OS_IMG 2>/dev/null || echo 0) + 511) / 512)) 2>/dev/null || true
    
    # 显示文件大小
    BOOT_SIZE=$(stat -c%s $BOOT_BIN 2>/dev/null || echo "0")
    KERNEL_SIZE=$(stat -c%s $KERNEL_BIN 2>/dev/null || echo "0")
    IMG_SIZE=$(stat -c%s $OS_IMG 2>/dev/null || echo "0")
    
    echo -e "${GREEN}Build successful!${NC}"
    echo -e "  Boot sector: ${BOOT_SIZE} bytes"
    echo -e "  Kernel: ${KERNEL_SIZE} bytes"
    echo -e "  Disk image: ${IMG_SIZE} bytes"
}

# 运行
run() {
    if [ ! -f $OS_IMG ]; then
        echo -e "${RED}Error: Disk image not found. Please run ./build.sh first${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Starting QEMU...${NC}"
    $QEMU -drive format=raw,file=$OS_IMG \
          -monitor stdio \
          -m 128M \
          -vga std \
          -display sdl,gl=off
}

# 调试模式
debug() {
    if [ ! -f $OS_IMG ]; then
        echo -e "${RED}Error: Disk image not found. Please run ./build.sh first${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Starting QEMU in debug mode...${NC}"
    echo -e "${YELLOW}Run 'gdb' in another terminal and connect with: target remote localhost:1234${NC}"
    $QEMU -drive format=raw,file=$OS_IMG \
          -monitor stdio \
          -s -S \
          -m 128M \
          -vga std
}

# 显示信息
info() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}Hello OS Kernel - Build Info${NC}"
    echo -e "${GREEN}================================${NC}"
    echo -e "Files:"
    echo -e "  - ${BOOT_ASM}: Bootloader (NASM)"
    echo -e "  - ${KERNEL_C}: C kernel"
    echo -e "  - ${LINKER_SCRIPT}: Linker script"
    echo -e "  - build.sh: Build script"
    echo -e ""
    echo -e "Commands:"
    echo -e "  ./build.sh      - Build the kernel"
    echo -e "  ./build.sh run  - Run in QEMU"
    echo -e "  ./build.sh debug- Run in debug mode"
    echo -e "  ./build.sh clean- Clean build files"
    echo -e "  ./build.sh info - Show this info"
}

# 主函数
main() {
    case "$1" in
        clean)
            clean
            ;;
        run)
            check_dependencies
            if [ ! -f $OS_IMG ]; then
                build
            fi
            run
            ;;
        debug)
            check_dependencies
            if [ ! -f $OS_IMG ]; then
                build
            fi
            debug
            ;;
        info)
            info
            ;;
        *)
            check_dependencies
            build
            ;;
    esac
}

# 执行主函数
main "$@"
