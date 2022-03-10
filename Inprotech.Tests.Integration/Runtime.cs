using System;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net.Configuration;
using System.Net.Mail;
using Inprotech.Tests.Integration.Utils;

namespace Inprotech.Tests.Integration
{
    public static class Runtime
    {
        const string InstallBase = @"C:\Program Files (x86)\CPA Global\Inprotech Web Applications";

        const string InstancesBase = InstallBase + @"\Instances";

        public const string RemoteDatabaseBackupLocation = @"\\aus-inpsqlvd009\public_current_build\DATABASE BACKUP\IPDEV.bak";

        public const string LocalDatabaseBackupLocation = @"c:\Assets\E2E\IPDEV.bak";

        public const string DevelopmentHostStorageLocation = @"c:\inprotech_e2e\storage";

        public static string InstalledHostConfigLocation
        {
            get
            {
                var instanceName = new InstanceNameResolver().ResolveInstanceName(InstancesBase);

                return Path.Combine(InstancesBase, instanceName, @"Inprotech.Server\Inprotech.Server.exe.config");
            }
        }

        public static string InstalledHostIntegrationConfigLocation
        {
            get
            {
                var instanceName = new InstanceNameResolver().ResolveInstanceName(InstancesBase);

                return Path.Combine(InstancesBase, instanceName, @"Inprotech.IntegrationServer\Inprotech.IntegrationServer.exe.config");
            }
        }

        public static bool IsRunningInDockerMode { get; private set; }

        public static bool UseChromeHeadless { get; private set; }

        public static string InstanceName => new InstanceNameResolver().ResolveInstanceName(InstancesBase);

        public static string StorageLocation { get; private set; }

        public static string MailPickupLocation => Env.UseDevelopmentHost ? Path.Combine(DevelopmentHostStorageLocation, "Mails") : Path.Combine(StorageLocation, "Mails");

        public static void SetExecutionContextToDockerMode(string installUrl, string storageLocation)
        {
            TestSubject.DefaultInstallInprotechServerRoot = installUrl;
            IsRunningInDockerMode = true;
            StorageLocation = storageLocation;
        }

        public static void SetSettingsForAgentRunningInContainer()
        {
            UseChromeHeadless = true;
        }

        public static void ConfigureConnectionStringsAndAppSettings(out bool developmentConfigChanged)
        {
            developmentConfigChanged = false;

            string inprotechConnString = string.Empty;
            string inprotechIntegrationConnString = string.Empty;

            if (IsRunningInDockerMode)
            {
                InprotechServer.UpdateMailSettingsForInprotechAndIntegrationServer(MailPickupLocation);
            }
            else if (Env.UseInstalledHost)
            {
                var installConfigPath = InstalledHostConfigLocation;
                var installIntegrationConfigPath = InstalledHostIntegrationConfigLocation;

                if (!File.Exists(installConfigPath)) throw new Exception("cannot find Inprotech.Server.exe.config");
                if (!File.Exists(installIntegrationConfigPath)) throw new Exception("cannot find Inprotech.IntegrationServer.exe.config");

                var installConfig = ConfigurationManager.OpenMappedExeConfiguration(new ExeConfigurationFileMap { ExeConfigFilename = installConfigPath }, ConfigurationUserLevel.None);
                var installIntegrationConfig = ConfigurationManager.OpenMappedExeConfiguration(new ExeConfigurationFileMap { ExeConfigFilename = installIntegrationConfigPath }, ConfigurationUserLevel.None);
                var installInprotech = installConfig.ConnectionStrings.ConnectionStrings["Inprotech"];
                var installIntegration = installConfig.ConnectionStrings.ConnectionStrings["InprotechIntegration"];

                if (installInprotech == null) throw new Exception("Cannot find connection string");

                inprotechConnString = installInprotech.ConnectionString;
                inprotechIntegrationConnString = installIntegration.ConnectionString;

                StorageLocation = installConfig.AppSettings.Settings["StorageLocation"].Value;

                var testConfig = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);
                testConfig.ConnectionStrings.ConnectionStrings["Inprotech"].ConnectionString = inprotechConnString;
                testConfig.ConnectionStrings.ConnectionStrings["InprotechIntegration"].ConnectionString = inprotechIntegrationConnString;

                if (testConfig.AppSettings.Settings["e2e"]?.Value == null)
                {
                    testConfig.AppSettings.Settings.Add("e2e", "true");
                }

                testConfig.Save(ConfigurationSaveMode.Full, true);
                ConfigurationManager.RefreshSection("connectionStrings");
                ConfigurationManager.RefreshSection("appSettings");

                UpdateMailSettings(installIntegrationConfig);
            }
            else if (Env.UseDevelopmentHost)
            {
                (inprotechConnString, inprotechIntegrationConnString) = BuildE2EConnStringForDev();

                var devConfig = ConfigurationManager.OpenExeConfiguration(Env.InprotechServerDebugPath);
                if (SaveConnectionStringAndAppSettings(devConfig))
                    developmentConfigChanged = true;

                var devIntegrationServerConfig = ConfigurationManager.OpenExeConfiguration(Env.IntegrationServerDebugPath);
                if (SaveConnectionStringAndAppSettings(devIntegrationServerConfig))
                    developmentConfigChanged = true;

                var devStorageServiceConfig = ConfigurationManager.OpenExeConfiguration(Env.StorageServiceDebugPath);
                if (SaveConfigurationIfConnectionStringChanged(devStorageServiceConfig))
                    developmentConfigChanged = true;

                StorageLocation = DevelopmentHostStorageLocation;

                UpdateMailSettings(devIntegrationServerConfig);

                if (!Directory.Exists(StorageLocation))
                {
                    Directory.CreateDirectory(StorageLocation);
                }
            }

            if (!Directory.Exists(MailPickupLocation))
            {
                Directory.CreateDirectory(MailPickupLocation);
            }

            (string inprotechConnStr, string integrationConnStr) BuildE2EConnStringForDev()
            {
                var inprotechConnStr = ConfigurationManager.ConnectionStrings["Inprotech"].ConnectionString;
                inprotechConnStr = new SqlConnectionStringBuilder(inprotechConnStr) { InitialCatalog = "IPDEV_E2E" }.ConnectionString;
                var integrationConnStr = ConfigurationManager.ConnectionStrings["InprotechIntegration"].ConnectionString;
                integrationConnStr = new SqlConnectionStringBuilder(integrationConnStr) { InitialCatalog = "IPDEV_E2EIntegration" }.ConnectionString;
                return (inprotechConnStr, integrationConnStr);
            }

            bool SaveConfigurationIfConnectionStringChanged(Configuration devConfig)
            {
                if (devConfig.ConnectionStrings.ConnectionStrings["Inprotech"].ConnectionString != inprotechConnString ||
                    devConfig.ConnectionStrings.ConnectionStrings["InprotechIntegration"].ConnectionString != inprotechIntegrationConnString)
                {
                    devConfig.ConnectionStrings.ConnectionStrings["Inprotech"].ConnectionString = inprotechConnString;
                    devConfig.ConnectionStrings.ConnectionStrings["InprotechIntegration"].ConnectionString = inprotechIntegrationConnString;
                    devConfig.Save(ConfigurationSaveMode.Modified, true);
                    return true;
                }

                return false;
            }

            bool SaveStorageLocationIfChanged(Configuration devConfig)
            {
                if (devConfig.AppSettings.Settings["StorageLocation"].Value != DevelopmentHostStorageLocation)
                {
                    devConfig.AppSettings.Settings["StorageLocation"].Value = DevelopmentHostStorageLocation;
                    devConfig.Save(ConfigurationSaveMode.Modified, true);
                    return true;
                }

                return false;
            }

            bool SaveE2EIndicatorInAppSetting(Configuration devConfig)
            {
                if (string.IsNullOrEmpty(devConfig.AppSettings.Settings["e2e"]?.Value))
                {
                    devConfig.AppSettings.Settings.Add("e2e", "true");
                    devConfig.Save(ConfigurationSaveMode.Modified, true);
                    return true;
                }

                return false;
            }

            bool SaveConnectionStringAndAppSettings(Configuration config)
            {
                var changed = SaveConfigurationIfConnectionStringChanged(config);

                if (SaveStorageLocationIfChanged(config))
                    changed = true;

                if (SaveE2EIndicatorInAppSetting(config))
                    changed = true;

                return changed;
            }

            void UpdateMailSettings(Configuration configuration)
            {
                var mailSettings = (MailSettingsSectionGroup)configuration.GetSectionGroup("system.net/mailSettings");
                if (mailSettings == null || mailSettings.Smtp == null) throw new Exception("Cannot find mail settings");

                if (mailSettings.Smtp.DeliveryMethod != SmtpDeliveryMethod.SpecifiedPickupDirectory || mailSettings.Smtp.SpecifiedPickupDirectory.PickupDirectoryLocation != MailPickupLocation)
                {
                    mailSettings.Smtp.DeliveryMethod = SmtpDeliveryMethod.SpecifiedPickupDirectory;
                    mailSettings.Smtp.SpecifiedPickupDirectory.PickupDirectoryLocation = MailPickupLocation;
                }

                configuration.Save(ConfigurationSaveMode.Modified, true);

                ConfigurationManager.RefreshSection("mailSettings");
            }
        }

        public static string DetermineBackupLocation()
        {
            if (Try.Do(() =>
            {
                var fileInfo = new FileInfo(RemoteDatabaseBackupLocation);
                if (!File.Exists(LocalDatabaseBackupLocation))
                {
                    File.Copy(RemoteDatabaseBackupLocation, LocalDatabaseBackupLocation);
                }
                else
                {
                    var localBackupInfo = new FileInfo(RemoteDatabaseBackupLocation);
                    if (localBackupInfo.CreationTimeUtc != fileInfo.CreationTimeUtc ||
                        localBackupInfo.LastWriteTimeUtc != fileInfo.LastWriteTimeUtc ||
                        localBackupInfo.Length != fileInfo.Length)
                    {
                        // simple comparison.  Avoid restoring from network on every test.
                        File.Copy(RemoteDatabaseBackupLocation, LocalDatabaseBackupLocation, true);
                    }
                }
            }))
            {
                return LocalDatabaseBackupLocation;
            }

            // fall back to using remote database.
            return RemoteDatabaseBackupLocation;
        }

        /// <summary>
        ///     You are required to have
        ///     - FireFox installed
        ///     - IE Driver downloaded and in the location below
        ///     - Chrome Driver downloaded and in the location below
        /// </summary>
        public static class BrowserDriverLocations
        {
            /// <summary>
            ///     https://sites.google.com/a/chromium.org/chromedriver/downloads
            /// </summary>
            public const string Chrome = @"C:\Assets\E2E";

            /// <summary>
            ///     http://www.seleniumhq.org/download/ (choose 32-bit)
            /// </summary>
            public const string InternetExplorer = @"C:\Assets\E2E";

            /// <summary>
            ///     https://github.com/mozilla/geckodriver/releases (choose 32-bit)
            /// </summary>
            public const string FireFox = @"C:\Assets\E2E";
        }

        public static class Browser
        {
            public const string FireFoxReleaseVersion = "66.0";

            public const string FireFox = @"C:\Assets\E2E";

            public static string FireFoxBinaryLocation => $"{FireFox}\\FireFox {FireFoxReleaseVersion}\\core\\firefox.exe";
        }

        public static class Tools
        {
            public static string Upgrade
            {
                get
                {
                    var upgrade = new[]
                                  {
                                      @"C:\Web Apps Nightly Build\InprotechKaizen.Database\InprotechKaizen.Database.exe",
                                      Path.Combine(Path.GetDirectoryName(typeof(Program).Assembly.Location), @"..\..\..\InprotechKaizen.Database\bin\Debug\InprotechKaizen.Database.exe"),
                                      Path.Combine(Path.GetDirectoryName(typeof (Tools).Assembly.Location), @"..\InprotechKaizen.Database\InprotechKaizen.Database.exe")
                                  }.FirstOrDefault(File.Exists);

                    if (string.IsNullOrEmpty(upgrade)) throw new Exception("Cannot find InprotechKaizen.Database.exe");

                    return Path.GetFullPath(upgrade);
                }
            }
        }

        public static class TestSubject
        {
            public static string DefaultInstallInprotechServerRoot = "http://localhost/cpainpro/apps";

            public const string DefaultTestInprotechServerRoot = "http://localhost/cpainproma/apps";

            public const string DefaultTestIntegrationServerStatus = "http://localhost/inprotech-integration-server-defaultinstance/api/integrationserver/status";

            public const string DefaultTestStorageServiceStatus = "http://localhost/inprotech-storage-service-defaultinstance/api/storageservice/status";
        }

        public class InstanceNameResolver
        {
            public string ResolveInstanceName(string instancesRoot)
            {
                var instanceName = "instance-1";

                if (!Directory.Exists($@"{instancesRoot}\{instanceName}"))
                {
                    instanceName = Directory.Exists($@"{instancesRoot}")
                        ? Directory.EnumerateDirectories($"{instancesRoot}").FirstOrDefault()
                        : null;

                    if (string.IsNullOrWhiteSpace(instanceName))
                        return null;

                    instanceName = new DirectoryInfo(instanceName).Name;
                }

                return instanceName;
            }
        }
    }
}