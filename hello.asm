; hello.asm: binary format, 32bit, origin 0x1000000
use32
org 0x1000000
mov eax, 4
mov ebx, 1
mov ecx, message
mov edx, 13
int 0x80
mov eax, 1
xor ebx, ebx
int 0x80
message: db 'Hello, World!', 0x0a