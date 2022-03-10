using System;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Actions;

namespace Inprotech.Setup.Core
{
    public interface ISetupWorkflows
    {
        SetupWorkflow New(string rootPath, string iisSite, string iisPath, string dbUsername,
                          string dbPassword, ContextSettings contextSettings, AuthenticationSettings authenticationSettings);

        SetupWorkflow Remove(string instancePath, string dbUsername, string dbPassword, ContextSettings contextSettings);

        SetupWorkflow Resync(string instancePath, string dbUsername, string dbPassword, ContextSettings contextSettings);

        SetupWorkflow Update(string instancePath, string dbUsername, string dbPassword, ContextSettings contextSettings, AuthenticationSettings authenticationSettings);

        SetupWorkflow Upgrade(string instancePath, string newRootPath, string dbUsername,
                              string dbPassword, ContextSettings contextSettings, AuthenticationSettings authenticationSettings);

        SetupWorkflow Resume(string instancePath, string dbUsername, string dbPassword, ContextSettings contextSettings);

        SetupWorkflow Recovery(string instancePath, string failedActionName, string dbUsername, string dbPassword, ContextSettings contextSettings);
    }

    internal class SetupWorkflows : ISetupWorkflows
    {
        readonly Func<SetupWorkflow> _workflow;

        public SetupWorkflows(Func<SetupWorkflow> workflow)
        {
            _workflow = workflow;
        }

        public SetupWorkflow New(string rootPath, string iisSite, string iisPath,
                                 string dbUsername, string dbPassword, ContextSettings contextSettings, AuthenticationSettings authenticationSettings)
        {
            return
                _workflow()
                    .Context(_ =>
                    {
                        _.IisSite = iisSite;
                        _.IisPath = iisPath;
                        _.StorageLocation = contextSettings.StorageLocation;
                        _.DatabaseUsername = dbUsername;
                        _.DatabasePassword = dbPassword;
                        _.RootPath = rootPath;
                        _.Authentication2FAMode = authenticationSettings.TwoFactorAuthenticationMode;
                        _.AuthenticationMode = authenticationSettings.AuthenticationMode;
                        _.IpPlatformSettings = authenticationSettings.IpPlatformSettings;
                        _.AdfsSettings = authenticationSettings.AdfsSettings;
                        _.PrivateKey = contextSettings.PrivateKey;
                        _.IntegrationServerPort = contextSettings.IntegrationServerPort;
                        _.RemoteIntegrationServerUrl = contextSettings.RemoteIntegrationServerUrl;
                        _.RemoteStorageServiceUrl = contextSettings.RemoteStorageServiceUrl;
                        _.CookieConsentSettings = contextSettings.CookieConsentSettings;
                        _.UsageStatisticsSettings = contextSettings.UsageStatisticsSettings;
                        _.IisAppInfoProfiles = contextSettings.IisAppInfoProfiles;
                        _.IsE2EMode = contextSettings.IsE2EMode;
                        _.BypassSslCertificateCheck = contextSettings.BypassSslCertificateCheck;
                    })
                    .Do<InitInstall>()
                    .BuildNewWorkflow();
        }

        public SetupWorkflow Remove(string instancePath, string dbUsername, string dbPassword, ContextSettings contextSettings)
        {
            return
                _workflow()
                    .Context(_ =>
                    {
                        _.InstancePath = instancePath;
                        _.DatabaseUsername = dbUsername;
                        _.DatabasePassword = dbPassword;
                        _.PrivateKey = contextSettings.PrivateKey;
                        _.IisAppInfoProfiles = contextSettings.IisAppInfoProfiles;
                    })
                    .Do<InitRemove>()
                    .BuildRemoveWorkflow();
        }

        public SetupWorkflow Resync(string instancePath, string dbUsername, string dbPassword, ContextSettings contextSettings)
        {
            return
                _workflow()
                    .Context(_ =>
                    {
                        _.InstancePath = instancePath;
                        _.DatabaseUsername = dbUsername;
                        _.DatabasePassword = dbPassword;
                        _.PrivateKey = contextSettings.PrivateKey;
                        _.RemoteIntegrationServerUrl = contextSettings.RemoteIntegrationServerUrl;
                        _.RemoteStorageServiceUrl = contextSettings.RemoteStorageServiceUrl;
                        _.CookieConsentSettings = contextSettings.CookieConsentSettings;
                        _.IisAppInfoProfiles = contextSettings.IisAppInfoProfiles;
                        _.IsE2EMode = contextSettings.IsE2EMode;
                        _.BypassSslCertificateCheck = contextSettings.BypassSslCertificateCheck;
                    })
                    .Do<InitResync>()
                    .BuildResyncWorkflow();
        }

        public SetupWorkflow Update(string instancePath, string dbUsername, string dbPassword, ContextSettings contextSettings, AuthenticationSettings authenticationSettings)
        {
            return
                _workflow()
                    .Context(_ =>
                    {
                        _.InstancePath = instancePath;
                        _.StorageLocation = contextSettings.StorageLocation;
                        _.DatabaseUsername = dbUsername;
                        _.DatabasePassword = dbPassword;
                        _.AuthenticationMode = authenticationSettings.AuthenticationMode;
                        _.Authentication2FAMode = authenticationSettings.TwoFactorAuthenticationMode;
                        _.IpPlatformSettings = authenticationSettings.IpPlatformSettings;
                        _.AdfsSettings = authenticationSettings.AdfsSettings;
                        _.PrivateKey = contextSettings.PrivateKey;
                        _.IntegrationServerPort = contextSettings.IntegrationServerPort;
                        _.RemoteIntegrationServerUrl = contextSettings.RemoteIntegrationServerUrl;
                        _.RemoteStorageServiceUrl = contextSettings.RemoteStorageServiceUrl;
                        _.CookieConsentSettings = contextSettings.CookieConsentSettings;
                        _.UsageStatisticsSettings = contextSettings.UsageStatisticsSettings;
                        _.IisAppInfoProfiles = contextSettings.IisAppInfoProfiles;
                        _.IsE2EMode = contextSettings.IsE2EMode;
                        _.BypassSslCertificateCheck = contextSettings.BypassSslCertificateCheck;
                    })
                    .Do<InitUpdate>()
                    .BuildUpdateWorkflow();
        }

        public SetupWorkflow Upgrade(string instancePath, string newRootPath, string dbUsername,
                                     string dbPassword, ContextSettings contextSettings, AuthenticationSettings authenticationSettings)
        {
            return
                _workflow()
                    .Context(_ =>
                    {
                        _.InstancePath = instancePath;
                        _.StorageLocation = contextSettings.StorageLocation;
                        _.DatabaseUsername = dbUsername;
                        _.DatabasePassword = dbPassword;
                        _.NewRootPath = newRootPath;
                        _.AuthenticationMode = authenticationSettings.AuthenticationMode;
                        _.Authentication2FAMode = authenticationSettings.TwoFactorAuthenticationMode;
                        _.IpPlatformSettings = authenticationSettings.IpPlatformSettings;
                        _.AdfsSettings = authenticationSettings.AdfsSettings;
                        _.PrivateKey = contextSettings.PrivateKey;
                        _.IntegrationServerPort = contextSettings.IntegrationServerPort;
                        _.RemoteIntegrationServerUrl = contextSettings.RemoteIntegrationServerUrl;
                        _.RemoteStorageServiceUrl = contextSettings.RemoteStorageServiceUrl;
                        _.CookieConsentSettings = contextSettings.CookieConsentSettings;
                        _.UsageStatisticsSettings = contextSettings.UsageStatisticsSettings;
                        _.IisAppInfoProfiles = contextSettings.IisAppInfoProfiles;
                        _.IsE2EMode = contextSettings.IsE2EMode;
                        _.BypassSslCertificateCheck = contextSettings.BypassSslCertificateCheck;
                    })
                    .Do<InitUpgrade>()
                    .BuildUpgradeWorkflow();
        }

        public SetupWorkflow Resume(string instancePath, string dbUsername, string dbPassword, ContextSettings contextSettings)
        {
            return
                _workflow()
                    .Context(_ =>
                    {
                        _.InstancePath = instancePath;
                        _.DatabaseUsername = dbUsername;
                        _.DatabasePassword = dbPassword;
                        _.PrivateKey = contextSettings.PrivateKey;
                        _.IisAppInfoProfiles = contextSettings.IisAppInfoProfiles;
                    })
                    .Do<InitResume>()
                    .Do<FastForward>();
        }

        public SetupWorkflow Recovery(string instancePath, string failedActionName, string dbUsername, string dbPassword, ContextSettings contextSettings)
        {
            return
                _workflow()
                    .Context(_ =>
                    {
                        _.InstancePath = instancePath;
                        _.DatabaseUsername = dbUsername;
                        _.DatabasePassword = dbPassword;
                        _.PrivateKey = contextSettings.PrivateKey;
                        _.IisAppInfoProfiles = contextSettings.IisAppInfoProfiles;
                        _["failedActionName"] = failedActionName;
                    })
                    .Do<InitRecovery>()
                    .Load(b => new[] {((ISetupActionBuilder3) b).BuildRecoveryActions(failedActionName)});
        }
    }

    internal static class SetupWorkflowExtensions
    {
        public static SetupWorkflow BuildNewWorkflow(this SetupWorkflow workflow)
        {
            return workflow.Status(SetupStatus.Begin)
                           .Do<CopySetupFiles>()
                           .Status(SetupStatus.Install)
                           .Load(b => new[] {b.BuildInstallActions()})
                           .Status(SetupStatus.Complete);
        }

        public static SetupWorkflow BuildResumeNewWorkflow(this SetupWorkflow workflow)
        {
            return workflow.Status(SetupStatus.Begin)
                           .Do<CopySetupFiles>()
                           .Status(SetupStatus.Install)
                           .Load(b => new[] {b.BuildMaintenanceActions(), b.BuildInstallActions()})
                           .Status(SetupStatus.Complete);
        }

        public static SetupWorkflow BuildRemoveWorkflow(this SetupWorkflow workflow)
        {
            return workflow
                .Status(SetupStatus.Begin)
                .TryLoad(b => new[] {b.BuildMaintenanceActions(), b.BuildUnInstallActions()})
                .Status(SetupStatus.CleanUp)
                .Do<CleanUpInstance>();
        }

        public static SetupWorkflow BuildResyncWorkflow(this SetupWorkflow workflow)
        {
            return workflow
                .Status(SetupStatus.Begin)
                .Load(b => new[] {b.BuildMaintenanceActions(), b.BuildResyncActions()})
                .Status(SetupStatus.Complete);
        }

        public static SetupWorkflow BuildUpdateWorkflow(this SetupWorkflow workflow)
        {
            return workflow
                .Status(SetupStatus.Begin)
                .Load(b => new[] {b.BuildMaintenanceActions(), ((ISetupActionBuilder2) b).BuildUpdateActions()})
                .Status(SetupStatus.Complete);
        }

        public static SetupWorkflow BuildUpgradeWorkflow(this SetupWorkflow workflow)
        {
            return workflow
                .Status(SetupStatus.Begin)
                .Load(
                      b =>
                          new[] {b.BuildMaintenanceActions(), b.BuildPrepareForUpgradeActions(), b.BuildUnInstallActions()})
                .Status(SetupStatus.CleanUp)
                .Do<ReadyToUpgrade>()
                .Status(SetupStatus.Initialise)
                .Do<CopySetupFiles>()
                .Status(SetupStatus.Install)
                .Load(b => new[] {b.BuildUpgradeActions()})
                .Status(SetupStatus.Complete);
        }
    }
}