format PE GUI

include 'win32ax.inc'

section '.text' code readable executable writable

start:
        lea esi, [crypted]
        xor eax, eax
        mov bl, byte [len]
        or edx, 0xFFFFFFFF
a:
        mov al, byte [esi]
        xor byte [esi], dl
        mov cl, al
        and cl, 2
        ror dl, cl
        xor dl, 1Eh
        mov cl, al
        shr cl, 5
        and cl,2
        ror dl,cl
        add dl,al
        inc esi
        sub bl, 1
        ja a
        push 0
        call [ExitProcess]

crypted:
        db 'This is suposed to be crypted...', 0
        len db $-crypted



section '.idata' import data readable

 library user, 'USER32.DLL',\
         kernel, 'KERNEL32.DLL'

 import user,\
        MessageBox, 'MessageBoxA'

 import kernel, \
        ExitProcess, 'ExitProcess'