#testing the pull request to modify the existing code.
 # OS Optimizations for WVD
 write-host 'AIB Customization: OS Optimizations for WVD'
 $appName = 'Optimize'
 $drive = 'C:\apps'
 New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
 $LocalPath = $drive + '\' + $appName 
 set-Location $LocalPath
 $osOptURL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/master.zip'
 $osOptURLexe = 'Virtual-Desktop-Optimization-Tool-main.zip'
 $outputPath = $LocalPath + '\' + $osOptURLexe
 Invoke-WebRequest -Uri $osOptURL -OutFile $outputPath
 write-host 'AIB Customization: Starting OS Optimizations script'
 Expand-Archive -LiteralPath 'C:\\apps\\Optimize\\Virtual-Desktop-Optimization-Tool-main.zip' -DestinationPath $Localpath -Force -Verbose
 Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
 Set-Location -Path C:\\apps\\Optimize\\Virtual-Desktop-Optimization-Tool-main
   
 
 # Patch: overide the Win10_VirtualDesktop_Optimize.ps1 - setting 'Set-NetAdapterAdvancedProperty'(see readme.md)
 Write-Host 'Patch: Disabling Set-NetAdapterAdvancedProperty'
 $updatePath= "C:\apps\Optimize\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1"
 ((Get-Content -path $updatePath -Raw) -replace 'Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB','#Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB') | Set-Content -Path $updatePath

 # run script
.\Windows_VDOT.ps1 -Verbose -AcceptEula
  write-host 'AIB Customization: Finished OS Optimizations script'
 
  
