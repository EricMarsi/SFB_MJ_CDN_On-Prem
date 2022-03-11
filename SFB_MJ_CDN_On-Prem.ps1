#Script: SFB_MJ_On-Prem_v2105.1
#Description: Bring Skype for Business Server Meeting Join CDN On-Premises Utility
#Created by: Eric Marsi (www.UCIT.Blog)
#Date: March 25, 2021
#Updated: May 30, 2021

Clear-Host

Write-Host "**************************************************************************************" -ForegroundColor Green
Write-Host "*         Bring Skype for Business Server Meeting Join CDN On-Premises Utility       *" -ForegroundColor Green
Write-Host "*                         Created by: Eric Marsi (www.UCIT.Blog)                     *" -ForegroundColor Green
Write-Host "*                                   Version: 2105.1                                  *" -ForegroundColor Green
Write-Host "*                                Date: March 25, 2021                                *" -ForegroundColor Green
Write-Host "*                                Updated: May 30, 2021                               *" -ForegroundColor Green
Write-Host "**************************************************************************************`n" -ForegroundColor Green

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Script Tests 
#Verify that the Script is executing as an Administrator
Write-Host "Verifying that the script is executing as an Administrator"
function Test-IsAdmin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    }
    if (!(Test-IsAdmin)){
        throw "Please run this script as an Administrator!"
    }
    else {
        Write-Host "Pass: The script is executing as an Administrator `n" -ForegroundColor Green       
    }

#Verify that the script is executing in the PowerShell Console and not the ISE
Write-Host "Verifying that the script is executing in the PowerShell Console and not the ISE"
    if((Get-Host).Name -eq "ConsoleHost")
    {
        Write-Host "Pass: The script is executing in the PowerShell Console`n" -ForegroundColor Green
    }else {
        Write-Error "The script is not executing in the PowerShell Console!" -ErrorAction Stop
    }

#Verify that the Skype for Business Server PowerShell Module is installed
Write-Host "Verifying that the Skype for Business Server PowerShell Module is Installed"
    if(Get-Module -ListAvailable SkypeforBusiness)
        {
            Import-Module SkypeforBusiness
            Write-Host "Pass: The Skype for Business Server PowerShell Module is Installed`n" -ForegroundColor Green
        }else {
            Write-Error "Script terminating as the Skype for Business Server PowerShell Module is NOT Installed! " -ErrorAction Stop
        }   

#Get which drive Skype for Business Server is installed on
    Write-Host "Querying all Avalible Volumes on the Host PC------`n"
    (Get-WmiObject win32_logicaldisk).DeviceID | ForEach-Object { $_ -replace ':',''}
    Write-Host ""
    Write-Host "--------------------------------------------------`n"    
    $DriveL = Read-Host "Please enter the drive letter from the above option(s) that Skype for Business Server is installed on. (In most cases, this is C)"
    if ($null -eq $DriveL){
        Write-Error  "An invalid response was provided! Terminating the Script" -ErrorAction Stop
    }else {
        Write-Host "$($DriveL) Drive Selected`n" -ForegroundColor Green
    }
    
#Verify that Skype for Business Server is installed and Get Skype for Business Server Version
Write-Host "Verifying that Skype for Business Server is installed and get the Skype for Business Server Version"
if(test-path "$($DriveL):\Program Files\Skype for Business Server 2019\")
    {
        Write-Host "Pass: The host machine is running Skype for Business Server 2019`n" -ForegroundColor Green
        $ServerVer = "2019"
    }elseif(test-path "$($DriveL):\Program Files\Skype for Business Server 2015\")
    {
        Write-Host "Pass: The host machine is running Skype for Business Server 2015`n" -ForegroundColor Green
        $ServerVer = "2015"    
    }else {
        Write-Error "Host Machine is not running Skype for Business Server! Terminating the Script" -ErrorAction Stop
    }

#Get Source Branch
Write-Host "Source Branch-------------------------------------`n"
Write-Host "1.) PROD" -ForegroundColor Green
Write-Host "2.) DEV`n" -ForegroundColor Green
Write-Host "--------------------------------------------------`n"
$Branch = Read-Host "From the above options, which branch should the script obtain the CDN files from? (Enter the Option Number - 1 or 2)"
Write-Host ""
Write-Host "--------------------------------------------------`n"

#Validate Source Branch Input
if($Branch -eq 1) {$Branch = 'prod'}
elseif($Branch -eq 2) {$Branch = 'dev'}
elseif($Branch -eq 'prod') {$Branch = 'prod'}
elseif($Branch -eq 'dev') {$Branch = 'dev'}
else{Write-Error "No CDN Branch Selected! Terminating the Script" -ErrorAction Stop}

#Determine CDN Source Locaton
Write-Host "CDN Files Location--------------------------------`n"
Write-Host "1.) Locally Provided Files (Preferred)" -ForegroundColor Green
Write-Host "2.) Latest from the Microsoft CDN`n" -ForegroundColor Green
Write-Host "--------------------------------------------------`n"
$CDN = Read-Host "From the above options, what location should the script obtain the CDN files from? (Enter the Option Number - 1 or 2)"
Write-Host ""
Write-Host "--------------------------------------------------`n"

#Validate CDN Source Locaton Input
if($CDN -eq 1) {$CDN = 'local'}
elseif($CDN  -eq 2) {$CDN  = 'msft'}
else{Write-Error "No CDN Branch Selected! Terminating the Script" -ErrorAction Stop}

#Get the External Skype for Business Pool FQDNs
Write-Host "Querying the External Skype for Business Pool FQDNs`n"
(Get-CsService -WebServer).ExternalFqdn
Write-Host ""
$ExtFQDN = Read-Host "Please enter the external FQDN of the SFB Pool that you wish to host the on-prem meeting CDN:`n"
if ($null -eq $ExtFQDN){
        Write-Error "No external pool FQDN was entered! | Terminating the Script" -ErrorAction Stop
    }else {
        if((Get-CsService -WebServer).ExternalFqdn -contains $ExtFQDN){            
            Write-Host "A valid external pool FQDN was entered" -ForegroundColor Green
        }else{
            Write-Error "An invalid external pool FQDN was entered! | Terminating the Script" -ErrorAction Stop
        }
    }
Write-Host "--------------------------------------------------`n"

#Verify that the Temp joinux\branch directory is empty. If not, delete the folders' contents
$FRoot = 'C:\Temp\joinux\'
$JoinUX = $($FRoot) + $($Branch)
Write-Host "Verifying that the temporary directory at $($JoinUX) is empty. If not, deleting the folders' contents"
        if(!(test-path $JoinUX))
        {
            Write-Host "Pass: The folder: $($JoinUX) does not exist. No cleanup necessary`n" -ForegroundColor Green
        }else {
            Write-Host "The folder: $($JoinUX) exists. Deleting the folder and its contents" -ForegroundColor Yellow
            try{
                Remove-Item $JoinUX -Recurse -Force -ErrorAction Stop 
                Write-Host "The folder: $($JoinUX) was removed successfully`n" -ForegroundColor Green
            }catch{
                Write-Error "The folder: $($JoinUX) was unabled to be removed. The exception caught was $_" -ErrorAction Stop
            }
        }

#Verify that the $($DriveL):\Program Files\Skype for Business Server\Web Components\Join Launcher\Ext\joinux directory is empty. If not, delete the folders' contents
Write-Host "Verifying that the $($DriveL):\Program Files\Skype for Business Server\Web Components\Join Launcher\Ext\joinux\$($Branch) directory is empty. If not, deleting the folders' contents"
$IntWeb = "$($DriveL):\Program Files\Skype for Business Server $($ServerVer)\Web Components\Join Launcher\Ext\joinux\$($Branch)"
        if(!(test-path $IntWeb))
        {
            Write-Host "Pass: The folder: $($IntWeb) does not exist. No cleanup necessary`n" -ForegroundColor Green
        }else {
            Write-Host "The folder: $($IntWeb) exists. Deleting the folder and its contents" -ForegroundColor Yellow
            try{
                Remove-Item $IntWeb -Recurse -Force -ErrorAction Stop 
                Write-Host "The folder: $($IntWeb) was removed successfully`n" -ForegroundColor Green
            }catch{
                Write-Error "The folder: $($IntWeb) was unabled to be removed. The exception caught was $_" -ErrorAction Stop
            } 
        }

#Verify that the $($DriveL):\Program Files\Skype for Business Server\Web Components\Join Launcher\Int\joinux directory is empty. If not, delete the folders' contents
Write-Host "Verifying that the $($DriveL):\Program Files\Skype for Business Server\Web Components\Join Launcher\Int\joinux\$($Branch) directory is empty. If not, deleting the folders' contents"
$ExtWeb = "$($DriveL):\Program Files\Skype for Business Server $($ServerVer)\Web Components\Join Launcher\Int\joinux\$($Branch)"
        if(!(test-path $ExtWeb))
        {
            Write-Host "Pass: The folder: $($ExtWeb) does not exist. No cleanup necessary`n" -ForegroundColor Green
        }else {
            Write-Host "The folder: $($ExtWeb) exists. Deleting the folder and its contents" -ForegroundColor Yellow
            try{
                Remove-Item $ExtWeb -Recurse -Force -ErrorAction Stop 
                Write-Host "The folder: $($ExtWeb) was removed successfully`n" -ForegroundColor Green
            }catch{
                Write-Error "The folder: $($ExtWeb) was unabled to be removed. The exception caught was $_" -ErrorAction Stop
            } 
        }

#If Local CDN, Obtain the CDN ZIP File and Extract it to the Temp Directory
if ($CDN -eq 'local'){
    try{
        Write-Host "Please select the local CDN ZIP Archive to import to the temp directory"
        Add-Type -AssemblyName System.Windows.Forms
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
        $FileBrowser.filter = "ZIP Archive (*.zip)| *.zip"
        [void]$FileBrowser.ShowDialog()
        $CDNZIP = $FileBrowser.FileName
        Write-Host "Local CDN ZIP Archive Selected`n" -ForegroundColor Green
    }
    catch{
        Write-Error "An error occured. The exception caught was $_"-ErrorAction Stop
    }

    Write-Host "Attempting to extact the CDN Files ZIP Archive to the Temp Directory"
    try{
        Expand-Archive -LiteralPath "$($CDNZIP)" -DestinationPath "$($FRoot)" -Force -ErrorAction Stop
        Write-Host "Success: Extacted the CDN Files ZIP Archive to the Temp Directory`n" -ForegroundColor Green
    }
    catch{
        Write-Error "Unable to extact the CDN Files ZIP Archive to the Temp Directory. The exception caught was $_" -ErrorAction Stop
    }
}

#Get File Information and Versioning information
if ($CDN -eq 'local'){
    $CDNData = Get-Content "$($FRoot)$($Branch)\config.json" | Out-String | ConvertFrom-Json
    $Ver = $CDNData.baseUrl | ForEach-Object { $_ -replace "https://meetings.sfbassets.com/joinux/prod/",''} | ForEach-Object { $_ -replace '/',''} 
}
elseif ($CDN -eq 'msft'){
    $CDNData = Invoke-RestMethod -Uri "https://meetings.sfbassets.com/joinux/$($Branch)/config.json"
    $Ver = $CDNData.baseUrl | ForEach-Object { $_ -replace "https://meetings.sfbassets.com/joinux/prod/",''} | ForEach-Object { $_ -replace '/',''} 
}
        
#If MSFT CDN, Check file destination folders, if not there, create them
if ($CDN -eq 'msft'){
    $Dest =  "$($FRoot)$($Branch)\$($Ver)\"
	$Paths = "$($Dest)assets\mac","$($Dest)assets\windows","$($Dest)assets\plugins\en-us","$($Dest)assets\plugins\windows","$($Dest)assets\plugins\mac","$($Dest)css","$($Dest)libs","$($Dest)nls","$($Dest)views","$($Dest)assets\fonts\segoe-ui\west-european\normal","$($Dest)assets\fonts\segoe-ui\west-european\light","$($Dest)assets\fonts\segoe-ui\west-european\semibold","$($Dest)assets\2021.0330.1001\lwa\styles","$($Dest)assets\2021.0330.1001\lwa\i18n\en-us","$($Dest)assets\2021.0330.1001\lwa\scripts\Model","$($Dest)assets\2021.0330.1001\lwa\scripts\UI","$($Dest)assets\2021.0330.1001\lwa\scripts\Common","$($Dest)assets\2021.0330.1001\lwa\images","$($Dest)assets\2021.0330.1001\plugins\plugins\en-us","$($Dest)assets\2021.0330.1001\plugins\windows","$($Dest)assets\2021.0330.1001\plugins\mac"	
    foreach  ($Path in $Paths)
        {
            Write-Host "Verifying that the folder: $($Path) exists"
            if(!(test-path $Path))
            {
                New-Item -ItemType Directory -Force -Path $Path | out-null
                Write-Host "The folder: $($Path) did not exist, but it was created`n" -ForegroundColor Green
            }else {
                Write-Host "Pass: The folder: $($Path) already exists`n" -ForegroundColor Green
            }
        }
    }else {
        $Dest =  "$($FRoot)$($Branch)\$($Ver)\"
    }
    
#If MSFT CDN, Download the latest files from the selected branch
if ($CDN -eq 'msft'){
    Write-Host "Downloading 69 Files from the $($Branch) Microsoft CDN Environment | Version $($Ver) | Please Standby...`n"
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri "https://meetings.sfbassets.com/joinux/$($Branch)/config.json" -OutFile "$($FRoot)$($Branch)\config.json"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)views/ClientSelection.html" -OutFile "$($Dest)views\ClientSelection.html"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)assets/background-skype-meetings-blue.jpeg" -OutFile "$($Dest)assets\background-skype-meetings-blue.jpeg"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)assets/LogoWhite.32x32.png" -OutFile "$($Dest)assets\LogoWhite.32x32.png"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)assets/spinner64.gif" -OutFile "$($Dest)assets\spinner64.gif"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)views/MeetingJoin.html" -OutFile "$($Dest)views\MeetingJoin.html"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)views/Success.html" -OutFile "$($Dest)views\Success.html"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)views/mLaunch.html" -OutFile "$($Dest)views\mLaunch.html"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)views/Launch.html" -OutFile "$($Dest)views\Launch.html"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)views/Download.html" -OutFile "$($Dest)views\Download.html"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)views/Error.html" -OutFile "$($Dest)views\Error.html"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)nls/strings.js" -OutFile "$($Dest)nls\strings.js"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)libs/i18n.js" -OutFile "$($Dest)libs\i18n.js"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)libs/jquery.js" -OutFile "$($Dest)libs\jquery.js"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)libs/aria-web-telemetry.js" -OutFile "$($Dest)libs\aria-web-telemetry.js"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)app.config.js" -OutFile "$($Dest)app.config.js"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)css/bootstrap-theme.css" -OutFile "$($Dest)css\bootstrap-theme.css"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)css/bootstrap.css" -OutFile "$($Dest)css\bootstrap.css"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)libs/require.js" -OutFile "$($Dest)libs\require.js"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)css/app.css" -OutFile "$($Dest)css\app.css"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)views/Redirect.html" -OutFile "$($Dest)views\Redirect.html"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)assets/sad_100.png" -OutFile "$($Dest)assets\sad_100.png"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)assets/Logo.80x80.png" -OutFile "$($Dest)assets\Logo.80x80.png"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)assets/SfBLogo_Android.png" -OutFile "$($Dest)assets\SfBLogo_Android.png"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)assets/SfBLogo_iOS.png" -OutFile "$($Dest)assets\SfBLogo_iOS.png"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)assets/SfBLogo_WinPhone.png" -OutFile "$($Dest)assets\SfBLogo_WinPhone.png"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)assets/Safari.png" -OutFile "$($Dest)assets\Safari.png"
        Invoke-WebRequest -Uri "$($CDNData.baseUrl)assets/Firefox.png" -OutFile "$($Dest)assets\Firefox.png"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/LWA/plugins/mac/SkypeMeetingsApp.dmg" -OutFile "$($Dest)assets\mac\SkypeMeetingsApp.dmg"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/LWA/plugins/windows/SkypeMeetingsApp.msi" -OutFile "$($Dest)assets\windows\SkypeMeetingsApp.msi"
        Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=831677&clcid=0x409" -OutFile "$($Dest)assets\SkypeForBusinessInstaller-16.29.0.42.pkg"
        Invoke-WebRequest -Uri "https://meetings.sfbassets.com/lwa/prod/onprem/W16/config.js" -OutFile "$($Dest)config.js"
        #LWA App
        Invoke-WebRequest -Uri "https://i.s-microsoft.com/fonts/segoe-ui/west-european/normal/latest.css" -OutFile "$($Dest)assets/fonts/segoe-ui/west-european/normal/latest.css"
        Invoke-WebRequest -Uri "https://i.s-microsoft.com/fonts/segoe-ui/west-european/light/latest.css" -OutFile "$($Dest)assets/fonts/segoe-ui/west-european/light/latest.css"
        Invoke-WebRequest -Uri "https://i.s-microsoft.com/fonts/segoe-ui/west-european/semibold/latest.css" -OutFile "$($Dest)assets/fonts/segoe-ui/west-european/semibold/latest.css"
        Invoke-WebRequest -Uri "https://i.s-microsoft.com/fonts/segoe-ui/west-european/normal/latest.woff" -OutFile "$($Dest)assets/fonts/segoe-ui/west-european/normal/latest.woff"
        Invoke-WebRequest -Uri "https://i.s-microsoft.com/fonts/segoe-ui/west-european/light/latest.woff" -OutFile "$($Dest)assets/fonts/segoe-ui/west-european/light/latest.woff"
        Invoke-WebRequest -Uri "https://i.s-microsoft.com/fonts/segoe-ui/west-european/semibold/latest.woff" -OutFile "$($Dest)assets/fonts/segoe-ui/west-european/semibold/latest.woff"
        Invoke-WebRequest -Uri "https://i.s-microsoft.com/fonts/segoe-ui/west-european/normal/latest.ttf" -OutFile "$($Dest)assets/fonts/segoe-ui/west-european/normal/latest.ttf"
        Invoke-WebRequest -Uri "https://i.s-microsoft.com/fonts/segoe-ui/west-european/light/latest.ttf" -OutFile "$($Dest)assets/fonts/segoe-ui/west-european/light/latest.ttf"
        Invoke-WebRequest -Uri "https://i.s-microsoft.com/fonts/segoe-ui/west-european/semibold/latest.ttf" -OutFile "$($Dest)assets/fonts/segoe-ui/west-european/semibold/latest.ttf"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/styles/sprite1.css?2021.0330.1001" -OutFile "$($Dest)assets/2021.0330.1001/lwa/styles/sprite1.css"
		Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/styles/nonhc_sprite1.css?2021.0330.1001" -OutFile "$($Dest)assets/2021.0330.1001/lwa/styles/sprite1.css"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/styles/Lync.Client.Consolidated_ltr.css?2021.0330.1001" -OutFile "$($Dest)assets/2021.0330.1001/lwa/styles/Lync.Client.Consolidated_ltr.css"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/i18n/en-us/strings.js?2021.0330.1001" -OutFile "$($Dest)assets/2021.0330.1001/lwa/i18n/en-us/strings.js"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/scripts/Model/Lync.Client.PluginFramework.js?2021.0330.1001" -OutFile "$($Dest)assets/2021.0330.1001/lwa/scripts/Model/Lync.Client.PluginFramework.js"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/scripts/Model/Lync.Client.PreAuth.Model.Consolidated.js?2021.0330.1001" -OutFile "$($Dest)assets/2021.0330.1001/lwa/scripts/Model/Lync.Client.PreAuth.Model.Consolidated.js"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/scripts/UI/Lync.Client.AppLibConsolidated.js?2021.0330.1001" -OutFile "$($Dest)assets/2021.0330.1001/lwa/scripts/UI/Lync.Client.AppLibConsolidated.js"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/scripts/UI/animation.js?2021.0330.1001" -OutFile "$($Dest)assets/2021.0330.1001/lwa/scripts/UI/animation.js"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/scripts/UI/Lync.Extensions.js?2021.0330.1001" -OutFile "$($Dest)assets/2021.0330.1001/lwa/scripts/UI/Lync.Extensions.js"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/scripts/UI/Lync.Client.CommonControlConsolidated.js?2021.0330.1001" -OutFile "$($Dest)assets/2021.0330.1001/lwa/scripts/UI/Lync.Client.CommonControlConsolidated.js"
		Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/scripts/UI/Lync.Client.ControlConsolidated.js?lcsentwebapp6.0.9299.0" -OutFile "$($Dest)assets/2021.0330.1001/lwa/scripts/UI/Lync.Client.ControlConsolidated.js"
		Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/scripts/Common/Lync.Client.Common.Consolidated.js" -OutFile "$($Dest)assets/2021.0330.1001/lwa/scripts/Common/Lync.Client.Common.Consolidated.js"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/scripts/UI/Lync.Client.MiscClientConsolidated.js?2021.0330.1001" -OutFile "$($Dest)assets/2021.0330.1001/lwa/scripts/UI/Lync.Client.MiscClientConsolidated.js"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/scripts/Model/Lync.Client.Model.Consolidated.js?lcsentwebapp6.0.9299.0" -OutFile "$($Dest)assets/2021.0330.1001/lwa/scripts/Model/Lync.Client.Model.Consolidated.js"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/images/skypelogo.png" -OutFile "$($Dest)assets/2021.0330.1001/lwa/images/skypelogo.png"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/images/sprite1.png?15.0.0.0" -OutFile "$($Dest)assets/2021.0330.1001/lwa/images/sprite1.png"
		Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/images/nonhc_sprite1.png?15.0.0.0" -OutFile "$($Dest)assets/2021.0330.1001/lwa/images/nonhc_sprite1.png"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/images/unchecked_normal.png?15.0.0.0" -OutFile "$($Dest)assets/2021.0330.1001/lwa/images/unchecked_normal.png"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/images/join_preloader.gif?15.0.0.0" -OutFile "$($Dest)assets/2021.0330.1001/lwa/images/join_preloader.gif"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/images/lwa_login_loader.gif?15.0.0.0" -OutFile "$($Dest)assets/2021.0330.1001/lwa/images/lwa_login_loader.gif"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/images/lwa_arrow_staticup_16.png" -OutFile "$($Dest)assets/2021.0330.1001/lwa/images/lwa_arrow_staticup_16.png"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/images/lwa_arrow_staticdown_16.png" -OutFile "$($Dest)assets/2021.0330.1001/lwa/images/lwa_arrow_staticdown_16.png"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/images/lwa_arrow_staticleft_16.png" -OutFile "$($Dest)assets/2021.0330.1001/lwa/images/lwa_arrow_staticleft_16.png"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/images/lwa_arrow_staticright_16.png" -OutFile "$($Dest)assets/2021.0330.1001/lwa/images/lwa_arrow_staticright_16.png"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/lwa/2021.0330.1001/lwa/scripts/UI/Lync.Client.AVConsolidated.js?lcsentwebapp6.0.9299.0" -OutFile "$($Dest)assets/2021.0330.1001/lwa/scripts/UI/Lync.Client.AVConsolidated.js"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/LWA/plugins/plugins/en-us/LWAPluginEULA.htm" -OutFile "$($Dest)assets/plugins/en-us/LWAPluginEULA.htm"
        Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/LWA/plugins/windows/SkypeMeetingsApp.msi" -OutFile "$($Dest)assets/plugins/windows/SkypeMeetingsApp.msi"
		Invoke-WebRequest -Uri "https://az801095.vo.msecnd.net/prod/LWA/plugins/mac/SkypeMeetingsApp.dmg" -OutFile "$($Dest)assets/plugins/mac/SkypeMeetingsApp.dmg"
        Write-Host "69 files downloaded successfully to $($FRoot)`n" -ForegroundColor Green
    }catch{
        Write-Error "1 or more required file(s) failed to download. The exception caught was $_ | Terminating the Script" -ErrorAction Stop
    }
}
#Modify config.json to have a new URL Mapping
Write-Host "Modifying config.json to have a new URL Mapping"
$NExtFQDN = "https://" + $ExtFQDN + "/meet/joinux/" + "$($Branch)/$($Ver)/"
$File1 = Get-Content "$($FRoot)$($Branch)\config.json" | Out-String | ConvertFrom-Json
$File1Ext = @([pscustomobject]@{styleSheet=$($File1.styleSheet);baseUrl=$($NExtFQDN);requireJs=$($File1.requireJs);appConfig=$($File1.appConfig);})
Write-Host "$($File1.baseUrl) in config.json now points to $($NExtFQDN)`n" -ForegroundColor Green

#Modify app.config.js to have new URL Mappings
Write-Host "Modifying app.config.js to have new URL Mappings"
$File2 = Get-Content "$($Dest)app.config.js" | Out-String

$App1Ext = "https://" + $ExtFQDN + "/meet/joinux/" + "$($Branch)/$($Ver)/assets/mac/SkypeMeetingsApp.dmg"
$App2Ext = "https://" + $ExtFQDN + "/meet/joinux/" + "$($Branch)/$($Ver)/assets/windows/SkypeMeetingsApp.msi"
$App3Ext = "https://" + $ExtFQDN + "/meet/joinux/" + "$($Branch)/$($Ver)/assets/SkypeForBusinessInstaller-16.29.0.42.pkg"

$File2Ext = $File2 | ForEach-Object { $_ -replace 'https://az801095.vo.msecnd.net/prod/LWA/plugins/mac/SkypeMeetingsApp.dmg',"$($App1Ext)"}
$File2Ext = $File2Ext | ForEach-Object { $_ -replace 'https://az801095.vo.msecnd.net/prod/LWA/plugins/windows/SkypeMeetingsApp.msi',"$($App2Ext)"}
$File2Ext = $File2Ext | ForEach-Object { $_ -replace 'https://go.microsoft.com/fwlink/\?linkid=831677&clcid=0x409',"$($App3Ext)"}

Write-Host "https://az801095.vo.msecnd.net/prod/LWA/plugins/mac/SkypeMeetingsApp.dmg in app.config.js now points to $($App1Ext)" -ForegroundColor Green
Write-Host "https://az801095.vo.msecnd.net/prod/LWA/plugins/windows/SkypeMeetingsApp.msi in app.config.js now points to $($App2Ext)" -ForegroundColor Green
Write-Host "https://go.microsoft.com/fwlink/\?linkid=831677&clcid=0x409 in app.config.js now points to $($App3Ext)`n" -ForegroundColor Green

#Modify config.js to have new URL Mappings
Write-Host "Modifying config.js to have new URL Mappings"
$File3 = Get-Content "$($Dest)config.js" | Out-String

$PLExt = "https://" + $ExtFQDN + "/meet/joinux/" + "$($Branch)/$($Ver)/assets/"
$WABExt = "https://" + $ExtFQDN + "/meet/joinux/" + "$($Branch)/$($Ver)/assets/"
$File3Ext = $File3 | ForEach-Object { $_ -replace 'https://az801095.vo.msecnd.net/prod/LWA/plugins/',"$($PLExt)"}
$File3Ext = $File3Ext | ForEach-Object { $_ -replace 'https://az801095.vo.msecnd.net/prod/lwa/',"$($WABExt)"}
Write-Host "https://az801095.vo.msecnd.net/prod/LWA/plugins/ in config.js now points to $($PLExt)" -ForegroundColor Green
Write-Host "https://az801095.vo.msecnd.net/prod/lwa/ in config.js now points to $($WABExt)`n" -ForegroundColor Green

#Modify Error.html to have fixed img src header - MSFT Bug in the site
Write-Host "Modifying Error.html to have fixed img src header - Fixes a Microsoft Bug on the site"
$File4 = Get-Content "$($Dest)views\Error.html" | Out-String

$File4Dest = '<img id="skype_logo" src="' + "https://" + $ExtFQDN + "/meet/joinux/" + "$($Branch)/$($Ver)/assets/LogoWhite.32x32.png" + '" />'
$File4Ext = $File4 | ForEach-Object { $_ -replace '<img id="skype_logo"/>',"$($File4Dest)"}
Write-Host "<img id="skype_logo"/> in Error.html was modified to $($File4Dest)`n" -ForegroundColor Green

#Generate and Write Modified External Files to the Temp Directory
Write-Host "Generating and Writing the 4 Modified External Files to the Temp Directory"
$File1Ext | ConvertTo-Json | Out-File -FilePath "$($FRoot)$($Branch)\config.json" -Force
$File2Ext | Out-File -FilePath "$($Dest)app.config.js" -Force
$File3Ext | Out-File -FilePath "$($Dest)config.js" -Force
$File4Ext | Out-File -FilePath "$($Dest)views\Error.html" -Force
Write-Host "Successfully Generated and Wrote the 4 Modified Files to the Temp Directory`n" -ForegroundColor Green

#Copy modified files into the Internal & External IIS Directory for the meetings page
Write-Host "Copying the modified files into the Internal & External IIS Directory for the meetings page"
try{
    Copy-Item "$($FRoot)$($Branch)\" -Destination "$($DriveL):\Program Files\Skype for Business Server $($ServerVer)\Web Components\Join Launcher\Int\joinux\$($Branch)" -Recurse -Force -ErrorAction Stop
    Copy-Item "$($FRoot)$($Branch)\" -Destination "$($DriveL):\Program Files\Skype for Business Server $($ServerVer)\Web Components\Join Launcher\Ext\joinux\$($Branch)" -Recurse -Force -ErrorAction Stop
    Write-Host "69 Files were copied into the External IIS Directory for the meetings page`n" -ForegroundColor Green
}catch{
    Write-Error "Could not copy 69 files to the External IIS Directory for the meetings page. The exception caught was $_ | Terminating the Script" -ErrorAction Stop
}

#Delete the temp folder used in the script
Write-Host "Deleting the temp folder used in the script"
try{
    Remove-Item $FRoot -Recurse -Force -ErrorAction Stop
    Write-Host "The temp folder used in the script was deleted`n" -ForegroundColor Green
}catch{
    Write-Error "The temp folder used in the script could NOT be deleted. The exception caught was $_ | Terminating the Script" -ErrorAction Stop
}

#Obtain the internal Skype for Business Server FQDN from the external pool FQDN
Write-Host "Obtaining the internal Skype for Business Server FQDN from the external pool FQDN"
try{
    $FQDNMod = "https://" + $($ExtFQDN) + "/Dialin"
    $IntFQDN = Get-CsService -WebServer | Where-Object DialinExternalUri -eq $($FQDNMod) | Select-Object -ExpandProperty PoolFqdn -ErrorAction Stop
    $IntFQDNWS = "service:WebServer:" + $($IntFQDN)
    Write-Host "Found the Internal Pool FQDN to be $($IntFQDNWS)`n" -ForegroundColor Green
}catch{
    Write-Error "Unable to obtain the internal pool FQDN. The exception caught was $_ | Terminating the Script" -ErrorAction Stop
}

#Enable Skype for Business Server to use the Meeting Join CDN and point it at the new local location
Write-Host "Enabling Skype for Business Server to use the Meeting Join CDN and point it at the new local location"
$JLCCU = "https://" + $ExtFQDN + "/meet/joinux/" + "$($Branch)/config.json"
$LWACCU = "https://" + $ExtFQDN + "/meet/joinux/" + "$($Branch)/$($Ver)/config.js"
#Test for CsWebServiceConfiguration for the pool
try {
    Set-CsWebServiceConfiguration -Identity $IntFQDNWS -MeetingUxUseCdn $True -ErrorAction Stop
    Write-Host "A CsWebServiceConfiguration already exists for the $($IntFQDN) pool`n" -ForegroundColor Green
}catch{
    Write-Host "A CsWebServiceConfiguration does not exist for the $($IntFQDN) pool, Creating..." -ForegroundColor Yellow
    try{
        New-CsWebServiceConfiguration -Identity $IntFQDNWS -ErrorAction Stop | Out-Null
        Write-Host "A CsWebServiceConfiguration was successfully created for the $($IntFQDN) pool`n" -ForegroundColor Green
    }catch{
        Write-Error "An error occured while creating a new CsWebServiceConfiguration. The exception caught was $_ | Terminating the Script" -ErrorAction Stop
    }
}

try {
    Set-CsWebServiceConfiguration -MeetingUxUseCdn $True
    Set-CsWebServiceConfiguration -MeetingUxEnableTelemetry $False
    Set-CsWebServiceConfiguration -identity $IntFQDNWS -MeetingUxUseCdn $True
    Set-CsWebServiceConfiguration -identity $IntFQDNWS -MeetingUxEnableTelemetry $False
    Set-CsWebServiceConfiguration -identity $IntFQDNWS -JoinLauncherCdnConfigUri $JLCCU
    Set-CsWebServiceConfiguration -identity $IntFQDNWS -LWACdnConfigUri $LWACCU
    Write-Host "This Skype for Business Server is now set to use the Meeting Join CDN and is pointed it at the new local location`n" -ForegroundColor Green
}catch {
    Write-Error "Could not enable this Skype for Business Server to use the Meeting Join CDN and point it at the new local location. The exception caught was $_ | Terminating the Script" -ErrorAction Stop
}

#Updating IIS to allow Access-Control-Allow-Origin in the header since the URL is hosted on the source server
$IISRes = Read-Host "Would you like to allow Access-Control-Allow-Origin in the header since the URL is hosted on the source server in IIS (If you have ran this script once, Enter N or press enter as it will break) (Y/N)`n"
if ($IISRes -eq 'Y'){
    Write-Host "Updating IIS to allow Access-Control-Allow-Origin in the header since the URL is hosted on the source server !Ignore Errors on script runs past the first-time run!"
    cmd /c %windir%\System32\inetsrv\appcmd.exe set config "Skype for Business Server Internal Web Site/meet" -section:system.webServer/httpProtocol /+"customHeaders.[name='Access-Control-Allow-Origin',value='*']"
    cmd /c %windir%\System32\inetsrv\appcmd.exe set config "Skype for Business Server External Web Site/meet" -section:system.webServer/httpProtocol /+"customHeaders.[name='Access-Control-Allow-Origin',value='*']"
    Write-Host "IIS updated to allow Access-Control-Allow-Origin in the header`n" -ForegroundColor Green
}else{
    Write-Host "Skipping Updating IIS`n" -ForegroundColor Yellow
}

Write-Host "Process Complete" -ForegroundColor Green

#Revert Change
#Set-CsWebServiceConfiguration -MeetingUxUseCdn $True
#Set-CsWebServiceConfiguration -JoinLauncherCdnConfigUri "https://meetings.sfbassets.com/joinux/prod/config.json"
#Set-CsWebServiceConfiguration -LWACdnConfigUri "https://meetings.sfbassets.com/lwa/prod/onprem/W16/config.js"
