;By Laszlo, adapted by TheGood
;http://www.autohotkey.com/forum/viewtopic.php?p=377086#377086

Bin2Hex(addr,len) {
    Static fun, ptr 
    If (fun = "") {
        If A_IsUnicode
            If (A_PtrSize = 8)
                h=4533c94c8bd14585c07e63458bd86690440fb60248ffc2418bc9410fb6c0c0e8043c090fb6c00f97c14180e00f66f7d96683e1076603c8410fb6c06683c1304180f8096641890a418bc90f97c166f7d94983c2046683e1076603c86683c13049ffcb6641894afe75a76645890ac366448909c3
            Else h=558B6C241085ED7E5F568B74240C578B7C24148A078AC8C0E90447BA090000003AD11BD2F7DA66F7DA0FB6C96683E2076603D16683C230668916240FB2093AD01BC9F7D966F7D96683E1070FB6D06603CA6683C13066894E0283C6044D75B433C05F6689065E5DC38B54240833C966890A5DC3
        Else h=558B6C241085ED7E45568B74240C578B7C24148A078AC8C0E9044780F9090F97C2F6DA80E20702D1240F80C2303C090F97C1F6D980E10702C880C1308816884E0183C6024D75CC5FC606005E5DC38B542408C602005DC3
        VarSetCapacity(fun, StrLen(h) // 2)
        Loop % StrLen(h) // 2
            NumPut("0x" . SubStr(h, 2 * A_Index - 1, 2), fun, A_Index - 1, "Char")
        ptr := A_PtrSize ? "Ptr" : "UInt"
        DllCall("VirtualProtect", ptr, &fun, ptr, VarSetCapacity(fun), "UInt", 0x40, "UInt*", 0)
    }
    VarSetCapacity(hex, A_IsUnicode ? 4 * len + 2 : 2 * len + 1)
    DllCall(&fun, ptr, &hex, ptr, addr, "UInt", len, "CDecl")
    VarSetCapacity(hex, -1) ; update StrLen
    Return hex
}

; baseAddress is an address of a word in memory.
; bitNumber is the index of a bit, starting at zero for bit zero of the word at baseAddress,
; and continuing on through the byte at baseAddress and then on into the next address, etc.
; It is up to the user not to try to access a bit index that would cause an access violation.
getBit(baseAddress, bitIndex) {
	Local wordOffset, word, bitValue
	wordOffset:=bitIndex // (A_PtrSize * 8)
	bitIndexWithinWord := mod(bitIndex, A_PtrSize * 8)
	
	word := NumGet(baseAddress + wordOffset, 0, "Ptr")
	bitValue := (word>>bitIndexWithinWord) & 1
	Return bitValue
}

; baseAddress is an address of a word in memory.
; bitNumber is the index of a bit, starting at zero for bit zero of the word at baseAddress,
; and continuing on through the byte at baseAddress and then on into the next address, etc.
; It is up to the user not to try to access a bit index that would cause an access violation.
getByte(baseAddress, byteIndex) {
	Local wordOffset, word, byteValue
	wordOffset:=byteIndex // (A_PtrSize)
	byteIndexWithinWord := mod(byteIndex, A_PtrSize)
	
	word := NumGet(baseAddress + wordOffset, 0, "Ptr")
	byteValue := (word>>(byteIndexWithinWord*8)) & 255
	Return byteValue
}

; Returns a string consisting of "1" and "0" characters, formed by reading
; length bytes, starting at baseAddress.  
bitString(baseAddress, length)
{
	Local returnValue
	returnValue := ""
	Loop % length*8 
	{
		returnValue := returnValue . getBit(baseAddress, A_Index - 1)
		if(mod(A_Index - 1, 8) = 7)
		{
			returnValue := returnValue . " -- " ;add a spacer between bytes.
		}
	}
	Return returnValue
}

; Returns a string consisting of decimal numbers, delimited by spaces, formed by reading
; length bytes, starting at baseAddress.  
byteString(baseAddress, length)
{
	Local returnValue
	returnValue := ""
	Loop % length 
	{
		returnValue := returnValue . Format("{:3u}", getByte(baseAddress, A_Index - 1)) . " "
	}
	Return returnValue
}

