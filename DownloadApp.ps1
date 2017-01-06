Function LogWrite {
    <#
    .SYNOPSIS
    Adds a line to log file.
    .DESCRIPTION
    This function can be used everywhere in the script to make a log entry in a logfile.
	.PARAMETER logfile
	The location where the logfile is located or will be created
	.PARAMETER logstring
	The text that is added to the end of the log file
    .EXAMPLE
    LogWrite -logfile "c:\temp\test.log" -logstring "`nlogentrycreated"
    .NOTES
    This is an internal script function and should typically not be called directly.
    .LINK
    #>
   Param ([string]$logfile,[string]$logstring)
        Add-content $logfile -value $logstring
}

Function Copy-ItemWithProgress {
<#
.SYNOPSIS
RoboCopy with PowerShell progress.

.DESCRIPTION
Performs file copy with RoboCopy. Output from RoboCopy is captured,
parsed, and returned as Powershell native status and progress.

.PARAMETER RobocopyArgs
List of arguments passed directly to Robocopy.
Must not conflict with defaults: /ndl /TEE /Bytes /NC /nfl /Log

.OUTPUTS
Returns an object with the status of final copy.
REMINDER: Any error level below 8 can be considered a success by RoboCopy.

.EXAMPLE
C:\PS> .\Copy-ItemWithProgress c:\Src d:\Dest

Copy the contents of the c:\Src directory to a directory d:\Dest
Without the /e or /mir switch, only files from the root of c:\src are copied.

.EXAMPLE
C:\PS> .\Copy-ItemWithProgress '"c:\Src Files"' d:\Dest /mir /xf *.log -Verbose

Copy the contents of the 'c:\Name with Space' directory to a directory d:\Dest
/mir and /XF parameters are passed to robocopy, and script is run verbose

.LINK
https://keithga.wordpress.com/2014/06/23/copy-itemwithprogress

.NOTES
By Keith S. Garner (KeithGa@KeithGa.com) - 6/23/2014
With inspiration by Trevor Sullivan @pcgeek86

#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true,ValueFromRemainingArguments=$true)] 
	[string[]] $RobocopyArgs
)

$ScanLog  = "c:\temp\scanlog.txt"
$RoboLog  = "c:\temp\robolog.txt"
$ScanArgs = $RobocopyArgs + "/ndl /TEE /bytes /Log:$ScanLog /nfl /L".Split(" ")
$RoboArgs = $RobocopyArgs + "/ndl /TEE /bytes /Log:$RoboLog /NC".Split(" ")

# Launch Robocopy Processes
write-verbose ("Robocopy Scan:`n" + ($ScanArgs -join " "))
write-verbose ("Robocopy Full:`n" + ($RoboArgs -join " "))
$ScanRun = start-process C:\windows\system32\robocopy.exe -PassThru -WindowStyle Hidden -ArgumentList $ScanArgs
$RoboRun = start-process C:\windows\system32\robocopy.exe -PassThru -WindowStyle Hidden -ArgumentList $RoboArgs

# Parse Robocopy "Scan" pass
$ScanRun.WaitForExit()
$LogData = get-content $ScanLog
if ($ScanRun.ExitCode -ge 8)
{
	$LogData|out-string|Write-Error
	throw "Robocopy $($ScanRun.ExitCode)"
}
#$FileSize = [regex]::Match($LogData[-4],".+:\s+(\d+)\s+(\d+)").Groups[2].Value
# write-verbose ("Robocopy Bytes: $FileSize `n" +($LogData -join "`n"))

<# Monitor Full RoboCopy
while (!$RoboRun.HasExited)
{
	$LogData = get-content $RoboLog
	$Files = $LogData -match "^\s*(\d+)\s+(\S+)"
    $Percs = $logData -match "(.+?)%"
    if ($Files -ne $Null )
    {
	    #start-sleep -Seconds 2
        $copied = ($Files[0..($Files.Length-2)] | %{$_.Split("`t")[-2]} | Measure -sum).Sum
	    if ($LogData[-1] -match "(100|\d?\d\.\d)\%")
	    {
		    #write-progress Copy -ParentID $RoboRun.ID -percentComplete $LogData[-1].Trim("% `t") $LogData[-1]
            LogWrite -logfile $logfile -logstring $LogData[-1].Trim("% `t") $LogData[-1]
		    $Copied += $Files[-1].Split("`t")[-2] /100 * ($LogData[-1].Trim("% `t"))
	    }
	    else
	    {
		    # logWrite -logfile $logfile -logstring "Complete"
	    }
	   LogWrite -logfile $logfile -logstring ($Copied/$FileSize*100) $Files[-1].Split("`t")[-1]
       
    }
}
#>
while (!$RoboRun.HasExited)
{
 # do nothing
}
# Parse full RoboCopy pass results, and cleanup
(get-content $RoboLog)[-11..-2] | out-string | Write-Verbose
[PSCustomObject]@{ ExitCode = $RoboRun.ExitCode }
remove-item $RoboLog, $ScanLog
exit 0
}

Function createBalloonNotification {
     <#
    .SYNOPSIS
    Create a balloon notification
    .DESCRIPTION
    ""
    .EXAMPLE
    createBalloonNotification -BalloonTipIcon "Info" -BalloonTipText "De software wordt gedownload naar uw pc" -BalloonTipTitle "Software Download"
    .NOTES
    This is an internal script function and should typically not be called directly.
    .LINK
    #>
	param (
	 [parameter(Mandatory=$true)]
	 [ValidateNotNullOrEmpty()]$BalloonTipIcon,
	 [parameter(Mandatory=$true)]
	 [ValidateNotNullOrEmpty()]$BalloonTipText,
	 [parameter(Mandatory=$true)]
	 [ValidateNotNullOrEmpty()]$BalloonTipTitle
	)

    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

    $objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon 

    $objNotifyIcon.Icon = [System.Drawing.SystemIcons]::Information
    $objNotifyIcon.BalloonTipIcon = $BalloonTipIcon
    $objNotifyIcon.BalloonTipText = $BalloonTipText 
    $objNotifyIcon.BalloonTipTitle = $BalloonTipTitle
 
    $objNotifyIcon.Visible = $True 
    $objNotifyIcon.ShowBalloonTip(100000)
}

Function Set-Owner {
  Param ([parameter(Mandatory=$true)]
		 [ValidateNotNullOrEmpty()]$fldpath,
		 [parameter(Mandatory=$true)]
		 [ValidateNotNullOrEmpty()]$owner)
  $objAdmins               = New-Object System.Security.Principal.NTAccount($owner)
  $acl                     = (Get-Item $fldpath).GetAccessControl("Access") 
  $acl_isprotected         = $False
  $acl_preserveinheritance = $True
  $acl.SetAccessRuleProtection($acl_isprotected, $acl_preserveinheritance)
  if($owner) {$acl.SetOwner($objAdmins)}
  $run                     = Set-Acl -Path $fldpath -AclObject $acl
    

}

Function Set-Permissions {
  Param ([parameter(Mandatory=$true)]
		 [ValidateNotNullOrEmpty()]$fldpath,
		 [parameter(Mandatory=$true)]
		 [ValidateNotNullOrEmpty()]$right,
		 [parameter(Mandatory=$true)]
		 [ValidateNotNullOrEmpty()]$group)

  $acl                     = (Get-Item $fldpath).GetAccessControl("Access") 
  $acl_isprotected         = $False
  $acl_preserveinheritance = $True
  $acl.SetAccessRuleProtection($acl_isprotected, $acl_preserveinheritance)
  $rule                    = New-Object System.Security.AccessControl.FileSystemAccessRule($group,$right,"ContainerInherit, ObjectInherit", "None", "Allow")
  $add    = $acl.AddAccessRule($rule)
  $run                     = Set-Acl -Path $fldpath -AclObject $acl
}

Function Remove-Permissions {
  Param ([parameter(Mandatory=$true)]
		 [ValidateNotNullOrEmpty()]$fldpath,
		 [parameter(Mandatory=$true)]
		 [ValidateNotNullOrEmpty()]$right,
		 [parameter(Mandatory=$true)]
		 [ValidateNotNullOrEmpty()]$group)

  $acl                     = (Get-Item $fldpath).GetAccessControl("Access") 
  $acl_isprotected         = $False
  $acl_preserveinheritance = $True
  $acl.SetAccessRuleProtection($acl_isprotected, $acl_preserveinheritance)
  $rule                    = New-Object System.Security.AccessControl.FileSystemAccessRule($group,$right,"ContainerInherit, ObjectInherit", "None", "Allow")
  $remove = $acl.RemoveAccessRule($rule)
  $run                     = Set-Acl -Path $fldpath -AclObject $acl
}

Function CreateDir {
	Param ([string]$fldpath)
	
	If (!(Test-Path $fldpath))
	{
		$create = New-Item $fldpath -Type Directory -Force
	}
}

$error.clear() # clear error variable
$logfile                   = $env:SystemDrive + "\temp\ThinAppDownload.log" 
#$loggedOnUser          = (Get-wmiObject -class Win32_ComputerSystem).username
#$username              = $loggedOnUser.Substring( $loggedOnUser.length -7, 7)
$myDate                    = Get-date -Format "dd-MM-yyyy"
#$appName               = get-content ($env:SystemDrive + "\temp\apps.txt")
#$executableName        = "start.exe"
#$from                  = $env:ThinAppStoreUNC + "\" + $appname
#$from                  = "\\umcn.nl\apps\thinapp" + "\" + $appname
#$from                  = "C:\temp"
#$localPath             = $env:ThinAppStore + "\" + $appname
#$startmenu             = $env:startmenu
#$linkLocation              = "Ziekenhuis Informatie Systemen"
#$linkName                  = "Rotem viewer"
[xml]$xdoc                  = Get-Content "c:\temp\APPLDLG.xml"
$appNames                   = (Get-Content ($env:SystemDrive + "\temp\apps.txt"))
if ($appNames.count -gt 1) {$appNames           = (Get-Content ($env:SystemDrive + "\temp\apps.txt"))[-1]}

Foreach ($appName in $appNames) {
    LogWrite -logfile $logfile -logstring "`nlogentrycreated on $($myDate).`nApplication:$($appName)"
    $xAppNode              = $xdoc.SelectSingleNode("//$($appname)") ; LogWrite -logfile $logfile -logstring "`nAppNode:$($xAppNode)"
    $xLinksCollection      = $xdoc.SelectNodes("//$($appname)/Links"); LogWrite -logfile $logfile -logstring "`nLinks:$($xLinksCollection)"
    $from                  = ($xAppNode.Path) + "\" + $appName ; LogWrite -logfile $logfile -logstring "`nSource:$($from)"
    
    If (Test-Path $from) {
        
        # 1. Create local folder
        $localPath                  = "c:\thinapp" + "\" + $appName ; LogWrite -logfile $logfile -logstring "`nLocal install path:$($localPath)"
        if (!(Test-Path $localPath)) {CreateDir -fldpath $localPath}
        # 2. Set the owner
        if (!(Test-Path $localPath)) {Set-owner -owner "Administrators" -fldpath $localPath}
        # 3. Set ReadAndExecute Permissions   to the application security group
        Set-Permissions -group "APPLDLG_$($appname)" -right "ReadAndExecute" -fldpath $localPath
        # Set-Permissions -group "umcn\z165211" -right "ReadAndExecute" -fldpath $localPath
        # 4. Start Copy

    } #end if

    Get-ChildItem $localPath -Include * | Remove-Item -Recurse
    Copy-ItemWithProgress "$($from) $($localPath) /E /R:1 /W:1 "
    
} #end foreach