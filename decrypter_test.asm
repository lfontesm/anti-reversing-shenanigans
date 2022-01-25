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
        rol dl, cl
        xor dl, 1Eh
        mov cl, al
        shl cl, 5
        and cl,2
        rol dl,cl
        add dl,al
        inc esi
        sub bl, 1
        ja a
        push 0
        call [ExitProcess]

crypted:
        db 0xAB, 0xA4, 0x75, 0x9A, 0xAC, 0xDB, 0xE7, 0x61, 0x0C, 0x96, 0x84, 0x45, 0xE7, 0x24, 0x58, 0xCC, 0x66, 0x18, 0x7F, 0x03, 0x96, 0xC0, 0x7D, 0xBB, 0xF4, 0x2D, 0x34, 0x6E, 0xCE, 0xBF, 0x86, 0x4C, 0xB4
        len db $-crypted



section '.idata' import data readable

 library user, 'USER32.DLL',\
         kernel, 'KERNEL32.DLL'

 import user,\
        MessageBox, 'MessageBoxA'

 import kernel, \
        ExitProcess, 'ExitProcess'