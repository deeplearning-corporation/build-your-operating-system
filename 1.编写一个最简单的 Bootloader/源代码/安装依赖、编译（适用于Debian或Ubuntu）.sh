sudo apt update 
sudo apt install nasm
sudo apt install qemu-system-x86
nasm -f bin -o boot.bin boot.asm
dd if=boot.bin of=boot.img bs=512 count=1
