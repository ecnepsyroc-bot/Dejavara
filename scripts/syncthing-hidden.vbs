' Hidden launcher for Syncthing (bypass SyncTrayzor)
' Runs syncthing directly without a visible window
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run """C:\Users\cory\AppData\Roaming\SyncTrayzor\syncthing.exe"" serve --no-browser", 0, False
