<#
 Script created by Mark Crommentuijn
 
 This script downloads a thinapp package is that a user initiates through a link.
 12-15-2016 Created
 1-11-2017  POC approved
 
#>

# Script variables
$scriptPath                 = split-path -parent $MyInvocation.MyCommand.Definition # Get the path where the script is executed from
$error.clear()                # clear error variable
$logfile                    = $env:SystemDrive + "\temp\ThinAppDownload.log" # the location where the logfile is created
$myDate                     = Get-date -Format "dd-MM-yyyy" # Get the current data



try {
# Read the contents of the text files.    
    [xml]$xdoc                  = Get-Content "$($scriptPath)\APPLDLG.xml" # Read te XML defenition file
    $appNames                   = (Get-Content ($env:SystemDrive + "\temp\apps.txt")) # The apps that need to be copied. created by the user script
    if ($appNames.count -gt 1) {$appNames = (Get-Content ($env:SystemDrive + "\temp\apps.txt"))[-1]}
}
catch {
    $errorMessage = $_.Exception.message
    $errorItem    = $_.Exception.ItemName
    LogWrite -logfile $logfile -logstring "`nThe following error occurred:$($errorItem)`n with the following error message:`n$($errorMessage)"
}

# Import modules
try {
    Import-Module "$($scriptPath)\modules\logfile.psm1" -ErrorAction stop
    Import-Module "$($scriptPath)\modules\robocopy.psm1" -ErrorAction stop
    Import-Module "$($scriptPath)\modules\rights.psm1" -ErrorAction stop
    Import-Module "$($scriptPath)\modules\filesystem.psm1" -ErrorAction stop
}
catch {
    $errorMessage = $_.Exception.message
    $errorItem    = $_.Exception.ItemName
    LogWrite -logfile $logfile -logstring "`nThe following imports failed:$($errorItem)`n with the following error:`n$($errorMessage)"
}

# create first log entry After imports
LogWrite -logfile $logfile -logstring "`nlogentrycreated on $($myDate).`nScript executed from:$($scriptPath)"
    
Foreach ($appName in $appNames) {
    LogWrite -logfile $logfile -logstring "`nApplication: $($appName)"
    $xAppNode               = $xdoc.SelectSingleNode("//$($appname)") ; LogWrite -logfile $logfile -logstring "`nAppNode: $($xAppNode.outerXml)"
    $xLinksCollection       = $xdoc.SelectNodes("//$($appname)/Links"); LogWrite -logfile $logfile -logstring "`nLinks: $($xLinksCollection.outerXml)"
    $from                   = ($xAppNode.Path) + "\" + $appName ; LogWrite -logfile $logfile -logstring "`nSource: $($from)"
    
    If (Test-Path $from) {      
        # 1. Create local folder
        $localPath          = "c:\thinapp" + "\" + $appName ; LogWrite -logfile $logfile -logstring "`nLocal install path: $($localPath)"
        if (!(Test-Path $localPath)) {CreateDir -fldpath $localPath;LogWrite -logfile $logfile -logstring "`nDirectory $($localPath) created."}
        # 2. Set the owner
        if (!(Test-Path $localPath)) {Set-owner -owner "Administrators" -fldpath $localPath ; LogWrite -logfile $logfile -logstring "`nThe owner is set to Administrator."}
        # 3. Set ReadAndExecute Permissions on the folder for the application security group
        Add-Permissions -group "APPLDLG_$($appname)" -right "ReadAndExecute" -fldpath $localPath ; LogWrite -logfile $logfile -logstring "`nRead and execute rights are set for APPLDLG_$($appname)."
        

    } #end if
    # 4. Start Copy
    Get-ChildItem $localPath -Include * | Remove-Item -Recurse
    Copy-ItemWithProgress "$($from) $($localPath) /E /R:1 /W:1 " -appname $appName
    
} #end foreach
# SIG # Begin signature block
# MIINKAYJKoZIhvcNAQcCoIINGTCCDRUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQynsdzu86ku9PPe70WWWXFw0
# 3HGgggpvMIIFGTCCBAGgAwIBAgIQDbnGEbOq/3RgewIGXryqxTANBgkqhkiG9w0B
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
# BDEWBBRlDzl2daEG3glLbNdbHS9ObeDmAjANBgkqhkiG9w0BAQEFAASCAQA5peDc
# WXeoxddqh1VjjIjQT0S2J3DvOpWyz7x4xyP322QGax/PXijTWIb49Ou/+snlNxhg
# PPri7om7HcAwEWYi3fKVTfqD5/DTaLiPVV/Itz9/37yWaJz+0pw5Q3iyNiHimkbV
# r5Ovd/2KUqRiiCPfe8V9QhGinAa+vI1Mj3WFm9lW1TbHX/iyEKvvM/WpfT6cN++k
# r5vgHu2YFszopqPuDKAOf4xQLkIBQkxhq/kKPFRbiFiT5AYC7T7Le5urR+pJ7leE
# s9yt/dZa3+nyyJv+krXsr4UF91DvF8N5zzNK/YmjMM/QdB38cZtd4lK4biRrDzef
# N3WrWrdmCKgE41Mf
# SIG # End signature block
