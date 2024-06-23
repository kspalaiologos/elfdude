# elfdude
a small &amp; primitive elf32 packer. (c) 2024 kamila szewczyk, made on a sunny sunday afternoon of 23-06.
```
% head -n 10 rpn.asm
use32
org 0x1000000
;; Entry point.
_entry:
  jmp main
;; Stack operations: push, pop.
;; Calling convention: MS fastcall.
stkpush:
  mov edx, eax
  mov eax, DWORD [rpnstack_size]
% fasm rpn.asm
flat assembler  version 1.73.32  (16384 kilobytes memory)
3 passes, 1570 bytes.
% ./elfdude 0x1000 16777216 rpn.bin rpn.elf
% wc -c rpn.elf
966 rpn.elf
```
