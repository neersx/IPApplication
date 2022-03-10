using CommandLine;
using CommandLine.Text;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.CommandLine
{
    internal class Options
    {
        [VerbOption("add", HelpText = "Add a new instance to pair with existing IIS application.")]
        public AddOptions AddOptions { get; set; }

        [VerbOption("upgrade", HelpText = "Upgrade an existing instance.")]
        public UpgradeOptions UpgradeOptions { get; set; }

        [VerbOption("remove", HelpText = "Remove an existing instance.")]
        public RemoveOptions RemoveOptions { get; set; }

        [VerbOption("resync", HelpText = "Resync an existing instance.")]
        public ResyncOptions ResyncOptions { get; set; }

        [VerbOption("update", HelpText = "Update an existing instance.")]
        public UpdateOptions UpdateOptions { get; set; }

        [VerbOption("resume", HelpText = "Continue previous setup.")]
        public ResumeOptions ResumeOptions { get; set; }

        [VerbOption("list", HelpText = "List all instances.")]
        public ListOptions ListOptions { get; set; }

        [VerbOption("iis", HelpText = "List all IIS Applications.")]
        public IisOptions IisOptions { get; set; }

        [HelpOption]
        public string GetUsage()
        {
            return HelpText.AutoBuild(this, helpText => HelpText.DefaultParsingErrorsHandler(this, helpText), true);
        }
    }

    public class VerbOptions
    {
        [HelpOption]
        public string GetUsage()
        {
            return HelpText.AutoBuild(this, helpText => HelpText.DefaultParsingErrorsHandler(this, helpText));
        }
    }

    internal class AddOptions : VerbOptions
    {
        [Option("root", Required = false, DefaultValue = Constants.DefaultRootPath, HelpText = "The root path specifies the location where the new instance will be installed.")]
        public string RootPath { get; set; }

        [Option("iis", Required = true, HelpText = "The path of paired IIS application. The format is <Site Name>/<Site Path> e.g. \"Default Web Site/CPAInproma\"")]
        public string IisAppPath { get; set; }

        [Option("storage", Required = false, DefaultValue = Constants.DefaultStorageLocation, HelpText = "The storage location. Defaults to " + Constants.DefaultStorageLocation)]
        public string StorageLocation { get; set; }
        
        [Option("authentication", Required = false, HelpText = "The authentication mode. Defaults to IIS Authentication Mode. Can be any comma seprated combination of " + Constants.AuthenticationModeKeys.Forms + "," + Constants.AuthenticationModeKeys.Windows + "," + Constants.AuthenticationModeKeys.Sso)]
        public string AuthenticationMode { get; set; }

        [Option("authentication2fa", Required = false, HelpText = "The authentication two factor authentication mode. Defaults to off for all users. Can be any comma seprated combination of " + Constants.Authentication2FAModeKeys.Internal + "," + Constants.Authentication2FAModeKeys.External)]
        public string Authentication2FAMode { get; set; }

        [Option("sso-client-id", Required = false, HelpText = "Client Id for The IP Platform. This option is applicable only when sso authentication mode is selected.")]
        public string ClientId { get; set; }

        [Option("sso-client-secret", Required = false, HelpText = "Client secret for The IP Platform. This option is applicable only when sso authentication mode is selected.")]
        public string ClientSecret { get; set; }
        
        [Option("bypassSslCertificateCheck", Required = false, HelpText = "Bypass Ssl Check WARNING do not turn this flag on for production.")]
        public bool BypassSslCertificateCheck { get; set; }

        [Option("db-username", Required = false, HelpText = "The admin's username to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabaseUsername { get; set; }

        [Option("db-password", Required = false, HelpText = "The admin's password to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabasePassword { get; set; }

        [Option("integration-server-port", DefaultValue = "80", HelpText = "The port number used for the integration server")]
        public string IntegrationServerPort { get; set; }

        [Option("iis-app-info-profile", HelpText = "The path to retrieve IIS applications from a file, internal use only")]
        public string IisAppInfoProfiles { get; set; }
        
        [Option("cookie-consent-banner-hook", HelpText = "The script hook to be passed in to display cookie consent.")]
        public string CookieConsentBannerHook { get; set; }

        [Option("cookie-declaration-hook", HelpText = "The script hook to be passed in to display cookie declaration.")]
        public string CookieDeclarationHook { get; set; }

        [Option("e2e", HelpText = "Configure the instance to be used in the e2e context (internal use only)")]
        public bool E2E { get; set; }
    }

    internal class UpgradeOptions : VerbOptions
    {
        [Option("path", Required = true, HelpText = "The target instance path.")]
        public string InstancePath { get; set; }

        [Option("new-root", Required = false, HelpText = "The new path of the location where the instance will be moved to after upgrade.")]
        public string NewRootPath { get; set; }

        [Option("storage", Required = false, DefaultValue = Constants.DefaultStorageLocation, HelpText = "The storage location. Defaults to " + Constants.DefaultStorageLocation)]
        public string StorageLocation { get; set; }

        [Option("authentication", Required = false, HelpText = "The authentication mode. Defaults to IIS Authentication Mode. Can be any comma seprated combination of " + Constants.AuthenticationModeKeys.Forms + "," + Constants.AuthenticationModeKeys.Windows + "," + Constants.AuthenticationModeKeys.Sso)]
        public string AuthenticationMode { get; set; }

        [Option("authentication2fa", Required = false, HelpText = "The authentication two factor authentication mode. Defaults to off for all users. Can be any comma seprated combination of " + Constants.Authentication2FAModeKeys.Internal + "," + Constants.Authentication2FAModeKeys.External)]
        public string Authentication2FAMode { get; set; }

        [Option("sso-client-id", Required = false, HelpText = "Client Id for The IP Platform. This option is applicable only when sso authentication mode is selected.")]
        public string ClientId { get; set; }

        [Option("sso-client-secret", Required = false, HelpText = "Client secret for The IP Platform. This option is applicable only when sso authentication mode is selected.")]
        public string ClientSecret { get; set; }

        [Option("bypassSslCertificateCheck", Required = false, HelpText = "Bypass Ssl Check WARNING do not turn this flag on for production.")]
        public bool BypassSslCertificateCheck { get; set; }

        [Option("db-username", Required = false, HelpText = "The admin's username to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabaseUsername { get; set; }

        [Option("db-password", Required = false, HelpText = "The admin's password to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabasePassword { get; set; }

        [Option("integration-server-port", DefaultValue = "80", HelpText = "The port number used for the integration server")]
        public string IntegrationServerPort { get; set; }

        [Option("iis-app-info-profile", HelpText = "The path to retrieve IIS applications from a file, internal use only")]
        public string IisAppInfoProfiles { get; set; }

        [Option("cookie-consent-banner-hook", HelpText = "The script hook to be passed in to display cookie consent.")]
        public string CookieConsentBannerHook { get; set; }

        [Option("cookie-declaration-hook", HelpText = "The script hook to be passed in to display cookie declaration.")]
        public string CookieDeclarationHook { get; set; }

        [Option("e2e", HelpText = "Configure the instance to be used in the e2e context (internal use only)")]
        public bool E2E { get; set; }
    }

    internal class RemoveOptions : VerbOptions
    {
        [Option("path", Required = true, HelpText = "The target instance path.")]
        public string InstancePath { get; set; }

        [Option("db-username", Required = false, HelpText = "The admin's username to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabaseUsername { get; set; }

        [Option("db-password", Required = false, HelpText = "The admin's password to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabasePassword { get; set; }

        [Option("iis-app-info-profile", HelpText = "The path to retrieve IIS applications from a file, internal use only")]
        public string IisAppInfoProfiles { get; set; }

    }

    public class ResyncOptions : VerbOptions
    {
        [Option("path", Required = true, HelpText = "The target instance path.")]
        public string InstancePath { get; set; }

        [Option("db-username", Required = false, HelpText = "The admin's username to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabaseUsername { get; set; }

        [Option("db-password", Required = false, HelpText = "The admin's password to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabasePassword { get; set; }

        [Option("iis-app-info-profile", HelpText = "The path to retrieve IIS applications from a file, internal use only")]
        public string IisAppInfoProfiles { get; set; }
        
        [Option("e2e", HelpText = "Configure the instance to be used in the e2e context (internal use only)")]
        public bool E2E { get; set; }

    }

    internal class UpdateOptions : VerbOptions
    {
        [Option("path", Required = true, HelpText = "The target instance path.")]
        public string InstancePath { get; set; }

        [Option("storage", Required = true, HelpText = "The new storage location.")]
        public string StorageLocation { get; set; }

        [Option("authentication", Required = false, HelpText = "The new authentication mode. Defaults to IIS Authentication Mode. Can be any comma seprated combination of " + Constants.AuthenticationModeKeys.Forms + "," + Constants.AuthenticationModeKeys.Windows + "," + Constants.AuthenticationModeKeys.Sso)]
        public string AuthenticationMode { get; set; }
        
        [Option("authentication2fa", Required = false, HelpText = "The authentication two factor authentication mode. Defaults to off for all users. Can be any comma seprated combination of " + Constants.Authentication2FAModeKeys.Internal + "," + Constants.Authentication2FAModeKeys.External)]
        public string Authentication2FAMode { get; set; }

        [Option("sso-client-id", Required = false, HelpText = "Client Id for The IP Platform. This option is applicable only when sso authentication mode is selected.")]
        public string ClientId { get; set; }

        [Option("sso-client-secret", Required = false, HelpText = "Client secret for The IP Platform. This option is applicable only when sso authentication mode is selected.")]
        public string ClientSecret { get; set; }
        
        [Option("db-username", Required = false, HelpText = "The admin's username to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabaseUsername { get; set; }

        [Option("db-password", Required = false, HelpText = "The admin's password to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabasePassword { get; set; }
        
        [Option("bypassSslCertificateCheck", Required = false, HelpText = "Bypass Ssl Check WARNING do not turn this flag on for production.")]
        public bool BypassSslCertificateCheck { get; set; }
        
        [Option("integration-server-port", DefaultValue = "80", HelpText = "The port number used for the integration server")]
        public string IntegrationServerPort { get; set; }

        [Option("iis-app-info-profile", HelpText = "The path to retrieve IIS applications from a file, internal use only")]
        public string IisAppInfoProfiles { get; set; }

        [Option("cookie-consent-banner-hook", HelpText = "The script hook to be passed in to display cookie consent.")]
        public string CookieConsentBannerHook { get; set; }

        [Option("cookie-declaration-hook", HelpText = "The script hook to be passed in to display cookie declaration.")]
        public string CookieDeclarationHook { get; set; }
        
        [Option("e2e", HelpText = "Configure the instance to be used in the e2e context (internal use only)")]
        public bool E2E { get; set; }

    }

    internal class ListOptions : VerbOptions
    {
        [Option("root", Required = false, DefaultValue = Constants.DefaultRootPath, HelpText = "The root path of all instances. Defaults to " + Constants.DefaultRootPath)]
        public string RoothPath { get; set; }

        [Option("iis-app-info-profile", HelpText = "The path to retrieve IIS applications from a file, internal use only")]
        public string IisAppInfoProfiles { get; set; }
    }

    internal class IisOptions : VerbOptions
    {
        [Option("root", Required = false, DefaultValue = Constants.DefaultRootPath, HelpText = "The root path of all instances. Defaults to " + Constants.DefaultRootPath)]
        public string RootPath { get; set; }

        [Option("iis-app-info-profile", HelpText = "The path to retrieve IIS applications from a file, internal use only")]
        public string IisAppInfoProfiles { get; set; }
    }

    internal class ResumeOptions : VerbOptions
    {
        [Option("path", Required = true, HelpText = "The target instance path.")]
        public string InstancePath { get; set; }

        [Option("db-username", Required = false, HelpText = "The admin's username to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabaseUsername { get; set; }

        [Option("db-password", Required = false, HelpText = "The admin's password to access database. This parameter is required only if the login of Inprotech database defined in connection string doesn't have enough previleges.")]
        public string DatabasePassword { get; set; }

        [Option("iis-app-info-profile", HelpText = "The path to retrieve IIS applications from a file, internal use only")]
        public string IisAppInfoProfiles { get; set; }
    }
}