<#
.SYNOPSIS
    Modifies the Ip Platform target environment for Inprotech server
.DESCRIPTION

********************************************************************************************************************************************************
*******************************       MUST NOT BE DISTRIBUTED OUTSIDE OF CPA GLOBAL          ***********************************************************
********************************************************************************************************************************************************


    This script is used to modify the target for Ip Platform. 
    It makes it easier for CPA users to switch between different IP Platforrm environments.
    Following app settings can be changed using this script.
    --SSO Environment (Staging, Pre-Production, Production)----Required,
    --SSO Client ID----Optional,
    --SSO Client Secret----Optional,
    --Session Timeout----Optional    
.NOTES
    File Name  : configsso.ps1
    Author     : hasan malik (hmalik@cpaglobal.com)
    Requires   : PowerShell v2+,
    Version    : 1.0
.LINK
#>
param(    
    [Parameter(Mandatory = $true)][ValidateSet('Staging', 'PreProd', 'Prod')][string] $server,
    [string] $clientId,
    [string] $clientSecret,
    [int16] $sessionTimeOut
)

[string] $configFilePath = Resolve-Path ".\Inprotech.Server.exe.config";
[String] $sectionName = "appSettings";


if (!(Test-Path $configFilePath)) {
    Write-Host "Script must be run from Inprotech Server instance directory";
    Write-Host "Press any key to exit"
    [void][System.Console]::ReadKey($true)
    return;
}
#The System.Configuration assembly must be loaded
if ($PSVersionTable.PSVersion.Major -ge 3) {
    $configurationAssembly = "System.Configuration, Version=4.0.0.0, Culture=Neutral, PublicKeyToken=b03f5f7f11d50a3a"
    Write-Host "Loaded Config V4"
}
else {
    $configurationAssembly = "System.Configuration, Version=2.0.0.0, Culture=Neutral, PublicKeyToken=b03f5f7f11d50a3a"
    Write-Host "Loaded Config V2"
}
[void] [Reflection.Assembly]::Load($configurationAssembly)
  
$configurationFileMap = New-Object -TypeName System.Configuration.ExeConfigurationFileMap
$configurationFileMap.ExeConfigFilename = $configFilePath
$configuration = [System.Configuration.ConfigurationManager]::OpenMappedExeConfiguration($configurationFileMap, [System.Configuration.ConfigurationUserLevel]"None")
$section = $configuration.GetSection($sectionName)
$serviceInstance = "Inprotech.Server$" + $configuration.AppSettings.Settings["InstanceName"].Value;

function SaveAndEncryptInprotechSettings () {

    function SetSsoConfig($serverUrl, $iamUrl, $certificate) {
        $configuration.AppSettings.Settings["cpa.sso.serverUrl"].Value = $serverUrl;
        $configuration.AppSettings.Settings["cpa.sso.iamUrl"].Value = $iamUrl;
        $configuration.AppSettings.Settings["cpa.iam.proxy.serverUrl"].Value = $iamUrl;
        $configuration.AppSettings.Settings["cpa.sso.certificate"].Value = $certificate;
    }


    if ($sessionTimeOut -ne 0) {
        $configuration.AppSettings.Settings["SessionTimeout"].Value = $sessionTimeOut;
    }
    if (![string]::IsNullOrEmpty($clientId)) {
        $configuration.AppSettings.Settings["cpa.sso.clientId"].Value = $clientId;
    }
    if (![string]::IsNullOrEmpty($clientSecret)) {
        $configuration.AppSettings.Settings["cpa.sso.clientSecret"].Value = $clientSecret;
    }
    [string]$stagingCertificate = "MIIC6jCCAdKgAwIBAgIGAU8HQlEkMA0GCSqGSIb3DQEBDQUAMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpDUEEgR2xvYmFsMRIwEAYDVQQDEwlKV1QgVG9rZW4wHhcNMTUwODA3MDgyMzUwWhcNMTYwODA2MDgyMzUwWjA2MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQ1BBIEdsb2JhbDESMBAGA1UEAxMJSldUIFRva2VuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAp5+/mEfIWBNLGBbKVRP4r8vUfLsaMLIYWFl/zSRCQeeos6VD1yX4vMnCj6AxCpY2dqlvXLEkwDQLSquzqG3feYA74ZBm+45k5Fe+m3EG4wU1gPAbkAP2zHyaJ/61oDck0HFNnrSuB2OtNE3y/XoXjy1MPeTDt3/UGB0Otxgeu51ZK0AYQMa1nkeUPLUvY/lp7vZKdCu4cZgfh8rvT+gkGJCa6IJberblMRQ6vwVPuCK6VvAzMPBKEzLhF9GkegWy7NDk8h+/Ya8OT9sJtvPt9fHas6dnwICzjKYLG4TbJKHPWm+ufME08JVjvCDwQSeDs3vlS01HiCO81CI2bKGDkQIDAQABMA0GCSqGSIb3DQEBDQUAA4IBAQBFegx6hvxTRA+V0sIhAm6bGg4+oDgDFslxTD7CBd4Gh72gWYRFgTB4nOQu/t9+zNgW+FDy/KqmGhO3MC3ImeZ1L++V+kPnvpNw9hUARVoQTrdO6IX3714Y43RZ1iTRMnex32gwzFKuE4lL325ydtUjM7gwBc7wTKpbMcdu6o2axnfGXfbBMq/u6x1368qsx5wNq9EviqwsGPoVuiqpC2Z9sR2QLAFLzNfIWdnRFA5mxMWUc8JkNZb+rOu4DITYJXhIN5K4Kr36mHf1hRwAhR5VhvXpEn0K5gnF1z8npfwPxDnVG44Gme4ogsBQnzXW0gJ+Cmct6f4KxucmHBhM8DR9";
    [string]$PreProdCertificate = "MIIC6jCCAdKgAwIBAgIGAVg7EMBoMA0GCSqGSIb3DQEBCwUAMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpDUEEgR2xvYmFsMRIwEAYDVQQDEwlTU08gVG9rZW4wHhcNMTYxMTA2MTkxNTAzWhcNMjYxMTA0MTkxNTAzWjA2MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQ1BBIEdsb2JhbDESMBAGA1UEAxMJU1NPIFRva2VuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAm2dgPxURoIJNQxcxG18XteeU3H//4LBOB1uVsLt5wO0E6feoJh6TiSQ8YIGeI623BUVqLDU5PNjoWF3MQQEcv+FiQ6is1CV5aU4kmmPHNP13ebkzOmAD65WAPY5kGI4bhT57vYZIEVEzNynjVUJd8JcNE2QGrSWd/gBYxFGc+R4RJLGgEzGfxIFYjhGmhYgi7kX+5cO+QQpcSIhPazRUjpFOObGyl7rWzIdtrr8aXAK8NiHL6w10jBv6gd5HFOpAhR7+OzFWbgLiHf/cptyplvmnDplJ27maS9eUVN64ld3B/Pj+KO/aOyRyqYq5ygHGl6utTzBHC3puYYvXChOtdwIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQAPPrcD58o+mvqTOiLsW4oExJQlelufs+rGX6r4YILSKiPRbnBaQ5NfJP1fIkubzpmpxrusclJSUEOQSAsh7Tb2W3qiuSYe+LcEZaBbCgOT+xKhehTBHnqMCa6SPjiotXZzWvp4ZvP8/xUo7NxLjn7RVnoNwLoQbsL5YBwntC9SMeWYN9zMf6JWGaSBtenV9nH7FRKiYQK2usel9TUUST2C+w33XVqKLmp12Gz+mGiIWunD+n/e0xfdJDQ+KdoKG0yY4rcROQ/4dWw0XR4sD07+fqRUPPV0ka271t4cDriop3EJddnkAkh4+faEyk5K11leHSk3qAHNZ1r0OxWEg3vo​";
    [string]$ProdCertificate = "MIIC6jCCAdKgAwIBAgIGAVgloDsRMA0GCSqGSIb3DQEBCwUAMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpDUEEgR2xvYmFsMRIwEAYDVQQDEwlTU08gVG9rZW4wHhcNMTYxMTAyMTUyMDA3WhcNMTgxMTAyMTUyMDA3WjA2MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQ1BBIEdsb2JhbDESMBAGA1UEAxMJU1NPIFRva2VuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAkF3hqzVPJx15ymg5YHHFcT/zYaLW46/wNK2QOMIafp0s/DC7yOQgYEoEIINNN2MQde2dNA742L+7VErsQzSNO6JXgRLOIfaHPzDM2vKSDYhj8nhW248bG/x8rsb3tPnfqEe2qR4+yLrNuI5q+zzbweO8A4BP3Ni9MKCnQ/NPT5VY+WGfdS/y35Xt1cOy8Vi4H1vahTLumaenZ+R3lxdtNOoWCMSxiysQ458zlFaZ+UQ03/74cvr1sQj2XXowFy4c1lMzd9at1MNCP/3PBm9p/5/FVLAoQeRsK99V3cidvPkmNlFh5rkwwqj/jM2+V38UWByrg2GlbVScTOqIUybBcwIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQAVV+WPwODKvTpXQq8n1vL1zt00lxQbPql93ersb+180YksH2xrQj3IkRGJCYvNilNPbGjOQKObzfV0DS3FfFyFryWWdQxX2869kA7wn9In3HB7SRYDRZ1NZ+0g0lVNmdo/sxbN1+z62aNOqjfybq34F6uSCgOdzm4tp4HNsKsQBrv9g4ZU1Zpsa/zvCgT3zpnNzhLayfZT/YKI4whq+oam0jqEtxwCsUiw0wqO4ih4gtErSRmUIWIXo2c7pfOT1Igaskd29FO6DfnJktYUqtXvD+gpazcOv7+GDQehdf5wtxcrJlV0FVqm3lUjXZRFyzgL3pZTqdnJBTGuLTuJKIYt";
    switch ($server) {        
        'Staging' {
            SetSsoConfig "https://sso.ipendonet.com" "https://iamreverseproxyiw3vv5r3fvnuy.azurewebsites.net" $stagingCertificate;
        }
        'PreProd' {
            SetSsoConfig "https://sso-preprod.ipplatform.com" "https://users.sso-preprod.ipplatform.com" $PreProdCertificate;
        }
        'Prod' {
            SetSsoConfig "https://sso.ipplatform.com" "https://users.sso.ipplatform.com" $ProdCertificate;
        }
        Default {
            $(throw "Server mode not found");
        }
    }
    Write-Host "Settings changed";    
    $section.SectionInformation.ProtectSection("DataProtectionConfigurationProvider")    
    $configuration.Save([System.Configuration.ConfigurationSaveMode]::Modified);
    Write-Host "Success: Configuration saved";
}

function RestartServer() {
    try {
        Write-Host "Restarting Inprotech Service";
        if (Get-Service $serviceInstance -ErrorAction SilentlyContinue) {
            Stop-Service $serviceInstance;
            Start-Service $serviceInstance;
            Write-Host "Success Service Restarted";
        }
        else {
            Write-Host "Service not found: "+$serviceInstance; 
        }
    }
    catch {
        Write-Host $_.Exception.Message;
    }
}

SaveAndEncryptInprotechSettings;
RestartServer;