; shift+space = underbar (_)
; +Space::
; 	Send, _
; 	return

^[::
^Space::
    ret := IME_CHECK("A")
    if %ret% <> 0           ; 1 means IME is in Hangul(Korean) mode now.
        {
            ; MsgBox, 0, test, test1, ]
            Send, ^
            Send, ^
            Send, {vk15}    ;한글인 경우 Esc키를 입력하고 한영키를 입력해 준다.
            Sleep, 5
            Send, {Esc}
        }
    else if %ret% = 0       ; 0 means IME is in English mode now.
        {
            ; MsgBox, 0, test, test2, ]
            Send, ^
            Send, ^
            Send, {Esc}     ;영문인 경우 Esc키만 입력한다.
        }
    return

; IME check


$Esc::
    ret := IME_CHECK("A")
    if %ret% <> 0           ; 1 means IME is in Hangul(Korean) mode now.
        {
            Send, {vk15}    ;한글인 경우 Esc키를 입력하고 한영키를 입력해 준다.
            Sleep, 10
            Send, {Esc}
        }
    else if %ret% = 0       ; 0 means IME is in English mode now.
        {
            Send, {Esc}     ;영문인 경우 Esc키만 입력한다.
        }
    return

; IME check


IME_CHECK(WinTitle) {
	WinGet,hWnd,ID,%WinTitle%
	Return Send_ImeControl(ImmGetDefaultIMEWnd(hWnd),0x005,"")
}
Send_ImeControl(DefaultIMEWnd, wParam, lParam) {
	DetectSave := A_DetectHiddenWindows
	DetectHiddenWindows,ON
	SendMessage 0x283, wParam,lParam,,ahk_id %DefaultIMEWnd%
	if (DetectSave <> A_DetectHiddenWindows)
		DetectHiddenWindows,%DetectSave%
	return ErrorLevel
}
ImmGetDefaultIMEWnd(hWnd) {
	return DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hWnd, Uint)
}
