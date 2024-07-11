#Naveen.S
#region Set logging 
$logFile = "c:\windows\temp\" + (get-date -format 'yyyyMMdd') + '_AIBApplicationinstall.log'
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}
#endregion

#install AIP
Write-host 'AIB Customization: Install AIP'
try {
    Start-Process -filepath "C:\apps\AVDapps\AIP\DistributionFiles\Windows\Microsoft AIP 2.13.49\Deploy-Application.exe" -Wait -ErrorAction Stop 
    write-log "AIP installed successfully"
    write-host "AIP installed successfully"
    }
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing AIP: $ErrorMessage"
    Write-host "Error installing AIP: $ErrorMessage"
}
#endregion
Write-host 'AIB Customization: EndRegion AIP'
#install JRE
Write-host 'AIB Customization: Install JRE'
try {
    Start-Process -filepath "C:\apps\AVDapps\JRE\Deploy-Application.exe" -Wait -ErrorAction Stop 
    write-log "JRE installed successfully"
    write-host "JRE installed successfully"
    }
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing JRE: $ErrorMessage"
    write-host "Error installing JRE: $ErrorMessage"
}
#endregion
Write-host 'AIB Customization: EndRegion JRE'
#install Netclean
Write-host 'AIB Customization: Install NetClean'
try {
    Start-Process -filepath "C:\apps\AVDapps\Netclean\Deploy-Application.exe" -Wait -ErrorAction Stop 
    write-log "Netclean installed successfully"
    write-host "Netclean installed successfully"
    }
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing Netclean: $ErrorMessage"
    write-host "Error installing Netclean: $ErrorMessage"
}
#endregion
Write-host 'AIB Customization: endregion NetClean'

#install TNS_names
Write-host 'AIB Customization: Install TNS_Names'
try {
    Start-Process -filepath "C:\apps\AVDapps\TNS_names\Deploy-Application.exe" -Wait -ErrorAction Stop 
    write-log "TNS_names installed successfully"
    write-host "TNS_names installed successfully"
    }
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing TNS_names: $ErrorMessage"
    write-host "Error installing TNS_names: $ErrorMessage"
}
#endregion
Write-host 'AIB Customization: endregion TNS_Names'

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
Write-host 'AIB Customization: Install vcc_fonts'
try {
    Start-Process -filepath "C:\apps\AVDapps\VCC_Fonts\Deploy-Application.exe" -Wait -ErrorAction Stop 
    write-log "VCC_Fonts installed successfully"
    write-host "VCC_Fonts installed successfully"
    }
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing VCC_Fonts: $ErrorMessage"
    write-host "Error installing VCC_Fonts: $ErrorMessage"
}
#endregion
Write-host 'AIB Customization: endregion vccfonts'

#install VCC_Templates
Write-host 'AIB Customization: Install templates'
try {
    Start-Process -filepath "C:\apps\AVDapps\VCC_Templates\Deploy-Application.exe" -Wait -ErrorAction Stop 
    write-log "VCC_Templates installed successfully"
    write-host "VCC_Templates installed successfully"
    New-Item -path "HKEY_USERS\.DEFAULT\Software\Microsoft\Office\16.0\Common\General\" -Name 'sharedtemplates' -Force
    set-itemproperty "HKEY_USERS\.DEFAULT\Software\Microsoft\Office\16.0\Common\General\" -Name sharedtemplates -Value "C:\ProgramData\Microsoft\Windows\Corporate Templates"
    write-log "VCC_Templates added to registry successfully"
    write-host "VCC_Templates added to registry successfully"
    }
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing VCC_Templates: $ErrorMessage"
    write-host "Error installing VCC_Templates: $ErrorMessage"
}
#endregion
Write-host 'AIB Customization: endregion templates'

#install #StartMenu
try {
    Import-StartLayout -LayoutPath "C:\apps\AVDapps\StartMenu\VCC-StartM.bin" -MountPath $env:SystemDrive\
    write-log "Start menu layout successfully"
    write-host "Start menu layout successfully"
    }
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error setting up start menu: $ErrorMessage"
}
#end region.



#install Java
Write-host 'AIB Customization: Install Java'
try {
    
    Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', "C:\apps\AVDapps\Java_8\source\jre1.8.0_72.msi", TRANSFORMS="C:\apps\AVDapps\Java_8\source\Java_8_Update_72_x86_8.0.720.15_W10.mst" , '/qn','/l*v',  "C:\Windows\Temp\Java-INSTALL.log"
    Write-Log "successfully installed Java"
    Write-host "successfully installed Java"

    }
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installed Java: $ErrorMessage"
    Write-Log "Error installed Java: $ErrorMessage"
}

#endregion Java
Write-host 'AIB Customization: endregion Java'
#Onboard Windows Defender ATP.
Write-host 'AIB Customization: Configure Defender ATP'
try{
$dir='C:\WINDOWS\System32\GroupPolicy\Machine\Scripts\Startup'
New-Item -Path $dir -ItemType Directory -force
Copy-Item -path "c:\apps\AVDapps\Onboard ATP\Onboard-NonPersistentMachine.ps1" -Destination $dir
write-log "Copying Onboard-NonPersistentMachine : success" 
}
catch{
    $ErrorMessage = $_.Exception.message
    write-log "Error copying Onboard-NonPersistentMachine : $ErrorMessage" 
    write-host "Error copying Onboard-NonPersistentMachine : $ErrorMessage" 
}
try {
    Copy-Item -path "c:\apps\AVDapps\Onboard ATP\WindowsDefenderATPOnboardingScript.cmd" -Destination $dir
    write-log "Copying atponboardingscript.cmd"
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error copying WindowsDefenderATPOnboardingScript : $ErrorMessage" 
    write-host "Error copying WindowsDefenderATPOnboardingScript : $ErrorMessage" 
}
#endregion of defender ATP.
Write-host 'AIB Customization: endregion defender ATP'

# install optimized teams.
Write-host 'AIB Customization: install optimized teams'

try {
    Start-Process -filepath "C:\apps\AVDapps\AVDTeams\DistributionFiles\Windows\Microsoft New Teams for VDI 2.0\Deploy-Application.exe" -Wait -ErrorAction Stop 
    write-log "AVD Teams installed successfully."
    write-host "AVD Teams installed successfully."
      }
 catch {
     $ErrorMessage = $_.Exception.message
     write-log "Error installing AVD Teams: $ErrorMessage"
     write-host "Error installing AVD Teams: $ErrorMessage"
 }
 #endregion of teams.
 Write-host 'AIB Customization: endregion optimized teams'

#install VCC wallpaper
Write-host 'AIB Customization: Configure Wallpaper'
try {
    Start-Process -filepath "C:\apps\AVDapps\VCC_Wallpaper\Deploy-Application.exe" -Wait -ErrorAction Stop 
    Start-Sleep -Seconds 5
    write-log "VCC Wallpaper successfully"
    write-host "VCC Wallpaper successfully"
    New-Item -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force
    set-itemproperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name LockScreenImage -Value "C:\windows\Themes\VCCWallpaper\Default.jpg"
    write-log "VCC Wallpaper & lockscreen configured successfully."
    write-host "VCC Wallpaper & lockscreen configured successfully."
    }
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error setting wallpaper: $ErrorMessage"
}
#endregion

#install Chrome
Write-host 'AIB Customization: Install Chrome'
try {
    Start-Process -filepath "C:\apps\AVDapps\Google Chrome 90.0.4430.212\Deploy-Application.exe" -Wait -ErrorAction Stop 
    write-log "Chrome installed successfully"
    write-host "Chrome installed successfully"
    }
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing Chrome: $ErrorMessage"
    write-host "Error installing Chrome: $ErrorMessage"
}
Write-host 'AIB Customization: endregion chrome'

#install AVDBG
Write-host 'AIB Customization: Install AVDBG'
try {
  Start-Process -filepath "C:\apps\AVDapps\AVDBG\Deploy-Application.exe" -Wait -ErrorAction Stop
    }
catch {
    $ErrorMessage = $_.Exception.message
    
    write-host "Error AVDBG: $ErrorMessage"
}

Write-host 'AIB Customization: EndRegion AVDBG'
#endregion AVDBG 

#install Notepadd
Write-host 'AIB Customization: Install Notepadd'
try {
  Start-Process -filepath "C:\apps\AVDapps\Notepad++\DistributionFiles\Windows\Open Software Notepad++ 8.4\Deploy-Application.exe" -Wait -ErrorAction Stop
    }
catch {
    $ErrorMessage = $_.Exception.message
    
    write-host "Error Notepadd: $ErrorMessage"
}

Write-host 'AIB Customization: EndRegion Notepadd'
#endregion Notepadd 

#install Putty
Write-host 'AIB Customization: Install Putty'
try {
 Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', "C:\apps\AVDapps\Putty\OriginalFiles\putty-64bit-0.74-installer.msi", '/qn','/l*v',  "C:\Windows\Temp\Putty-INSTALL.log"
    }
catch {
    $ErrorMessage = $_.Exception.message
    
    write-host "Error Putty: $ErrorMessage"
}

Write-host 'AIB Customization: EndRegion Putty'
#endregion Putty 

#installfslogix
write-host 'AIB customization: install fslogix'
try{
Invoke-WebRequest -Uri 'https://aka.ms/fslogix_download' -outfile   "C:\apps\AVDapps\fslogix.zip"
Start-Sleep -Seconds 20
Expand-Archive -Path "C:\apps\AVDapps\fslogix.zip" -DestinationPath "C:\apps\AVDapps\fslogix\"  -Force
Invoke-Expression -Command "C:\apps\AVDapps\fslogix\x64\Release\FSLogixAppsSetup.exe /install /quiet /norestart"
}
catch{
    $ErrorMessage = $_.Exception.message
    
    write-host "Error FSLOGIX: $ErrorMessage"
}
write-host  'AIB customization: end region fslogix'
#endregion fslogix


#removal of inbuilt applications.
$apps=@(     
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
    Write-host $app "Ready to remove"
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online
            
    $appPath="$Env:LOCALAPPDATA\Packages\$app*"
    Remove-Item $appPath -Recurse -Force -ErrorAction 0
}
write-host  "AIB: removal of applications"
#endregion of inbuilt applications.



