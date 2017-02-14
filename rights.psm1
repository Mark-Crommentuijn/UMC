<# 
 .Synopsis
  Add and delete folder permissions and set the owner on a directory

 .Description
  Functions to add or delete user permissions on a specified folder.
  There is also a function that sets the owner

 .Parameter fldpath
  The full path of the directory.

 .Parameter owner
  The username of te owner of de directory. mostly this will be the Administror

 .Parameter right
  Specifies the rights you intent to give. for example Modify or ReadAndExecute

 .Parameter group
  Which group do you want to give permissions

 .Example
   # Sets the owner on the specified folder.
   Set-Owner -fldpath "C:\temp\myfolder" -owner "Administrators"

 .Example
   # Remove permissions on a folder for a specific user or group. the group parameter could also be a user account.
   Remove-Permissions -fldpath "C:\temp\myfolder" -right "ReadAndExecute" -group "umcn\appldlg_CI........"

 .Example
   # Add permissions on a folder for a specific user or group. the group parameter could also be a user account.
   Add-Permissions -fldpath "C:\temp\myfolder" -right "ReadAndExecute" -group "umcn\appldlg_CI........"

#>
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

Function Add-Permissions {
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
  $add = $acl.AddAccessRule($rule)
  $run                     = Set-Acl -Path $fldpath -AclObject $acl
}
# SIG # Begin signature block
# MIINKAYJKoZIhvcNAQcCoIINGTCCDRUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJl6bTDgniTttC7mqG8yK/OvU
# 9migggpvMIIFGTCCBAGgAwIBAgIQDbnGEbOq/3RgewIGXryqxTANBgkqhkiG9w0B
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
# BDEWBBQrkM/Gmf1ohbDR5kw959Vxr5Vy6zANBgkqhkiG9w0BAQEFAASCAQBevBwI
# LSwHJkAM53KICjmRl7T8YjkgI+6p5n2So/mHOYFu0pYQP5QdgMNH9wa6/zuHSOTG
# FdrZAjMk/VXEuHurtKmMbIcut3K/kTe0+Qltebc64MHBORJNNab1i7qWVBIJqMCS
# ibQ+ANgFUchgoObp0VTBx2StlIgfl3WGKWKRfYbNSSTUZfhem7xUYXlpV1apigbV
# uJgev2NjQhAG22qFqC+46H6Q2PlqcrwlDognJI94YeziQM1F6SZot3PtqXU2JKGL
# quMwGg8Ql7p0XR/fhyDeslrl6HnsI7QKERs0KiFf9R3CrE5RZr5EB9vkLDlSScsj
# ksJW8wU0G3VUHUOh
# SIG # End signature block
