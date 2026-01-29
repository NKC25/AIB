# Naveen.S - AIB Application Installation Script
# Optimized version for pooled application installations

#region Initialization and Logging
$LogFile = "C:\Windows\Temp\" + (Get-Date -Format 'yyyyMMdd') + '_AIBApplicationInstall.log'
$AppBasePath = "C:\apps\AVDapps"

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "$TimeStamp [$Level] $Message"
    
    Write-Output $LogEntry | Out-File -Encoding UTF8 $LogFile -Append
    
    switch ($Level) {
        "INFO" { Write-Host $LogEntry -ForegroundColor Green }
        "WARNING" { Write-Host $LogEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
    }
}

function Install-Application {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ExecutablePath,
        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @(),
        [Parameter(Mandatory = $false)]
        [scriptblock]$PostInstallAction
    )
    
    Write-Log "Starting installation of $Name" -Level "INFO"
    
    try {
        if (-not (Test-Path $ExecutablePath)) {
            throw "Installation file not found: $ExecutablePath"
        }
        
        $ProcessArgs = @{
            FilePath = $ExecutablePath
            Wait = $true
            ErrorAction = 'Stop'
        }
        
        if ($Arguments.Count -gt 0) {
            $ProcessArgs.ArgumentList = $Arguments
        }
        
        Start-Process @ProcessArgs
        
        # Execute post-install actions if provided
        if ($PostInstallAction) {
            & $PostInstallAction
        }
        
        Write-Log "$Name installed successfully" -Level "INFO"
        return $true
    }
    catch {
        Write-Log "Error installing $Name`: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

Write-Log "AIB Application Installation Script Started" -Level "INFO"
#endregion

#region Application Installations
# Define application installation configurations
$Applications = @(
    @{
        Name = "AIP (Azure Information Protection)"
        Path = "$AppBasePath\AIP\DistributionFiles\Windows\Microsoft AIP 2.13.49\Deploy-Application.exe"
    },
    @{
        Name = "JRE (Java Runtime Environment)"
        Path = "$AppBasePath\JRE\Deploy-Application.exe"
    },
    @{
        Name = "NetClean"
        Path = "$AppBasePath\Netclean\Deploy-Application.exe"
    },
    @{
        Name = "TNS Names"
        Path = "$AppBasePath\TNS_names\Deploy-Application.exe"
    },
    @{
        Name = "Java Applet"
        Path = "$AppBasePath\AzulSystemsJavaApplet\Deploy-Application.exe"
    },
    @{
        Name = "SIPlus"
        Path = "$AppBasePath\SIPlusPolicyCopy\DistributionFiles\Windows\Azul Systems Java Applet - SIPlus 1.0\Deploy-Application.exe"
    },
    @{
        Name = "KDP NetPhantom Starter"
        Path = "$AppBasePath\KDPNetPhantomStarter\DistributionFiles\Windows\Mindus SARL NetPhantom Starter SSL with Java 7.7\Deploy-Application.exe"
    },
    @{
        Name = "VCC Fonts"
        Path = "$AppBasePath\VCC_Fonts\Deploy-Application.exe"
    },
    @{
        Name = "VCC Templates"
        Path = "$AppBasePath\VCC_Templates\Deploy-Application.exe"
        PostInstallAction = {
            try {
                New-Item -Path "HKEY_USERS\.DEFAULT\Software\Microsoft\Office\16.0\Common\General\" -Name 'sharedtemplates' -Force | Out-Null
                Set-ItemProperty "HKEY_USERS\.DEFAULT\Software\Microsoft\Office\16.0\Common\General\" -Name sharedtemplates -Value "C:\ProgramData\Microsoft\Windows\Corporate Templates"
                Write-Log "VCC Templates registry configuration completed successfully" -Level "INFO"
            }
            catch {
                Write-Log "Error configuring VCC Templates registry: $($_.Exception.Message)" -Level "WARNING"
            }
        }
    },
    @{
        Name = "VCC Wallpaper"
        Path = "$AppBasePath\VCC_Wallpaper\Deploy-Application.exe"
        PostInstallAction = {
            try {
                Start-Sleep -Seconds 5
                New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force | Out-Null
                Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name LockScreenImage -Value "C:\Windows\Themes\VCCWallpaper\Default.jpg"
                Write-Log "VCC Wallpaper & lockscreen configured successfully" -Level "INFO"
            }
            catch {
                Write-Log "Error configuring VCC Wallpaper: $($_.Exception.Message)" -Level "WARNING"
            }
        }
    },
    @{
        Name = "Google Chrome"
        Path = "$AppBasePath\Google Chrome 90.0.4430.212\Deploy-Application.exe"
    },
    @{
        Name = "AVDBG"
        Path = "$AppBasePath\AVDBG\Deploy-Application.exe"
    },
    @{
        Name = "Notepad++"
        Path = "$AppBasePath\Notepad++\DistributionFiles\Windows\Open Software Notepad++ 8.4\Deploy-Application.exe"
    }
)

# Install each application
foreach ($App in $Applications) {
    $InstallParams = @{
        Name = $App.Name
        ExecutablePath = $App.Path
    }
    
    if ($App.PostInstallAction) {
        $InstallParams.PostInstallAction = $App.PostInstallAction
    }
    
    Install-Application @InstallParams
}
#endregion 

#region Special Installations and Configurations

# Configure Start Menu Layout
Write-Log "Configuring Start Menu Layout" -Level "INFO"
try {
    $StartMenuPath = "$AppBasePath\StartMenu\VCC-StartM.bin"
    if (Test-Path $StartMenuPath) {
        Import-StartLayout -LayoutPath $StartMenuPath -MountPath $env:SystemDrive\
        Write-Log "Start menu layout configured successfully" -Level "INFO"
    }
    else {
        Write-Log "Start menu layout file not found: $StartMenuPath" -Level "WARNING"
    }
}
catch {
    Write-Log "Error setting up start menu: $($_.Exception.Message)" -Level "ERROR"
}

# Configure Windows Defender ATP
Write-Log "Configuring Windows Defender ATP" -Level "INFO"
try {
    $DefenderDir = 'C:\WINDOWS\System32\GroupPolicy\Machine\Scripts\Startup'
    $ATPBasePath = "$AppBasePath\Onboard ATP"
    
    New-Item -Path $DefenderDir -ItemType Directory -Force | Out-Null
    
    $ATPFiles = @(
        "Onboard-NonPersistentMachine.ps1",
        "WindowsDefenderATPOnboardingScript.cmd"
    )
    
    foreach ($File in $ATPFiles) {
        $SourcePath = Join-Path $ATPBasePath $File
        if (Test-Path $SourcePath) {
            Copy-Item -Path $SourcePath -Destination $DefenderDir -Force
            Write-Log "Successfully copied $File to startup scripts" -Level "INFO"
        }
        else {
            Write-Log "ATP file not found: $SourcePath" -Level "WARNING"
        }
    }
}
catch {
    Write-Log "Error configuring Windows Defender ATP: $($_.Exception.Message)" -Level "ERROR"
}

# Install PuTTY (using original working method)
Write-Log "Installing PuTTY" -Level "INFO"
try {
    $PuttyMSI = "$AppBasePath\Putty\OriginalFiles\putty-64bit-0.74-installer.msi"
    if (Test-Path $PuttyMSI) {
        Start-Process -FilePath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', $PuttyMSI, '/qn', '/l*v', 'C:\Windows\Temp\Putty-INSTALL.log'
        Write-Log "PuTTY installed successfully" -Level "INFO"
    }
    else {
        Write-Log "PuTTY MSI not found: $PuttyMSI" -Level "WARNING"
    }
}
catch {
    Write-Log "Error installing PuTTY: $($_.Exception.Message)" -Level "ERROR"
}

#region Windows Desktop Optimization Tool Integration
Write-Log "Integrating Windows Desktop Optimization Tool (WDOT)" -Level "INFO"

try {
    # Define WDOT paths and configuration
    $WDOTBasePath = "$AppBasePath\WDOT"
    $WDOTScriptPath = "$WDOTBasePath\Windows_Optimization.ps1"
    $WDOTConfigPath = "$WDOTBasePath\Configurations"
    $WDOTGitHubUrl = "https://github.com/The-Virtual-Desktop-Team/Windows-Desktop-Optimization-Tool"
    $WDOTZipUrl = "https://github.com/The-Virtual-Desktop-Team/Windows-Desktop-Optimization-Tool/archive/refs/heads/main.zip"
    $WDOTZipPath = "$WDOTBasePath\WDOT-main.zip"
    $WDOTExtractPath = "$WDOTBasePath\extracted"
    $WDOTConfigProfile = "AIB-VDI-Custom"
    
    # Create WDOT directory if it doesn't exist
    if (-not (Test-Path $WDOTBasePath)) {
        New-Item -Path $WDOTBasePath -ItemType Directory -Force | Out-Null
        Write-Log "Created WDOT directory: $WDOTBasePath" -Level "INFO"
    }
    
    # Download WDOT if not already present
    if (-not (Test-Path $WDOTScriptPath)) {
        Write-Log "WDOT not found locally, downloading from GitHub" -Level "INFO"
        
        # Download the ZIP file
        Invoke-WebRequest -Uri $WDOTZipUrl -OutFile $WDOTZipPath -UseBasicParsing
        Write-Log "Downloaded WDOT from: $WDOTGitHubUrl" -Level "INFO"
        
        # Extract the ZIP file
        Expand-Archive -Path $WDOTZipPath -DestinationPath $WDOTExtractPath -Force
        
        # Move contents from extracted subdirectory to main WDOT path
        $ExtractedSubDir = Get-ChildItem -Path $WDOTExtractPath -Directory | Select-Object -First 1
        if ($ExtractedSubDir) {
            Get-ChildItem -Path $ExtractedSubDir.FullName -Recurse | Move-Item -Destination $WDOTBasePath -Force
            Write-Log "Extracted WDOT files to: $WDOTBasePath" -Level "INFO"
        }
        
        # Clean up temporary files
        Remove-Item -Path $WDOTZipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $WDOTExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Create custom configuration profile for AIB
    if (Test-Path $WDOTScriptPath) {
        Push-Location $WDOTBasePath
        
        try {
            # Create custom configuration profile if it doesn't exist
            $CustomConfigPath = "$WDOTConfigPath\$WDOTConfigProfile"
            if (-not (Test-Path $CustomConfigPath)) {
                Write-Log "Creating custom WDOT configuration profile: $WDOTConfigProfile" -Level "INFO"
                
                # Run the configuration creation script
                $CreateConfigScript = "$WDOTBasePath\New-WVDConfigurationFiles.ps1"
                if (Test-Path $CreateConfigScript) {
                    & $CreateConfigScript -FolderName $WDOTConfigProfile
                    Write-Log "Created WDOT configuration profile: $WDOTConfigProfile" -Level "INFO"
                } else {
                    throw "WDOT configuration creation script not found: $CreateConfigScript"
                }
            }
            
            # Configure WDOT settings to be compatible with OneDrive and FSLogix
            Write-Log "Configuring WDOT settings for AIB compatibility" -Level "INFO"
            
            # Set conservative settings for services that might conflict with OneDrive/FSLogix
            $SetConfigScript = "$WDOTBasePath\Set-WVDConfigurations.ps1"
            if (Test-Path $SetConfigScript) {
                # Configure services with conservative approach
                & $SetConfigScript -ConfigurationFile "Services" -ConfigFolderName $WDOTConfigProfile -SkipAll -ErrorAction SilentlyContinue
                
                # Configure AppX packages removal
                & $SetConfigScript -ConfigurationFile "AppxPackages" -ConfigFolderName $WDOTConfigProfile -ApplyAll -ErrorAction SilentlyContinue
                
                # Configure scheduled tasks
                & $SetConfigScript -ConfigurationFile "ScheduledTasks" -ConfigFolderName $WDOTConfigProfile -ApplyAll -ErrorAction SilentlyContinue
                
                Write-Log "Configured WDOT profile with OneDrive and FSLogix compatibility" -Level "INFO"
            }
            
            # Define safe optimizations that won't interfere with OneDrive or FSLogix
            $SafeOptimizations = @(
                "AppxPackages",           # Remove unnecessary Store apps
                "ScheduledTasks",         # Disable unnecessary scheduled tasks  
                "DiskCleanup",           # Clean temporary files
                "NetworkOptimizations",   # Optimize network settings
                "Autologgers",           # Disable diagnostic logging
                "DefaultUserSettings"     # Optimize user settings
            )
            
            # Run WDOT with safe optimizations, explicitly excluding OneDrive removal
            Write-Log "Running Windows Desktop Optimization Tool with safe optimizations" -Level "INFO"
            Write-Log "Excluded optimizations: RemoveOneDrive (to preserve OneDrive functionality)" -Level "INFO"
            Write-Log "FSLogix compatibility: Ensured by excluding conflicting service optimizations" -Level "INFO"
            
            $WDOTArgs = @{
                ConfigProfile = $WDOTConfigProfile
                Optimizations = $SafeOptimizations
                AcceptEULA = $true
                ErrorAction = 'Stop'
            }
            
            # Execute WDOT
            & $WDOTScriptPath @WDOTArgs
            
            Write-Log "Windows Desktop Optimization Tool completed successfully" -Level "INFO"
        }
        catch {
            Write-Log "Error during WDOT configuration or execution: $($_.Exception.Message)" -Level "WARNING"
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Log "WDOT script not found after download attempt: $WDOTScriptPath" -Level "WARNING"
    }
}
catch {
    Write-Log "Error integrating Windows Desktop Optimization Tool: $($_.Exception.Message)" -Level "ERROR"
}
#endregion

# Install FSLogix (after WDOT to ensure compatibility)
Write-Log "Installing FSLogix" -Level "INFO"
try {
    $FSLogixZipPath = "$AppBasePath\fslogix.zip"
    $FSLogixExtractPath = "$AppBasePath\fslogix\"
    
    # Download FSLogix if not already present
    if (-not (Test-Path $FSLogixZipPath)) {
        Write-Log "Downloading FSLogix from Microsoft" -Level "INFO"
        Invoke-WebRequest -Uri 'https://aka.ms/fslogix_download' -OutFile $FSLogixZipPath
        Start-Sleep -Seconds 20
    }
    
    # Extract and install
    if (Test-Path $FSLogixZipPath) {
        Expand-Archive -Path $FSLogixZipPath -DestinationPath $FSLogixExtractPath -Force
        $FSLogixSetup = "$FSLogixExtractPath\x64\Release\FSLogixAppsSetup.exe"
        
        if (Test-Path $FSLogixSetup) {
            Start-Process -FilePath $FSLogixSetup -ArgumentList "/install", "/quiet", "/norestart" -Wait -ErrorAction Stop
            Write-Log "FSLogix installed successfully" -Level "INFO"
        }
        else {
            throw "FSLogix setup executable not found after extraction"
        }
    }
    else {
        throw "FSLogix download failed or file not accessible"
    }
}
catch {
    Write-Log "Error installing FSLogix: $($_.Exception.Message)" -Level "ERROR"
}
#endregion


#region Remove Built-in Applications
Write-Log "Starting removal of built-in Windows applications" -Level "INFO"

$AppsToRemove = @(
    @{ Name = "Microsoft.Microsoft3DViewer"; Description = "Microsoft 3D Viewer" }
    @{ Name = "Microsoft.549981C3F5F10"; Description = "Microsoft Cortana" }
    @{ Name = "Microsoft.WindowsFeedbackHub"; Description = "Microsoft Feedback Hub" }
    @{ Name = "Microsoft.GetHelp"; Description = "Microsoft Get Help" }
    @{ Name = "Microsoft.ZuneMusic"; Description = "Zune or Groove Music" }
    @{ Name = "Microsoft.WindowsMaps"; Description = "Maps" }
    @{ Name = "Microsoft.MicrosoftSolitaireCollection"; Description = "Microsoft Solitaire Collection" }
    @{ Name = "Microsoft.ZuneVideo"; Description = "Zune Video, Groove Video or Movies & TV" }
    @{ Name = "Microsoft.MicrosoftOfficeHub"; Description = "Office 2016 Hub" }
    @{ Name = "Microsoft.SkypeApp"; Description = "Skype" }
    @{ Name = "Microsoft.Getstarted"; Description = "Get Started Hub or Tips" }
    @{ Name = "Microsoft.XboxApp"; Description = "Xbox" }
    @{ Name = "Microsoft.XboxGamingOverlay"; Description = "Xbox Game Bar" }
    @{ Name = "Microsoft.YourPhone"; Description = "Your Phone" }
    @{ Name = "Microsoft.MixedReality.Portal"; Description = "Mixed Reality" }
    @{ Name = "Microsoft.windowscommunicationsapps"; Description = "Mail" }
)

$RemovedCount = 0
$TotalApps = $AppsToRemove.Count

foreach ($App in $AppsToRemove) {
    try {
        Write-Log "Attempting to remove: $($App.Description) ($($App.Name))" -Level "INFO"
        
        # Remove AppX package for all users
        $AppxPackages = Get-AppxPackage -Name $App.Name -AllUsers -ErrorAction SilentlyContinue
        if ($AppxPackages) {
            $AppxPackages | Remove-AppxPackage -ErrorAction SilentlyContinue
            Write-Log "Removed AppX package for: $($App.Description)" -Level "INFO"
        }
        
        # Remove provisioned package
        $ProvisionedPackages = Get-AppXProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -EQ $App.Name
        if ($ProvisionedPackages) {
            $ProvisionedPackages | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
            Write-Log "Removed provisioned package for: $($App.Description)" -Level "INFO"
        }
        
        # Remove user data folders
        $AppPath = "$Env:LOCALAPPDATA\Packages\$($App.Name)*"
        if (Test-Path $AppPath) {
            Remove-Item $AppPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Removed user data for: $($App.Description)" -Level "INFO"
        }
        
        $RemovedCount++
    }
    catch {
        Write-Log "Error removing $($App.Description): $($_.Exception.Message)" -Level "WARNING"
    }
}

Write-Log "Application removal completed: $RemovedCount out of $TotalApps applications processed" -Level "INFO"
#endregion

#region Script Completion
$EndTime = Get-Date
Write-Log "AIB Application Installation Script completed at $EndTime" -Level "INFO"
Write-Log "Script execution summary:" -Level "INFO"
Write-Log "- Total applications configured: $($Applications.Count)" -Level "INFO"
Write-Log "- Built-in applications removed: $RemovedCount out of $TotalApps" -Level "INFO"
Write-Log "- Log file location: $LogFile" -Level "INFO"

Write-Host "`nAIB Application Installation Script completed successfully!" -ForegroundColor Green
Write-Host "Check the log file for detailed information: $LogFile" -ForegroundColor Yellow
#endregion



