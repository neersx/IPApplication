using System.Collections.Generic;
using System.Linq;
using Inprotech.Setup.Actions.StorageServiceActions;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using Inprotech.Setup.Core.Utilities;
using FileSystem = Inprotech.Setup.Core.FileSystem;

namespace Inprotech.Setup.Actions
{
    public class SetupActionBuilder : ISetupActionBuilder, ISetupActionBuilder2, ISetupActionBuilder3
    {
        public IEnumerable<ISetupAction> BuildInstallActions()
        {
            var processRunner = new ProcessRunner();

            return new ISetupAction[]
            {
                new PrepareConnectionStrings(),
                new VerifySqlServerAdministrationAccess(),
                new SetFilePermission(),
                new UpdateInprotechServerConfiguration(),
                new UpdateInprotechServerConnectionStrings(),
                new UpdateInprotechIntegrationServerConfiguration(),
                new UpdateInprotechStorageServiceConfiguration(),
                new EncryptConnectionString(),
                new UpdateStorageLocationSettings(),
                new ApplyInprotechDatabaseChanges(processRunner),
                new ApplyIntegrationDatabaseChanges(processRunner),
                new VerifyLoginInInprotechDatabase(),
                new VerifyLoginInIntegrationDatabase(),
                new VerifyReaderWriterAccessToInprotechDatabase(),
                new VerifyReaderWriterAccessToIntegrationDatabase(),
                new ConfigureHttpSysForInprotechServer(),
                new ConfigureHttpSysForInprotechIntegrationServer(),
                new ConfigureHttpSysForInprotechStorageService(),
                new CopyExportConfig(),
                new ImportExistingDmsSettings(new CryptoService(), new IwsSettingHelper()),
                new ImportExistingReportingServicesSettings(new CryptoService(), new IwsSettingHelper()),
                new ImportExistingAttachmentSettings(new CryptoService(), new IwsSettingHelper()),
                new CopyLicenseAttributionsText(),
                new PublishCaseImportTemplates(),
                new RegisterInprotechServer(),
                new RegisterInprotechIntegrationServer(),
                new RegisterInprotechStorageService(),
                new AllocateUnassignedJobsToInstance(),
                new PersistSettingsInConfigSettings(),
                new RestoreTranslationChanges(),
                new ConfigureThirdPartyScriptHooks(new FileSystem()),
                new ConfigureProductImprovementProgram(),
                new StartInprotechServer(),
                new StartInprotechIntegrationServer(),
                new StartInprotechStorageService(),
                new UpdateReleaseVersion(),
                new AfterInstallOrUpgradeCleanup(),
                new AdfsConnectivity()
            };
        }

        public IEnumerable<ISetupAction> BuildUnInstallActions()
        {
            return new ISetupAction[]
            {
                new PrepareConnectionStrings(),
                new VerifySqlServerAdministrationAccess(),
                new RemoveAppsBridgeCsrfNounceForInprotechConfiguration(),
                new RemoveLicenseAttributionsText(),
                new ReassignRunningJobAllocations(),
                new UnregisterInprotechIntegrationServer(),
                new UnregisterInprotechServer(),
                new UnRegisterInprotechStorageService(),
                new RemoveHttpSysConfigurationForInprotechServer(),
                new RemoveHttpSysConfigurationForInprotechIntegrationServer(),
                new RemoveHttpSysConfigurationForInprotechStorageService()
            };
        }

        public IEnumerable<ISetupAction> BuildMaintenanceActions()
        {
            return new ISetupAction[]
            {
                new StopInprotechServer(),
                new StopInprotechIntegrationServer(),
                new StopInprotechStorageService()
            };
        }

        public IEnumerable<ISetupAction> BuildResyncActions()
        {
            var processRunner = new ProcessRunner();

            return new ISetupAction[]
            {
                new UnregisterInprotechServer(),
                new UnregisterInprotechIntegrationServer(),
                new UnRegisterInprotechStorageService(),
                new PrepareConnectionStrings(),
                new VerifySqlServerAdministrationAccess(),
                new SetFilePermission(),
                new UpdateInprotechServerConfiguration(),
                new UpdateInprotechServerConnectionStrings(),
                new UpdateInprotechIntegrationServerConfiguration(),
                new UpdateInprotechStorageServiceConfiguration(),
                new EncryptConnectionString(),
                new ApplyInprotechDatabaseChanges(processRunner),
                new ApplyIntegrationDatabaseChanges(processRunner),
                new VerifyLoginInInprotechDatabase(),
                new VerifyLoginInIntegrationDatabase(),
                new VerifyReaderWriterAccessToInprotechDatabase(),
                new VerifyReaderWriterAccessToIntegrationDatabase(),
                new ConfigureHttpSysForInprotechServer(),
                new ConfigureHttpSysForInprotechIntegrationServer(),
                new ConfigureHttpSysForInprotechStorageService(),
                new CopyExportConfig(),
                new ImportExistingDmsSettings(new CryptoService(), new IwsSettingHelper()),
                new ImportExistingReportingServicesSettings(new CryptoService(), new IwsSettingHelper()),
                new ImportExistingAttachmentSettings(new CryptoService(), new IwsSettingHelper()),
                new CopyLicenseAttributionsText(),
                new PublishCaseImportTemplates(),
                new RegisterInprotechServer(),
                new RegisterInprotechIntegrationServer(),
                new RegisterInprotechStorageService(),
                new StartInprotechServer(),
                new StartInprotechIntegrationServer(),
                new StartInprotechStorageService(),
                new UpdateReleaseVersion()
            };
        }

        public IEnumerable<ISetupAction> BuildPrepareForUpgradeActions()
        {
            return new ISetupAction[]
            {
                new PrepareForUpgrade(new FileSystem())
            };
        }

        public IEnumerable<ISetupAction> BuildUpgradeActions()
        {
            var processRunner = new ProcessRunner();

            return new ISetupAction[]
            {
                new PrepareConnectionStrings(),
                new VerifySqlServerAdministrationAccess(),
                new SetFilePermission(),
                new UpdateInprotechServerConfiguration(),
                new UpdateInprotechServerConnectionStrings(),
                new UpdateInprotechIntegrationServerConfiguration(),
                new UpdateInprotechStorageServiceConfiguration(),
                new EncryptConnectionString(),
                new MoveStorageLocationContents(),
                new RemoveOldStorageLocation(),
                new UpdateStorageLocationSettings(),
                new ApplyInprotechDatabaseChanges(processRunner),
                new ApplyIntegrationDatabaseChanges(processRunner),
                new VerifyLoginInInprotechDatabase(),
                new VerifyLoginInIntegrationDatabase(),
                new VerifyReaderWriterAccessToInprotechDatabase(),
                new VerifyReaderWriterAccessToIntegrationDatabase(),
                new ConfigureHttpSysForInprotechServer(),
                new ConfigureHttpSysForInprotechIntegrationServer(),
                new ConfigureHttpSysForInprotechStorageService(),
                new RemoveAppsBridgeCsrfNounceForInprotechConfiguration(),
                new CopyLicenseAttributionsText(),
                new PublishCaseImportTemplates(),
                new RegisterInprotechServer(),
                new RegisterInprotechIntegrationServer(),
                new RegisterInprotechStorageService(),
                new AllocateUnassignedJobsToInstance(),
                new PersistSettingsInConfigSettings(),
                new RestoreBackup(),
                new RestoreTranslationChanges(),
                new ImportExistingDmsSettings(new CryptoService(), new IwsSettingHelper()),
                new ImportExistingReportingServicesSettings(new CryptoService(), new IwsSettingHelper()),
                new ImportExistingAttachmentSettings(new CryptoService(), new IwsSettingHelper()),
                new ConfigureThirdPartyScriptHooks(new FileSystem()),
                new ConfigureProductImprovementProgram(),
                new StartInprotechServer(),
                new StartInprotechIntegrationServer(),
                new StartInprotechStorageService(),
                new UpdateReleaseVersion(),
                new AfterInstallOrUpgradeCleanup(),
                new AdfsConnectivity()
            };
        }

        IEnumerable<ISetupAction> ISetupActionBuilder2.BuildUpdateActions()
        {
            return new ISetupAction[]
            {
                new PrepareConnectionStrings(),
                new MoveStorageLocationContents(),
                new RemoveOldStorageLocation(),
                new RemoveHttpSysConfigurationForInprotechIntegrationServer(),
                new RemoveHttpSysConfigurationForInprotechStorageService(),
                new UnregisterInprotechIntegrationServer(),
                new UnRegisterInprotechStorageService(),
                new UpdateInprotechIntegrationServerEndpoint(),
                new UpdateInprotechStorageServiceEndpoint(),
                new UpdateAuthenticationSettings(),
                new UpdateStorageLocationSettings(),
                new ConfigureHttpSysForInprotechIntegrationServer(),
                new ConfigureHttpSysForInprotechStorageService(),
                new RegisterInprotechIntegrationServer(),
                new RegisterInprotechStorageService(),
                new PublishCaseImportTemplates(),
                new PersistSettingsInConfigSettings(),
                new RestoreTranslationChanges(true),
                new ConfigureThirdPartyScriptHooks(new FileSystem()),
                new ConfigureProductImprovementProgram(),
                new StartInprotechServer(),
                new StartInprotechIntegrationServer(),
                new StartInprotechStorageService(),
                new AdfsConnectivity()
            };
        }

        IEnumerable<ISetupAction> ISetupActionBuilder3.BuildRecoveryActions(string failedActionForRecovery)
        {
            var dbRecoveryActions = new[]
            {
                typeof(ApplyInprotechDatabaseChanges).Name,
                typeof(ApplyIntegrationDatabaseChanges).Name
            };

            if (dbRecoveryActions.Contains(failedActionForRecovery))
            {
                var processRunner = new ProcessRunner();
                return new ISetupAction[]
                {
                    new PrepareConnectionStrings(),
                    new VerifySqlServerAdministrationAccess(),
                    new FailedDatabaseScript(processRunner)
                };
            }

            if (failedActionForRecovery == typeof(CleanUpInstance).Name)
            {
                return new ISetupAction[]
                {
                    new FailedCleanUpInstance()
                };
            }

            return Enumerable.Empty<ISetupAction>();
        }
    }
}