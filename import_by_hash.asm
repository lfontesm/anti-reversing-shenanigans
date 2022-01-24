format PE GUI

entry start

include 'win32ax.inc'

section '.text' code readable executable

start:
        .alloc_granularity = 10000h
        mov ebx, [esp]
        xor bx, bx
        sub ebx, .alloc_granularity

        lea ebp, [__imp_tab_start]

find_export_dir:
        .e_lfanew = 3Ch
        mov eax, [ebx + .e_lfanew]

        .data_dir_0 = 78h

        mov eax, [ebx + eax +.data_dir_0]

        add eax, ebx

read_export_dir:
        .export_names_num  = 18h
        .export_funcs_addr = 1Ch
        .export_names_addr = 20h
        .export_ords_addr  = 24h

        mov ecx, [eax + .export_funcs_addr]
        mov edx, [eax + .export_names_addr]
        mov esi, [eax + .export_ords_addr]
        mov edi, [eax + .export_names_num]

        mov [addrOfFunc], ecx
        mov [addrOfName], edx
        mov [addrOfOrdi], esi
        mov [addrOfNumb], edi

        add [addrOfFunc], ebx
        add [addrOfName], ebx
        add [addrOfOrdi], ebx

        xor ecx, ecx

find_exports:
        mov esi, [addrOfName]
        mov esi, [esi + ecx*4]
        add esi, ebx

        mov edx, 5381
.djb2:
        mov eax, edx
        shl edx, 5
        add edx, eax
        xor eax, eax
        lodsb
        add edx, eax
        test eax, eax
        jnz .djb2

        mov esi, ebp

.find_table_entry:
        lodsd
        test eax, eax
        jz .next_export
        cmp eax, edx
        jne .find_table_entry

.get_export_addr:
        mov eax, [addrOfOrdi]
        mov ax, [eax + ecx*2]
        and eax, 0000FFFFh
        mov edi, [addrOfFunc]
        mov eax, [edi + eax*4]
        add eax, ebx
        mov [esi - 4], eax

.next_export:
        inc ecx
        cmp ecx, [addrOfNumb]
        jl find_exports

next_dll:
        mov edi, ebp
        xor eax, eax
        repnz scasd
        mov esi, edi
        lodsb
        test al, al
        jz done_importing
        lea ebp, [esi + eax - 1]
        push esi
        mov ecx, LoadLibraryA
        call dword [ecx]
        mov ebx, eax
        jmp find_export_dir

done_importing:
        ; call main

        push 0
        push _msg
        push _msg
        push 0
        call [MessageBoxA]

        push 0
        call [ExitProcess]

_msg db 'this is test', 0

section '.idata' code readable writable executable

macro import_start {}
macro import_end { dd 0 }

macro use dll, [imp_name] {
      common
        imp_num = 0

        db @f - $, dll, 0
        align 8
        @@:

      forward
          local imp, imp_len, i, h, c
          virtual at 0
              imp::
                  db `imp_name
                  db 0
              imp_len = $ - 1
          end virtual

          ; hash using djb2
          i = 0
          h = 5381
          while i <= imp_len
              load c byte from imp:i
              h = ((h shl 5) + h + c) mod 0x100000000
              i = i + 1
          end while

          if dll eq 'kernel32' & imp_num = 0
            #__imp_tab_start:
          end if

          label imp_name:dword
            dd h

          imp_num = imp_num + 1
      common
          dd 0  ; terminate table entry
  }

  ; 115 bytes table, 172 bytes import asm
  ; equivalent default imp table is 358 bytes saving 71 bytes already
  ; with this small table
  import_start
    use 'kernel32',\
      AcquireSRWLockExclusive,\
      GetProcessAffinityMask,\
      LoadLibraryA,\
      GetProcAddress,\
      ExitProcess

    use 'user32',\
      DispatchMessageA,\
      MessageBoxA,\
      DestroyWindow
  import_end

;section '.bss' readable writable

; msgbox dd ?
 addrOfFunc dd ?
 addrOfName dd ?
 addrOfOrdi dd ?
 addrOfNumb dd ?