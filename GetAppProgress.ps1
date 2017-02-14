	param (
	 #[parameter(Mandatory=$true)]
	 [ValidateNotNullOrEmpty()]$appname,
     #[parameter(Mandatory=$true)]
	 [ValidateNotNullOrEmpty()]$exe
	)

$scriptPath            = split-path -parent $MyInvocation.MyCommand.Definition # Get the path where the script is executed from 
$logfile               = $env:SystemDrive + "\temp\ThinAppDownload.log" # the location where the logfile is created   

try {
    Import-Module "$($scriptPath)\modules\logfile.psm1" -ErrorAction stop
    Import-Module "$($scriptPath)\modules\console.psm1" -ErrorAction stop
}
catch {
    $errorMessage = $_.Exception.message
    $errorItem    = $_.Exception.ItemName
    LogWrite -logfile $logfile -logstring "`nThe following imports failed:$($errorItem)`n with the following error:`n$($errorMessage)"
    exit 0
}

LogWrite -logfile $logfile -logstring "`nThe scriptpath:`n$($scriptPath)`nThe logfileh:`n$($logfile)"

# If Mandatory variables are somehow not filled the exit the script
if (!($Appname) -or !($exe)) { LogWrite -logfile $logfile -logstring "`nScript stoped. No appname or exe in Shortcut" ; exit 0}

# Force the console window hidden
Try {
    Hide-Console 
    LogWrite -logfile $logfile -logstring "`nThe following action is executed:Hide-Console"
}
catch {
    $errorMessage = $_.Exception.message
    $errorItem    = $_.Exception.ItemName
    LogWrite -logfile $logfile -logstring "`nThe following action failed:$($errorItem)`n with the following error:`n$($errorMessage)"
}

# build a form
Add-Type -assembly System.Windows.Forms
    LogWrite -logfile $logfile -logstring "`nThe following action is executed:Building the user form"
    #title for the winform
    $Title = "Download $($appName)"
    #winform dimensions
    $height=120
    $width=600
    #winform background color
    $color = "White"

    #create the form
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")  
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    [void] [System.Windows.Forms.Application]::EnableVisualStyles() 
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
    $label1.Text = "Deze applicatie is nog niet aanwezig. Voorbereiden om te starten"
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
    LogWrite -logfile $logfile -logstring "`nThe following action is executed:Show the form on the users desktop."
    #give the form focus
    $form1.Focus() | out-null
     #update the form
    $label1.Text = "kopieeren van $($appName) voorbereiden, een moment aub...."
    $form1.Refresh()
	
# test if you are connected to the domain	
if (Test-Connection umcn.nl -Quiet) {
    LogWrite -logfile $logfile -logstring "`nThe Computer is connected to the domain."
    start-sleep -Seconds 1

    $appfile               = $env:SystemDrive + "\temp\apps.txt" # transport application to SVC account 
    $RoboLog               = "c:\temp\$($appname)_robolog.txt"
    $localPath             = "c:\thinapp" + "\" + $appname
    $startmenu             = $env:startmenu
    [xml]$xdoc             = Get-Content "c:\thinapp\source\APPLDLG.xml"
    $xAppNode              = $xdoc.SelectSingleNode("//$($appname)")
    $xLinksCollection      = $xdoc.SelectNodes("//$($appname)/Links")
    $from                  = ($xAppNode.Path) + "\" + $appName

    Foreach($link in $xLinksCollection){
        $linkPath = ($startmenu + "\" + $link.linklocation + "\" + $link.LinkName+ ".lnk")
        if(Test-Path $linkPath) {remove-item $linkPath}
        LogWrite -logfile $logfile -logstring "`nRemoved the link $($link) to Path $($linkPath)."
    } # end foreach

    If (!(Test-Path $appfile)) {
        # parse the application name 
        LogWrite -logfile $appfile -logstring "$($appName)"
    }
    else
    {
        LogWrite -logfile $appfile -logstring "`n$($appName)"
    } # end if
    Start-Sleep -Milliseconds 200
    LogWrite -logfile $logfile -logstring "`nThe following action is executed:Refeshnow."
    Start-Process -FilePath ($env:ProgramFiles + "\Appsense\refreshnow.exe") -ArgumentList "-startdownload"

    $pct = 0
    $x   = 0
    while ((!($LogData)) -and ($x -lt 80))
    {
        $x++
        Start-Sleep -Milliseconds 200
        $LogData = get-content $RoboLog -ErrorAction SilentlyContinue
        LogWrite -logfile $logfile -logstring "`nWaiting for the Robocopy log to be created($($x))."
    } # end while
    
    # End if timeout occurred
    if ($x -ge 80) {
        LogWrite -logfile $logfile -logstring "`na timeout occurred while waiting for robocopy to begin. Execution stopped!"
        Remove-item $appfile
        LogWrite -logfile $logfile -logstring "`nDeleting the AppFile."
        exit 0
    } 
    
    LogWrite -logfile $logfile -logstring "`nThe Robocopy log is created."
    
    while ($LogData)
    {
    	
        $LogData = get-content $RoboLog
    	$Files = $LogData -match "^\s*(\d+)\s+(\S+)"
        $Percs = $logData -match "(.+?)%"
        $LastFile = (($Files[-1]).split("`t")[-1].split('\')[-1])
        [decimal]$lastPerc = $Percs[-1] -replace '[^0-9.]'
        LogWrite -logfile $logfile -logstring "`nReading the Robocopy log. File $($LastFile) is being copied. ($($lastPerc) %)"
        $label1.Text = "Kopieren van: $($lastFile)"
        $label2.Text = "$($lastPerc) %"
        $progressbar1.Value = $lastPerc
        Start-Sleep -Milliseconds 100
        $form1.Refresh()
    } # end while
     
    $label1.Text = "Aanmaken nieuwe snelkoppelingen."
    Start-Sleep -Milliseconds 100
    $form1.Refresh()
    

    Remove-item $appfile
    LogWrite -logfile $logfile -logstring "`nDeleting the AppFile."
    
    Foreach($link in $xLinksCollection){
        $linkPath = ($startmenu + "\" + $link.Linklocation + "\" + $link.LinkName + ".lnk")
        LogWrite -logfile $logfile -logstring "`nCreate shortcut: $($linkPath)"
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($linkPath)
        $targetPath = ($localPath  + "\" + $link.Executable)
        $Shortcut.TargetPath = $targetPath
        $Shortcut.Arguments = $link.Arguments
        $Shortcut.Save()
        LogWrite -logfile $logfile -logstring "`nCreated the link $($linkPath) to $($targetPath)."
    } # end foreach
    
    # start the application that was selected
    $label1.Text = "Starten van $($link.LinkName). Een momentje geduld aub"
    LogWrite -logfile $logfile -logstring "`nStarten van $($link.LinkName)."
    $form1.Refresh()
	Start-sleep -seconds 2
    $thisProcess = start-process ($localPath  + "\" + $exe)

} # end if test-connection

    Start-Sleep -Milliseconds 200
    $form1.Refresh()
    $form1.Close()
    LogWrite -logfile $logfile -logstring "`nUser from closed."
    LogWrite -logfile $logfile -logstring "__________________Finished________________________"
# SIG # Begin signature block
# MIINKAYJKoZIhvcNAQcCoIINGTCCDRUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhqz5mZSSf8y66wK1iH7NyrE3
# AoagggpvMIIFGTCCBAGgAwIBAgIQDbnGEbOq/3RgewIGXryqxTANBgkqhkiG9w0B
# AQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMTQxMTE4MTIwMDAwWhcNMjQxMTE4MTIwMDAwWjBtMQsw
# CQYDVQQGEwJOTDEWMBQGA1UECBMNTm9vcmQtSG9sbGFuZDESMBAGA1UEBxMJQW1z
# dGVyZGFtMQ8wDQYDVQQKEwZURVJFTkExITAfBgNVBAMTGFRFUkVOQSBDb2RlIFNp
# Z25pbmcgQ0EgMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKri5yAv
# rBCV+s0k5fig3/WirZ+8s8nh+B/EPuSWQW275wPwDBRxvaY4UbdQOac59kJt4lzE
# nv+reNW9ZwMh6W4EzEbfxYcklJ/91iwFYYOTsvXhd2QqutVQ87bab9CLvH8+awDu
# XLM0v1DA+MjwfVd+dApIr21ITItvil4jvnbLXYR4VjuIZ5vRiGCiCEQHiImmw/Lc
# KuBzbMKbhCb3FD6LSqhpCPSTiegfaeu0KnUyCxmPfLMMuFrkRrRka8fQUJvwgLRP
# NXGfIH9ZyFRm7M0zE98JMoUQAmFoPLSSJGC6oNK8tccHvfxQ6jRgCB8CoY8ftyz9
# WqZJgLk5+llJ+RkCAwEAAaOCAbswggG3MBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYD
# VR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0w
# azAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUF
# BzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVk
# SURSb290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRw
# Oi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3Js
# MD0GA1UdIAQ2MDQwMgYEVR0gADAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5k
# aWdpY2VydC5jb20vQ1BTMB0GA1UdDgQWBBQyCsEMwWg+V6gt+Xki5Y6c6USOMjAf
# BgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOC
# AQEARK1QChmvA+HzpJ7KM8s0RJW06t34uUi15WqZw7cBjq7VxHMefVoI/Rm/IEzF
# AbvIstsQydkrDd3OcTzcW665Z0vvvbBEmLhhKdyoenOyFL10PzBcw3nADPRW3LP+
# 4Yl4RaWH6Fkoj0SLbQY/sTbEMO50bFTLxAPXb3ga42xDdhVGniJJWZdNON4bTNJ8
# lhv8utfpehgwFyzVhoku0JoZPjXyxiu+UUlnSR1lIa9CIk4NTQ8aAumbgnbn/Iqw
# e3VWTeo/kA+KJwRVMBN6U6H+9l6i9kk5VF8DyYtqNc4wqALgQBXtFZUQHQZj7++N
# o5rhwVpgmjGEl7nwi5AqasvHIjCCBU4wggQ2oAMCAQICEAw5qb9loAcuUV4tl0kn
# L2cwDQYJKoZIhvcNAQELBQAwbTELMAkGA1UEBhMCTkwxFjAUBgNVBAgTDU5vb3Jk
# LUhvbGxhbmQxEjAQBgNVBAcTCUFtc3RlcmRhbTEPMA0GA1UEChMGVEVSRU5BMSEw
# HwYDVQQDExhURVJFTkEgQ29kZSBTaWduaW5nIENBIDMwHhcNMTcwMTE3MDAwMDAw
# WhcNMjAwMTIxMTIwMDAwWjCBmjELMAkGA1UEBhMCTkwxEzARBgNVBAgTCkdlbGRl
# cmxhbmQxETAPBgNVBAcTCE5pam1lZ2VuMRMwEQYDVQQKEwpSYWRib3VkdW1jMQsw
# CQYDVQQLEwJJTTETMBEGA1UEAxMKUmFkYm91ZHVtYzEsMCoGCSqGSIb3DQEJARYd
# dGVhbXdlcmtwbGVrLmltQHJhZGJvdWR1bWMubmwwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCrrExnfSfby1C9NYte4mnQMs8VleGWvIToQclMkV3LyeU6
# OscCovVHEPaGXPBt4qTVDErpKHDJ98oUQNHwcHJYv1v8Bqw3bEW5t5WsFCyWwE9I
# JE1wECvZj9hx7V0tjnvrQxIBfJ5La3CByl+vgsRIJQRNig3ypunDH/37gfGRewzA
# Z6AeakMbuFn6Fp4atg7xlB4SSy8WfzDqanVTte5ejw+7fKu4eOuJcBsQqVl2PnRe
# DI/nQv6gwvOjsJxngFEyfZqsPzH6N41/zYPYDCpB8FC0MYUokNplOqmgIB8HHcVH
# YmyjuGlPA+0/8CsXnk3h33Rq8iaoQomNx357J6BjAgMBAAGjggG6MIIBtjAfBgNV
# HSMEGDAWgBQyCsEMwWg+V6gt+Xki5Y6c6USOMjAdBgNVHQ4EFgQUsnnXRAhWobGt
# rHDmwXi+EpM5ckgwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MHsGA1UdHwR0MHIwN6A1oDOGMWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9URVJF
# TkFDb2RlU2lnbmluZ0NBMy5jcmwwN6A1oDOGMWh0dHA6Ly9jcmw0LmRpZ2ljZXJ0
# LmNvbS9URVJFTkFDb2RlU2lnbmluZ0NBMy5jcmwwTAYDVR0gBEUwQzA3BglghkgB
# hv1sAwEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQ
# UzAIBgZngQwBBAEwdgYIKwYBBQUHAQEEajBoMCQGCCsGAQUFBzABhhhodHRwOi8v
# b2NzcC5kaWdpY2VydC5jb20wQAYIKwYBBQUHMAKGNGh0dHA6Ly9jYWNlcnRzLmRp
# Z2ljZXJ0LmNvbS9URVJFTkFDb2RlU2lnbmluZ0NBMy5jcnQwDAYDVR0TAQH/BAIw
# ADANBgkqhkiG9w0BAQsFAAOCAQEAX51AMgsM7HWtQ1zE2689Li0x/iVpbA0tJV0Y
# 1iOv5Vn8BJBE2V14bI8LPreHpinw0nqgV9oIDh6fPSKT+5W/+dRponhw523bkgzD
# LjeZhC+hxZKfZ1v4Wq9gkHvvgowDyw3sOdA6PS5QA3vbLbrLLJSrP35QtRsRgx4h
# DzTnswJA5VTC/3fb74fsLPvNBMvQ+lQjoZIrgOPaceHSAuqcpzM7rnSkZd1kCVto
# O+FJD4dYhi/ijeMVIXpbHLwNS+Rd50zmaTb9/adywJul+pdsIyRQX8WB83di2vjD
# gOu8cyXL4yo+XlD1oJNSBsKhoyFxOVZ2TWWaU39h/WnRiWT48zGCAiMwggIfAgEB
# MIGBMG0xCzAJBgNVBAYTAk5MMRYwFAYDVQQIEw1Ob29yZC1Ib2xsYW5kMRIwEAYD
# VQQHEwlBbXN0ZXJkYW0xDzANBgNVBAoTBlRFUkVOQTEhMB8GA1UEAxMYVEVSRU5B
# IENvZGUgU2lnbmluZyBDQSAzAhAMOam/ZaAHLlFeLZdJJy9nMAkGBSsOAwIaBQCg
# eDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEE
# AYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJ
# BDEWBBQ7hUpUdINXt2pF0EZQlz6UmSCBMTANBgkqhkiG9w0BAQEFAASCAQAcjvSg
# 6vLCfqTvWRs0ryIYNRcUb7eNCwb80GvpRBLM3p7J38OGGOMk2nD7Og6he3Lx0lZM
# myf13u+rANseWRI/bpLdTbUZof6+t2f+8Ii7b1s1m94Lw5fyCEM2vxY9BwWLKvZC
# 9l3AxhAphBFOlx9hum3M3n092hJR4B+dgDo7QSgfk4aKfZe2P5HFC4cywZRDqITX
# X9JiicXai39ElcUEIEe1A4/YepTf9O8GAgQW+toI4p7gQGV2ioYZ+lXTqJNekFu4
# N4hpKCzeYhga+hpRyToEf6rAthnZdQLMJfDPqbSQgtmkbVw38Qi6NmYQDei8w2rG
# 9hwAcPP7cpGxlxow
# SIG # End signature block
