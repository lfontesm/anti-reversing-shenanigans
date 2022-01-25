; -------------------------------------------------------------------------------------

 format PE GUI 4.0

 entry start

 include 'win32a.inc'

; -------------------------------------------------------------------------------------

 IDD_THE_DIALOG = 102
 IDC_INPUT = 1000
 IDC_OUTPUT = 1001
 IDC_KEY = 1002
 IDC_BTN_ENCRYPT = 1005
 IDC_BTN_DECRYPT = 1006
 IDC_BTN_KEY = 1007
 IDC_BTN_TO_HEX = 1008
 IDC_BTN_TO_TXT = 1009
 IDC_BTN_RESET = 1010
 IDC_BTN_SUB_KEYS = 1011

; -------------------------------------------------------------------------------------

 section '.code' code readable executable

  start:

    invoke GetModuleHandle,0
    invoke DialogBoxParam,eax,IDD_THE_DIALOG,0,DialogProc,0

  exit:

    invoke  ExitProcess,0 

; -------------------------------------------------------------------------------------

proc DialogProc uses esi edi ebx,hwnddlg,msg,wparam,lparam

        cmp [msg],WM_INITDIALOG
        je .wminitdialog

        cmp [msg],WM_COMMAND
        je .wmcommand

        cmp [msg],WM_CLOSE
        je .wmclose

        xor eax,eax
        jmp .quit

  .wminitdialog:

        invoke SetDlgItemText,[hwnddlg],IDC_INPUT,szInputInfoText
        invoke SetDlgItemText,[hwnddlg],IDC_OUTPUT,szOutputInfoText
        invoke SetDlgItemText,[hwnddlg],IDC_KEY,szKeyInfoText

        stdcall onInitDialog

        jmp .done

  .wmcommand:

        cmp [wparam], BN_CLICKED shl 16 + IDC_BTN_SUB_KEYS
        je .SHOW_SUB_KEYS

        cmp [wparam], BN_CLICKED shl 16 + IDC_BTN_ENCRYPT
        je .ENCRYPT

        cmp [wparam], BN_CLICKED shl 16 + IDC_BTN_DECRYPT
        je .DECRYPT

        cmp [wparam], BN_CLICKED shl 16 + IDC_BTN_KEY
        je .GET_KEY

        cmp [wparam], BN_CLICKED shl 16 + IDC_BTN_TO_HEX
        je .INPUT_TO_HEX

        cmp [wparam], BN_CLICKED shl 16 + IDC_BTN_TO_TXT
        je .OUTPUT_TO_TXT

        cmp  [wparam], BN_CLICKED shl 16 + IDC_BTN_RESET
        je .CLEARDATA

        jmp .done

  .SHOW_SUB_KEYS:

        stdcall onShowSubKeys

        invoke SetDlgItemText,[hwnddlg],IDC_INPUT,bfShowSubKeys

        jmp .done

  .ENCRYPT:

        invoke GetDlgItemText,[hwnddlg],IDC_INPUT,bfDisplay,2400

        stdcall onNullInput

        stdcall StrToInputBuffer

        stdcall PrintInputBuffer

        invoke SetDlgItemText,[hwnddlg],IDC_INPUT,bfDisplay

        stdcall BswapInputBuffer

        stdcall EncryptInputBuffer

        stdcall BswapOutputBuffer

        stdcall PrintOutputBuffer

        invoke SetDlgItemText,[hwnddlg],IDC_OUTPUT,bfDisplay

        jmp .done

  .DECRYPT:

        invoke GetDlgItemText,[hwnddlg],IDC_INPUT,bfDisplay,2400

        stdcall onNullInput

        stdcall StrToInputBuffer

        stdcall PrintInputBuffer

        invoke SetDlgItemText,[hwnddlg],IDC_INPUT,bfDisplay

        stdcall BswapInputBuffer

        stdcall DecryptInputBuffer

        stdcall BswapOutputBuffer

        stdcall PrintOutputBuffer

        invoke SetDlgItemText,[hwnddlg],IDC_OUTPUT,bfDisplay

        jmp .done

  .GET_KEY:

        invoke GetDlgItemText,[hwnddlg],IDC_KEY,bfDisplay,200

        stdcall StrToKeyBits

        stdcall PrintKeyBits

        stdcall BswapKeyBitsBuffer

        stdcall Init_SubKey_Arrays

        stdcall GenerateSubKeys

        invoke SetDlgItemText,[hwnddlg],IDC_OUTPUT,bfDisplay

        jmp .done

  .INPUT_TO_HEX:

        invoke GetDlgItemText,[hwnddlg],IDC_INPUT,bfDisplay,2400

        stdcall onNullInput

        stdcall InputToHex

        stdcall PrintInputBuffer

        invoke SetDlgItemText,[hwnddlg],IDC_INPUT,bfDisplay

        jmp .done

  .OUTPUT_TO_TXT:

        invoke GetDlgItemText,[hwnddlg],IDC_OUTPUT,bfDisplay,2400

        stdcall onNullInput

        stdcall StrToInputBuffer

        stdcall OutputToText

        invoke SetDlgItemText,[hwnddlg],IDC_OUTPUT,bfDisplay

        jmp .done

  .CLEARDATA:

        invoke SetDlgItemText,[hwnddlg],IDC_INPUT,szInputInfoText
        invoke SetDlgItemText,[hwnddlg],IDC_OUTPUT,szOutputInfoText
        invoke SetDlgItemText,[hwnddlg],IDC_KEY,szKeyInfoText

        jmp .done

  .wmclose:

        invoke EndDialog,[hwnddlg],0

  .done:

        mov eax,1

  .quit:

        ret

endp

; -------------------------------------------------------------------------------------

proc onInitDialog

        ; init with the zero key

        stdcall ResetKeyBits

        stdcall Init_SubKey_Arrays

        stdcall GenerateSubKeys

        ret

endp

; -------------------------------------------------------------------------------------

proc onShowSubKeys

  ; print the P array and S-boxes to the bfShowSubKeys string

        lea esi,[P_ARR]

        lea edi,[bfShowSubKeys]

        mov cx,18

        mov dx,0

  .PRINT:

        mov eax,dword [esi]

        stdcall DWordToStr

        mov [edi],byte 32

        inc edi

        ; update ESI

        add esi,4

        ; DX counts the number of dwords

        inc dx

        ; add a CRLF after every 8 dwords

        test dx,7

        jnz .NEXT

        mov [edi],byte 13
        inc edi
        mov [edi],byte 10
        inc edi

  .NEXT:

        dec cx

        cmp cx,0

        jg .PRINT

        ; move on to the next S-Box

        cmp dx,1024

        jge .DONE

        ; CRLF

        mov [edi],byte 13
        inc edi
        mov [edi],byte 10
        inc edi

        cmp dx,18

        jg .CONT

        ; CRLF

        mov [edi],byte 13
        inc edi
        mov [edi],byte 10
        inc edi

        mov dx,0

        lea esi,[S_BOXES]

  .CONT:

        mov cx,256

        jmp .PRINT

  .DONE:

        ; zero terminate the string

        mov [edi],byte 0

        ret

endp

; -------------------------------------------------------------------------------------

proc WordToStr uses edx

  ; print a word (2 bytes) to a string

  ; word passed in AX
  ; EDI set outside of this function

        mov dx,ax
        mov al,ah

        stdcall ByteToDigits

        mov [edi],ah
        inc edi

        mov [edi],al
        inc edi

        mov al,dl

        stdcall ByteToDigits

        mov [edi],ah
        inc edi

        mov [edi],al
        inc edi

        ret

endp

; -------------------------------------------------------------------------------------

proc DWordToStr

  ; print a dword (4 bytes) to a string

  ; word passed in EAX
  ; EDI set outside of this function

        locals

          tmp dw 0

        endl

        mov word [tmp],ax

        shr eax,16

        stdcall WordToStr

        mov ax,word [tmp]

        stdcall WordToStr

        ret

endp

; -------------------------------------------------------------------------------------

proc InputToHex uses edi esi

  ; convert an ascii text string to a hex number in memory

        lea esi,[bfDisplay]

        lea edi,[InputBuffer]

        ; just copy bfDisplay to InputBuffer

        stdcall ResetInputBuffer

        mov cx,0

  .COPY:

        mov al,[esi]

        cmp al,0

        je .DONE

        mov [edi],al

        inc esi
        inc edi

        inc cx

        cmp cx,1024

        jne .COPY

  .DONE:

        ; adjust CX so it is a multiple of 8 bytes

        test cx,0x7

        jz .QUIT

        shr cx,3

        inc cx

        shl cx,3

  .QUIT:

        ; save the number of bytes that were read:

        mov word [nInputBytes],cx

        ret

endp

; -------------------------------------------------------------------------------------

proc OutputToText uses esi edi

  ; convert a hex number to a text string

        lea esi,[InputBuffer]

        lea edi,[bfDisplay]

        ; just copy InputBuffer to bfDisplay

        mov cx,word [nInputBytes]

  .COPY:

        mov al,[esi]

        cmp al,32

        jl .HASH

        cmp al,126

        jg .HASH

        mov [edi],al

        jmp .NEXT

  .HASH:

        ; non-printing character - substitute the # character

        mov [edi],byte 35

  .NEXT:

        inc esi
        inc edi

        dec cx

        jcxz .DONE

        jmp .COPY

  .DONE:

        mov [edi],byte 0

        ret

endp

; -------------------------------------------------------------------------------------

proc ResetInputBuffer uses edi ecx

  ; clear the input buffer

        lea edi,[InputBuffer]

        mov cx,0

  .CLEAR:

        mov [edi],byte 0

        inc edi

        inc cx

        cmp cx,1024

        jl .CLEAR

        ret

endp

; -------------------------------------------------------------------------------------

proc ResetOutputBuffer uses edi ecx

  ; clear the output buffer

        lea edi,[OutputBuffer]

        mov cx,0

  .CLEAR:

        mov [edi],byte 0

        inc edi

        inc cx

        cmp cx,1024

        jl .CLEAR

        ret

endp

; -------------------------------------------------------------------------------------

proc ResetKeyBits uses edi ecx

  ; clear the key bits buffer

        lea edi,[KeyBits]

        mov cx,0

  .CLEAR:

        mov [edi],byte 0

        inc edi

        inc cx

        cmp cx,72

        jl .CLEAR

        ret

endp

; -------------------------------------------------------------------------------------

proc BswapInputBuffer

  ; for each 32 bit dword in the input buffer, reverse the bytes

        mov cx,word [nInputBytes]

        ; divide by 4

        shr cx,2

        lea eax,[InputBuffer]

        stdcall ReverseBytes

        ret

endp

; -------------------------------------------------------------------------------------

proc BswapOutputBuffer

  ; for each 32 bit dword in the output buffer, reverse the bytes

        mov cx,word [nInputBytes]

        ; divide by 4

        shr cx,2

        lea eax,[OutputBuffer]

        stdcall ReverseBytes

        ret

endp

; -------------------------------------------------------------------------------------

proc BswapKeyBitsBuffer

  ; for each 32 bit dword in the key bits buffer, reverse the bytes

        mov cx,18

        lea eax,[KeyBits]

        stdcall ReverseBytes

        ret

endp

; -------------------------------------------------------------------------------------

proc ReverseBytes uses esi

  ; for each 32 bit dword in a buffer, reverse the bytes

  ; address of buffer passed in EAX

  ; size of buffer in dwords passed in CX

        mov esi,eax

  .REVERSE:

        mov eax,[esi]

        bswap eax

        mov [esi],eax

        add esi,4

        dec cx

        cmp cx,0

        jg .REVERSE

        ret

endp

; -------------------------------------------------------------------------------------

proc onNullInput

  ; if the bfDisplay string is empty, set it to "0"

        lea edi,[bfDisplay]

        cmp [edi],byte 0

        jne .DONE

        mov [edi],byte 48
        mov [edi+1],byte 0

  .DONE:

        ret

endp

; -------------------------------------------------------------------------------------

proc StrToBuffer

  ; load the buffer in memory from the string bfDisplay

  ; address of input buffer is passed in EAX

  ; max number of hex digits to read passed in EDX

        locals

          count dw 0

        endl

        lea esi,[bfDisplay]

        mov edi,eax

        mov ecx,0

  .GET_CHARS:

        mov al,byte [esi]

        cmp al,0

        je .DONE

        stdcall HexDigitToValue

        ; just skip and get the next char if not a hex digit

        cmp eax,0xffff

        je .NEXT

        ; AL contains a nibble, determine where to place it in the dest byte

        ; if count is even, the nibble is mapped to the lower 4 bits in dest
        ; if count is odd, the nibble is mapped to the upper 4 bits in dest

        inc word [count]

        ; even if count AND 1 == 0

        test [count],1

        jz .EVEN

  .ODD:

        inc cx

        shl al,4

        mov [edi],al

        jmp .NEXT

  .EVEN:

        inc cx

        or [edi],al

        inc edi

  .NEXT:

        inc esi

        cmp cx,dx

        jge .DONE

        jmp .GET_CHARS

  .DONE:

        ; CX contains the number of hex digits that were read, return in EDX

        mov edx,ecx

        ret

endp

; -------------------------------------------------------------------------------------

proc PrintBuffer uses esi edi

  ; print the hex value in the buffer to the bfDisplay string

  ; address of buffer passed in EAX

  ; number of bytes in buffer passed in EDX

        locals

          count db 0

        endl

        mov esi,eax

        lea edi,[bfDisplay]

        mov ecx,edx

  .PRINT:

        ; byte to digits

        mov al,[esi]

        stdcall ByteToDigits

        ; add the 2 digits to the string

        mov [edi],ah
        inc edi

        mov [edi],al
        inc edi

        dec cx

        jcxz .DONE

        ; update ESI

        inc esi

        ; add spaces and CRLF to the output string

        ; a space after every 8 chars
        ; a CRLF after every 64 chars

        add [count],2

        test [count],7

        jne .PRINT

        test [count],63

        je .ADD_CRLF

        mov [edi],byte 32

        inc edi

        jmp .PRINT

  .ADD_CRLF:

        mov [edi],byte 13

        inc edi

        mov [edi],byte 10

        inc edi

        jmp .PRINT

  .DONE:

        ; zero terminate the string

        mov [edi],byte 0

        ret

endp

; -------------------------------------------------------------------------------------

proc PrintKeyBits

  ; print the 72 byte key bits buffer to the display string

        lea eax,[KeyBits]

        mov edx,72

        stdcall PrintBuffer

        ret

endp

; -------------------------------------------------------------------------------------

proc PrintInputBuffer

  ; print the input buffer to the display string

        lea eax,[InputBuffer]

        xor edx,edx

        mov dx,word [nInputBytes]

        stdcall PrintBuffer

        ret

endp

; -------------------------------------------------------------------------------------

proc PrintOutputBuffer

  ; print the output buffer to the display string

        lea eax,[OutputBuffer]

        xor edx,edx

        mov dx,word [nInputBytes]

        stdcall PrintBuffer

        ret

endp

; -------------------------------------------------------------------------------------

proc StrToHexStr uses esi edi

  ; filter out any non hex digit characters from the bfDisplay string

        lea esi,[bfDisplay]
        lea edi,[bfDisplay]

  .FILTER:

        mov al,[esi]

        cmp al,0

        je .DONE

        cmp al,48

        jl .NOT_HEX

        cmp al,57

        jle .COPY

        cmp al,65

        jl .NOT_HEX

        cmp al,70

        jle .COPY

        cmp al,97

        jl .NOT_HEX

        cmp al,102

        jg .NOT_HEX

  .COPY:

        mov [edi],al

        inc edi

  .NOT_HEX:

        inc esi

        jmp .FILTER

  .DONE:

        ; null terminate the new string

        mov [edi],byte 0

        ret

endp

; -------------------------------------------------------------------------------------

proc GetKeyStr uses esi edi

  ; the input key is in bfDisplay - process this string

  ; if bfDisplay is longer than 56 bytes - truncate it to 56 bytes

  ; fill the key bits out to 72 bytes

        lea esi,[bfDisplay]

        mov ecx,0

  .GET_LEN:

        cmp [esi],byte 0

        je .FILL

        inc esi

        inc cx

        cmp cx,112

        jl .GET_LEN

  .FILL:

        cmp cx,0

        je .NULL_KEY

        mov dx,cx

        lea esi,[bfDisplay]

        lea edi,[bfDisplay]

        add edi,ecx

        mov cx,0

  .COPY_DIGITS:

        ; copy up the hex digits in the input string

        mov al,[esi]

        mov [edi],al

        inc esi
        inc edi

        inc cx

        cmp cx,dx

        jl .COPY_DIGITS

        add cx,dx

        cmp cx,144

        jl .FILL

        jmp .DONE

  .NULL_KEY:

        lea edi,[bfDisplay]

        mov cx,0

  .FILL_0:

        mov [edi],byte 48

        inc edi

        inc cx

        cmp cx,144

        jl .FILL_0

  .DONE:

        ; terminate the string at 72 bytes (144 hex chars)

        lea edi,[bfDisplay]

        add edi,144

        mov [edi],byte 0

        ret

endp

; -------------------------------------------------------------------------------------

proc StrToKeyBits

  ; get the key from the input string

  ; input string is a hex value

        stdcall ResetKeyBits

        ; pre-process the bfDisplay string to fill the key out to 144 hex digits

        stdcall StrToHexStr

        stdcall GetKeyStr

        ; load the hex value of the key into the [KeyBits] buffer

        lea eax,[KeyBits]

        mov edx,144

        stdcall StrToBuffer

        ret

endp

; -------------------------------------------------------------------------------------

proc StrToInputBuffer

  ; load the input buffer from the input string

  ; input string is a hex value

        ; reset the input buffer

        stdcall ResetInputBuffer

        lea eax,[InputBuffer]

        mov edx,2048

        stdcall StrToBuffer

        ; the number of hex digits that were read are now in EDX

        ; the size of the input buffer should be a multiple of 8 bytes

        ; adjust InputLength if necessary

        ; input buffer is already padded with zeros

        ; test if EDX is a multiple of 16 (hex digits)

        test edx,0xf

        jz .QUIT

        ; adjust EDX so it is a multiple of 16 hex digits (8 bytes)

        shr edx,4

        inc edx

        shl edx,4

  .QUIT:

        ; divide EDX by 2 and save to InputLength

        shr edx,1

        mov word [nInputBytes],dx

        ret

endp

; -------------------------------------------------------------------------------------

proc HexDigitToValue

  ; convert a hex digit to a 4 bit value

  ; input in AL - output in AL

        ; is AL in the range: 48 - 57 (0 - 9) ?

        cmp al,48

        jl .NOT_HEX

        cmp al,57

        jg .A_Z

        sub al,48

        jmp .DONE

  .A_Z:

        ; is AL in the range: 65 - 70 (A - B) ?

        cmp al,65

        jl .NOT_HEX

        cmp al,70

        jg .a_z

        sub al,55

        jmp .DONE

  .a_z:

        ; is AL in the range: 97 - 102 (a - b) ?

        cmp al,97

        jl .NOT_HEX

        cmp al,102

        jg .NOT_HEX

        sub al,87

        jmp .DONE

  .NOT_HEX:

        ; set EAX to 0xffff if input is not a valid hex digit

        mov eax,0xffff

  .DONE:

        ret

endp

; -------------------------------------------------------------------------------------

proc ByteToDigits

  ; convert 1 byte to 2 hex digits

  ; input in AL - output in AX

        ; copy AL to AH

        mov ah,al

        ; AH: get the upper 4 bits of the byte

        shr ah,4

        ; nibble to hex digit

        add ah,48

        cmp ah,57

        jle .NEXT

        add ah,7

  .NEXT:

        ; AL: get the lower 4 bits of the byte

        and al,0xf

        ; nibble to hex digit

        add al,48

        cmp al,57

        jle .DONE

        add al,7

  .DONE:

        ; output is in AX

        ret

endp

; -------------------------------------------------------------------------------------

proc EncryptInputBuffer uses esi edi

  ; input length should be a multiple of 8 bytes

  ; divide by 8 to give the number of 64 bit blocks to process

        mov cx,word [nInputBytes]

        shr cx,3

        ; quit if greater than 128 (1024 bytes)

        cmp cx,128

        jg .DONE

        ; clear the output buffer

        stdcall ResetOutputBuffer

        ; do the encryption

        lea esi,[InputBuffer]
        lea edi,[OutputBuffer]

  .PROCESS:

        mov eax,[esi]
        mov edx,[esi+4]

        stdcall Encrypt

        mov [edi],eax
        mov [edi+4],edx

        add esi,8
        add edi,8

        dec cx

        jcxz .DONE

        jmp .PROCESS

  .DONE:

        ret

endp

; -------------------------------------------------------------------------------------

proc DecryptInputBuffer uses esi edi

  ; input length should be a multiple of 8 bytes

  ; divide by 8 to give the number of 64 bit blocks to process

        mov cx,word [nInputBytes]

        shr cx,3

        ; quit if greater than 128 (1024 bytes)

        cmp cx,128

        jg .DONE

        ; clear the output buffer

        stdcall ResetOutputBuffer

        ; do the encryption

        lea esi,[InputBuffer]
        lea edi,[OutputBuffer]

  .PROCESS:

        mov eax,[esi]
        mov edx,[esi+4]

        stdcall Decrypt

        mov [edi],eax
        mov [edi+4],edx

        add esi,8
        add edi,8

        dec cx

        jcxz .DONE

        jmp .PROCESS

  .DONE:

        ret

endp

; -------------------------------------------------------------------------------------

proc Encrypt uses esi ecx ebx

  ; xL is passed in EAX
  ; xR is passed in EDX

        lea esi,[P_ARR]

        mov cx,16

  .ROUNDS:

        mov ebx,edx

        ; xL = xL xor P[i]

        xor eax,[esi]

        ; calc F(xL)

        stdcall F_xL

        ; xR = F(xL) xor xR

        xor edx,ebx

        ; xL is in EAX and xR in EDX

        add esi,4

        dec cx

        ; don't want to swap xL,xR in the last round

        jcxz .FINISH

        ; swap xL and xR (xR is in EDX)

        mov ebx,edx
        mov edx,eax
        mov eax,ebx

        ; xL has been moved to EDX and xR to EAX

        jmp .ROUNDS

  .FINISH:

        ; xR = xR xor P[17]

        xor edx,dword [esi]

        ; xL = xL xor P[18]

        add esi,4

        xor eax,dword [esi]

        ; xL is now in EAX
        ; xR is now in EDX

        ; RETURN

        ret

endp

; -------------------------------------------------------------------------------------

proc Decrypt uses esi ecx ebx

  ; xL is passed in EAX
  ; xR is passed in EDX

        lea esi,[P_ARR]

        ; use P in the reverse order (start from P[18])

        add esi,68

        mov cx,16

  .ROUNDS:

        mov ebx,edx

        ; xL = xL xor P[i]

        xor eax,dword [esi]

        ; calc F(xL)

        stdcall F_xL

        ; xR = F(xL) xor xR

        xor edx,ebx

        ; xL is in EAX and xR in EDX

        sub esi,4

        dec cx

        ; don't want to swap xL,xR in the last round

        jcxz .FINISH

        ; swap xL and xR (xR is in EDX)

        mov ebx,edx
        mov edx,eax
        mov eax,ebx

        ; xL has been moved to EDX and xR to EAX

        jmp .ROUNDS

  .FINISH:

        ; xR = xR xor P[2]

        xor edx,dword [esi]

        ; xL = xL xor P[1]

        sub esi,4

        xor eax,dword [esi]

        ; xL is now in EAX
        ; xR is now in EDX

        ; RETURN

        ret

endp

; -------------------------------------------------------------------------------------

macro GET_A reg
{
  shr reg,24
  and reg,0xff
  shl reg,2
}

; -------------------------------------------------------------------------------------

macro GET_B reg
{
  shr reg,16
  and reg,0xff
  shl reg,2
}

; -------------------------------------------------------------------------------------

macro GET_C reg
{
  shr reg,8
  and reg,0xff
  shl reg,2
}

; -------------------------------------------------------------------------------------

macro GET_D reg
{
  and reg,0xff
  shl reg,2
}

; -------------------------------------------------------------------------------------

proc F_xL uses esi

  ; F(xL) = ((S1[a] + S2[b]) xor S3[c]) + S4[d]

  ; xL is passed in EAX

        locals

          temp dd 0

        endl

        mov dword [temp],eax

        ; xL = a,b,c,d

        ; F = S1[a]

        lea esi,[S_BOXES]

        GET_A eax

        mov edx,[esi+eax]

        ; F += S2[b]

        lea esi,[S_BOXES]

        add esi,1024

        mov eax,dword [temp]

        GET_B eax

        add edx,[esi+eax]

        ; F = F xor S3[c]

        lea esi,[S_BOXES]

        add esi,2048

        mov eax,dword [temp]

        GET_C eax

        xor edx,[esi+eax]

        ; F += S4[d]

        lea esi,[S_BOXES]

        add esi,3072

        mov eax,dword [temp]

        GET_D eax

        add edx,[esi+eax]

        ; restore EAX

        mov eax,dword [temp]

        ; return xR in EDX

        ret

endp

; -------------------------------------------------------------------------------------

proc GenerateSubKeys uses ebx esi edi

        ; xor the key bits into the P array:

        lea esi,[KeyBits]

        lea edi,[P_ARR]

        mov cx,0

  .XOR_P:

        mov eax,dword [esi]

        xor dword [edi],eax

        add esi,4
        add edi,4

        inc cx

        cmp cx,18

        jl .XOR_P

        ; encrypt and replace the P and S-Box arrays

        ; start with the all-zero string (in EAX and EDX)

        xor eax,eax
        xor edx,edx

        ; the P array

        lea edi,[P_ARR]

        mov cx,9

        stdcall Replace

        ; the S Boxes

        lea edi,[S_BOXES]

        mov cx,512

        stdcall Replace

        ret

endp

; -------------------------------------------------------------------------------------

proc Replace

  ; called by GenerateSubKeys

  .REPLACE:

        stdcall Encrypt

        mov dword [edi],eax
        mov dword [edi+4],edx

        add edi,8

        dec cx

        jcxz .DONE

        jmp .REPLACE

  .DONE:

        ret

endp

; -------------------------------------------------------------------------------------

macro LOAD_8 w1,w2,w3,w4,w5,w6,w7,w8,offset
{
  mov [edi+offset],dword w1
  mov [edi+offset+4],dword w2
  mov [edi+offset+8],dword w3
  mov [edi+offset+12],dword w4
  mov [edi+offset+16],dword w5
  mov [edi+offset+20],dword w6
  mov [edi+offset+24],dword w7
  mov [edi+offset+28],dword w8
}

; -------------------------------------------------------------------------------------

macro LOAD_6 w1,w2,w3,w4,w5,w6,offset
{
  mov [edi+offset],dword w1
  mov [edi+offset+4],dword w2
  mov [edi+offset+8],dword w3
  mov [edi+offset+12],dword w4
  mov [edi+offset+16],dword w5
  mov [edi+offset+20],dword w6
}

; -------------------------------------------------------------------------------------

proc Init_SubKey_Arrays uses edi

  ; subkey arrays = 4168 bytes

  ; initialise the P Array (72 bytes)

  lea edi,[P_ARR]

  LOAD_6 0x243f6a88,0x85a308d3,0x13198a2e,0x03707344,0xa4093822,0x299f31d0,0
  LOAD_6 0x082efa98,0xec4e6c89,0x452821e6,0x38d01377,0xbe5466cf,0x34e90c6c,24
  LOAD_6 0xc0ac29b7,0xc97c50dd,0x3f84d5b5,0xb5470917,0x9216d5d9,0x8979fb1b,48

  ; initialise S-box 1 (1024 bytes)

  lea edi,[S_BOXES]

  LOAD_8 0xd1310ba6,0x98dfb5ac,0x2ffd72db,0xd01adfb7,0xb8e1afed,0x6a267e96,0xba7c9045,0xf12c7f99,0
  LOAD_8 0x24a19947,0xb3916cf7,0x0801f2e2,0x858efc16,0x636920d8,0x71574e69,0xa458fea3,0xf4933d7e,32
  LOAD_8 0x0d95748f,0x728eb658,0x718bcd58,0x82154aee,0x7b54a41d,0xc25a59b5,0x9c30d539,0x2af26013,64
  LOAD_8 0xc5d1b023,0x286085f0,0xca417918,0xb8db38ef,0x8e79dcb0,0x603a180e,0x6c9e0e8b,0xb01e8a3e,96
  LOAD_8 0xd71577c1,0xbd314b27,0x78af2fda,0x55605c60,0xe65525f3,0xaa55ab94,0x57489862,0x63e81440,128
  LOAD_8 0x55ca396a,0x2aab10b6,0xb4cc5c34,0x1141e8ce,0xa15486af,0x7c72e993,0xb3ee1411,0x636fbc2a,160
  LOAD_8 0x2ba9c55d,0x741831f6,0xce5c3e16,0x9b87931e,0xafd6ba33,0x6c24cf5c,0x7a325381,0x28958677,192
  LOAD_8 0x3b8f4898,0x6b4bb9af,0xc4bfe81b,0x66282193,0x61d809cc,0xfb21a991,0x487cac60,0x5dec8032,224
  LOAD_8 0xef845d5d,0xe98575b1,0xdc262302,0xeb651b88,0x23893e81,0xd396acc5,0x0f6d6ff3,0x83f44239,256
  LOAD_8 0x2e0b4482,0xa4842004,0x69c8f04a,0x9e1f9b5e,0x21c66842,0xf6e96c9a,0x670c9c61,0xabd388f0,288
  LOAD_8 0x6a51a0d2,0xd8542f68,0x960fa728,0xab5133a3,0x6eef0b6c,0x137a3be4,0xba3bf050,0x7efb2a98,320
  LOAD_8 0xa1f1651d,0x39af0176,0x66ca593e,0x82430e88,0x8cee8619,0x456f9fb4,0x7d84a5c3,0x3b8b5ebe,352
  LOAD_8 0xe06f75d8,0x85c12073,0x401a449f,0x56c16aa6,0x4ed3aa62,0x363f7706,0x1bfedf72,0x429b023d,384
  LOAD_8 0x37d0d724,0xd00a1248,0xdb0fead3,0x49f1c09b,0x075372c9,0x80991b7b,0x25d479d8,0xf6e8def7,416
  LOAD_8 0xe3fe501a,0xb6794c3b,0x976ce0bd,0x04c006ba,0xc1a94fb6,0x409f60c4,0x5e5c9ec2,0x196a2463,448
  LOAD_8 0x68fb6faf,0x3e6c53b5,0x1339b2eb,0x3b52ec6f,0x6dfc511f,0x9b30952c,0xcc814544,0xaf5ebd09,480
  LOAD_8 0xbee3d004,0xde334afd,0x660f2807,0x192e4bb3,0xc0cba857,0x45c8740f,0xd20b5f39,0xb9d3fbdb,512
  LOAD_8 0x5579c0bd,0x1a60320a,0xd6a100c6,0x402c7279,0x679f25fe,0xfb1fa3cc,0x8ea5e9f8,0xdb3222f8,544
  LOAD_8 0x3c7516df,0xfd616b15,0x2f501ec8,0xad0552ab,0x323db5fa,0xfd238760,0x53317b48,0x3e00df82,576
  LOAD_8 0x9e5c57bb,0xca6f8ca0,0x1a87562e,0xdf1769db,0xd542a8f6,0x287effc3,0xac6732c6,0x8c4f5573,608
  LOAD_8 0x695b27b0,0xbbca58c8,0xe1ffa35d,0xb8f011a0,0x10fa3d98,0xfd2183b8,0x4afcb56c,0x2dd1d35b,640
  LOAD_8 0x9a53e479,0xb6f84565,0xd28e49bc,0x4bfb9790,0xe1ddf2da,0xa4cb7e33,0x62fb1341,0xcee4c6e8,672
  LOAD_8 0xef20cada,0x36774c01,0xd07e9efe,0x2bf11fb4,0x95dbda4d,0xae909198,0xeaad8e71,0x6b93d5a0,704
  LOAD_8 0xd08ed1d0,0xafc725e0,0x8e3c5b2f,0x8e7594b7,0x8ff6e2fb,0xf2122b64,0x8888b812,0x900df01c,736
  LOAD_8 0x4fad5ea0,0x688fc31c,0xd1cff191,0xb3a8c1ad,0x2f2f2218,0xbe0e1777,0xea752dfe,0x8b021fa1,768
  LOAD_8 0xe5a0cc0f,0xb56f74e8,0x18acf3d6,0xce89e299,0xb4a84fe0,0xfd13e0b7,0x7cc43b81,0xd2ada8d9,800
  LOAD_8 0x165fa266,0x80957705,0x93cc7314,0x211a1477,0xe6ad2065,0x77b5fa86,0xc75442f5,0xfb9d35cf,832
  LOAD_8 0xebcdaf0c,0x7b3e89a0,0xd6411bd3,0xae1e7e49,0x00250e2d,0x2071b35e,0x226800bb,0x57b8e0af,864
  LOAD_8 0x2464369b,0xf009b91e,0x5563911d,0x59dfa6aa,0x78c14389,0xd95a537f,0x207d5ba2,0x02e5b9c5,896
  LOAD_8 0x83260376,0x6295cfa9,0x11c81968,0x4e734a41,0xb3472dca,0x7b14a94a,0x1b510052,0x9a532915,928
  LOAD_8 0xd60f573f,0xbc9bc6e4,0x2b60a476,0x81e67400,0x08ba6fb5,0x571be91f,0xf296ec6b,0x2a0dd915,960
  LOAD_8 0xb6636521,0xe7b9f9b6,0xff34052e,0xc5855664,0x53b02d5d,0xa99f8fa1,0x08ba4799,0x6e85076a,992

  ; initialise S-box 2 (1024 bytes)

  add edi,1024

  LOAD_8 0x4b7a70e9,0xb5b32944,0xdb75092e,0xc4192623,0xad6ea6b0,0x49a7df7d,0x9cee60b8,0x8fedb266,0
  LOAD_8 0xecaa8c71,0x699a17ff,0x5664526c,0xc2b19ee1,0x193602a5,0x75094c29,0xa0591340,0xe4183a3e,32
  LOAD_8 0x3f54989a,0x5b429d65,0x6b8fe4d6,0x99f73fd6,0xa1d29c07,0xefe830f5,0x4d2d38e6,0xf0255dc1,64
  LOAD_8 0x4cdd2086,0x8470eb26,0x6382e9c6,0x021ecc5e,0x09686b3f,0x3ebaefc9,0x3c971814,0x6b6a70a1,96
  LOAD_8 0x687f3584,0x52a0e286,0xb79c5305,0xaa500737,0x3e07841c,0x7fdeae5c,0x8e7d44ec,0x5716f2b8,128
  LOAD_8 0xb03ada37,0xf0500c0d,0xf01c1f04,0x0200b3ff,0xae0cf51a,0x3cb574b2,0x25837a58,0xdc0921bd,160
  LOAD_8 0xd19113f9,0x7ca92ff6,0x94324773,0x22f54701,0x3ae5e581,0x37c2dadc,0xc8b57634,0x9af3dda7,192
  LOAD_8 0xa9446146,0x0fd0030e,0xecc8c73e,0xa4751e41,0xe238cd99,0x3bea0e2f,0x3280bba1,0x183eb331,224
  LOAD_8 0x4e548b38,0x4f6db908,0x6f420d03,0xf60a04bf,0x2cb81290,0x24977c79,0x5679b072,0xbcaf89af,256
  LOAD_8 0xde9a771f,0xd9930810,0xb38bae12,0xdccf3f2e,0x5512721f,0x2e6b7124,0x501adde6,0x9f84cd87,288
  LOAD_8 0x7a584718,0x7408da17,0xbc9f9abc,0xe94b7d8c,0xec7aec3a,0xdb851dfa,0x63094366,0xc464c3d2,320
  LOAD_8 0xef1c1847,0x3215d908,0xdd433b37,0x24c2ba16,0x12a14d43,0x2a65c451,0x50940002,0x133ae4dd,352
  LOAD_8 0x71dff89e,0x10314e55,0x81ac77d6,0x5f11199b,0x043556f1,0xd7a3c76b,0x3c11183b,0x5924a509,384
  LOAD_8 0xf28fe6ed,0x97f1fbfa,0x9ebabf2c,0x1e153c6e,0x86e34570,0xeae96fb1,0x860e5e0a,0x5a3e2ab3,416
  LOAD_8 0x771fe71c,0x4e3d06fa,0x2965dcb9,0x99e71d0f,0x803e89d6,0x5266c825,0x2e4cc978,0x9c10b36a,448
  LOAD_8 0xc6150eba,0x94e2ea78,0xa5fc3c53,0x1e0a2df4,0xf2f74ea7,0x361d2b3d,0x1939260f,0x19c27960,480
  LOAD_8 0x5223a708,0xf71312b6,0xebadfe6e,0xeac31f66,0xe3bc4595,0xa67bc883,0xb17f37d1,0x018cff28,512
  LOAD_8 0xc332ddef,0xbe6c5aa5,0x65582185,0x68ab9802,0xeecea50f,0xdb2f953b,0x2aef7dad,0x5b6e2f84,544
  LOAD_8 0x1521b628,0x29076170,0xecdd4775,0x619f1510,0x13cca830,0xeb61bd96,0x0334fe1e,0xaa0363cf,576
  LOAD_8 0xb5735c90,0x4c70a239,0xd59e9e0b,0xcbaade14,0xeecc86bc,0x60622ca7,0x9cab5cab,0xb2f3846e,608
  LOAD_8 0x648b1eaf,0x19bdf0ca,0xa02369b9,0x655abb50,0x40685a32,0x3c2ab4b3,0x319ee9d5,0xc021b8f7,640
  LOAD_8 0x9b540b19,0x875fa099,0x95f7997e,0x623d7da8,0xf837889a,0x97e32d77,0x11ed935f,0x16681281,672
  LOAD_8 0x0e358829,0xc7e61fd6,0x96dedfa1,0x7858ba99,0x57f584a5,0x1b227263,0x9b83c3ff,0x1ac24696,704
  LOAD_8 0xcdb30aeb,0x532e3054,0x8fd948e4,0x6dbc3128,0x58ebf2ef,0x34c6ffea,0xfe28ed61,0xee7c3c73,736
  LOAD_8 0x5d4a14d9,0xe864b7e3,0x42105d14,0x203e13e0,0x45eee2b6,0xa3aaabea,0xdb6c4f15,0xfacb4fd0,768
  LOAD_8 0xc742f442,0xef6abbb5,0x654f3b1d,0x41cd2105,0xd81e799e,0x86854dc7,0xe44b476a,0x3d816250,800
  LOAD_8 0xcf62a1f2,0x5b8d2646,0xfc8883a0,0xc1c7b6a3,0x7f1524c3,0x69cb7492,0x47848a0b,0x5692b285,832
  LOAD_8 0x095bbf00,0xad19489d,0x1462b174,0x23820e00,0x58428d2a,0x0c55f5ea,0x1dadf43e,0x233f7061,864
  LOAD_8 0x3372f092,0x8d937e41,0xd65fecf1,0x6c223bdb,0x7cde3759,0xcbee7460,0x4085f2a7,0xce77326e,896
  LOAD_8 0xa6078084,0x19f8509e,0xe8efd855,0x61d99735,0xa969a7aa,0xc50c06c2,0x5a04abfc,0x800bcadc,928
  LOAD_8 0x9e447a2e,0xc3453484,0xfdd56705,0x0e1e9ec9,0xdb73dbd3,0x105588cd,0x675fda79,0xe3674340,960
  LOAD_8 0xc5c43465,0x713e38d8,0x3d28f89e,0xf16dff20,0x153e21e7,0x8fb03d4a,0xe6e39f2b,0xdb83adf7,992

  ; initialise S-box 3 (1024 bytes)

  add edi,1024

  LOAD_8 0xe93d5a68,0x948140f7,0xf64c261c,0x94692934,0x411520f7,0x7602d4f7,0xbcf46b2e,0xd4a20068,0
  LOAD_8 0xd4082471,0x3320f46a,0x43b7d4b7,0x500061af,0x1e39f62e,0x97244546,0x14214f74,0xbf8b8840,32
  LOAD_8 0x4d95fc1d,0x96b591af,0x70f4ddd3,0x66a02f45,0xbfbc09ec,0x03bd9785,0x7fac6dd0,0x31cb8504,64
  LOAD_8 0x96eb27b3,0x55fd3941,0xda2547e6,0xabca0a9a,0x28507825,0x530429f4,0x0a2c86da,0xe9b66dfb,96
  LOAD_8 0x68dc1462,0xd7486900,0x680ec0a4,0x27a18dee,0x4f3ffea2,0xe887ad8c,0xb58ce006,0x7af4d6b6,128
  LOAD_8 0xaace1e7c,0xd3375fec,0xce78a399,0x406b2a42,0x20fe9e35,0xd9f385b9,0xee39d7ab,0x3b124e8b,160
  LOAD_8 0x1dc9faf7,0x4b6d1856,0x26a36631,0xeae397b2,0x3a6efa74,0xdd5b4332,0x6841e7f7,0xca7820fb,192
  LOAD_8 0xfb0af54e,0xd8feb397,0x454056ac,0xba489527,0x55533a3a,0x20838d87,0xfe6ba9b7,0xd096954b,224
  LOAD_8 0x55a867bc,0xa1159a58,0xcca92963,0x99e1db33,0xa62a4a56,0x3f3125f9,0x5ef47e1c,0x9029317c,256
  LOAD_8 0xfdf8e802,0x04272f70,0x80bb155c,0x05282ce3,0x95c11548,0xe4c66d22,0x48c1133f,0xc70f86dc,288
  LOAD_8 0x07f9c9ee,0x41041f0f,0x404779a4,0x5d886e17,0x325f51eb,0xd59bc0d1,0xf2bcc18f,0x41113564,320
  LOAD_8 0x257b7834,0x602a9c60,0xdff8e8a3,0x1f636c1b,0x0e12b4c2,0x02e1329e,0xaf664fd1,0xcad18115,352
  LOAD_8 0x6b2395e0,0x333e92e1,0x3b240b62,0xeebeb922,0x85b2a20e,0xe6ba0d99,0xde720c8c,0x2da2f728,384
  LOAD_8 0xd0127845,0x95b794fd,0x647d0862,0xe7ccf5f0,0x5449a36f,0x877d48fa,0xc39dfd27,0xf33e8d1e,416
  LOAD_8 0x0a476341,0x992eff74,0x3a6f6eab,0xf4f8fd37,0xa812dc60,0xa1ebddf8,0x991be14c,0xdb6e6b0d,448
  LOAD_8 0xc67b5510,0x6d672c37,0x2765d43b,0xdcd0e804,0xf1290dc7,0xcc00ffa3,0xb5390f92,0x690fed0b,480
  LOAD_8 0x667b9ffb,0xcedb7d9c,0xa091cf0b,0xd9155ea3,0xbb132f88,0x515bad24,0x7b9479bf,0x763bd6eb,512
  LOAD_8 0x37392eb3,0xcc115979,0x8026e297,0xf42e312d,0x6842ada7,0xc66a2b3b,0x12754ccc,0x782ef11c,544
  LOAD_8 0x6a124237,0xb79251e7,0x06a1bbe6,0x4bfb6350,0x1a6b1018,0x11caedfa,0x3d25bdd8,0xe2e1c3c9,576
  LOAD_8 0x44421659,0x0a121386,0xd90cec6e,0xd5abea2a,0x64af674e,0xda86a85f,0xbebfe988,0x64e4c3fe,608
  LOAD_8 0x9dbc8057,0xf0f7c086,0x60787bf8,0x6003604d,0xd1fd8346,0xf6381fb0,0x7745ae04,0xd736fccc,640
  LOAD_8 0x83426b33,0xf01eab71,0xb0804187,0x3c005e5f,0x77a057be,0xbde8ae24,0x55464299,0xbf582e61,672
  LOAD_8 0x4e58f48f,0xf2ddfda2,0xf474ef38,0x8789bdc2,0x5366f9c3,0xc8b38e74,0xb475f255,0x46fcd9b9,704
  LOAD_8 0x7aeb2661,0x8b1ddf84,0x846a0e79,0x915f95e2,0x466e598e,0x20b45770,0x8cd55591,0xc902de4c,736
  LOAD_8 0xb90bace1,0xbb8205d0,0x11a86248,0x7574a99e,0xb77f19b6,0xe0a9dc09,0x662d09a1,0xc4324633,768
  LOAD_8 0xe85a1f02,0x09f0be8c,0x4a99a025,0x1d6efe10,0x1ab93d1d,0x0ba5a4df,0xa186f20f,0x2868f169,800
  LOAD_8 0xdcb7da83,0x573906fe,0xa1e2ce9b,0x4fcd7f52,0x50115e01,0xa70683fa,0xa002b5c4,0x0de6d027,832
  LOAD_8 0x9af88c27,0x773f8641,0xc3604c06,0x61a806b5,0xf0177a28,0xc0f586e0,0x006058aa,0x30dc7d62,864
  LOAD_8 0x11e69ed7,0x2338ea63,0x53c2dd94,0xc2c21634,0xbbcbee56,0x90bcb6de,0xebfc7da1,0xce591d76,896
  LOAD_8 0x6f05e409,0x4b7c0188,0x39720a3d,0x7c927c24,0x86e3725f,0x724d9db9,0x1ac15bb4,0xd39eb8fc,928
  LOAD_8 0xed545578,0x08fca5b5,0xd83d7cd3,0x4dad0fc4,0x1e50ef5e,0xb161e6f8,0xa28514d9,0x6c51133c,960
  LOAD_8 0x6fd5c7e7,0x56e14ec4,0x362abfce,0xddc6c837,0xd79a3234,0x92638212,0x670efa8e,0x406000e0,992

  ; initialise S-box 4 (1024 bytes)

  add edi,1024

  LOAD_8 0x3a39ce37,0xd3faf5cf,0xabc27737,0x5ac52d1b,0x5cb0679e,0x4fa33742,0xd3822740,0x99bc9bbe,0
  LOAD_8 0xd5118e9d,0xbf0f7315,0xd62d1c7e,0xc700c47b,0xb78c1b6b,0x21a19045,0xb26eb1be,0x6a366eb4,32
  LOAD_8 0x5748ab2f,0xbc946e79,0xc6a376d2,0x6549c2c8,0x530ff8ee,0x468dde7d,0xd5730a1d,0x4cd04dc6,64
  LOAD_8 0x2939bbdb,0xa9ba4650,0xac9526e8,0xbe5ee304,0xa1fad5f0,0x6a2d519a,0x63ef8ce2,0x9a86ee22,96
  LOAD_8 0xc089c2b8,0x43242ef6,0xa51e03aa,0x9cf2d0a4,0x83c061ba,0x9be96a4d,0x8fe51550,0xba645bd6,128
  LOAD_8 0x2826a2f9,0xa73a3ae1,0x4ba99586,0xef5562e9,0xc72fefd3,0xf752f7da,0x3f046f69,0x77fa0a59,160
  LOAD_8 0x80e4a915,0x87b08601,0x9b09e6ad,0x3b3ee593,0xe990fd5a,0x9e34d797,0x2cf0b7d9,0x022b8b51,192
  LOAD_8 0x96d5ac3a,0x017da67d,0xd1cf3ed6,0x7c7d2d28,0x1f9f25cf,0xadf2b89b,0x5ad6b472,0x5a88f54c,224
  LOAD_8 0xe029ac71,0xe019a5e6,0x47b0acfd,0xed93fa9b,0xe8d3c48d,0x283b57cc,0xf8d56629,0x79132e28,256
  LOAD_8 0x785f0191,0xed756055,0xf7960e44,0xe3d35e8c,0x15056dd4,0x88f46dba,0x03a16125,0x0564f0bd,288
  LOAD_8 0xc3eb9e15,0x3c9057a2,0x97271aec,0xa93a072a,0x1b3f6d9b,0x1e6321f5,0xf59c66fb,0x26dcf319,320
  LOAD_8 0x7533d928,0xb155fdf5,0x03563482,0x8aba3cbb,0x28517711,0xc20ad9f8,0xabcc5167,0xccad925f,352
  LOAD_8 0x4de81751,0x3830dc8e,0x379d5862,0x9320f991,0xea7a90c2,0xfb3e7bce,0x5121ce64,0x774fbe32,384
  LOAD_8 0xa8b6e37e,0xc3293d46,0x48de5369,0x6413e680,0xa2ae0810,0xdd6db224,0x69852dfd,0x09072166,416
  LOAD_8 0xb39a460a,0x6445c0dd,0x586cdecf,0x1c20c8ae,0x5bbef7dd,0x1b588d40,0xccd2017f,0x6bb4e3bb,448
  LOAD_8 0xdda26a7e,0x3a59ff45,0x3e350a44,0xbcb4cdd5,0x72eacea8,0xfa6484bb,0x8d6612ae,0xbf3c6f47,480
  LOAD_8 0xd29be463,0x542f5d9e,0xaec2771b,0xf64e6370,0x740e0d8d,0xe75b1357,0xf8721671,0xaf537d5d,512
  LOAD_8 0x4040cb08,0x4eb4e2cc,0x34d2466a,0x0115af84,0xe1b00428,0x95983a1d,0x06b89fb4,0xce6ea048,544
  LOAD_8 0x6f3f3b82,0x3520ab82,0x011a1d4b,0x277227f8,0x611560b1,0xe7933fdc,0xbb3a792b,0x344525bd,576
  LOAD_8 0xa08839e1,0x51ce794b,0x2f32c9b7,0xa01fbac9,0xe01cc87e,0xbcc7d1f6,0xcf0111c3,0xa1e8aac7,608
  LOAD_8 0x1a908749,0xd44fbd9a,0xd0dadecb,0xd50ada38,0x0339c32a,0xc6913667,0x8df9317c,0xe0b12b4f,640
  LOAD_8 0xf79e59b7,0x43f5bb3a,0xf2d519ff,0x27d9459c,0xbf97222c,0x15e6fc2a,0x0f91fc71,0x9b941525,672
  LOAD_8 0xfae59361,0xceb69ceb,0xc2a86459,0x12baa8d1,0xb6c1075e,0xe3056a0c,0x10d25065,0xcb03a442,704
  LOAD_8 0xe0ec6e0e,0x1698db3b,0x4c98a0be,0x3278e964,0x9f1f9532,0xe0d392df,0xd3a0342b,0x8971f21e,736
  LOAD_8 0x1b0a7441,0x4ba3348c,0xc5be7120,0xc37632d8,0xdf359f8d,0x9b992f2e,0xe60b6f47,0x0fe3f11d,768
  LOAD_8 0xe54cda54,0x1edad891,0xce6279cf,0xcd3e7e6f,0x1618b166,0xfd2c1d05,0x848fd2c5,0xf6fb2299,800
  LOAD_8 0xf523f357,0xa6327623,0x93a83531,0x56cccd02,0xacf08162,0x5a75ebb5,0x6e163697,0x88d273cc,832
  LOAD_8 0xde966292,0x81b949d0,0x4c50901b,0x71c65614,0xe6c6c7bd,0x327a140a,0x45e1d006,0xc3f27b9a,864
  LOAD_8 0xc9aa53fd,0x62a80f00,0xbb25bfe2,0x35bdd2f6,0x71126905,0xb2040222,0xb6cbcf7c,0xcd769c2b,896
  LOAD_8 0x53113ec0,0x1640e3d3,0x38abbd60,0x2547adf0,0xba38209c,0xf746ce76,0x77afa1c5,0x20756060,928
  LOAD_8 0x85cbfe4e,0x8ae88dd8,0x7aaaf9b0,0x4cf9aa7e,0x1948c25c,0x02fb8a8c,0x01c36ae4,0xd6ebe1f9,960
  LOAD_8 0x90d4f869,0xa65cdea0,0x3f09252d,0xc208e69f,0xb74e6132,0xce77e25b,0x578fdfe3,0x3ac372e6,992  

  ret

endp

; -------------------------------------------------------------------------------------

section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
          user,'USER32.DLL'

  import kernel,\
         GetModuleHandle,'GetModuleHandleA',\
         ExitProcess,'ExitProcess'

  import user,\
         DialogBoxParam,'DialogBoxParamA',\ 
         SetDlgItemText,'SetDlgItemTextA',\
         GetDlgItemText,'GetDlgItemTextA',\
         EndDialog,'EndDialog'

; -------------------------------------------------------------------------------------

section '.sbox' readable writeable

  S_BOXES rb 4096

; -------------------------------------------------------------------------------------

section '.data' readable writeable

  P_ARR rb 72

  KeyBits rb 72

  nInputBytes dw 0

  InputBuffer rb 1024
  OutputBuffer rb 1024

  bfDisplay rb 2400

  szInputInfoText db "Enter the input as a hex number. Max length = 1024 bytes (2048 hex digits).",0
  szOutputInfoText db "The output: Encrypted plain text or decrypted cipher text.",0
  szKeyInfoText db "Enter the key as a hex number. Max length = 56 bytes (112 hex digits).",0

; -------------------------------------------------------------------------------------

section '.data2' readable writeable

  bfShowSubKeys rb 10000

; -------------------------------------------------------------------------------------

section '.rc' resource data readable

  directory RT_DIALOG,dialogs

  resource dialogs,IDD_THE_DIALOG,LANG_ENGLISH+SUBLANG_DEFAULT,blowfish_dialog

  dialog blowfish_dialog,\
  'Blowfish',50,50,360,415,\
  DS_MODALFRAME+WS_MINIMIZEBOX+WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SYSMENU,\
  0,0,"Lucida Console",11

  dialogitem 'BUTTON','Input',-1,7,5,346,150,BS_GROUPBOX+WS_VISIBLE,0
  dialogitem 'BUTTON',"Output",-1,7,160,346,150,BS_GROUPBOX+WS_VISIBLE,0
  dialogitem 'BUTTON',"Key",-1,7,315,220,90,BS_GROUPBOX+WS_VISIBLE,0

  dialogitem 'EDIT',0,IDC_INPUT,13,17,335,130,ES_MULTILINE+ES_AUTOVSCROLL+ES_WANTRETURN+WS_VSCROLL+WS_BORDER+WS_VISIBLE,0
  dialogitem 'EDIT',0,IDC_OUTPUT,13,172,335,130,ES_MULTILINE+ES_AUTOVSCROLL+ES_WANTRETURN+WS_VSCROLL+WS_BORDER+WS_VISIBLE,0
  dialogitem 'EDIT',0,IDC_KEY,13,327,208,70,ES_MULTILINE+ES_AUTOVSCROLL+ES_WANTRETURN+WS_VSCROLL+WS_BORDER+WS_VISIBLE,0

  dialogitem 'BUTTON',"Encrypt",IDC_BTN_ENCRYPT,231,319,60,14,BS_PUSHBUTTON+WS_VISIBLE,0
  dialogitem 'BUTTON',"Decrypt",IDC_BTN_DECRYPT,293,319,60,14,BS_PUSHBUTTON+WS_VISIBLE,0

  dialogitem 'BUTTON',"Input To Hex",IDC_BTN_TO_HEX,231,335,60,14,BS_PUSHBUTTON+WS_VISIBLE,0
  dialogitem 'BUTTON',"Output To Text",IDC_BTN_TO_TXT,293,335,60,14,BS_PUSHBUTTON+WS_VISIBLE,0

  dialogitem 'BUTTON',"Refresh Key",IDC_BTN_KEY,231,351,60,14,BS_PUSHBUTTON+WS_VISIBLE,0
  dialogitem 'BUTTON',"Sub Keys",IDC_BTN_SUB_KEYS,293,351,60,14,BS_PUSHBUTTON+WS_VISIBLE,0

  dialogitem 'BUTTON',"Clear",IDC_BTN_RESET,231,367,60,14,BS_PUSHBUTTON+WS_VISIBLE,0

  enddialog

; -------------------------------------------------------------------------------------