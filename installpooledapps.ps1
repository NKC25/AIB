#Naveen.S
#region Set logging and helpers
$logFile = "c:\windows\temp\" + (Get-Date -Format 'yyyyMMdd') + '_AIBApplicationinstall.log'
function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet('INFO','ERROR','WARN')][string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyyMMdd HH:mm:ss'
    "[$timestamp][$Level] $Message" | Out-File -Encoding utf8 $logFile -Append
}

# Generic wrapper to run a step with logging
function Invoke-Step {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][scriptblock]$Action
    )
    Write-Host "AIB Customization: $Name"
    Write-Log "Starting: $Name"
    try {
        & $Action
        Write-Log "Completed: $Name"
        Write-Host "$Name completed successfully"
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Log "Error in '$Name': $ErrorMessage" -Level ERROR
        Write-Host "Error in '$Name': $ErrorMessage"
    }
}

# Install an application via Deploy-Application.exe or any executable path
function Install-App {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Path,
        [string[]]$Arguments
    )
    Invoke-Step -Name "Install $Name" -Action {
        if (-not (Test-Path -LiteralPath $Path)) { throw "File not found: $Path" }
        if ($Arguments -and $Arguments.Count -gt 0) {
            Start-Process -FilePath $Path -ArgumentList $Arguments -Wait -ErrorAction Stop
        } else {
            Start-Process -FilePath $Path -Wait -ErrorAction Stop
        }
        Write-Log "$Name installed successfully"
    }
}

# Install an MSI via msiexec
function Install-MSI {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$MsiPath,
        [string[]]$Transforms,
        [string]$LogPath
    )
    Invoke-Step -Name "Install $Name (MSI)" -Action {
        if (-not (Test-Path -LiteralPath $MsiPath)) { throw "MSI not found: $MsiPath" }
        $argList = @('/i', $MsiPath)
        if ($Transforms -and $Transforms.Count -gt 0) { $argList += @('TRANSFORMS=' + ($Transforms -join ';')) }
        $argList += '/qn'
        if ($LogPath) { $argList += @('/l*v', $LogPath) }
        Start-Process -FilePath msiexec.exe -ArgumentList $argList -Wait -ErrorAction Stop
        Write-Log "$Name (MSI) installed successfully"
    }
}
#endregion

Install-App -Name 'AIP' -Path "C:\apps\AVDapps\AIP\DistributionFiles\Windows\Microsoft AIP 2.13.49\Deploy-Application.exe"
Write-Host 'AIB Customization: EndRegion AIP'
Install-App -Name 'JRE' -Path "C:\apps\AVDapps\JRE\Deploy-Application.exe"
Write-Host 'AIB Customization: EndRegion JRE'
Install-App -Name 'NetClean' -Path "C:\apps\AVDapps\Netclean\Deploy-Application.exe"
Write-Host 'AIB Customization: endregion NetClean'

Install-App -Name 'TNS_names' -Path "C:\apps\AVDapps\TNS_names\Deploy-Application.exe"
Write-Host 'AIB Customization: endregion TNS_Names'


Install-App -Name 'Javaapplet fullinstall' -Path "C:\apps\AVDapps\AzulSystemsJavaApplet\Deploy-Application.exe"
Install-App -Name 'siplus fullinstall' -Path "C:\apps\AVDapps\SIPlusPolicyCopy\DistributionFiles\Windows\Azul Systems Java Applet - SIPlus 1.0\Deploy-Application.exe"

Install-App -Name 'KDPNetPhantomStarter' -Path "C:\apps\AVDapps\KDPNetPhantomStarter\DistributionFiles\Windows\Mindus SARL NetPhantom Starter SSL with Java 7.7\Deploy-Application.exe"


# #install Cisco Secure Client 5.0.01242
# Write-host 'AIB Customization: Install Cisco Secure Client 5.0.01242'
# try {
#     Start-Process -filepath "C:\apps\AVDapps\Cisco Secure Client 5.0.01242\Deploy-Application.exe" -Wait -ErrorAction Stop 
#     write-log "Cisco Secure Client 5.0.01242 installed successfully"
#     write-host "Cisco Secure Client 5.0.01242 installed successfully"
#     }
# catch {
#     $ErrorMessage = $_.Exception.message
#     write-log "Error installing Cisco Secure Client 5.0.01242: $ErrorMessage"
#     write-host "Error installing Cisco Secure Client 5.0.01242: $ErrorMessage"
# }
# #endregion
# Write-host 'AIB Customization: endregion Cisco Secure Client 5.0.01242'

Install-App -Name 'VCC_Fonts' -Path "C:\apps\AVDapps\VCC_Fonts\Deploy-Application.exe"
Write-Host 'AIB Customization: endregion vccfonts'

Install-App -Name 'SAP' -Path "C:\apps\AVDapps\SAP_1\Deploy-Application.exe"
write-host 'AIB Customization: endregion SAP'

Install-App -Name 'LotusNotes' -Path "C:\apps\AVD_SD_Apps\LotusNotes\DistributionFiles\Windows\HCL Lotus Notes 11.0.1\Deploy-Application.exe"
Write-Host 'AIB Customization: endregion LotusNotes'




Invoke-Step -Name 'Install templates' -Action {
    Install-App -Name 'VCC_Templates' -Path "C:\apps\AVDapps\VCC_Templates\Deploy-Application.exe"
    New-Item -Path "HKEY_USERS\.DEFAULT\Software\Microsoft\Office\16.0\Common\General\" -Name 'sharedtemplates' -Force | Out-Null
    Set-ItemProperty "HKEY_USERS\.DEFAULT\Software\Microsoft\Office\16.0\Common\General\" -Name sharedtemplates -Value "C:\ProgramData\Microsoft\Windows\Corporate Templates"
    Write-Log "VCC_Templates added to registry successfully"
}
Write-Host 'AIB Customization: endregion templates'

Invoke-Step -Name 'Configure StartMenu layout' -Action {
    Import-StartLayout -LayoutPath "C:\apps\AVDapps\StartMenu\VCC-StartM.bin" -MountPath $env:SystemDrive\
    Write-Log "Start menu layout successfully"
}
#end region.



# #install Java
# Write-host 'AIB Customization: Install Java'
# try {
    
#     Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', "C:\apps\AVDapps\Java_8\source\jre1.8.0_72.msi", TRANSFORMS="C:\apps\AVDapps\Java_8\source\Java_8_Update_72_x86_8.0.720.15_W10.mst" , '/qn','/l*v',  "C:\Windows\Temp\Java-INSTALL.log"
#     Write-Log "successfully installed Java"
#     Write-host "successfully installed Java"

#     }
# catch {
#     $ErrorMessage = $_.Exception.message
#     write-log "Error installed Java: $ErrorMessage"
#     Write-Log "Error installed Java: $ErrorMessage"
# }

# #endregion Java
# Write-host 'AIB Customization: endregion Java'

#install Azul Zulu JDK
# Write-host 'AIB Customization: Install Azul Zulu Java'
# try {
#     Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', "C:\apps\AVDapps\Azul_Zulu\zulu25.30.17-ca-jdk25.0.1-win_x64.msi", '/qn','/l*v',  "C:\Windows\Temp\Azul_Zulu-Java-INSTALL.log"
#     Write-Log "successfully installed Azul Zulu Java"
#     Write-host "successfully installed Azul Zulu Java"

#     }
# catch {
#     $ErrorMessage = $_.Exception.message
#     write-log "Error installed Azul Zulu Java: $ErrorMessage"
#     Write-Log "Error installed Azul Zulu Java: $ErrorMessage"
# }
# #endregion Azul Zulu Java
# Write-host 'AIB Customization: endregion Azul Zulu Java'
Invoke-Step -Name 'Configure Defender ATP' -Action {
    $dir = 'C:\WINDOWS\System32\GroupPolicy\Machine\Scripts\Startup'
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
    Copy-Item -Path "c:\apps\AVDapps\Onboard ATP\Onboard-NonPersistentMachine.ps1" -Destination $dir -Force
    Write-Log "Copying Onboard-NonPersistentMachine : success"
    Copy-Item -Path "c:\apps\AVDapps\Onboard ATP\WindowsDefenderATPOnboardingScript.cmd" -Destination $dir -Force
    Write-Log "Copying atponboardingscript.cmd"
}
Write-Host 'AIB Customization: endregion defender ATP'

# install optimized teams.
# Write-host 'AIB Customization: install optimized teams'

# try {
#   Start-Process -filepath "C:\apps\AVDapps\AVDTeams\DistributionFiles\Windows\Microsoft New Teams for VDI 2.0\Deploy-Application.exe" -Wait -ErrorAction Stop 
#   write-log "AVD Teams installed successfully."
#   write-host "AVD Teams installed successfully."
#     }
# catch {
#   $ErrorMessage = $_.Exception.message
#    write-log "Error installing AVD Teams: $ErrorMessage"
#    write-host "Error installing AVD Teams: $ErrorMessage"
# }
 #endregion of teams.
 Write-Host 'AIB Customization: endregion optimized teams'

Invoke-Step -Name 'Configure Wallpaper' -Action {
    Install-App -Name 'VCC_Wallpaper' -Path "C:\apps\AVDapps\VCC_Wallpaper\Deploy-Application.exe"
    Start-Sleep -Seconds 5
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force | Out-Null
    Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name LockScreenImage -Value "C:\windows\Themes\VCCWallpaper\Default.jpg"
    Write-Log "VCC Wallpaper & lockscreen configured successfully."
}
#endregion

Install-App -Name 'Chrome' -Path "C:\apps\AVDapps\Google Chrome 90.0.4430.212\Deploy-Application.exe"
Write-Host 'AIB Customization: endregion chrome'

Install-App -Name 'AVDBG' -Path "C:\apps\AVDapps\AVDBG\Deploy-Application.exe"
Write-Host 'AIB Customization: EndRegion AVDBG'
#endregion AVDBG 

Install-App -Name 'Notepad++' -Path "C:\apps\AVDapps\Notepad++\DistributionFiles\Windows\Open Software Notepad++ 8.4\Deploy-Application.exe"
Write-Host 'AIB Customization: EndRegion Notepadd'
#endregion Notepadd 

Install-MSI -Name 'Putty' -MsiPath "C:\apps\AVDapps\Putty\OriginalFiles\putty-64bit-0.74-installer.msi" -LogPath "C:\Windows\Temp\Putty-INSTALL.log"
Write-Host 'AIB Customization: EndRegion Putty'
#endregion Putty 


Invoke-Step -Name 'Install FSLogix' -Action {
    $zipPath = "C:\apps\AVDapps\fslogix.zip"
    $extractPath = "C:\apps\AVDapps\fslogix\"
    Invoke-WebRequest -Uri 'https://aka.ms/fslogix_download' -OutFile $zipPath
    Start-Sleep -Seconds 20
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    $setupExe = Join-Path $extractPath 'x64\Release\FSLogixAppsSetup.exe'
    if (-not (Test-Path -LiteralPath $setupExe)) { throw "FSLogixAppsSetup.exe not found at $setupExe" }
    Start-Process -FilePath $setupExe -ArgumentList '/install','/quiet','/norestart' -Wait -ErrorAction Stop
}
Write-Host  'AIB customization: end region fslogix'
#endregion fslogix


#removal of inbuilt applications.
$apps = @(
    "Microsoft.Microsoft3DViewer" #Microsoft 3D Viewer
    "Microsoft.549981C3F5F10" #Microsoft Cortana
    "Microsoft.WindowsFeedbackHub" #Microsoft Feedback Hub
    "Microsoft.GetHelp" #Microsoft Get Help
    "Microsoft.ZuneMusic" #Zune or Groove Music
    "Microsoft.WindowsMaps" #Maps
    "Microsoft.MicrosoftSolitaireCollection" #Microsoft Solitaire Collection
    "Microsoft.ZuneVideo" #Zune Video, Groove Video or Movies & TV
    "Microsoft.MicrosoftOfficeHub" #Office 2016 Hub
    "Microsoft.SkypeApp" #Skype
    "Microsoft.Getstarted" #Get Started Hub or Tips
    "Microsoft.XboxApp" #Xbox
    "Microsoft.XboxGamingOverlay" #Xbox Game Bar
    "Microsoft.YourPhone" #Your Phone
    "Microsoft.MixedReality.Portal" #Mixed Reality
    "Microsoft.windowscommunicationsapps" #Mail
)
foreach ($app in $apps) {
    Write-Host "$app Ready to remove"
    try {
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppXProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        $appPath = "$Env:LOCALAPPDATA\Packages\$app*"
        Remove-Item $appPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Removed built-in app: $app"
    }
    catch {
        Write-Log "Error removing built-in app: $app - $($_.Exception.Message)" -Level ERROR
    }
}
Write-Host  "AIB: removal of applications"
#endregion of inbuilt applications.



