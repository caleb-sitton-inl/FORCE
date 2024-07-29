; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "FORCE"
#define MyAppVersion "0.8"
#define MyAppPublisher "Idaho National Laboratory"
#define MyAppURL "https://github.com/idaholab/FORCE"
#define MyAppExeName "MyProg.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{D0EBD58D-0C2A-4451-8E20-C3C9C1AA5BE0}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Remove the following line to run in administrative install mode (install for all users.)
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=inno_output
OutputBaseFilename=force_setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "workbenchinstall"; Description: "Install NEAMS Workbench-5.4.1"; GroupDescription: "Optional Components"

[Files]
Source: "force_install\heron.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "force_install\raven_framework.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "force_install\Workbench-5.4.1.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "force_install\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\FORCE\HERON"; Filename: "{app}\heron.exe"
Name: "{autoprograms}\FORCE\RAVEN"; Filename: "{app}\raven_framework.exe"
Name: "{autoprograms}\FORCE\TEAL"; Filename: "{app}\teal.exe"
Name: "{autoprograms}\FORCE\docs"; Filename: "{app}\docs"
Name: "{autoprograms}\FORCE\examples"; Filename: "{app}\examples"
Name: "{autodesktop}\HERON"; Filename: "{app}\heron.exe"; Tasks: desktopicon
Name: "{autodesktop}\RAVEN"; Filename: "{app}\raven_framework.exe"; Tasks: desktopicon
Name: "{autodesktop}\TEAL"; Filename: "{app}\teal.exe"; Tasks: desktopicon
; Add desktop icons for the documentation and examples directories
Name: "{autodesktop}\FORCE Documentation"; Filename: "{app}\docs"; Tasks: desktopicon
Name: "{autodesktop}\FORCE Examples"; Filename: "{app}\examples"; Tasks: desktopicon

[Registry]
; File association for .heron files
Root: HKCU; Subkey: "Software\Classes\.heron"; ValueType: string; ValueName: ""; ValueData: "FORCE.heron"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\FORCE.heron"; ValueType: string; ValueName: ""; ValueData: "HERON File"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\FORCE.heron\DefaultIcon"; ValueType: string; ValueData: "{app}\heron.exe,0"
; The open command will be set dynamically in the [Code] section

;[Run]
;Filename: "{app}\Workbench-5.4.1.exe"; Description: "Install NEAMS Workbench-5.4.1"; Flags: nowait postinstall skipifsilent

[Code]
var
  WorkbenchPath: string;

function FindWorkbenchInstallPath(): string;
var
    Paths: array of string;
    Path: string;
    I: Integer;
begin
  Result := '';
  Paths := [
    ExpandConstant('{%USERPROFILE}'),
    ExpandConstant('{userpf}'),
    ExpandConstant('{userprograms}'),
    ExpandConstant('{commonpf}'),
    ExpandConstant('{commonpf64}'),
    ExpandConstant('{commonpf32}'),
    ExpandConstant('{commonprograms}'),
    ExpandConstant('{sd}'),
    ExpandConstant('{app}')
  ];
  for I := 0 to GetArrayLength(Paths) - 1 do
    begin
        Path := Paths[I];
        // MsgBox('Checking for Workbench at path ' + Path + '\Workbench-5.4.1\bin\Workbench.exe', mbInformation, MB_OK);
        if FileExists(Path + '\Workbench-5.4.1\bin\Workbench.exe') then
        begin
          Result := Path + '\Workbench-5.4.1\';
          // MsgBox('Found workbench at path ' + Result + '!', mbInformation, MB_OK);
          break;
        end;
    end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  DefaultAppsFilePath: string;
  DefaultAppsContent: string;
  ResultCode: Integer;
begin
  // Install Workbench if the user selected the option and associate .heron files with the Workbench executable
  if (CurStep = ssPostInstall) and WizardIsTaskSelected('workbenchinstall') then
  begin
    // Run the Workbench installer
    Exec(ExpandConstant('{app}\Workbench-5.4.1.exe'), '', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
    // Find the path to the Workbench executable
    WorkbenchPath := FindWorkbenchInstallPath();

    // Associate .heron files with the Workbench executable
    RegWriteStringValue(HKEY_CURRENT_USER, 'Software\Classes\FORCE.heron\shell\open\command', '', '"' + WorkbenchPath + 'bin\Workbench.exe' + '" "%1"');

    // default.apps.son file tells Workbench where to find HERON
    DefaultAppsFilePath := WorkbenchPath + 'default.apps.son';
    DefaultAppsContent :=
      'applications {' + #13#10 +
      '  HERON {' + #13#10 +
      '    configurations {' + #13#10 +
      '      default {' + #13#10 +
      '        options {' + #13#10 +
      '          shared {' + #13#10 +
      '            "Executable"="' + ExpandConstant('{app}') + '\heron.exe"' + #13#10 +
      '          }' + #13#10 +
      '        }' + #13#10 +
      '      }' + #13#10 +
      '    }' + #13#10 +
      '  }' + #13#10 +
      '}';

    // Save the default.apps.son file in the Workbench base directory
    if not SaveStringToFile(DefaultAppsFilePath, DefaultAppsContent, False) then
    begin
      MsgBox('Failed to create default.apps.son in the Workbench directory. Attempted to write to ' + DefaultAppsFilePath, mbError, MB_OK);
    end;

    // Save the path to the Workbench executable in a file at {app}/.workbench.
    if not SaveStringToFile(ExpandConstant('{app}') + '\.workbench', 'WORKBENCHDIR=' + WorkbenchPath, False) then
    begin
      MsgBox('Failed to save the path to the Workbench executable. Attempted to write to ' + ExpandConstant('{app}') + '\.workbench', mbError, MB_OK);
    end;
  end
  else
  begin
    if CurStep = ssPostInstall then
    begin
      MsgBox('Workbench not installed. Not creating Workbench defaults. WorkbenchPath = ' + WorkbenchPath, mbInformation, MB_OK);
    end;
  end;
end;
