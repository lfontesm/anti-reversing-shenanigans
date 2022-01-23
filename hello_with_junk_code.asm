format PE GUI
entry start

include 'win32ax.inc'

section '.text' code readable executable writable

start:
        push MB_OK
        call aux
        db 'Quente', 0

aux:
        call bux
        db 'Batata', 0

bux:
        push HWND_DESKTOP
        call [MessageBox]

section '.idata' import data readable

 library user, 'USER32.DLL'

 import user,\
        MessageBox, 'MessageBoxA'