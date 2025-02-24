#Include %A_ScriptDir%\Scripts\Include\Gdip_All.ahk
version = Rockets PTCGP Bot
#SingleInstance, force
CoordMode, Mouse, Screen
SetTitleMatchMode, 3

githubUser := ""
repoName := "PTCGPB"
localVersion := "v6.3.9"
scriptFolder := A_ScriptDir
zipPath := A_Temp . "\update.zip"
extractPath := A_Temp . "\update"

if not A_IsAdmin
{
	; Relaunch script with admin rights
	Run *RunAs "%A_ScriptFullPath%"
	ExitApp
}

;KillADBProcesses()

global Instances, jsonFileName, PacksText, runMain, scaleParam, proxy, screenshotName

totalFile := A_ScriptDir . "\json\total.json"
backupFile := A_ScriptDir . "\json\total-backup.json"
if FileExist(totalFile) ; Check if the file exists
{
	FileCopy, %totalFile%, %backupFile%, 1 ; Copy source file to target
	if (ErrorLevel)
		MsgBox, Failed to create %backupFile%. Ensure permissions and paths are correct.
}
FileDelete, %totalFile%
packsFile := A_ScriptDir . "\json\Packs.json"
backupFile := A_ScriptDir . "\json\Packs-backup.json"
if FileExist(packsFile) ; Check if the file exists
{
	FileCopy, %packsFile%, %backupFile%, 1 ; Copy source file to target
	if (ErrorLevel)
		MsgBox, Failed to create %backupFile%. Ensure permissions and paths are correct.
}
InitializeJsonFile() ; Create or open the JSON file
pToken := Gdip_Startup()
global FriendID

; Create the main GUI for selecting number of instances
IniRead, FriendID, Settings.ini, UserSettings, FriendID
IniRead, waitTime, Settings.ini, UserSettings, waitTime, 5
IniRead, Delay, Settings.ini, UserSettings, Delay, 250
IniRead, folderPath, Settings.ini, UserSettings, folderPath, C:\Program Files\Netease
IniRead, discordWebhookURL, Settings.ini, UserSettings, discordWebhookURL, ""
IniRead, discordUserId, Settings.ini, UserSettings, discordUserId, ""
IniRead, Columns, Settings.ini, UserSettings, Columns, 5
IniRead, godPack, Settings.ini, UserSettings, godPack, Continue
IniRead, Instances, Settings.ini, UserSettings, Instances, 1
IniRead, defaultLanguage, Settings.ini, UserSettings, defaultLanguage, Scale125
IniRead, MainLanguage, Settings.ini, UserSettings, MainLanguage, Chinese
IniRead, SelectedMonitorIndex, Settings.ini, UserSettings, SelectedMonitorIndex, 1
IniRead, swipeSpeed, Settings.ini, UserSettings, swipeSpeed, 300
IniRead, deleteMethod, Settings.ini, UserSettings, deleteMethod, 3 Pack
IniRead, runMain, Settings.ini, UserSettings, runMain, 1
IniRead, heartBeat, Settings.ini, UserSettings, heartBeat, 1
IniRead, heartBeatWebhookURL, Settings.ini, UserSettings, heartBeatWebhookURL, ""
IniRead, heartBeatName, Settings.ini, UserSettings, heartBeatName, ""
IniRead, DeadHBWebhookURL, Settings.ini, UserSettings, DeadHBWebhookURL, ""
IniRead, nukeAccount, Settings.ini, UserSettings, nukeAccount, 0
IniRead, packMethod, Settings.ini, UserSettings, packMethod, 0
IniRead, TrainerCheck, Settings.ini, UserSettings, TrainerCheck, 0
IniRead, FullArtCheck, Settings.ini, UserSettings, FullArtCheck, 0
IniRead, RainbowCheck, Settings.ini, UserSettings, RainbowCheck, 0
IniRead, CrownCheck, Settings.ini, UserSettings, CrownCheck, 0
IniRead, ImmersiveCheck, Settings.ini, UserSettings, ImmersiveCheck, 0
IniRead, PseudoGodPack, Settings.ini, UserSettings, PseudoGodPack, 0
IniRead, minStars, Settings.ini, UserSettings, minStars, 0
IniRead, Palkia, Settings.ini, UserSettings, Palkia, 0
IniRead, Dialga, Settings.ini, UserSettings, Dialga, 1
IniRead, Mew, Settings.ini, UserSettings, Mew, 0
IniRead, Pikachu, Settings.ini, UserSettings, Pikachu, 0
IniRead, Charizard, Settings.ini, UserSettings, Charizard, 0
IniRead, Mewtwo, Settings.ini, UserSettings, Mewtwo, 0
IniRead, slowMotion, Settings.ini, UserSettings, slowMotion, 0
IniRead, proxy, Settings.ini, UserSettings, proxy, 0
IniRead, checkHBWebhookURL, Settings.ini, UserSettings, checkHBWebhookURL, 0

Gui, Add, Text, x10 y10, Friend ID:
; Add input controls
if(FriendID = "ERROR")
	FriendID =

if(FriendID = )
	Gui, Add, Edit, vFriendID w120 x60 y8
else
	Gui, Add, Edit, vFriendID w120 x60 y8 h18, %FriendID%

Gui, Add, Text, x10 y30, Rerolling Instances:
Gui, Add, Text, x30 y50, Instances:
Gui, Add, Edit, vInstances w25 x80 y45 h18, %Instances%
Gui, Add, Text, x30 y75, Columns:
Gui, Add, Edit, vColumns w25 x80 y70 h18, %Columns%
if(runMain)
	Gui, Add, Checkbox, Checked vrunMain x30 y95, Run Main
else
	Gui, Add, Checkbox, vrunMain x30 y95, Run Main

Gui, Add, Text, x10 y120, God Pack Settings:
Gui, Add, Text, x30 y140, Min. 2 Stars:
Gui, Add, Edit, vminStars w25 x90 y135 h18, %minStars%

Gui, Add, Text, x10 y160, Method:
Gui, Add, Text, x130 y160, Language:
Gui, Add, Text, x130 y178, (Main account)
Gui, Add, Picture, x450 y340 w30 h30, %A_ScriptDir%\logs\dino.png

; Pack selection logic
if (deleteMethod = "5 Pack") {
	defaultDelete := 1
} else if (deleteMethod = "3 Pack") {
	defaultDelete := 2
} else if (deleteMethod = "Inject") {
	defaultDelete := 3
}
; Pack selection logic
if (MainLanguage = "Chinese") {
	defaultMainLanguage := 1
} else if (MainLanguage = "English") {
	defaultMainLanguage := 2
} else if (MainLanguage = "Doods") {
	defaultMainLanguage := 3
}

Gui, Add, DropDownList, vdeleteMethod gdeleteSettings choose%defaultDelete% x55 y158 w60, 5 Pack|3 Pack|Inject
Gui, Add, DropDownList, vMainLanguage gdeleteSettings choose%defaultMainLanguage% x185 y158 w60, Chinese|English|Doods
if(packMethod)
	Gui, Add, Checkbox, Checked vpackMethod x30 y185, 1 Pack Method
else
	Gui, Add, Checkbox, vpackMethod x30 y185, 1 Pack Method

if(nukeAccount)
	Gui, Add, Checkbox, Checked vnukeAccount x30 y205, Menu Delete Account
else
	Gui, Add, Checkbox, vnukeAccount x30 y205, Menu Delete Account

if(StrLen(discordUserID) < 3)
	discordUserID =
if(StrLen(discordWebhookURL) < 3)
	discordWebhookURL =

Gui, Add, Text, x10 y225, Discord Settings:
Gui, Add, Text, x30 y245, Discord ID:
Gui, Add, Edit, vdiscordUserId w100 x90 y240 h18, %discordUserId%
Gui, Add, Text, x30 y270, Discord Webhook URL:
Gui, Add, Edit, vdiscordWebhookURL h20 w100 x150 y265 h18, %discordWebhookURL%

if(StrLen(heartBeatName) < 3)
	heartBeatName =
if(StrLen(heartBeatWebhookURL) < 3)
	heartBeatWebhookURL =
if(StrLen(DeadHBWebhookURL) < 3)
	DeadHBWebhookURL =

Gui, Add, Text, x10 y295, Discord Heartbeat:
Gui, Add, Text, vhbName x30 y315, Name:
Gui, Add, Edit, vheartBeatName w50 x70 y310 h18, %heartBeatName%
Gui, Add, Text, vhbText x125 y315, (the reroller account name)
Gui, Add, Text, vhbURL x30 y340, Webhook URL:
Gui, Add, Edit, vheartBeatWebhookURL h20 w100 x110 y335 h18, %heartBeatWebhookURL%
Gui, Add, Text, vDhbURL x30 y365, DeadHBWebhook URL:
Gui, Add, Edit, vDeadHBWebhookURL h20 w100 x130 y360 h18, %DeadHBWebhookURL%

Gui, Add, Text, x275 y10, Choose Pack(s):

if(Dialga)
	Gui, Add, Checkbox, Checked vDialga x295 y30, Dialga
else
	Gui, Add, Checkbox, vDialga x295 y30, Dialga

if(Palkia)
	Gui, Add, Checkbox, Checked vPalkia x295 y50, Palkia
else
	Gui, Add, Checkbox, vPalkia x295 y50, Palkia

if(Mew)
	Gui, Add, Checkbox, Checked vMew x295 y70, Mew
else
	Gui, Add, Checkbox, vMew x295 y70, Mew

if(Pikachu)
	Gui, Add, Checkbox, Checked vPikachu x350 y30, Pikachu
else
	Gui, Add, Checkbox, vPikachu x350 y30, Pikachu

if(Charizard)
	Gui, Add, Checkbox, Checked vCharizard x350 y50, Charizard
else
	Gui, Add, Checkbox, vCharizard x350 y50, Charizard

if(Mewtwo)
	Gui, Add, Checkbox, Checked vMewtwo x350 y70, Mewtwo
else
	Gui, Add, Checkbox, vMewtwo x350 y70, Mewtwo

Gui, Add, Text, x275 y90, Other Pack Detection Settings:

if(FullArtCheck)
	Gui, Add, Checkbox, Checked vFullArtCheck x295 y110, Single Full Art
else
	Gui, Add, Checkbox, vFullArtCheck x295 y110, Single Full Art

if(TrainerCheck)
	Gui, Add, Checkbox, Checked vTrainerCheck x295 y130, Single Trainer
else
	Gui, Add, Checkbox, vTrainerCheck x295 y130, Single Trainer

if(RainbowCheck)
	Gui, Add, Checkbox, Checked vRainbowCheck x295 y150, Single Rainbow
else
	Gui, Add, Checkbox, vRainbowCheck x295 y150, Single Rainbow

if(PseudoGodPack)
	Gui, Add, Checkbox, Checked vPseudoGodPack x392 y110, Double 2 Star
else
	Gui, Add, Checkbox, vPseudoGodPack x392 y110, Double 2 Star

if(CrownCheck)
	Gui, Add, Checkbox, Checked vCrownCheck x392 y130, Save Crowns
else
	Gui, Add, Checkbox, vCrownCheck x392 y130, Save Crowns

if(ImmersiveCheck)
	Gui, Add, Checkbox, Checked vImmersiveCheck x392 y150, Save Immersives
else
	Gui, Add, Checkbox, vImmersiveCheck x392 y150, Save Immersives

Gui, Add, Text, x275 y170, Time Settings:
Gui, Add, Text, x295 y190, Delay:
Gui, Add, Edit, vDelay w35 x330 y190 h18, %Delay%
Gui, Add, Text, x295 y210, Wait Time:
Gui, Add, Edit, vwaitTime w25 x350 y210 h18, %waitTime%
Gui, Add, Text, x295 y230, Swipe Speed:
Gui, Add, Edit, vswipeSpeed w35 x365 y230 h18, %swipeSpeed%

Gui, Add, Text, x275 y250, Other Settings:
Gui, Add, Text, x295 y270, Monitor:
; Initialize monitor dropdown options
SysGet, MonitorCount, MonitorCount
MonitorOptions := ""
Loop, %MonitorCount%
{
	SysGet, MonitorName, MonitorName, %A_Index%
	SysGet, Monitor, Monitor, %A_Index%
	MonitorOptions .= (A_Index > 1 ? "|" : "") "" A_Index ": (" MonitorRight - MonitorLeft "x" MonitorBottom - MonitorTop ")"

}
SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
Gui, Add, DropDownList, x335 y268 w90 vSelectedMonitorIndex Choose%SelectedMonitorIndex%, %MonitorOptions%
Gui, Add, Text, x295 y290, Folder Path:
Gui, Add, Edit, vfolderPath w100 x355 y290 h18, %folderPath%
if(slowMotion)
	Gui, Add, Checkbox, Checked vslowMotion x295 y310, Base Game Compatibility
else
	Gui, Add, Checkbox, vslowMotion x295 y310, Base Game Compatibility

Gui, Add, Button, gArrangeWindows x275 y380 w120, Arrange Windows
Gui, Add, Button, gStart x405 y380 w120, Start

if (defaultLanguage = "Scale125") {
	defaultLang := 1
	scaleParam := 277
} else if (defaultLanguage = "Scale100") {
	defaultLang := 2
	scaleParam := 287
}

; Gui, Add, DropDownList, x80 y245 w145 vdefaultLanguage choose%defaultLang%, Scale125

Gui, Show, , %localVersion% Rockets PTCGPB Bot Setup [Non-Commercial 4.0 International License] ;'
Return

deleteSettings:
	Gui, Submit, NoHide
	;GuiControlGet, deleteMethod,, deleteMethod

	if(InStr(deleteMethod, "Inject")) {
		GuiControl, Hide, nukeAccount
		nukeAccount = false
	}
	else
		GuiControl, Show, nukeAccount
return

ArrangeWindows:
	GuiControlGet, runMain,, runMain
	GuiControlGet, Instances,, Instances
	GuiControlGet, Columns,, Columns
	GuiControlGet, SelectedMonitorIndex,, SelectedMonitorIndex
	Loop %Instances% {
		resetWindows(A_Index, SelectedMonitorIndex)
		sleep, 10
	}
return

; Handle the link click
OpenLink:
	Run, https://buymeacoffee.com/aarturoo
return

OpenDiscord:
	Run, https://discord.gg/C9Nyf7P4sT
return

Start:
	Gui, Submit  ; Collect the input values from the first page
	Instances := Instances  ; Directly reference the "Instances" variable

	; Create the second page dynamically based on the number of instances
	Gui, Destroy ; Close the first page

	IniWrite, %FriendID%, Settings.ini, UserSettings, FriendID
	IniWrite, %waitTime%, Settings.ini, UserSettings, waitTime
	IniWrite, %Delay%, Settings.ini, UserSettings, Delay
	IniWrite, %folderPath%, Settings.ini, UserSettings, folderPath
	IniWrite, %discordWebhookURL%, Settings.ini, UserSettings, discordWebhookURL
	IniWrite, %discordUserId%, Settings.ini, UserSettings, discordUserId
	IniWrite, %Columns%, Settings.ini, UserSettings, Columns
	IniWrite, %openPack%, Settings.ini, UserSettings, openPack
	IniWrite, %godPack%, Settings.ini, UserSettings, godPack
	IniWrite, %Instances%, Settings.ini, UserSettings, Instances
	;IniWrite, %setSpeed%, Settings.ini, UserSettings, setSpeed
	IniWrite, %defaultLanguage%, Settings.ini, UserSettings, defaultLanguage
	IniWrite, %SelectedMonitorIndex%, Settings.ini, UserSettings, SelectedMonitorIndex
	IniWrite, %swipeSpeed%, Settings.ini, UserSettings, swipeSpeed
	IniWrite, %deleteMethod%, Settings.ini, UserSettings, deleteMethod
	IniWrite, %MainLanguage%, Settings.ini, UserSettings, MainLanguage
	IniWrite, %runMain%, Settings.ini, UserSettings, runMain
	IniWrite, %heartBeat%, Settings.ini, UserSettings, heartBeat
	IniWrite, %heartBeatWebhookURL%, Settings.ini, UserSettings, heartBeatWebhookURL
	IniWrite, %heartBeatName%, Settings.ini, UserSettings, heartBeatName
	IniWrite, %DeadHBWebhookURL%, Settings.ini, UserSettings, DeadHBWebhookURL
	IniWrite, %nukeAccount%, Settings.ini, UserSettings, nukeAccount
	IniWrite, %packMethod%, Settings.ini, UserSettings, packMethod
	IniWrite, %TrainerCheck%, Settings.ini, UserSettings, TrainerCheck
	IniWrite, %FullArtCheck%, Settings.ini, UserSettings, FullArtCheck
	IniWrite, %RainbowCheck%, Settings.ini, UserSettings, RainbowCheck
	IniWrite, %CrownCheck%, Settings.ini, UserSettings, CrownCheck
	IniWrite, %ImmersiveCheck%, Settings.ini, UserSettings, ImmersiveCheck
	IniWrite, %PseudoGodPack%, Settings.ini, UserSettings, PseudoGodPack
	IniWrite, %minStars%, Settings.ini, UserSettings, minStars
	IniWrite, %Palkia%, Settings.ini, UserSettings, Palkia
	IniWrite, %Dialga%, Settings.ini, UserSettings, Dialga
	IniWrite, %Mew%, Settings.ini, UserSettings, Mew
	IniWrite, %Pikachu%, Settings.ini, UserSettings, Pikachu
	IniWrite, %Charizard%, Settings.ini, UserSettings, Charizard
	IniWrite, %Mewtwo%, Settings.ini, UserSettings, Mewtwo
	IniWrite, %slowMotion%, Settings.ini, UserSettings, slowMotion

	; Loop to process each instance
	Loop, %Instances%
	{
		if (A_Index != 1) {
			SourceFile := "Scripts\1.ahk" ; Path to the source .ahk file
			TargetFolder := "Scripts\" ; Path to the target folder
			TargetFile := TargetFolder . A_Index . ".ahk" ; Generate target file path
			if(Instances > 1) {
				FileDelete, %TargetFile%
				FileCopy, %SourceFile%, %TargetFile%, 1 ; Copy source file to target
			}
			if (ErrorLevel)
				MsgBox, Failed to create %TargetFile%. Ensure permissions and paths are correct.
		}

		FileName := "Scripts\" . A_Index . ".ahk"
		Command := FileName

		Run, %Command%
	}
	if(runMain) {
		FileName := "Scripts\Main.ahk"
		Run, %FileName%
	}
	if(inStr(FriendID, "https"))
		DownloadFile(FriendID, "ids.txt")
	SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
	SysGet, Monitor, Monitor, %SelectedMonitorIndex%
	rerollTime := A_TickCount
	Loop {
		Sleep, 30000
		; Sum all variable values and write to total.json
		total := SumVariablesInJsonFile()
		totalSeconds := Round((A_TickCount - rerollTime) / 1000) ; Total time in seconds
		mminutes := Floor(totalSeconds / 60)
		if(total = 0)
			total := "0                             "
		packStatus := "Time: " . mminutes . "m Packs: " . total
		CreateStatusMessage(packStatus, 287, 490)
		if(heartBeat)
			if((A_Index = 1 || (Mod(A_Index, 60) = 0))) {
				onlineAHK := "Online: "
				offlineAHK := "Offline: "
				Online := []
				if(runMain) {
					IniRead, value, HeartBeat.ini, HeartBeat, Main
					if(value)
						onlineAHK := "Online: Main, "
					else
						offlineAHK := "Offline: Main, "
					IniWrite, 0, HeartBeat.ini, HeartBeat, Main
				}
				Loop %Instances% {
					screenShot := Screenshot(A_Index)
					if(heartBeatName)
						discordUserID := heartBeatName
					LogToDiscord("\n" . screenshotName, screenShot, discordUserId, , true)
					IniRead, value, HeartBeat.ini, HeartBeat, Instance%A_Index%
					if(value)
						Online.push(1)
					else
						Online.Push(0)
					IniWrite, 0, HeartBeat.ini, HeartBeat, Instance%A_Index%
				}
				for index, value in Online {
					if(index = Online.MaxIndex())
						commaSeparate := "."
					else
						commaSeparate := ", "
					if(value)
						onlineAHK .= A_Index . commaSeparate
					else
						offlineAHK .= A_Index . commaSeparate
				}
				if(offlineAHK = "Offline: ")
					offlineAHK := "Offline: none."
				if(onlineAHK = "Online: ")
					onlineAHK := "Online: none."

				discMessage := "\n" . onlineAHK . "\n" . offlineAHK . "\n" . packStatus . "\nVer. Rocket_6.3.9"
				if(heartBeatName)
					discordUserID := heartBeatName
				LogToDiscord(discMessage, , discordUserID)
			}
	}
Return

GuiClose:
ExitApp

MonthToDays(year, month) {
	static DaysInMonths := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	days := 0
	Loop, % month - 1 {
		days += DaysInMonths[A_Index]
	}
	if (month > 2 && IsLeapYear(year))
		days += 1
	return days
}

IsLeapYear(year) {
	return (Mod(year, 4) = 0 && Mod(year, 100) != 0) || Mod(year, 400) = 0
}

LogToDiscord(message, screenshotFile := "", ping := false, xmlFile := "", checkHB := false) {
	global discordUserId, discordWebhookURL, friendCode, heartBeatWebhookURL, proxy, checkHBWebhookURL
	discordPing := discordUserId
	if(heartBeatWebhookURL)
		discordWebhookURL := heartBeatWebhookURL
	if(checkHB)
		discordWebhookURL := checkHBWebhookURL

	if (discordWebhookURL != "") {
		MaxRetries := 10
		RetryCount := 0
		Loop {
			try {
				; If an image file is provided, send it
				if (screenshotFile != "") {
					; Check if the file exists
					if (FileExist(screenshotFile)) {
						; Send the image using curl
						if(proxy = 0) {
							curlCommand := "curl -k "
							. "-F ""payload_json={\""content\"":\""" . discordPing . message . "\""};type=application/json;charset=UTF-8"" "
							. "-F ""file=@" . screenshotFile . """ "
							. discordWebhookURL
						}
						else {
							curlCommand := "curl -x " . proxy . " -k "
							. "-F ""payload_json={\""content\"":\""" . discordPing . message . "\""};type=application/json;charset=UTF-8"" "
							. "-F ""file=@" . screenshotFile . """ "
							. discordWebhookURL
						}
						RunWait, %curlCommand%,, Hide
					}
				}
				else {
					if(proxy = 0) {
						curlCommand := "curl -k "
							. "-F ""payload_json={\""content\"":\""" . discordPing . message . "\""};type=application/json;charset=UTF-8"" " . discordWebhookURL
					}
					else {
						curlCommand := "curl -x " . proxy . " -k "
							. "-F ""payload_json={\""content\"":\""" . discordPing . message . "\""};type=application/json;charset=UTF-8"" " . discordWebhookURL
					}
					RunWait, %curlCommand%,, Hide
				}
				break
			}
			catch {
				RetryCount++
				if (RetryCount >= MaxRetries) {
					CreateStatusMessage("Failed to send discord message.")
					break
				}
				Sleep, 250
			}
			sleep, 250
		}
	}
}

DownloadFile(url, filename) {
	global proxy
	url := url  ; Change to your hosted .txt URL "https://pastebin.com/raw/vYxsiqSs"
	localPath = %filename% ; Change to the folder you want to save the file
	errored := false
	try {
		whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		whr.Open("GET", url, true)
		if(proxy != 0){
			whr.SetProxy(2, proxy)
		}
		whr.Send()
		whr.WaitForResponse()
		ids := whr.ResponseText
	} catch {
		errored := true
	}
	if(!errored) {
		FileDelete, %localPath%
		FileAppend, %ids%, %localPath%
	}
}

resetWindows(Title, SelectedMonitorIndex){
	global Columns, runMain
	RetryCount := 0
	MaxRetries := 10
	if(runMain){
		if(Title = 1) {
			Loop
			{
				try {
					; Get monitor origin from index
					SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
					SysGet, Monitor, Monitor, %SelectedMonitorIndex%

					rowHeight := 533  ; Adjust the height of each row
					currentRow := Floor((Title - 1) / Columns)
					y := currentRow * rowHeight
					x := Mod((Title - 1), Columns) * scaleParam
					Title := "Main"
					WinMove, %Title%, , % (MonitorLeft + x), % (MonitorTop + y), scaleParam, 537
					break
				}
				catch {
					if (RetryCount > MaxRetries)
						Pause
				}
				Sleep, 1000
			}
			Title := 1
		}
	}
	Loop
	{
		try {
			; Get monitor origin from index
			SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
			SysGet, Monitor, Monitor, %SelectedMonitorIndex%
			if(runMain)
				Title := Title + 1
			rowHeight := 533  ; Adjust the height of each row
			currentRow := Floor((Title - 1) / Columns)
			y := currentRow * rowHeight
			x := Mod((Title - 1), Columns) * scaleParam
			if(runMain)
				Title := Title - 1
			WinMove, %Title%, , % (MonitorLeft + x), % (MonitorTop + y), scaleParam, 537
			break
		}
		catch {
			if (RetryCount > MaxRetries)
				Pause
		}
		Sleep, 1000
	}
	return true
}

CreateStatusMessage(Message, X := 0, Y := 80) {
	global PacksText, SelectedMonitorIndex, createdGUI, Instances
	MaxRetries := 10
	RetryCount := 0
	try {
		GuiName := 22
		SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
		SysGet, Monitor, Monitor, %SelectedMonitorIndex%
		X := MonitorLeft + X
		Y := MonitorTop + Y
		Gui %GuiName%:+LastFoundExist
		if WinExist() {
			GuiControl, , PacksText, %Message%
		} else {			OwnerWND := WinExist(1)
			if(!OwnerWND)
				Gui, %GuiName%:New, +ToolWindow -Caption
			else
				Gui, %GuiName%:New, +Owner%OwnerWND% +ToolWindow -Caption
			Gui, %GuiName%:Margin, 2, 2  ; Set margin for the GUI
			Gui, %GuiName%:Font, s8  ; Set the font size to 8 (adjust as needed)
			Gui, %GuiName%:Add, Text, vPacksText, %Message%
			Gui, %GuiName%:Show, NoActivate x%X% y%Y%, NoActivate %GuiName%
		}
	}
}

; Global variable to track the current JSON file
global jsonFileName := ""

; Function to create or select the JSON file
InitializeJsonFile() {
	global jsonFileName
	fileName := A_ScriptDir . "\json\Packs.json"
	if FileExist(fileName)
		FileDelete, %fileName%
	if !FileExist(fileName) {
		; Create a new file with an empty JSON array
		FileAppend, [], %fileName%  ; Write an empty JSON array
		jsonFileName := fileName
		return
	}
}

; Function to append a time and variable pair to the JSON file
AppendToJsonFile(variableValue) {
	global jsonFileName
	if (jsonFileName = "") {
		MsgBox, JSON file not initialized. Call InitializeJsonFile() first.
		return
	}

	; Read the current content of the JSON file
	FileRead, jsonContent, %jsonFileName%
	if (jsonContent = "") {
		jsonContent := "[]"
	}

	; Parse and modify the JSON content
	jsonContent := SubStr(jsonContent, 1, StrLen(jsonContent) - 1) ; Remove trailing bracket
	if (jsonContent != "[")
		jsonContent .= ","
	jsonContent .= "{""time"": """ A_Now """, ""variable"": " variableValue "}]"

	; Write the updated JSON back to the file
	FileDelete, %jsonFileName%
	FileAppend, %jsonContent%, %jsonFileName%
}

; Function to sum all variable values in the JSON file
SumVariablesInJsonFile() {
	global jsonFileName
	if (jsonFileName = "") {
		return
	}

	; Read the file content
	FileRead, jsonContent, %jsonFileName%
	if (jsonContent = "") {
		return 0
	}

	; Parse the JSON and calculate the sum
	sum := 0
	; Clean and parse JSON content
	jsonContent := StrReplace(jsonContent, "[", "") ; Remove starting bracket
	jsonContent := StrReplace(jsonContent, "]", "") ; Remove ending bracket
	Loop, Parse, jsonContent, {, }
	{
		; Match each variable value
		if (RegExMatch(A_LoopField, """variable"":\s*(-?\d+)", match)) {
			sum += match1
		}
	}

	; Write the total sum to a file called "total.json"

	if(sum > 0) {
		totalFile := A_ScriptDir . "\json\total.json"
		totalContent := "{""total_sum"": " sum "}"
		FileDelete, %totalFile%
		FileAppend, %totalContent%, %totalFile%
	}

	return sum
}

KillADBProcesses() {
	; Use AHK's Process command to close adb.exe
	Process, Close, adb.exe
	; Fallback to taskkill for robustness
	RunWait, %ComSpec% /c taskkill /IM adb.exe /F /T,, Hide
}

MoveFilesRecursively(srcFolder, destFolder) {
	; Loop through all files and subfolders in the source folder
	Loop, Files, % srcFolder . "\*", R
	{
		; Get the relative path of the file/folder from the srcFolder
		relativePath := SubStr(A_LoopFileFullPath, StrLen(srcFolder) + 2)

		; Create the corresponding destination path
		destPath := destFolder . "\" . relativePath

		; If it's a directory, create it in the destination folder
		if (A_LoopIsDir)
		{
			; Ensure the directory exists, if not, create it
			FileCreateDir, % destPath
		}
		else
		{
			if ((relativePath = "ids.txt" && FileExist(destPath)) || (relativePath = "usernames.txt" && FileExist(destPath)) || (relativePath = "discord.txt" && FileExist(destPath))) {
                continue
            }
			if (relativePath = "usernames.txt" && FileExist(destPath)) {
                continue
            }
			if (relativePath = "usernames.txt" && FileExist(destPath)) {
                continue
            }
			; If it's a file, move it to the destination folder
			; Ensure the directory exists before moving the file
			FileCreateDir, % SubStr(destPath, 1, InStr(destPath, "\", 0, 0) - 1)
			FileMove, % A_LoopFileFullPath, % destPath, 1
		}
	}
}

HttpGet(url) {
	http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	http.Open("GET", url, false)
	http.Send()
	return http.ResponseText
}

; Existing function to extract value from JSON
ExtractJSONValue(json, key1, key2:="", ext:="") {
	value := ""
	json := StrReplace(json, """", "")
	lines := StrSplit(json, ",")

	Loop, % lines.MaxIndex()
	{
		if InStr(lines[A_Index], key1 ":") {
			; Take everything after the first colon as the value
			value := SubStr(lines[A_Index], InStr(lines[A_Index], ":") + 1)
			if (key2 != "")
			{
				if InStr(lines[A_Index+1], key2 ":") && InStr(lines[A_Index+1], ext)
					value := SubStr(lines[A_Index+1], InStr(lines[A_Index+1], ":") + 1)
			}
			break
		}
	}
	return Trim(value)
}

FixFormat(text) {
	; Replace carriage return and newline with an actual line break
	text := StrReplace(text, "\r\n", "`n")  ; Replace \r\n with actual newlines
	text := StrReplace(text, "\n", "`n")    ; Replace \n with newlines

	; Remove unnecessary backslashes before other characters like "player" and "None"
	text := StrReplace(text, "\player", "player")   ; Example: removing backslashes around words
	text := StrReplace(text, "\None", "None")       ; Remove backslash around "None"
	text := StrReplace(text, "\Welcome", "Welcome") ; Removing \ before "Welcome"

	; Escape commas by replacing them with %2C (URL encoding)
	text := StrReplace(text, ",", "")

	return text
}

VersionCompare(v1, v2) {
	; Remove non-numeric characters (like 'alpha', 'beta')
	cleanV1 := RegExReplace(v1, "[^\d.]")
	cleanV2 := RegExReplace(v2, "[^\d.]")

	v1Parts := StrSplit(cleanV1, ".")
	v2Parts := StrSplit(cleanV2, ".")

	Loop, % Max(v1Parts.MaxIndex(), v2Parts.MaxIndex()) {
		num1 := v1Parts[A_Index] ? v1Parts[A_Index] : 0
		num2 := v2Parts[A_Index] ? v2Parts[A_Index] : 0
		if (num1 > num2)
			return 1
		if (num1 < num2)
			return -1
	}

	; If versions are numerically equal, check if one is an alpha version
	isV1Alpha := InStr(v1, "alpha") || InStr(v1, "beta")
	isV2Alpha := InStr(v2, "alpha") || InStr(v2, "beta")

	if (isV1Alpha && !isV2Alpha)
		return -1 ; Non-alpha version is newer
	if (!isV1Alpha && isV2Alpha)
		return 1 ; Alpha version is older

	return 0 ; Versions are equal
}

Screenshot(winTitle := 1) {
	global screenshotName
	SetWorkingDir %A_ScriptDir%  ; Ensures the working directory is the script's directory
	; Define folder and file paths
	screenshotsDir := A_ScriptDir "\Screenshots\check"
	if !FileExist(screenshotsDir)
		FileCreateDir, %screenshotsDir%

	; File path for saving the screenshot locally
	screenshotName := A_Now . "_" . winTitle . "_check.png"
	screenshotFile := screenshotsDir "\" . screenshotName

	pBitmap := from_window(WinExist(winTitle))
	Gdip_SaveBitmapToFile(pBitmap, screenshotFile)

	return screenshotFile
}

from_window(ByRef image) {
	; Thanks tic - https://www.autohotkey.com/boards/viewtopic.php?t=6517

	; Get the handle to the window.
	image := (hwnd := WinExist(image)) ? hwnd : image

	; Restore the window if minimized! Must be visible for capture.
	if DllCall("IsIconic", "ptr", image)
		DllCall("ShowWindow", "ptr", image, "int", 4)

	; Get the width and height of the client window.
	VarSetCapacity(Rect, 16) ; sizeof(RECT) = 16
	DllCall("GetClientRect", "ptr", image, "ptr", &Rect)
		, width  := NumGet(Rect, 8, "int")
		, height := NumGet(Rect, 12, "int")

	; struct BITMAPINFOHEADER - https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapinfoheader
	hdc := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
	VarSetCapacity(bi, 40, 0)                ; sizeof(bi) = 40
		, NumPut(       40, bi,  0,   "uint") ; Size
		, NumPut(    width, bi,  4,   "uint") ; Width
		, NumPut(  -height, bi,  8,    "int") ; Height - Negative so (0, 0) is top-left.
		, NumPut(        1, bi, 12, "ushort") ; Planes
		, NumPut(       32, bi, 14, "ushort") ; BitCount / BitsPerPixel
		, NumPut(        0, bi, 16,   "uint") ; Compression = BI_RGB
		, NumPut(        3, bi, 20,   "uint") ; Quality setting (3 = low quality, no anti-aliasing)
	hbm := DllCall("CreateDIBSection", "ptr", hdc, "ptr", &bi, "uint", 0, "ptr*", pBits:=0, "ptr", 0, "uint", 0, "ptr")
	obm := DllCall("SelectObject", "ptr", hdc, "ptr", hbm, "ptr")

	; Print the window onto the hBitmap using an undocumented flag. https://stackoverflow.com/a/40042587
	DllCall("PrintWindow", "ptr", image, "ptr", hdc, "uint", 0x3) ; PW_CLIENTONLY | PW_RENDERFULLCONTENT
	; Additional info on how this is implemented: https://www.reddit.com/r/windows/comments/8ffr56/altprintscreen/

	; Convert the hBitmap to a Bitmap using a built in function as there is no transparency.
	DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "ptr", 0, "ptr*", pBitmap:=0)

	; Cleanup the hBitmap and device contexts.
	DllCall("SelectObject", "ptr", hdc, "ptr", obm)
	DllCall("DeleteObject", "ptr", hbm)
	DllCall("DeleteDC",	 "ptr", hdc)

	return pBitmap
}

~+F7::ExitApp
