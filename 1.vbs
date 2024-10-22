Dim objFSO, objFile, objShell, strCommand, strTempPath
Dim scriptPath
scriptPath = WScript.Arguments(0)

' Initialize FileSystemObject and Shell
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")

' Read the commands from the PowerShell script file
If objFSO.FileExists(scriptPath) Then
    Set objFile = objFSO.OpenTextFile(scriptPath, 1)
    strTempPath = objShell.ExpandEnvironmentStrings("$env:TEMP\logs.txt")

    ' Loop through each line in the PowerShell script and execute it
    Do Until objFile.AtEndOfStream
        strCommand = Trim(objFile.ReadLine)
        If Len(strCommand) > 0 Then
            ' Execute the command and pipe output to the temp file
            objShell.Run "powershell.exe -Command """ & strCommand & """ >> """ & strTempPath & """", 0, True
        End If
    Loop

    objFile.Close
Else
    WScript.Echo "Error: PowerShell script file not found."
    WScript.Quit(1)
End If

' Clean up
Set objFile = Nothing
Set objFSO = Nothing
Set objShell = Nothing