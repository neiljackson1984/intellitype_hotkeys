; When the f-lock mode is on, the standard f keys do not trigger standard f-key kleycodes but instead trigger special functions.
; the handlers below make it so that the f-keys produce the expected f-kay behavior even when f-lock happens to be on.

#include intellikeyHandling.ahk

; assign traditional F-key actions to F-Keys so they will work regardless of F-mode being ON or OFF.
intellikey_f1_DOWN_handler()
{
	Send {F1}
}

intellikey_f2_DOWN_handler()
{
	Send {F2}
}

intellikey_f3_DOWN_handler()
{
	Send {F3}
}

intellikey_f4_DOWN_handler()
{
	Send {F4}
}

intellikey_f5_DOWN_handler()
{
	Send {F5}
}

intellikey_f6_DOWN_handler()
{
	Send {F6}
}

intellikey_f7_DOWN_handler()
{
	Send {F7}
}

intellikey_f8_DOWN_handler()
{
	Send {F8}
}

intellikey_f9_DOWN_handler()
{
	Send {F9}
}

intellikey_f10_DOWN_handler()
{
	Send {F10}
}

intellikey_f11_DOWN_handler()
{
	Send {F11}
}

intellikey_f12_DOWN_handler()
{
	Send {F12}
}
