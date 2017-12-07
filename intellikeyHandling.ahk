#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
DetectHiddenWindows, On
SetTitleMatchMode, 1
;#Include %A_ScriptDir%  ; Changes the working directory for subsequent #Includes and FileInstalls.  Note: SetWorkingDir does not have any effect on the driectory for includes, because the #include statements are processed before the program runs (compile time vs. run time)
global debugging
debugging:=false

#include AHKHID\AHKHID.ahk
#include bitTwiddling.ahk





Process, Exist
pid := ErrorLevel
WinGet, myHwnd, ID, ahk_pid %pid%
;MsgBox myHwnd is %myHwnd%
{
	AHKHID_Register(12,1,myHwnd, RIDEV_INPUTSINK) ; the intellitype keyboard special keys use useage page 12, usage 1
	; AHKHID_Register(1,6,myHwnd, RIDEV_INPUTSINK) ; standard keyboard keys use usage page 1, usage 6
	OnMessage(0x00FF, "InputMsg") ; 0x00FF is the message number for WM_INPUT messages
	; stdout := FileOpen("*", "w")  
	; stdout.Write("ahoy")
}


; ; ; ; ; ;Create GUI
; ; ; ; ; Gui +LastFound -Resize -MaximizeBox -MinimizeBox
; ; ; ; ; Gui, Font, s10, Courier New
if(debugging)
{
	Gui +LastFound -Resize -MaximizeBox -MinimizeBox
    Gui, Font, s10, Courier New
	Gui, Add, ListBox, x6 y6 w1900 h320 vlbxInput hwndhlbxInput ,
	Gui, Show
	
	
	;for testing, disable the special keys that trigger both WM_INPUT messages AND regular keystrokes.
	;disable a couple of the special hotkeys
	Browser_Back::return
	Browser_Forward::return
	Browser_Home::return
	Launch_Mail::return
	Volume_Down::return
	Volume_Up::return
	Media_Play_Pause::return
	Media_Prev::return
	Media_Next::return
	Volume_Mute::return
	Launch_App2::return
}

; ; ; ; ; ;Keep handle
; ; ; ; ; GuiHandle := WinExist()

; ; ; ; ; ;Set up the constants
; ; ; ; ; AHKHID_UseConstants()

; ; ; ; ; ;Show GUI
; ; ; ; ; Gui, Show
; ; ; ; ; Return

; ; ; ; ; GuiClose:
; ; ; ; ; ExitApp






InputMsg(wParam, lParam) {
	Local uData, r, hexDataString, h, keyName, stateReport, debugMessage
	
    ; Critical    ;Or otherwise you could get ERROR_INVALID_HANDLE
	; I really ought to check that the HID device that generated this message was the Microsoft keyboard and not some other device that happened to be using usage page 12, and usge 1.
	static lastStateOfMachine0 := 0
	static lastStateOfMachine1 := 0
	static lastStateOfMachine2 := 0
	static lastStateOfMachine3 := 0
	static lastStateOfMachine4 := 0
	static lastStateOfMachine5 := 0
	static lastStateOfMachine6 := 0
	static lastStateOfMachine7 := 0
	
	static newStateOfMachine0
	static newStateOfMachine1
	static newStateOfMachine2
	static newStateOfMachine3
	static newStateOfMachine4
	static newStateOfMachine5
	static newStateOfMachine6
	static newStateOfMachine7
	
	static machine7DownCount := 0 ; we will (attempt to) keep track of the number of the machine 7 buttons that are currently down (each of the machine 7 buttons generates a unique down event, and an up event that is indistinguishable from among the machine 7 buttons)
	
	;;an associative array containing one element for each of the 30 machine7 buttons.
	;; the keys are the characteristic values of machine7's states that occurs upon the given button going down.
	static machine7ButtonNames := {149 : "f1", 538 : "f2", 633 : "f3", 513 : "f4", 514 : "f5", 515 : "f6", 649 : "f7", 651 : "f8", 652 : "f9", 427 : "f10", 519 : "f11", 520 : "f12", 558 : "magnifierMinus", 557 : "magnifierPlus", 439 : "headphones", 438 : "camera", 423 : "folderPage", 547 : "house", 394 : "envelope", 548 : "back", 549 : "forward", 205 : "playPause", 182 : "skipBack", 181 : "skipForward", 226 : "mute", 234 : "volumeMinus", 233 : "volumePlus", 386 : "star", 402 : "calculator", 412 : "key" }

	; static statesHaveBeenInitialized := 0
	; Rather than use the first message merely to initialize the state machine,
	; I would prefer to use that first message to trigger an action (because the message
	; will be the result of a keystroke.  To achieve this, I am going to assume that the initial states are ; all 0.  This should work reasonably well because 0 is the non-pressed state for all of the state machines (as long as my hands are off the keyboard when the script starts up, the script's assumptions about the intials states will be correct.  The one exception is stateMAchine0 (F-Lock) which is a little different than the others; F-lock could conceivably be ON when the script starts, even if my hands were not touching the keyboard.  If I assume that F-lock is off, then, upon arrival of the first message, I will provide an incorrect answer to the question "did F-lock just transition?". However, in the current application that will not cause too much of a problem because I do not want to fire an event when F-lock changes state.  If I do anything with F-lock mode, it will simply be to read its state with each message, to potentially modify the action of other events, so it will not matter if I guess wrong about the intitial state of F-lock mode because I will gain the correct knowledge of F-lock mode when any meaningful event arrives (because I can read the F-lock bit that arrives in the message carrying the meaningful event).
	
	r := AHKHID_GetInputInfo(lParam, II_DEVTYPE) 
    If (r = -1)
        OutputDebug %ErrorLevel%
	If (r = RIM_TYPEHID) 
	{
        h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)
        r := AHKHID_GetInputData(lParam, uData)
		hexDataString := Bin2Hex(&uData, r) 
		
		if(debugging)
		{
			debugMessage := ""
				. " Vendor ID: "   AHKHID_GetDevInfo(h, DI_HID_VENDORID,     True)
				. " Product ID: "  AHKHID_GetDevInfo(h, DI_HID_PRODUCTID,    True)
				. " UsPg/Us: " AHKHID_GetDevInfo(h, DI_HID_USAGEPAGE, True) . "/" . AHKHID_GetDevInfo(h, DI_HID_USAGE, True)
				. " Data" . "(" . r . ")" . ": " Bin2Hex(&uData, r) 
		}
		
		
        if((getByte(&uData,0) = 1) && (r==8)) ; It seems, empirically, that all messages where the first byte is 1 are generated directly by keypresses, and all keypresses generate such messages.  Messages not having the first byte being 1 seem to be status updates, not directly caused by a key press.  
		; all type1 messages have 8 bytes.
		{
			newStateOfMachine0 := getBit(&uData, 40)
			newStateOfMachine1 := getBit(&uData, 42)
			newStateOfMachine2 := getBit(&uData, 43)
			newStateOfMachine3 := getBit(&uData, 44)
			newStateOfMachine4 := getBit(&uData, 45)
			newStateOfMachine5 := getBit(&uData, 46)
			newStateOfMachine6 := getByte(&uData, 6)
			newStateOfMachine7 := NumGet(&uData, 1, "UShort")
			
			machine0ChangedState := (newStateOfMachine0!=lastStateOfMachine0)
			machine1ChangedState := (newStateOfMachine1!=lastStateOfMachine1)
			machine2ChangedState := (newStateOfMachine2!=lastStateOfMachine2)
			machine3ChangedState := (newStateOfMachine3!=lastStateOfMachine3)
			machine4ChangedState := (newStateOfMachine4!=lastStateOfMachine4)
			machine5ChangedState := (newStateOfMachine5!=lastStateOfMachine5)
			machine6ChangedState := (newStateOfMachine6!=lastStateOfMachine6)
			machine7ChangedState := (newStateOfMachine7!=lastStateOfMachine7)
			
			atLeastOneOfTheMachinesChangedState := machine0ChangedState || machine1ChangedState ||  machine2ChangedState || machine3ChangedState || machine4ChangedState || machine5ChangedState || machine6ChangedState || machine7ChangedState
				
			if(machine0ChangedState)
			{
				; do nothing
			}
			
			if(machine1ChangedState)
			{
				if(newStateOfMachine1==0)
				{
					fireButtonHandler("special1", "UP")
				} else if (newStateOfMachine1==1) 
				{
					fireButtonHandler("special1", "DOWN")
				}
			}
			
			if(machine2ChangedState)
			{
				if(newStateOfMachine2==0)
				{
					fireButtonHandler("special2", "UP")
				} else if (newStateOfMachine2==1) 
				{
					fireButtonHandler("special2", "DOWN")
				}
			}
			
			if(machine3ChangedState)
			{
				if(newStateOfMachine3==0)
				{
					fireButtonHandler("special3", "UP")
				} else if (newStateOfMachine3==1) 
				{
					fireButtonHandler("special3", "DOWN")
				}
			}
			
			if(machine4ChangedState)
			{
				if(newStateOfMachine4==0)
				{
					fireButtonHandler("special4", "UP")
				} else if (newStateOfMachine4==1) 
				{
					fireButtonHandler("special4", "DOWN")
				}			
			}
			
			if(machine5ChangedState)
			{
				if(newStateOfMachine5==0)
				{
					fireButtonHandler("special5", "UP")
				} else if (newStateOfMachine5==1) 
				{
					fireButtonHandler("special5", "DOWN")
				}		
			}
			
			if(machine6ChangedState)
			{
				if(newStateOfMachine6==0)
				{
					; do nothing
				} else if (newStateOfMachine6==6) 
				{
					fireButtonHandler("spurGear", "DOWN")	
				} else if (newStateOfMachine6==7) 
				{
					fireButtonHandler("worldPhone", "DOWN")	
				} else
				{
					; this should never happen
				}
			}
			
			if(machine7ChangedState)
			{
				;; we will fire the UP handler of a machine7 button whenever machine 7 transitions out of that button's state.  
				;; In other words, for a machine7 button, we will regard that button as going down when we get that button's down event and as going up upon the next change of state of machine7.
				;;  This means the meaing og "UP" and "DOWN" does not quite match the physical reality in the case where we have multiple machine7 buttons down simultaneously. but it is close enough to be useful, and in the ususal case, which is a single-button-at-a-time, the illusion will be perfect.
				
				if(lastStateOfMachine7!=0)
				{
					if (machine7ButtonNames.HasKey(lastStateOfMachine7))
					{
						fireButtonHandler(machine7ButtonNames[lastStateOfMachine7], "UP")	
					} else
					{
						; I don't think this will ever happen.
					}
				}
				
				if(newStateOfMachine7==0)
				{
					; in this case, we know that one of the machine 7 buttons has gone up (but we do not know which one.)
					--machine7DownCount				
				} else if (machine7ButtonNames.HasKey(newStateOfMachine7))
				{
					++machine7DownCount
					fireButtonHandler(machine7ButtonNames[newStateOfMachine7], "DOWN")	
				} else
				{
					; I don't think this will ever happen.
				}
				
				
				; ; ; ; ; (newStateOfMachine7==149) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f1", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==538) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f2", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==633) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f3", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==513) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f4", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==514) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f5", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==515) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f6", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==649) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f7", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==651) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f8", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==652) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f9", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==427) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f10", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==519) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f11", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==520) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("f12", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==557) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("magnifierPlus", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==558) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("magnifierMinus", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==439) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("headphones", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==438) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("camera", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==423) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("folderPage", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==547) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("house", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==394) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("envelope", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==548) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("back", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==549) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("forward", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==205) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("playPause", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==182) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("skipBack", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==181) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("skipForward", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==226) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("mute", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==234) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("volumeMinus", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==233) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("volumePlus", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==386) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("star", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==402) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("calculator", "DOWN")	
				; ; ; ; ; } else if (newStateOfMachine7==412) 
				; ; ; ; ; {
					; ; ; ; ; ++machine7DownCount
					; ; ; ; ; fireButtonHandler("key", "DOWN")	
				; ; ; ; ; } else
				; ; ; ; ; {
					; ; ; ; ; ; this should never happen
				; ; ; ; ; }
			}
			
			if(newStateOfMachine7==0 && !atLeastOneOfTheMachinesChangedState)
			{
				; this event occurs when you go to release buttons after several machine7 buttons are having been pressed down simultaneously.   this event occurs on any releases after the first.
				; in this case, we know that one of the machine 7 buttons has gone up (but we do not know which one.)
				--machine7DownCount
			}
			
			; statesHaveBeenInitialized := 1
			lastStateOfMachine0 := newStateOfMachine0
			lastStateOfMachine1 := newStateOfMachine1
			lastStateOfMachine2 := newStateOfMachine2
			lastStateOfMachine3 := newStateOfMachine3
			lastStateOfMachine4 := newStateOfMachine4
			lastStateOfMachine5 := newStateOfMachine5
			lastStateOfMachine6 := newStateOfMachine6
			lastStateOfMachine7 := newStateOfMachine7

			if(debugging)
			{
				stateReport := ""
					. "0" . (machine0ChangedState ? "*" : " ") . ":" . newStateOfMachine0 . "    " 
					. "1" . (machine1ChangedState ? "*" : " ") . ":" . newStateOfMachine1 . "    " 
					. "2" . (machine2ChangedState ? "*" : " ") . ":" . newStateOfMachine2 . "    "  
					. "3" . (machine3ChangedState ? "*" : " ") . ":" . newStateOfMachine3 . "    "   
					. "4" . (machine4ChangedState ? "*" : " ") . ":" . newStateOfMachine4 . "    "   
					. "5" . (machine5ChangedState ? "*" : " ") . ":" . newStateOfMachine5 . "    "   
					. "6" . (machine6ChangedState ? "*" : " ") . ":" . newStateOfMachine6 . "    "   
					. "7" . (machine7ChangedState ? "*" : " ") . ":" . newStateOfMachine7 . "    " 
				
				debugMessage := debugMessage
				    . " machine7DownCount: " . machine7DownCount
					. " stateReport: " . stateReport

			}
		}
    } else 
	{
		if(debugging)
		{
			debugMessage:="InputMsg was called with something other than r = RIM_TYPEHID."
		}
	}
	if(debugging)
	{
		GuiControl,, lbxInput, %debugMessage%
		; the next two lines scroll the debugging message window to the bottom.
		SendMessage, 0x018B, 0, 0,, ahk_id %hlbxInput%
		SendMessage, 0x0186, ErrorLevel - 1, 0,, ahk_id %hlbxInput%
	}
}



; this function takes the name of a button, and the direction ("UP" or "DOWN") and fires the 
; the appropriate function
fireButtonHandler(nameOfButton, direction)
{
	; MsgBox %nameOfButton% %direction%
	; ; ; ; ; GuiControl,, lbxInput, %nameOfButton% %direction%
	Func("intellikey_" . nameOfButton . "_" . direction . "_handler").Call() 
}

