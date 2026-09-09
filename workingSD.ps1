#Naveen.S
#region Set logging
$logFile = "c:\windows\temp\" + (Get-Date -Format 'yyyyMMdd') + '_AIBApplicationinstall.log'
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
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$componentName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$installerPath,
        [string[]]$argumentList = @(),
        [string]$workingDirectory = $null,
        [int[]]$successExitCodes = @(0)
    )

    Write-Log "Starting installation: $componentName" -severity 'INFO' -WriteHost
    Write-Host "AIB Customization: Install $componentName"

    if (($installerPath -ne 'msiexec.exe') -and -not (Test-Path $installerPath)) {
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

        if ($successExitCodes -contains $exitCode) {
            if ($exitCode -eq 0) {
                Write-Log "$componentName installed successfully (Exit Code: $exitCode)" -severity 'INFO' -WriteHost
            } else {
                Write-Log "$componentName completed with accepted non-zero exit code: $exitCode" -severity 'WARNING' -WriteHost
            }
            return $true
        }

        $errorMsg = "$componentName installation completed with non-zero exit code: $exitCode"
        Write-Log $errorMsg -severity 'WARNING' -WriteHost
        $script:failureList += "$componentName - Exit Code: $exitCode"
        return $false
    }
    catch {
        $errorMsg = "Error installing ${componentName}: $($_.Exception.Message)"
        Write-Log $errorMsg -severity 'ERROR' -WriteHost
        $script:failureList += "$componentName - $($_.Exception.Message)"
        return $false
    }
}

function Invoke-AvdMultiSessionOptimization {
    Param(
        [string]$optimizationRoot = 'C:\apps\Optimize'
    )

    Write-Log 'Starting AVD multi-session optimization' -severity 'INFO' -WriteHost
    Write-Host 'AIB Customization: Optimize AVD multi-session'

    $zipPath = Join-Path $optimizationRoot 'Virtual-Desktop-Optimization-Tool-main.zip'
    $extractPath = Join-Path $optimizationRoot 'Virtual-Desktop-Optimization-Tool-main'
    $vDotScriptPath = Join-Path $extractPath 'Windows_VDOT.ps1'
    $downloadUrl = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/master.zip'

    try {
        if (-not (Test-Path $optimizationRoot)) {
            New-Item -Path $optimizationRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Log "Created optimization directory: $optimizationRoot" -severity 'INFO'
        }

        if (-not (Test-Path $zipPath)) {
            Write-Log "Downloading VDOT package from $downloadUrl" -severity 'INFO' -WriteHost
            Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        } else {
            Write-Log "Reusing existing VDOT archive: $zipPath" -severity 'INFO'
        }

        Expand-Archive -LiteralPath $zipPath -DestinationPath $optimizationRoot -Force -ErrorAction Stop

        if (-not (Test-Path $vDotScriptPath)) {
            throw "VDOT script not found after extraction: $vDotScriptPath"
        }

        $vDotContent = Get-Content -Path $vDotScriptPath -Raw -ErrorAction Stop
        $patchedContent = $vDotContent -replace 'Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB', '#Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB'

        if ($patchedContent -ne $vDotContent) {
            Set-Content -Path $vDotScriptPath -Value $patchedContent -Encoding utf8 -ErrorAction Stop
            Write-Log 'Patched VDOT to skip the known risky NIC buffer change.' -severity 'INFO'
        }

        $process = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $vDotScriptPath,
            '-AcceptEula'
        ) -WorkingDirectory $extractPath -Wait -PassThru -ErrorAction Stop

        if ($process.ExitCode -eq 0) {
            Write-Log 'AVD multi-session optimization completed successfully.' -severity 'INFO' -WriteHost
            return $true
        }

        $errorMsg = "AVD multi-session optimization completed with non-zero exit code: $($process.ExitCode)"
        Write-Log $errorMsg -severity 'WARNING' -WriteHost
        $script:failureList += "AVD Optimization - Exit Code: $($process.ExitCode)"
        return $false
    }
    catch {
        $errorMsg = "Error during AVD multi-session optimization: $($_.Exception.Message)"
        Write-Log $errorMsg -severity 'ERROR' -WriteHost
        $script:failureList += "AVD Optimization - $($_.Exception.Message)"
        return $false
    }
}
#endregion

#install JRE
Invoke-Installer -componentName 'JRE' -installerPath 'C:\apps\AVD_SD_Apps\JRE\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion JRE'

#install AIP
Invoke-Installer -componentName 'AIP' -installerPath 'C:\apps\AVD_SD_Apps\AIP\DistributionFiles\Windows\Microsoft AIP 2.13.49\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion AIP'

#install Netclean
Invoke-Installer -componentName 'NetClean' -installerPath 'C:\apps\AVD_SD_Apps\Netclean\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion NetClean'

#install TNS_names
Invoke-Installer -componentName 'TNS_names' -installerPath 'C:\apps\AVD_SD_Apps\TNS_names\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion TNS_Names'

#install Lotus Notes
Invoke-Installer -componentName 'LotusNotes' -installerPath 'C:\apps\AVD_SD_Apps\LotusNotes\DistributionFiles\Windows\HCL Lotus Notes 11.0.1\Deploy-Application.exe' -successExitCodes @(0, -1)
Write-Host 'AIB Customization: EndRegion LotusNotes'

# #install Cisco Secure Client 5.0.01242
# Write-Host 'AIB Customization: Install Cisco Secure Client 5.0.01242'
# try {
#     Start-Process -FilePath 'C:\apps\AVD_SD_Apps\Cisco Secure Client 5.0.01242\Deploy-Application.exe' -Wait -ErrorAction Stop
#     Write-Log 'Cisco Secure Client 5.0.01242 installed successfully' -severity 'INFO' -WriteHost
# }
# catch {
#     $errorMsg = "Error installing Cisco Secure Client 5.0.01242: $($_.Exception.Message)"
#     Write-Log $errorMsg -severity 'ERROR' -WriteHost
# }
# Write-Host 'AIB Customization: EndRegion Cisco Secure Client 5.0.01242'

#install VCC_Fonts
Invoke-Installer -componentName 'VCC_Fonts' -installerPath 'C:\apps\AVD_SD_Apps\VCC_Fonts\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion VCC_Fonts'

#install VCC_Templates
Write-Host 'AIB Customization: Install templates'
$templateInstalled = Invoke-Installer -componentName 'VCC_Templates' -installerPath 'C:\apps\AVD_SD_Apps\VCC_Templates\Deploy-Application.exe'
if ($templateInstalled) {
    try {
        $regPath = 'Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Office\16.0\Common\General'
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name 'sharedtemplates' -Value 'C:\ProgramData\Microsoft\Windows\Corporate Templates' -ErrorAction Stop
        Write-Log 'VCC_Templates added to registry successfully' -severity 'INFO' -WriteHost
    }
    catch {
        $errorMsg = "Error configuring VCC_Templates registry: $($_.Exception.Message)"
        Write-Log $errorMsg -severity 'ERROR' -WriteHost
        $script:failureList += "VCC_Templates Registry - $($_.Exception.Message)"
    }
}
Write-Host 'AIB Customization: EndRegion templates'

#install StartMenu
Write-Host 'AIB Customization: Configure Start Menu'
$startMenuPath = 'C:\apps\AVD_SD_Apps\StartMenu\VCC-StartM.bin'
if (Test-Path $startMenuPath) {
    try {
        Import-StartLayout -LayoutPath $startMenuPath -MountPath ($env:SystemDrive + '\') -ErrorAction Stop
        Write-Log 'Start menu layout imported successfully' -severity 'INFO' -WriteHost
    }
    catch {
        $errorMsg = "Error setting up start menu: $($_.Exception.Message)"
        Write-Log $errorMsg -severity 'ERROR' -WriteHost
        $script:failureList += "Start Menu Layout - $($_.Exception.Message)"
    }
} else {
    $errorMsg = "Start menu layout file not found: $startMenuPath"
    Write-Log $errorMsg -severity 'WARNING' -WriteHost
    $script:failureList += 'Start Menu Layout - File not found'
}
Write-Host 'AIB Customization: EndRegion Start Menu'

# #install Azul Zulu JDK
# Write-Host 'AIB Customization: Install Azul Zulu Java'
# try {
#     Start-Process -FilePath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', 'C:\apps\AVD_SD_Apps\Azul_Zulu\zulu25.30.17-ca-jdk25.0.1-win_x64.msi', '/qn', '/l*v', 'C:\Windows\Temp\Azul_Zulu-Java-INSTALL.log'
#     Write-Log 'Azul Zulu Java installed successfully' -severity 'INFO' -WriteHost
# }
# catch {
#     $errorMsg = "Error installing Azul Zulu Java: $($_.Exception.Message)"
#     Write-Log $errorMsg -severity 'ERROR' -WriteHost
# }
# Write-Host 'AIB Customization: EndRegion Azul Zulu Java'

#install AzulSystemsJavaApplet
Invoke-Installer -componentName 'AzulSystemsJavaApplet' -installerPath 'C:\apps\AVD_SD_Apps\AzulSystemsJavaApplet\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion AzulSystemsJavaApplet'

#install SIPlusPolicyCopy
Invoke-Installer -componentName 'SIPlusPolicyCopy' -installerPath 'C:\apps\AVD_SD_Apps\SIPlusPolicyCopy\DistributionFiles\Windows\Azul Systems Java Applet - SIPlus 1.0\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion SIPlusPolicyCopy'

# install Java
# Write-Host 'AIB Customization: Install Java'
# try {
#     Start-Process -FilePath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', 'C:\apps\AVD_SD_Apps\Java_8\source\jre1.8.0_72.msi', 'TRANSFORMS=C:\apps\AVD_SD_Apps\Java_8\source\Java_8_Update_72_x86_8.0.720.15_W10.mst', '/qn', '/l*v', 'C:\Windows\Temp\Java-INSTALL.log'
#     Write-Log 'Java installed successfully' -severity 'INFO' -WriteHost
# }
# catch {
#     $errorMsg = "Error installing Java: $($_.Exception.Message)"
#     Write-Log $errorMsg -severity 'ERROR' -WriteHost
# }
# Write-Host 'AIB Customization: EndRegion Java'



#Onboard Windows Defender ATP.
Write-Host 'AIB Customization: Configure Defender ATP'
$defenderDir = 'C:\WINDOWS\System32\GroupPolicy\Machine\Scripts\Startup'
try {
    if (-not (Test-Path $defenderDir)) {
        New-Item -Path $defenderDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Write-Log "Created Defender ATP directory: $defenderDir" -severity 'INFO' -WriteHost
    }

    $sourceFile1 = 'C:\apps\AVD_SD_Apps\Onboard ATP\Onboard-NonPersistentMachine.ps1'
    if (Test-Path $sourceFile1) {
        Copy-Item -Path $sourceFile1 -Destination $defenderDir -Force -ErrorAction Stop
        Write-Log 'Copying Onboard-NonPersistentMachine.ps1: success' -severity 'INFO' -WriteHost
    } else {
        $errorMsg = "Source file not found: $sourceFile1"
        Write-Log $errorMsg -severity 'WARNING' -WriteHost
        $script:failureList += 'Defender ATP Onboard-NonPersistentMachine - File not found'
    }

    $sourceFile2 = 'C:\apps\AVD_SD_Apps\Onboard ATP\WindowsDefenderATPOnboardingScript.cmd'
    if (Test-Path $sourceFile2) {
        Copy-Item -Path $sourceFile2 -Destination $defenderDir -Force -ErrorAction Stop
        Write-Log 'Copying WindowsDefenderATPOnboardingScript.cmd: success' -severity 'INFO' -WriteHost
    } else {
        $errorMsg = "Source file not found: $sourceFile2"
        Write-Log $errorMsg -severity 'WARNING' -WriteHost
        $script:failureList += 'Defender ATP OnboardingScript - File not found'
    }
}
catch {
    $errorMsg = "Error configuring Defender ATP: $($_.Exception.Message)"
    Write-Log $errorMsg -severity 'ERROR' -WriteHost
    $script:failureList += "Defender ATP - $($_.Exception.Message)"
}
Write-Host 'AIB Customization: EndRegion Defender ATP'

#install SAP
Invoke-Installer -componentName 'SAP' -installerPath 'C:\apps\AVD_SD_Apps\SAP\DistributionFiles\Windows\SAP GUI 7.6 P8\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion SAP'

#install SAP latest
Invoke-Installer -componentName 'SAP_Latest' -installerPath 'C:\apps\AVD_SD_Apps\SAP_1\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion SAP latest'

#install VCC wallpaper
Write-Host 'AIB Customization: Configure Wallpaper'
$wallpaperInstalled = Invoke-Installer -componentName 'VCC_Wallpaper' -installerPath 'C:\apps\AVD_SD_Apps\VCC_Wallpaper\Deploy-Application.exe'
if ($wallpaperInstalled) {
    try {
        Start-Sleep -Seconds 5
        New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Force -ErrorAction Stop | Out-Null
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name LockScreenImage -Value 'C:\windows\Themes\VCCWallpaper\Default.jpg' -ErrorAction Stop
        Write-Log 'VCC Wallpaper & lockscreen configured successfully.' -severity 'INFO' -WriteHost
    }
    catch {
        $errorMsg = "Error setting wallpaper: $($_.Exception.Message)"
        Write-Log $errorMsg -severity 'ERROR' -WriteHost
        $script:failureList += "Wallpaper - $($_.Exception.Message)"
    }
}
Write-Host 'AIB Customization: EndRegion Wallpaper'

#install Bomgarrep
Invoke-Installer -componentName 'Bomgarrep' -installerPath 'C:\apps\AVD_SD_Apps\bomgarrep.exe' -argumentList @('/S')
Write-Host 'AIB Customization: EndRegion Bomgarrep'

#install Printmgr
Invoke-Installer -componentName 'Printmgr' -installerPath 'C:\apps\AVD_SD_Apps\Print Manager\DistributionFiles\Windows\LRS Personal Print Manager With Pullprint 103.0.21.803\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion Printmgr'

#install Chrome
Invoke-Installer -componentName 'Chrome' -installerPath 'C:\apps\AVD_SD_Apps\Google Chrome 90.0.4430.212\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion Chrome'

#install CPP client
Invoke-Installer -componentName 'CPP client' -installerPath 'C:\apps\AVD_SD_Apps\CPP client\DistributionFiles\Windows\VCC CPP Client 4.0.0.1 M2\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion CPP client'

# #install IBM 3270 hosts
# Invoke-Installer -componentName 'IBM_3270_hosts' -installerPath 'msiexec.exe' -argumentList @('/i', 'C:\apps\AVD_SD_Apps\IBM\a2\source\Configuration\3270_hosts.msi', 'TRANSFORMS=C:\apps\AVD_SD_Apps\IBM\a3\source\Configuration\3270_hosts.mst', '/qn', '/l*v', 'c:\windows\temp\3270_hosts.log')
# Write-Host 'AIB Customization: EndRegion IBM 3270 hosts'

# #install IBM cdec
# Invoke-Installer -componentName 'IBM_cdec' -installerPath 'msiexec.exe' -argumentList @('/i', 'C:\apps\AVD_SD_Apps\IBM\a2\source\cdec\cdec.msi', 'TRANSFORMS=C:\apps\AVD_SD_Apps\IBM\a3\source\cdec\cdec.mst', '/qn', '/l*v', 'c:\windows\temp\cdec.log')
# Write-Host 'AIB Customization: EndRegion IBM cdec'

# #install IBM Personal Communications
# Invoke-Installer -componentName 'IBM_Personal_Communications' -installerPath 'msiexec.exe' -argumentList @('/i', 'C:\apps\AVD_SD_Apps\IBM\a3\source\IBM Personal Communications.msi', 'TRANSFORMS=C:\apps\AVD_SD_Apps\IBM\a3\source\IBM_Personnal_Communications_13.0.0.mst', '/qn', '/l*v', 'c:\windows\temp\ibm.log')
# Write-Host 'AIB Customization: EndRegion IBM Personal Communications'

#install AVDBG
Invoke-Installer -componentName 'AVDBG' -installerPath 'C:\apps\AVD_SD_Apps\AVDBG\Deploy-Application.exe'
Write-Host 'AIB Customization: EndRegion AVDBG'

#removebuiltinapps
Write-Host 'AIB Customization: Starting removal of inbuilt applications'
Write-Log 'Starting removal of inbuilt applications' -severity 'INFO' -WriteHost

$apps = @(
    'Microsoft.Microsoft3DViewer'
    'Microsoft.549981C3F5F10'
    'Microsoft.WindowsFeedbackHub'
    'Microsoft.GetHelp'
    'Microsoft.ZuneMusic'
    'Microsoft.WindowsMaps'
    'Microsoft.MicrosoftSolitaireCollection'
)

foreach ($app in $apps) {
    Write-Host "Processing removal: $app"
    Write-Log "Starting removal of app: $app" -severity 'INFO'

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

Write-Host 'AIB Customization: Completed removal of inbuilt applications'
Write-Log 'Completed removal of inbuilt applications' -severity 'INFO' -WriteHost

#optimize for AVD multi-session
Invoke-AvdMultiSessionOptimization | Out-Null
Write-Host 'AIB Customization: EndRegion AVD multi-session optimization'

#region Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host 'AIB APPLICATION INSTALL SUMMARY' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan

if ($script:failureList.Count -eq 0) {
    $summaryMsg = 'All installations and configurations completed successfully. No failures detected.'
    Write-Host $summaryMsg -ForegroundColor Green
    Write-Log $summaryMsg -severity 'INFO'
} else {
    $summaryMsg = "Installation completed with $($script:failureList.Count) failure(s). See details below:"
    Write-Host $summaryMsg -ForegroundColor Yellow
    Write-Log $summaryMsg -severity 'WARNING'

    Write-Host "`nFailure Details:" -ForegroundColor Yellow
    Write-Log '`n=== Failure Details ===' -severity 'WARNING'

    foreach ($failure in $script:failureList) {
        Write-Host "  - $failure" -ForegroundColor Red
        Write-Log "  FAILURE: $failure" -severity 'ERROR'
    }
}

Write-Host "`nLog file location: $logFile" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
Write-Log '=== AIB Application Install Script Completed ===' -severity 'INFO'
#endregion Summary
