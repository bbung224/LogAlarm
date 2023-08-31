http(method, url, oData := "", oHeaders := "") {
	static whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	;whr.SetProxy(2, "127.0.0.1:8888")
	whr.Open(method, url, true)

	for k, v in oHeaders {
		whr.SetRequestHeader(k, v)
	}
	if (method ~= "i)POST|PUT") && !oHeaders["Content-Type"] {
		whr.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	}

	if IsObject(oData) {
		for k, v in oData {
			sData .= "&" k "=" v
		}
		sData := SubStr(sData, 2)
	}
	else {
		sData := oData
	}

	whr.Send(sData)
	whr.WaitForResponse()

	arr := whr.responseBody
	pData := NumGet(ComObjValue(arr) + 8 + A_PtrSize)
	length := arr.MaxIndex() + 1

	return StrGet(pData, length, "utf-8")
}

;UriEncode(Uri)
;{
;    oSC := ComObjCreate("ScriptControl")
;    oSC.Language := "JScript"
;    Script := "var Encoded = encodeURIComponent(""" . Uri . """)"
;    oSC.ExecuteStatement(Script)
;    Return, oSC.Eval("Encoded")
;}

UriEncode(Uri)
{
	VarSetCapacity(Var, StrPut(Uri, "UTF-8"), 0)
	StrPut(Uri, &Var, "UTF-8")
	f := A_FormatInteger
	SetFormat, IntegerFast, H
	While Code := NumGet(Var, A_Index - 1, "UChar")
		If (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
			|| Code >= 0x61 && Code <= 0x7A) ; a-z
			Res .= Chr(Code)
		Else
			Res .= "%" . SubStr(Code + 0x100, -1)
	SetFormat, IntegerFast, %f%
	Return, Res
}

UriDecode(Uri)
{
    oSC := ComObjCreate("ScriptControl")
    oSC.Language := "JScript"
    Script := "var Decoded = decodeURIComponent(""" . Uri . """)"
    oSC.ExecuteStatement(Script)
    Return, oSC.Eval("Decoded")
}


PostDiscord(webhookUrl, postData) {
	/*
	postdata=
	(
	{
	  "content": "[Test](https://www.google.com/)",
	  "embeds": [
		{
		  "title": "Double Test",
		  "description": "[](https://www.google.com/)",
		  "url": "https://www.google.com/",
		  "color": 8280002,
		  "thumbnail": {
			"url": "https://i.imgur.com/KiRApYa.jpg"
		  },
		  "image": {
			"url": "https://i.imgur.com/KiRApYa.jpg"
		  }
		}
	  ]
	}
	) ; Use https://leovoel.github.io/embed-visualizer/ to generate above webhook code
	*/

	header := Object("Content-Type", "application/json")
	return http("POST", webhookUrl, postData, header)
}

PostDiscordString(webhookUrl, data) {
	postData := "{""content"":""" . data . """}"
	return PostDiscord(webhookUrl, postData)
}
