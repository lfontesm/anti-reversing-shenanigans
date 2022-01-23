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
        call get_peb
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

get_peb:
        xor eax, eax
        mov eax, [fs:0x30]
        mov eax, [eax + 0xc]
        mov esi, [eax + 0x14]
        lodsd
        xchg eax, esi
        lodsd
        xchg eax, esi
        lodsd
        xchg eax, esi
        lodsd
        mov eax, [eax + 0x10]

find_export_dir:
        .e_lfanew   = 3Ch
        .data_dir_0 = 78h

        mov ecx, [eax + .e_lfanew]
        mov ecx, [eax + ecx + .data_dir_0]
        add ecx, eax

read_export_dir:
        .export_names_num  = 18h
        .export_funcs_addr = 1Ch
        .export_names_addr = 20h
        .export_ords_addr  = 24h

        ; Obtain info from IMAGE_EXPORT_DIRECTORY
        mov edx, [ecx + .export_funcs_addr] ; AddressOfFunctions
        mov [addrOfFunc], edx

        mov edx, [ecx + .export_names_addr] ; AddressOfNames
        mov [addrOfName], edx

        mov edx, [ecx + .export_ords_addr]  ; AddressOfNameOrdinals
        mov [addrOfOrdi], edx

        mov edx, [ecx + .export_names_num]  ; NumberOfNames
        mov [addrOfNumb], edx

        add [addrOfFunc], ecx
        add [addrOfName], ecx
        add [addrOfOrdi], ecx

section '.idata' import data readable

 library user, 'USER32.DLL',\
         kernel, 'KERNEL32.DLL'

 import user,\
        MessageBox, 'MessageBoxA'

 import kernel, \
        ExitProcess, 'ExitProcess'

section '.bss' readable writable

 msgbox dd ?
 addrOfFunc dd ?
 addrOfName dd ?
 addrOfOrdi dd ?
 addrOfNumb dd ?