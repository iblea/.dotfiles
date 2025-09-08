; AutoHotkey v2 Script
; Ctrl+Space: 한글 입력 상태면 영어로 전환 후 ESC, 영어면 ESC만 발생

; Ctrl+Space 핫키
^Space:: {
    imeState := fnGetImeState()
    if (imeState = 1) {
        SendEvent( "{vk15sc138}" )
        SetTimer( fnWatchCursor, 16 )
        Sleep(50)
    }

    ; ESC 키 이벤트 발생
    Send("{Esc}")

}


fnGetImeState(){
	;MouseGetPos &vx, &vy, &ahk_Id, &ClassNN
	;imeState := DllCall("imm32\ImmGetDefaultIMEWnd", "Uint", ahk_Id, "Uint")
	;SendMessage (0x0283,0x005,"",ahk_id)
	
	return fnImeCheck()
	
}

fnImeCheck(){
	MouseGetPos &vx, &vy, &ahk_Id, &ClassNN
	Return Send_ImeControl(ImmGetDefaultIMEWnd(ahk_Id),0x005,"")
}

Send_ImeControl(DefaultIMEWnd, wParam, lParam)
{
	DetectHiddenWindows true                           
	rst := SendMessage(0x283,wParam,lParam,,"ahk_id " DefaultIMEWnd)
	return rst
}

ImmGetDefaultIMEWnd(hWnd)
{
	return DllCall("imm32\ImmGetDefaultIMEWnd", "Uint", hWnd, "Uint")
}

fnWatchCursor(){
	MouseGetPos &x, &y, &winId, &controlId
	imeState := fnGetImeState()
	if(imeState = 1){
		ToolTip "KOR", x+8, y+8
	}else{
		ToolTip 
	}
	
}

; n+k 또는 k+n 조합으로 IME 전환
~n:: {
    ih := InputHook("T0.08 L1")  ; 50ms 타임아웃, 1글자만 받기
    ih.Start()
    ih.Wait()
    
    ; k가 입력되었는지 확인
    if (ih.Input = "k") {
        ; n과 k를 백스페이스로 지우기
        ; Send("{BS 2}")
        Send("{BS 1}")
        ; IME 토글
        Send("{vk15sc138}")
    }
}

~k:: {
    ih := InputHook("T0.08 L1")  ; 50ms 타임아웃, 1글자만 받기
    ih.Start()
    ih.Wait()
    
    ; n이 입력되었는지 확인
    if (ih.Input = "n") {
        ; k와 n을 백스페이스로 지우기
        ; Send("{BS 2}")
        Send("{BS 1}")
        ; IME 토글
        Send("{vk15sc138}")
    }
}

; 한글 자판에서 ㅜ+ㅏ 또는 ㅏ+ㅜ 조합으로 IME 전환
; ㅜ (SC016 = t키 위치)
~SC016:: {

    imeState := fnGetImeState()
    if (imeState = 1) {  ; 한글 입력 상태일 때만
        ih := InputHook("T0.08 L1")
        ih.Start()
        ih.Wait()
        
        ; ㅏ가 입력되었는지 확인 (SC024 = j키 위치)
        if (ih.Input = "j") {
            ; ㅜ와 ㅏ를 백스페이스로 지우기
            ; Send("{BS 2}")
            Send("{BS 1}")
            ; IME 토글
            Send("{vk15sc138}")
        }
    }
}

; ㅏ (SC024 = j키 위치)
~SC024:: {
    imeState := fnGetImeState()
    if (imeState = 1) {  ; 한글 입력 상태일 때만
        ih := InputHook("T0.08 L1")
        ih.Start()
        ih.Wait()
        
        ; ㅜ가 입력되었는지 확인 (SC016 = t키 위치)
        if (ih.Input = "t") {
            ; ㅏ와 ㅜ를 백스페이스로 지우기
            ; Send("{BS 2}")
            Send("{BS 1}")
            ; IME 토글
            Send("{vk15sc138}")
        }
    }
}

; Shift+Windows+H/J/K/L을 방향키로 매핑
+#h::Send("{Left}")   ; Shift+Win+H → 왼쪽
+#j::Send("{Down}")   ; Shift+Win+J → 아래
+#k::Send("{Up}")     ; Shift+Win+K → 위
+#l::Send("{Right}")  ; Shift+Win+L → 오른쪽

; Ctrl+Shift+Windows+H/J/K/L을 Shift+방향키로 매핑
^+#h::Send("+{Left}")   ; Ctrl+Shift+Win+H → Shift+왼쪽
^+#j::Send("+{Down}")   ; Ctrl+Shift+Win+J → Shift+아래
^+#k::Send("+{Up}")     ; Ctrl+Shift+Win+K → Shift+위
^+#l::Send("+{Right}")  ; Ctrl+Shift+Win+L → Shift+오른쪽
