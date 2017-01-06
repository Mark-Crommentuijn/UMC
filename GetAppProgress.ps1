	param (
	 #[parameter(Mandatory=$true)]
	 [ValidateNotNullOrEmpty()]$appname,
     #[parameter(Mandatory=$true)]
	 [ValidateNotNullOrEmpty()]$exe
	)
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
 
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
 
function Show-Console {
   $consolePtr = [Console.Window]::GetConsoleWindow()
  #5 show
 [Console.Window]::ShowWindow($consolePtr, 5)
}
 
function Hide-Console {
    $consolePtr = [Console.Window]::GetConsoleWindow()
  #0 hide
 [Console.Window]::ShowWindow($consolePtr, 0)
}

Hide-Console

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


    Add-Type -assembly System.Windows.Forms

    #title for the winform
    $Title = "Download $($appName)"
    #winform dimensions
    $height=120
    $width=600
    #winform background color
    $color = "White"

    #create the form
    $form1 = New-Object System.Windows.Forms.Form
    $form1.Text = $title
    $form1.Height = $height
    $form1.Width = $width
    $form1.BackColor = $color

    $form1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle 
    #display center screen
    $form1.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    # create label
    $label1 = New-Object system.Windows.Forms.Label
    $label1.Text = "Voorbereiden om te starten"
    $label1.Left=5
    $label1.Top= 10
    $label1.Width= $width - 20
    #adjusted height to accommodate progress bar
    $label1.Height=20
    $label1.Font= "Verdana"
    #optional to show border 
    #$label1.BorderStyle=1
    $form1.controls.add($label1)

    # create label
    $label2 = New-Object system.Windows.Forms.Label
    $label2.Text = "0 %"
    $label2.Left=5
    $label2.Top= 40
    $label2.Width= 60
    #adjusted height to accommodate progress bar
    $label2.Height=20
    $label2.Font= "Verdana"
    #$label2.BorderStyle=1
    #add the label to the form
    $form1.controls.add($label2)

    $progressBar1 = New-Object System.Windows.Forms.ProgressBar
    $progressBar1.Name = 'progressBar1'
    $progressBar1.Value = 0
    $progressBar1.Style="Continuous"

    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Width = $width - 80
    $System_Drawing_Size.Height = 20
    $progressBar1.Size = $System_Drawing_Size

    $progressBar1.Left = 65
    $progressBar1.Top = 40
    $form1.Controls.Add($progressBar1)

    $form1.Show()| out-null

    #give the form focus
    $form1.Focus() | out-null
     #update the form
    $label1.Text = "Preparing to copy $($appName)"
    $form1.Refresh()
if (Test-Connection umcn.nl -Quiet) {

    start-sleep -Seconds 1

    $logfile               = $env:SystemDrive + "\temp\apps.txt" 
    $RoboLog               = "c:\temp\robolog.txt"
    #$localPath             = $env:ThinAppStore + "\" + $appname
    $localPath             = "c:\thinapp" + "\" + $appname
    $startmenu             = $env:startmenu
    [xml]$xdoc             = Get-Content "c:\temp\APPLDLG.xml"
    $xAppNode              = $xdoc.SelectSingleNode("//$($appname)")
    $xLinksCollection      = $xdoc.SelectNodes("//$($appname)/Links")
    $from                  = ($xAppNode.Path) + "\" + $appName

    Foreach($link in $xLinksCollection){
        $linkPath = ($startmenu + "\" + $link.linklocation + "\" + $link.LinkName+ ".lnk")
        if(Test-Path $linkPath) {remove-item $linkPath}
    } # end foreach

    If (!(Test-Path $logfile)) {
        LogWrite -logfile $logfile -logstring $appName
    }
    else
    {
        LogWrite -logfile $logfile -logstring "`n$($appName)"
    } # end if
    Start-Sleep -Milliseconds 200
    Start-Process -FilePath ($env:ProgramFiles + "\Appsense\refreshnow.exe") -ArgumentList "-startdownload"

    $pct = 0
    while (!$LogData)
    {
        Start-Sleep -Milliseconds 100
        $LogData = get-content $RoboLog
    } # end while
    
    while ($LogData)
    {
    	$LogData = get-content $RoboLog
    	$Files = $LogData -match "^\s*(\d+)\s+(\S+)"
        $Percs = $logData -match "(.+?)%"
        $LastFile = (($Files[-1]).split("`t")[-1].split('\')[-1])
        [decimal]$lastPerc = $Percs[-1] -replace '[^0-9.]'
        $label1.Text = "Kopieren van: $($lastFile)"
        $label2.Text = "$($lastPerc) %"
        $progressbar1.Value = $lastPerc
        Start-Sleep -Milliseconds 200
        $form1.Refresh()
    } # end while
     
    $label1.Text = "Aanmaken nieuwe snelkoppelingen."
    Start-Sleep -Milliseconds 200
    $form1.Refresh()
    

    Remove-item $logfile
    Foreach($link in $xLinksCollection){
        $linkPath = ($startmenu + "\" + $link.Linklocation + "\" + $link.LinkName + ".lnk")
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($linkPath)
        $Shortcut.TargetPath = ($localPath  + "\" + $link.Executable)
        $Shortcut.Arguments = $link.Arguments
        $Shortcut.Save()
    } # end foreach
    
    # start the application that was selected
    $label1.Text = "Starten van $($link.LinkName). Een momentje geduld aub"
    $thisProcess = start-process ($localPath  + "\" + $exe)
    Start-Sleep -Milliseconds 200
    $form1.Refresh()
    $form1.Close()
} # end if test-connection