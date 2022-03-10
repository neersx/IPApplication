<#
.SYNOPSIS
    Uses builtin aspnet_regiis to decrypt the app settings
.DESCRIPTION

********************************************************************************************************************************************************
*******************************       MUST NOT BE DISTRIBUTED OUTSIDE OF CPA GLOBAL          ***********************************************************
********************************************************************************************************************************************************

    aspnet_regiis only works with web.config. So we temporarily rename the app config and then set it back to original after decryption. 
.NOTES
    File Name  : Decrypt.ps1
    Author     : hasan malik (hmalik@cpaglobal.com)
    Requires   : PowerShell v2+,
    Version    : 1.0
.LINK
#>
param(    
    [Parameter(Mandatory = $true)][string] $instancePath
)
[String] $configFile = "Inprotech.Server.exe.config";
[String] $path = Join-Path $instancePath $configFile;

if (!(Test-Path $path -PathType Leaf)) {
    $configFile = "Inprotech.IntegrationServer.exe.config";
    $path = Join-Path $instancePath $configFile;
    if (!(Test-Path $path -PathType Leaf)) {
        Write-Host "The path must either be Inprotech Server or Integration server";
        Write-Host "Press any key to exit"
        [void][System.Console]::ReadKey($true)
        return;
    }
}

Rename-Item $path web.config;
Set-Location (Resolve-Path "C:\Windows\Microsoft.NET\Framework\v4*")[0]
#To Encrypt
#.\aspnet_regiis.exe -pef "appSettings" $($instancePath) -prov "DataProtectionConfigurationProvider";
.\aspnet_regiis.exe -pdf "appSettings" $($instancePath); #-prov "DataProtectionConfigurationProvider";
Rename-Item (Join-Path $instancePath "web.config") $configFile;