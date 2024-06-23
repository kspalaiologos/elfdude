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
  lea ecx, [eax+1]
  mov DWORD [rpnstack_size], ecx
  mov DWORD [rpnstack+eax*4], edx
  ret
stkpop:
  mov eax, DWORD [rpnstack_size]
  dec eax
  mov DWORD [rpnstack_size], eax
  mov eax, DWORD [rpnstack+eax*4]
  ret
;; The main function.
main:
  push ebx
  ;; We need to clear the BSS ourselves.
  push 256
  push 0
  push rpnstack
  call wipe
.input_loop:
  call getchar
  cmp eax, -1
  je .eof
  ; Determine if eax is a number.
  lea edx, [eax-'0']
  cmp edx, 9
  ja .parse_operator
  xor ebx, ebx
.parse_number:
  ; n = n * 10 + (c - '0')
  lea edx, [eax-'0']
  cmp edx, 9
  ja  .parse_number_done
  imul ebx, ebx, 10
  lea ebx, [eax-'0'+ebx]
  call getchar
  jmp .parse_number
.parse_number_done:
  mov eax, ebx
  jmp .operator_done
.parse_operator:
  cmp eax, '+'
  jne .not_plus
  call stkpop
  mov edx, eax
  call stkpop
  add eax, edx
  jmp .operator_done
.not_plus:
  cmp eax, '-'
  jne .not_minus
  call stkpop
  mov edx, eax
  call stkpop
  sub eax, edx
  jmp .operator_done
.not_minus:
  cmp eax, '*'
  jne .not_times
  call stkpop
  mov edx, eax
  call stkpop
  imul eax, edx
  jmp .operator_done
.not_times:
  cmp eax, '/'
  jne .not_slash
  call stkpop
  mov ecx, eax
  call stkpop
  cdq
  idiv ecx
.operator_done:
  call stkpush
  jmp .input_loop
.not_slash:
  cmp eax, 10
  jne .input_loop
  xor ebx, ebx
.print_stack:
  cmp DWORD [rpnstack_size], ebx
  jle .input_loop
  push DWORD [rpnstack+ebx*4]
  call print_number
  mov eax, DWORD [rpnstack_size]
  dec eax
  ; Stupid hack.
  mov edx, ' '
  cmp eax, ebx
  jne .not_end
  mov edx, 10 ; '\n'
.not_end:
  push edx
  call putchar
  inc ebx
  jmp .print_stack
.eof:
  mov eax, 1
  mov ebx, 0
  int 0x80
;; Convenient wrappers over Linux syscalls.
;; read(fd = esp+8, buf = esp+12, count = esp+16) -> eax
read:
  push ebx
  mov ecx, DWORD [esp+12]
  mov edx, DWORD [esp+16]
  mov eax, 3
  mov ebx, DWORD [esp+8]
  int 0x80
  pop ebx
  ret
;; write(fd = esp+8, buf = esp+12, count = esp+16) -> eax
write:
  push ebx
  mov ecx, DWORD [esp+12]
  mov edx, DWORD [esp+16]
  mov eax, 4
  mov ebx, DWORD [esp+8]
  int 0x80
  pop ebx
  ret
;; getchar() -> eax
getchar:
  push ebx
  lea ecx, [esp-4]
  mov eax, 3
  xor ebx, ebx
  mov edx, 1
  int 0x80
  or  edx, -1
  test eax, eax
  jle .no_eof
  mov edx, DWORD [esp-4]
.no_eof:
  mov eax, edx
  pop ebx
  ret
;; putchar(c = esp+8) -> eax
putchar:
  push ebx
  mov eax, 4
  mov ebx, 1
  lea ecx, [esp+8]
  mov edx, ebx
  int 0x80
  pop ebx
  ret
;; print_number(n = esp+8)
print_number:
  push ebp
  push edi
  push esi
  push ebx
  sub esp, 32
  mov esi, DWORD [esp+32+20]
  test esi, esi
  jne .nonzero
  mov DWORD [esp+16], '0'
  mov eax, 4
  mov ebx, 1
  lea ecx, [esp+16]
  mov edx, ebx
  int 0x80
  jmp .end
.nonzero:
  jns .positive
  mov DWORD [esp+16], '-'
  mov eax, 4
  mov ebx, 1
  lea ecx, [esp+16]
  mov edx, ebx
  int 0x80
  neg esi
.positive:
  xor edi, edi
  lea ebx, [esp+15]
  mov ecx, 10
.make_buffer:
  inc edi
  mov eax, esi
  cdq
  idiv ecx
  mov esi, eax
  add edx, 48
  mov BYTE [ebx+edi], dl
  test eax, eax
  jne .make_buffer
  lea ebp, [esp+16]
  mov esi, 4
.print_buffer:
  dec edi
  movsx eax, BYTE [edi+ebp]
  mov DWORD [esp+12], eax
  mov eax, esi
  mov ebx, 1
  lea ecx, [esp+12]
  mov edx, ebx
  int 0x80
  test edi, edi
  jne .print_buffer
.end:
  add esp, 32
  pop ebx
  pop esi
  pop edi
  pop ebp
  ret
;; wipe(dst = esp+8, c = esp+12, count = esp+16)
wipe:
  push edi
  mov eax, DWORD [esp+12]
  mov ecx, DWORD [esp+16]
  mov edi, DWORD [esp+8]
  rep stosb
  pop edi
  ret

;; "BSS"
rpnstack: times 255 dd 0
rpnstack_size: dd 0