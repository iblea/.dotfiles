set mousePos to do shell script "osascript -l JavaScript -e 'ObjC.import(\"CoreGraphics\"); var e = $.CGEventCreate(null); var loc = $.CGEventGetLocation(e); String(Math.round(loc.x)) + \" \" + String(Math.round(loc.y))'"

set xPos to word 1 of mousePos
set yPos to word 2 of mousePos

display dialog "마우스 좌표: x=" & xPos & ", y=" & yPos buttons {"복사", "확인"} default button "확인"
set btnResult to button returned of result

if btnResult is "복사" then
	set the clipboard to xPos & "," & yPos
end if
