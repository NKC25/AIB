#Naveen.S
#region Set logging 
$logFile = "c:\windows\temp\" + (get-date -format 'yyyyMMdd') + '_AIBApplicationinstall.log'
$script:failureList = @()

function Write-Log {
    Param(
        [string]$message,
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$severity = 'INFO',
        [switch]$WriteHost
    )
    $timestamp = Get-Date -Format 'yyyyMMdd HH:mm:ss'
    $logMessage = "$timestamp [$severity] $message"
    Write-Output $logMessage | Out-File -Encoding utf8 $logFile -Append
    if ($WriteHost) {
        switch ($severity) {
            'ERROR' { Write-Host $logMessage -ForegroundColor Red }
            'WARNING' { Write-Host $logMessage -ForegroundColor Yellow }
            default { Write-Host $logMessage }
        }
    }
}

function Invoke-Installer {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$componentName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$installerPath,
        [string[]]$argumentList = @(),
        [string]$workingDirectory = $null
    )
    
    Write-Log "Starting installation: $componentName" -severity 'INFO' -WriteHost
    Write-Host "AIB Customization: Install $componentName"
    
    # Validate installer path
    if (-not (Test-Path $installerPath)) {
        $errorMsg = "Installer not found: $installerPath"
        Write-Log $errorMsg -severity 'ERROR' -WriteHost
        $script:failureList += "$componentName - $errorMsg"
        return $false
    }
    
    try {
        $processParams = @{
            FilePath = $installerPath
            Wait = $true
            PassThru = $true
            ErrorAction = 'Stop'
        }
        
        if ($argumentList.Count -gt 0) {
            $processParams['ArgumentList'] = $argumentList
        }
        
        if ($workingDirectory) {
            $processParams['WorkingDirectory'] = $workingDirectory
        }
        
        $process = Start-Process @processParams
        $exitCode = $process.ExitCode
        
        if ($exitCode -eq 0) {
            Write-Log "$componentName installed successfully (Exit Code: $exitCode)" -severity 'INFO' -WriteHost
            return $true
        } else {
            $errorMsg = "$componentName installation completed with non-zero exit code: $exitCode"
            Write-Log $errorMsg -severity 'WARNING' -WriteHost
            $script:failureList += "$componentName - Exit Code: $exitCode"
            return $false
        }
    }
    catch {
        $errorMsg = "Error installing ${componentName}: $($_.Exception.Message)"
        Write-Log $errorMsg -severity 'ERROR' -WriteHost
        $script:failureList += "$componentName - $($_.Exception.Message)"
        return $false
    }
}
#endregion

#install AIP
Invoke-Installer -componentName "AIP" -installerPath "C:\apps\AVDapps\AIP\DistributionFiles\Windows\Microsoft AIP 2.13.49\Deploy-Application.exe"
Write-host 'AIB Customization: EndRegion AIP'
#install KDP
Invoke-Installer -componentName "KDP" -installerPath "C:\apps\AVDapps\KDPNetPhantomStarter\DistributionFiles\Windows\Mindus SARL NetPhantom Starter SSL with Java 7.7\Deploy-Application.exe"
Write-host 'AIB Customization: EndRegion KDP'
#install JRE
Invoke-Installer -componentName "JRE" -installerPath "C:\apps\AVDapps\JRE\Deploy-Application.exe"
Write-host 'AIB Customization: EndRegion JRE'
#install Netclean
Invoke-Installer -componentName "NetClean" -installerPath "C:\apps\AVDapps\Netclean\Deploy-Application.exe"
Write-host 'AIB Customization: endregion NetClean'

#install TNS_names
Invoke-Installer -componentName "TNS_names" -installerPath "C:\apps\AVDapps\TNS_names\Deploy-Application.exe"
Write-host 'AIB Customization: endregion TNS_Names'


# install javaapplet fullinstall bat file.
Invoke-Installer -componentName "JavaApplet" -installerPath "C:\apps\AVDapps\AzulSystemsJavaApplet\Deploy-Application.exe"

# install siplus file.
Invoke-Installer -componentName "SIPlus" -installerPath "C:\apps\AVDapps\SIPlusPolicyCopy\DistributionFiles\Windows\Azul Systems Java Applet - SIPlus 1.0\Deploy-Application.exe"

# install KDPNetPhantomStarter file.
Invoke-Installer -componentName "KDPNetPhantomStarter" -installerPath "C:\apps\AVDapps\KDPNetPhantomStarter\DistributionFiles\Windows\Mindus SARL NetPhantom Starter SSL with Java 7.7\Deploy-Application.exe"


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

#install VCC_Fonts
Invoke-Installer -componentName "VCC_Fonts" -installerPath "C:\apps\AVDapps\VCC_Fonts\Deploy-Application.exe"
Write-host 'AIB Customization: endregion vccfonts'

#install VCC_Templates
Write-host 'AIB Customization: Install templates'
$templateInstalled = Invoke-Installer -componentName "VCC_Templates" -installerPath "C:\apps\AVDapps\VCC_Templates\Deploy-Application.exe"
if ($templateInstalled) {
    try {
        $regPath = "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Office\16.0\Common\General"
        # Ensure the parent path exists
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name 'sharedtemplates' -Value "C:\ProgramData\Microsoft\Windows\Corporate Templates" -ErrorAction Stop
        Write-Log "VCC_Templates added to registry successfully" -severity 'INFO' -WriteHost
    }
    catch {
        $errorMsg = "Error configuring VCC_Templates registry: $($_.Exception.Message)"
        Write-Log $errorMsg -severity 'ERROR' -WriteHost
        $script:failureList += "VCC_Templates Registry - $($_.Exception.Message)"
    }
}
Write-host 'AIB Customization: endregion templates'

#install #StartMenu
Write-host 'AIB Customization: Configure Start Menu'
$startMenuPath = "C:\apps\AVDapps\StartMenu\VCC-StartM.bin"
if (Test-Path $startMenuPath) {
    try {
        Import-StartLayout -LayoutPath $startMenuPath -MountPath $env:SystemDrive\ -ErrorAction Stop
        Write-Log "Start menu layout imported successfully" -severity 'INFO' -WriteHost
    }
    catch {
        $errorMsg = "Error setting up start menu: $($_.Exception.Message)"
        Write-Log $errorMsg -severity 'ERROR' -WriteHost
        $script:failureList += "Start Menu Layout - $($_.Exception.Message)"
    }
} else {
    $errorMsg = "Start menu layout file not found: $startMenuPath"
    Write-Log $errorMsg -severity 'WARNING' -WriteHost
    $script:failureList += "Start Menu Layout - File not found"
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
#Onboard Windows Defender ATP.
Write-host 'AIB Customization: Configure Defender ATP'
$defenderDir = 'C:\WINDOWS\System32\GroupPolicy\Machine\Scripts\Startup'
try {
    # Ensure destination directory exists
    if (-not (Test-Path $defenderDir)) {
        New-Item -Path $defenderDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Write-Log "Created Defender ATP directory: $defenderDir" -severity 'INFO' -WriteHost
    }
    
    # Copy Onboard-NonPersistentMachine.ps1
    $sourceFile1 = "c:\apps\AVDapps\Onboard ATP\Onboard-NonPersistentMachine.ps1"
    if (Test-Path $sourceFile1) {
        Copy-Item -Path $sourceFile1 -Destination $defenderDir -Force -ErrorAction Stop
        Write-Log "Copying Onboard-NonPersistentMachine.ps1: success" -severity 'INFO' -WriteHost
    } else {
        $errorMsg = "Source file not found: $sourceFile1"
        Write-Log $errorMsg -severity 'WARNING' -WriteHost
        $script:failureList += "Defender ATP Onboard-NonPersistentMachine - File not found"
    }
    
    # Copy WindowsDefenderATPOnboardingScript.cmd
    $sourceFile2 = "c:\apps\AVDapps\Onboard ATP\WindowsDefenderATPOnboardingScript.cmd"
    if (Test-Path $sourceFile2) {
        Copy-Item -Path $sourceFile2 -Destination $defenderDir -Force -ErrorAction Stop
        Write-Log "Copying WindowsDefenderATPOnboardingScript.cmd: success" -severity 'INFO' -WriteHost
    } else {
        $errorMsg = "Source file not found: $sourceFile2"
        Write-Log $errorMsg -severity 'WARNING' -WriteHost
        $script:failureList += "Defender ATP OnboardingScript - File not found"
    }
}
catch {
    $errorMsg = "Error configuring Defender ATP: $($_.Exception.Message)"
    Write-Log $errorMsg -severity 'ERROR' -WriteHost
    $script:failureList += "Defender ATP - $($_.Exception.Message)"
}
#endregion of defender ATP.
Write-host 'AIB Customization: endregion defender ATP'

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
 Write-host 'AIB Customization: endregion optimized teams'

#install VCC wallpaper
Write-host 'AIB Customization: Configure Wallpaper'
$wallpaperInstalled = Invoke-Installer -componentName "VCC_Wallpaper" -installerPath "C:\apps\AVDapps\VCC_Wallpaper\Deploy-Application.exe"
if ($wallpaperInstalled) {
    try {
        # Wait for wallpaper files to be fully deployed before configuring registry
        Start-Sleep -Seconds 5
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force -ErrorAction Stop | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name LockScreenImage -Value "C:\windows\Themes\VCCWallpaper\Default.jpg" -ErrorAction Stop
        Write-Log "VCC Wallpaper & lockscreen configured successfully" -severity 'INFO' -WriteHost
    }
    catch {
        $errorMsg = "Error configuring wallpaper registry: $($_.Exception.Message)"
        Write-Log $errorMsg -severity 'ERROR' -WriteHost
        $script:failureList += "VCC Wallpaper Registry - $($_.Exception.Message)"
    }
}
#endregion

#install Chrome
Invoke-Installer -componentName "Chrome" -installerPath "C:\apps\AVDapps\Google Chrome 90.0.4430.212\Deploy-Application.exe"
Write-host 'AIB Customization: endregion chrome'

#install AVDBG
Invoke-Installer -componentName "AVDBG" -installerPath "C:\apps\AVDapps\AVDBG\Deploy-Application.exe"
Write-host 'AIB Customization: EndRegion AVDBG'

#install Notepad++
Invoke-Installer -componentName "Notepad++" -installerPath "C:\apps\AVDapps\Notepad++\DistributionFiles\Windows\Open Software Notepad++ 8.4\Deploy-Application.exe"
Write-host 'AIB Customization: EndRegion Notepad++'

#install Putty
Invoke-Installer -componentName "Putty" -installerPath "msiexec.exe" -argumentList @('/i', 'C:\apps\AVDapps\Putty\OriginalFiles\putty-64bit-0.74-installer.msi', '/qn', '/l*v', 'C:\Windows\Temp\Putty-INSTALL.log')
Write-host 'AIB Customization: EndRegion Putty' 

#install fslogix
write-host 'AIB customization: install fslogix'
try {
    $fslogixZip = "C:\apps\AVDapps\fslogix.zip"
    $fslogixExtract = "C:\apps\AVDapps\fslogix\"
    $fslogixInstaller = "C:\apps\AVDapps\fslogix\x64\Release\FSLogixAppsSetup.exe"
    
    # Download FSLogix
    Invoke-WebRequest -Uri 'https://aka.ms/fslogix_download' -OutFile $fslogixZip -ErrorAction Stop
    Write-Log "FSLogix downloaded successfully" -severity 'INFO' -WriteHost
    # Wait for file system to settle after download
    Start-Sleep -Seconds 20
    
    # Extract FSLogix
    Expand-Archive -Path $fslogixZip -DestinationPath $fslogixExtract -Force -ErrorAction Stop
    Write-Log "FSLogix extracted successfully" -severity 'INFO' -WriteHost
    
    # Install FSLogix using Invoke-Installer
    Invoke-Installer -componentName "FSLogix" -installerPath $fslogixInstaller -argumentList @('/install', '/quiet', '/norestart')
}
catch {
    $errorMsg = "Error installing FSLogix: $($_.Exception.Message)"
    Write-Log $errorMsg -severity 'ERROR' -WriteHost
    $script:failureList += "FSLogix - $($_.Exception.Message)"
}
write-host 'AIB customization: end region fslogix'
#endregion fslogix


#removal of inbuilt applications.
Write-Host "AIB Customization: Starting removal of inbuilt applications"
Write-Log "Starting removal of inbuilt applications" -severity 'INFO' -WriteHost

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
    Write-Host "Processing removal: $app"
    Write-Log "Starting removal of app: $app" -severity 'INFO'
    
    # Remove AppxPackage
    try {
        $packages = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
        if ($packages) {
            $packages | Remove-AppxPackage -ErrorAction Stop
            Write-Log "Removed AppxPackage: $app" -severity 'INFO'
        } else {
            Write-Log "No AppxPackage found for: $app" -severity 'INFO'
        }
    }
    catch {
        $errorMsg = "Error removing AppxPackage ${app}: $($_.Exception.Message)"
        Write-Log $errorMsg -severity 'WARNING'
        $script:failureList += "AppxPackage $app - $($_.Exception.Message)"
    }
    
    # Remove AppxProvisionedPackage
    try {
        $provisionedPkg = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -EQ $app
        if ($provisionedPkg) {
            $provisionedPkg | Remove-AppxProvisionedPackage -Online -ErrorAction Stop
            Write-Log "Removed AppxProvisionedPackage: $app" -severity 'INFO'
        } else {
            Write-Log "No AppxProvisionedPackage found for: $app" -severity 'INFO'
        }
    }
    catch {
        $errorMsg = "Error removing AppxProvisionedPackage ${app}: $($_.Exception.Message)"
        Write-Log $errorMsg -severity 'WARNING'
        $script:failureList += "AppxProvisionedPackage $app - $($_.Exception.Message)"
    }
    
    # Remove local app data packages - safer approach with enumeration
    try {
        $appPackagePath = "$Env:LOCALAPPDATA\Packages"
        if (Test-Path $appPackagePath) {
            $matchingDirs = Get-ChildItem -Path $appPackagePath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "$app*" }
            foreach ($dir in $matchingDirs) {
                try {
                    Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction Stop
                    Write-Log "Removed local package directory: $($dir.Name)" -severity 'INFO'
                }
                catch {
                    Write-Log "Error removing directory $($dir.Name): $($_.Exception.Message)" -severity 'WARNING'
                }
            }
        }
    }
    catch {
        Write-Log "Error processing local package directories for ${app}: $($_.Exception.Message)" -severity 'WARNING'
    }
    
    Write-Log "Completed processing: $app" -severity 'INFO'
}

Write-Host "AIB: Completed removal of inbuilt applications"
Write-Log "Completed removal of inbuilt applications" -severity 'INFO' -WriteHost
#endregion of inbuilt applications.

#region Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "AIB APPLICATION INSTALL SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($script:failureList.Count -eq 0) {
    $summaryMsg = "All installations and configurations completed successfully. No failures detected."
    Write-Host $summaryMsg -ForegroundColor Green
    Write-Log $summaryMsg -severity 'INFO'
} else {
    $summaryMsg = "Installation completed with $($script:failureList.Count) failure(s). See details below:"
    Write-Host $summaryMsg -ForegroundColor Yellow
    Write-Log $summaryMsg -severity 'WARNING'
    
    Write-Host "`nFailure Details:" -ForegroundColor Yellow
    Write-Log "`n=== Failure Details ===" -severity 'WARNING'
    
    foreach ($failure in $script:failureList) {
        Write-Host "  - $failure" -ForegroundColor Red
        Write-Log "  FAILURE: $failure" -severity 'ERROR'
    }
}

Write-Host "`nLog file location: $logFile" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
Write-Log "=== AIB Application Install Script Completed ===" -severity 'INFO'
#endregion Summary
