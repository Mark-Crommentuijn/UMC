<# 
 .Synopsis
  Functions for the files system

 .Description
  Functions to add or delete user permissions on a specified folder.
  There is also a function that sets the owner

 .Parameter fldpath
  The full path of the directory.

 .Parameter DateTime
  Files before this data will be deleted.

 .Switch DeletePathIfEmpty
  Specifies if all empty directories need to be deleted.
  
 .Switch OutputDeletedPaths
  Specify to output all paths.
  
 .Switch Whatif
  If specified the function will run in test mode.
  
 .Parameter OnlyDeleteDirectoriesCreatedBeforeDate
  Only directories created before this date will be deleted.
  
 .Parameter OnlyDeleteDirectoriesNotModifiedAfterDate
  Only directories that have not been modified after this date will be deleted.
  
 .Example
   # Delete all files created more than 2 days ago.
   Remove-FilesCreatedBeforeDate -fldPath "C:\Some\Directory" -DateTime ((Get-Date).AddDays(-2)) -DeletePathIfEmpty

 .Example
   # Delete all files that have not been updated in 8 hours.
   Remove-FilesNotModifiedAfterDate -fldPath "C:\Another\Directory" -DateTime ((Get-Date).AddHours(-8))

 .Example
   # Delete a single file if it is more than 30 minutes old.
   Remove-FilesCreatedBeforeDate -fldPath "C:\Another\Directory\SomeFile.txt" -DateTime ((Get-Date).AddMinutes(-30))
  
 .Example
   # Delete all empty directories in the Temp folder, as well as the Temp folder itself if it is empty.
    Remove-EmptyDirectories -fldPath "C:\SomePath\Temp" -DeletePathIfEmpty
    
 .Example
   # Delete all empty directories created after Jan 1, 2014 3PM.
   Remove-EmptyDirectories -fldPath "C:\SomePath\WithEmpty\Directories" -OnlyDeleteDirectoriesCreatedBeforeDate ([DateTime]::Parse("Jan 1, 2014 15:00:00"))
     
#>

Function CreateDir {
	Param ([string]$fldpath)
	
	If (!(Test-Path $fldpath))
	{
		$create = New-Item $fldpath -Type Directory -Force
	}
}

function Remove-EmptyDirectories([parameter(Mandatory)][ValidateScript({Test-Path $_})][string] $fldpath, [switch] $DeletePathIfEmpty, [DateTime] $OnlyDeleteDirectoriesCreatedBeforeDate = [DateTime]::MaxValue, [DateTime] $OnlyDeleteDirectoriesNotModifiedAfterDate = [DateTime]::MaxValue, [switch] $OutputDeletedPaths, [switch] $WhatIf)
{
    Get-ChildItem -Path $fldpath -Recurse -Force -Directory | Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -Force -File) -eq $null } | 
        Where-Object { $_.CreationTime -lt $OnlyDeleteDirectoriesCreatedBeforeDate -and $_.LastWriteTime -lt $OnlyDeleteDirectoriesNotModifiedAfterDate } | 
        ForEach-Object { if ($OutputDeletedPaths) { Write-Output $_.FullName } Remove-Item -Path $_.FullName -Force -WhatIf:$WhatIf }

    # If we should delete the given path when it is empty, and it is a directory, and it is empty, and it meets the date requirements, then delete it.
    if ($DeletePathIfEmpty -and (Test-Path -Path $fldpath -PathType Container) -and (Get-ChildItem -Path $fldpath -Force) -eq $null -and
        ((Get-Item $fldpath).CreationTime -lt $OnlyDeleteDirectoriesCreatedBeforeDate) -and ((Get-Item $fldpath).LastWriteTime -lt $OnlyDeleteDirectoriesNotModifiedAfterDate))
    { if ($OutputDeletedPaths) { Write-Output $fldpath } Remove-Item -Path $fldpath -Force -WhatIf:$WhatIf }
}

# Function to remove all files in the given Path that were created before the given date, as well as any empty directories that may be left behind.
function Remove-FilesCreatedBeforeDate([parameter(Mandatory)][ValidateScript({Test-Path $_})][string] $fldpath, [parameter(Mandatory)][DateTime] $DateTime, [switch] $DeletePathIfEmpty, [switch] $OutputDeletedPaths, [switch] $WhatIf)
{
    Get-ChildItem -Path $fldpath -Recurse -Force -File | Where-Object { $_.CreationTime -lt $DateTime } | 
		ForEach-Object { if ($OutputDeletedPaths) { Write-Output $_.FullName } Remove-Item -Path $_.FullName -Force -WhatIf:$WhatIf }
    Remove-EmptyDirectories -fldpath $fldpath -DeletePathIfEmpty:$DeletePathIfEmpty -OnlyDeleteDirectoriesCreatedBeforeDate $DateTime -OutputDeletedPaths:$OutputDeletedPaths -WhatIf:$WhatIf
}

# Function to remove all files in the given Path that have not been modified after the given date, as well as any empty directories that may be left behind.
function Remove-FilesNotModifiedAfterDate([parameter(Mandatory)][ValidateScript({Test-Path $_})][string] $fldpath, [parameter(Mandatory)][DateTime] $DateTime, [switch] $DeletePathIfEmpty, [switch] $OutputDeletedPaths, [switch] $WhatIf)
{
    Get-ChildItem -Path $fldpath -Recurse -Force -File | Where-Object { $_.LastWriteTime -lt $DateTime } | 
	ForEach-Object { if ($OutputDeletedPaths) { Write-Output $_.FullName } Remove-Item -Path $_.FullName -Force -WhatIf:$WhatIf }
    Remove-EmptyDirectories -fldPath $fldpath -DeletePathIfEmpty:$DeletePathIfEmpty -OnlyDeleteDirectoriesNotModifiedAfterDate $DateTime -OutputDeletedPaths:$OutputDeletedPaths -WhatIf:$WhatIf
}

# SIG # Begin signature block
# MIINKAYJKoZIhvcNAQcCoIINGTCCDRUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUp1GTW1b6bKphXPcAjPCSOUCJ
# 4fugggpvMIIFGTCCBAGgAwIBAgIQDbnGEbOq/3RgewIGXryqxTANBgkqhkiG9w0B
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
# BDEWBBR/Gv3Y1IJtosk8CWhzDj8JU+FYYjANBgkqhkiG9w0BAQEFAASCAQAi69tW
# CAO6/0qeIiPlCDSpDiNdTvkv52+SzIgLqYKONv3Unu53k1vDb7Yil5NbtVwxxfNH
# DhCdzea1uT4rGdNYXLBR6nU4z/iUTRcLWBxLp2T7QvY66r/nAQmG2S4A6W6gZFad
# F/BF3A51djQ9N3IVpQfzZTHEkTc7+gMZr3KFgUmJ56tuILjMr7KG+RnNM1g5V3uq
# 2p5JSIPMVicw85Q/B5t6UEgsjmP4OAhPQgnZop7eE8ykbXR5lcLCvZF4oWkjj6nV
# IoVNTLugagM8D4ZyHjqotTVVKbK5/BCwfLDzEeFCTdejxVw82zCh3oTr95L4Gk6d
# MJSy4GhSCVos0rEG
# SIG # End signature block
