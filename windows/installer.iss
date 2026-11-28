#ifndef MyAppVersion
  #define MyAppVersion "2.0.5"
#endif

[Setup]
AppId={{8D6B2A1E-9C4F-4E3A-B7D1-2F6A8E4C1B90}
AppName=GoldVault
AppVersion={#MyAppVersion}
AppPublisher=GoldVault
AppPublisherURL=https://goldvault-app.vercel.app
DefaultDirName={autopf}\GoldVault
DefaultGroupName=GoldVault
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist-windows
OutputBaseFilename=GoldVault-Setup
SetupIconFile=runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\GoldVault"; Filename: "{app}\goldvault.exe"
Name: "{autodesktop}\GoldVault"; Filename: "{app}\goldvault.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\goldvault.exe"; Description: "{cm:LaunchProgram,GoldVault}"; Flags: nowait postinstall skipifsilent
