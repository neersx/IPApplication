using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration
{
    [SetUpFixture]
    public class Assm
    {
        internal const int TimeoutSeconds = 20;

        [OneTimeSetUp]
        public static void AssmInit()
        {
            Runtime.ConfigureConnectionStringsAndAppSettings(out var developmentConfigChanged);

            if (DevelopmentHost.IsRunning())
            {
                return;
            }

            if (Env.IsTeamCity())
            {
                DatabaseRestore.Restore();
            }
            else
            {
                DatabaseRestore.GrantAllPermissions();
                DatabaseRestore.EnableServiceBroker();
                DatabaseRestore.UpdateDatabaseForE2E();
                DatabaseRestore.RebuildIntegrationDatabase();
            }

            if (Env.UseDevelopmentHost)
            {
                if (developmentConfigChanged)
                {
                    DevelopmentHost.Stop();
                    DevelopmentIntegrationServer.Stop();
                }

                if (!DevelopmentHost.IsRunning())
                {
                    DevelopmentHost.Start();
                    DbModelFiles.Remove();
                    AutoDbCleaner.Assm();
                }

                if (!DevelopmentIntegrationServer.IsRunning())
                {
                    DevelopmentIntegrationServer.Start();
                }

                if (!DevelopmentStorageService.IsRunning())
                {
                    DevelopmentStorageService.Start();
                }
            }

            WebDriverDownload.DownloadGeckoDriver(Runtime.BrowserDriverLocations.FireFox);

            WebDriverDownload.DownloadChromeDriver(Runtime.BrowserDriverLocations.Chrome);

            WebDriverDownload.DownloadInternetExplorerDriver(Runtime.BrowserDriverLocations.InternetExplorer);

            BrowserDownload.DownloadFireFox();
        }

        [OneTimeTearDown]
        public static void AssmCleanup()
        {
            BrowserProvider.CloseBrowsers();
        }
    }
}