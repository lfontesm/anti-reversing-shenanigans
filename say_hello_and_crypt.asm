format PE GUI
entry start

include 'win32ax.inc'

section '.text' code readable executable writable

start:
        call routine
        push eax
        push ebx
        lea eax, [routine]
crypt:
        mov bl, [eax]
        cmp bl, 0xc3
        jz exit
        xor bl, 0xa8
        mov [eax], bl
        inc eax
        jmp crypt

exit:
        push 0
        call [ExitProcess]

routine:
        push MB_OK
        call aux
        db 'Quente', 0

aux:
        call bux
        db 'Batata', 0

bux:
        push HWND_DESKTOP
        call [MessageBox]
        ret

section '.idata' import data readable

 library user, 'USER32.DLL',\
         kernel, 'KERNEL32.DLL'

 import user,\
        MessageBox, 'MessageBoxA'

 import kernel, \
        ExitProcess, 'ExitProcess'