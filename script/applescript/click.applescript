on clickAt(x, y)
	do shell script "osascript -l JavaScript -e 'ObjC.import(\"CoreGraphics\"); var p = $.CGPointMake(" & x & "," & y & "); var down = $.CGEventCreateMouseEvent(null, $.kCGEventLeftMouseDown, p, $.kCGMouseButtonLeft); var up = $.CGEventCreateMouseEvent(null, $.kCGEventLeftMouseUp, p, $.kCGMouseButtonLeft); $.CGEventPost($.kCGHIDEventTap, down); $.CGEventPost($.kCGHIDEventTap, up);'"
end clickAt

repeat
	my clickAt(1672, 1031)
	delay 0.5
	my clickAt(1842, 1031)
	delay 0.5
	my clickAt(1274, 1031)
	delay 0.5
	my clickAt(1842, 1031)
	delay 0.5
end repeat
