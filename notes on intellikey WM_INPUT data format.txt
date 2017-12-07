2016/04/02


The current project is to get Autohotkey to react to presses of the special buttons on my Microsoft wireless keyboard.  My keyboard is a "Microsoft Wireless Laser Keyboard 6000 v2.0".

There are 38 buttons on the keyboard that are of interest in the present study.  This set of buttons, which I call the special buttons, consists of 
	-- button0 : the button labeled "F-Lock".
	-- button1 : the button labeled "1".
	-- button2 : the button labeled "2".
	-- button3 : the button labeled "3".
	-- button4 : the button labeled "4".
	-- button5 : the button labeled "5".
	-- button6 : the button with the spurGear icon.
	-- button7 : the button with the worldPhone icon.
	-- button8, button9, ... , button 19: the 12 F-keys
	-- button20, ..., button37 : All the buttons that have not already been mentioned above and that have the flatter style of keycaps.


I have studied the WM_INPUT data packets received by Windows in response to presses of the special buttons on my keyboard. 
Every message consists of a sequence of 1 or more bytes.  We are concerned only with messages where the value of byte zero is 1.  Let us use the descriptor "type1" to describe this class of messages. 
Type1 messages only ever occur in response to a change in the press-state of the special keys.  No other type of WM_INPUT message ever occurs in response to a change in press-state of the special keys.
Occasionally, spontaneously, the keyboard sends a message whose first byte is not 1.  I reckon that these spontanteous messages are status updates, probably having to with battery life.  
All type1 messages are 8 bytes long.
In all type1 messages, the value of bytes 3, 4, and 7 are 0.
After looking at byte 0 to see if its value is 1, the information that we are concerned with resides entirely within bytes 1, 2, 5, and 6.
	
There is an internal state of the keyboard called FLock, which is, at any time, either ON or OFF. When FLock is ON, the F-keys behave in the traditional manner, sending F-key keystrokes to the operating system, and the F-Keys do not generate WM_INPUT messages.
When FLock is OFF, the F-keys do not send F-key keystrokes to the operating system, but instead generate WM_INPUT messages.

F-Lock DOWN always toggles F-LOCK mode.
F-Lock UP toggles F-lock mode if and only if the last event was not an F-lock DOWN. (this allows f-lock to work as a modifier key as well as a tap-to-toggle key -- sort of like combining caps-lock and shift into a single button.).

A subtype of type1 messages are messages that have byte 5, bit 2 high.  A message of this type is fired when, and only when, F-lock mode changes state.  (In such messages, byte 5, bit 0 indicates the new F-Lock state.)

byte 5, bit 0: indicates the truth of the statement: "FLock mode is ON".
byte 5, bit 1: indicates the truth of the statement: "The change of press-state that generated this message was a change of the press-state of the F-Lock key." (Note: An F-Lock DOWN event always causes a WM_INPUT message.  An F-Lock UP event causes a WM_INPUT message unless the most recent change of keyboard press state (for all keys on the keyboard) was an F-lock Down event.  --I do not totally understand the rationale behind this.)
byte 5, bit 2: indicates the truth of the statement: "Special1 is down"
byte 5, bit 3: indicates the truth of the statement: "Special2 is down"
byte 5, bit 4: indicates the truth of the statement: "Special3 is down"
byte 5, bit 5: indicates the truth of the statement: "Special4 is down"
byte 5, bit 6: indicates the truth of the statement: "Special5 is down"

There is a little state machine driven by button6 (spurGear) and button7 (worldPhone).  This state machine has three states: namely 0, 6 and 7.  Any change in state of this state machine causes a WM_INPUT message to occur,
and every WM_INPUT message encodes the state of this state machine in byte 6 (whose value is always 0, 6 or 7).
	- a gadget UP event causes the state to become 0.
	- a spurGear UP event causes the state to become 0.
	- a gadget DOWN event causes the state to become 7.
	- A spurGear DOWN event causes the state to become 6.
	
buttons 8-37 drive a state machine whose state is indicated by bytes 1 and 2:
Any UP event from buttons8-19 causes the state to become 0 if and only if F-lock was OFF when that button went DOWN. 
Any UP event from buttons20-37 causes the state to become 0.

Any DOWN event from buttons8-19 causes the state to become a value characteristic of that button if and only if F-lock was OFF when that button went down.
Any DOWN event from buttons 20-37 causes the state to become a value characteristic of that button.

(Some of the buttons 20-37 cause a regular keystroke to be sent to windows, in addition to changing the state of this state machine (and thus triggering a WM_INPUT message)).

Here are the characteristic values:

button8  (F1/HELP)           : 0x9500 (decimal bytes: 149,    0 ) (decimal UShort: 149)
button9  (F2/UNDO)           : 0x1A02 (decimal bytes:  26,    2 ) (decimal UShort: 538)
button10 (F3/REDO)           : 0x7902 (decimal bytes: 121,    2 ) (decimal UShort: 633)
button11 (F4/NEW)            : 0x0102 (decimal bytes:   1,    2 ) (decimal UShort: 513)
button12 (F5/OPEN)           : 0x0202 (decimal bytes:   2,    2 ) (decimal UShort: 514)
button13 (F6/CLOSE)          : 0x0302 (decimal bytes:   3,    2 ) (decimal UShort: 515)
button14 (F7/REPLY)          : 0x8902 (decimal bytes: 137,    2 ) (decimal UShort: 649)
button15 (F8/FWD)            : 0x8B02 (decimal bytes: 139,    2 ) (decimal UShort: 651)
button16 (F9/SEND)           : 0x8C02 (decimal bytes: 140,    2 ) (decimal UShort: 652)
button17 (F10/SPELL)         : 0xAB01 (decimal bytes: 171,    1 ) (decimal UShort: 427)
button18 (F11/SAVE)          : 0x0702 (decimal bytes:   7,    2 ) (decimal UShort: 519)
button19 (F12/PRINT)         : 0x0802 (decimal bytes:   8,    2 ) (decimal UShort: 520)
button20 (magnifierMinus)    : 0x2E02 (decimal bytes:  46,    2 ) (decimal UShort: 558)
button21 (magnifierPlus)     : 0x2D02 (decimal bytes:  45,    2 ) (decimal UShort: 557)
button22 (headphones)        : 0xB701 (decimal bytes: 183,    1 ) (decimal UShort: 439)
button23 (camera)            : 0xB601 (decimal bytes: 182,    2 ) (decimal UShort: 438)
button24 (folderPage)        : 0xA701 (decimal bytes: 167,    1 ) (decimal UShort: 423)
button25 (house)             : 0x2302 (decimal bytes:  35,    2 ) (decimal UShort: 547)
button26 (envelope)          : 0x8A01 (decimal bytes: 138,    1 ) (decimal UShort: 394)
button27 (back)              : 0x2402 (decimal bytes:  36,    2 ) (decimal UShort: 548)
button28 (forward)           : 0x2502 (decimal bytes:  37,    2 ) (decimal UShort: 549)
button29 (playPause)         : 0xCD00 (decimal bytes: 205,    0 ) (decimal UShort: 205)
button30 (skipBack)          : 0xB600 (decimal bytes: 182,    0 ) (decimal UShort: 182)
button31 (skipForward)       : 0xB500 (decimal bytes: 181,    0 ) (decimal UShort: 181)
button32 (mute)              : 0xE200 (decimal bytes: 226,    0 ) (decimal UShort: 226)
button33 (volumeMinus)       : 0xEA00 (decimal bytes: 234,    0 ) (decimal UShort: 234)
button34 (volumePlus)        : 0xE900 (decimal bytes: 233,    0 ) (decimal UShort: 233)
button35 (Star)              : 0x8201 (decimal bytes: 130,    1 ) (decimal UShort: 386)
button36 (calculator)        : 0x9201 (decimal bytes: 146,    1 ) (decimal UShort: 402)
button37 (key)               : 0x9C01 (decimal bytes: 156,    1 ) (decimal UShort: 412)

------------------------------------------------------

The fact that the special buttons are driving several state machines (one for each of {button1, ... button5}, one for the set {button6, button7}, one for the set {button8, ... button37}, and one for button0) opens up some interesting possibilities for chording keystrokes.  However, for my current purpose, I am content simply to be able to detect a DOWN event for each of {button1, ..., button37}.
	
Let me assign a number to the relevant state machines, so that I can track the state of each one in my Autohotkey script:

stateMachine0: F-Lock (possible state values: 0, 1)  (indicated by byte 5, bit 0 (i.e. bit40))
stateMachine1: button1 (possible state values: 0, 1) (indicated by byte 5, bit 2 (i.e. bit42))
stateMachine2: button2 (possible state values: 0, 1) (indicated by byte 5, bit 3 (i.e. bit43))
stateMachine3: button3 (possible state values: 0, 1) (indicated by byte 5, bit 4 (i.e. bit44))
stateMachine4: button4 (possible state values: 0, 1) (indicated by byte 5, bit 5 (i.e. bit45))
stateMachine5: button5 (possible state values: 0, 1) (indicated by byte 5, bit 6 (i.e. bit46))
stateMachine6: {button6, button7} (possible state values: 0, 6, 7) (indicated by byte 6)
stateMachine7: {button8, ..., button37} (possible state values: 0, or any of the 30 characteristic values above) (indicated by bytes 1 and 2)
