using System;
using System.IO;
using System.IO.Compression;
using System.Net;

namespace Inprotech.Tests.Integration.Utils
{
    internal static class WebDriverDownload
    {
        static string ChromeDriverVersion
        {
            get
            {
                var env = Environment.GetEnvironmentVariable("e2e.ChromeDriverVersion");
                return string.IsNullOrWhiteSpace(env) ? "85.0.4183.87" : env;
            }
        }

        static readonly string ChromeDriverUrl = $"http://chromedriver.storage.googleapis.com/{ChromeDriverVersion}/chromedriver_win32.zip";

        const string InternetExplorerDriverVersion = "2.53";
        const string InternetExplorerDriverBuild = "2.53.1";
        static readonly string InternetExplorerDriverUrl = $"http://selenium-release.storage.googleapis.com/{InternetExplorerDriverVersion}/IEDriverServer_Win32_{InternetExplorerDriverBuild}.zip";

        const string GeckoDriverVersion = "v0.24.0";
        static readonly string GeckoDriverUrl = $"https://github.com/mozilla/geckodriver/releases/download/{GeckoDriverVersion}/geckodriver-{GeckoDriverVersion}-win32.zip";

        public static void DownloadInternetExplorerDriver(string savePath)
        {
            Download(savePath, InternetExplorerDriverUrl, $"IEDriverServer_Win32_{InternetExplorerDriverBuild}.zip", "IEDriverServer.exe");
        }

        public static void DownloadChromeDriver(string savePath)
        {
            Download(savePath, ChromeDriverUrl, $"chromedriver_win32_{ChromeDriverVersion}.zip", "chromedriver.exe");
        }

        public static void DownloadGeckoDriver(string savePath)
        {
            // Selenium 3+
            Download(savePath, GeckoDriverUrl, $"geckodriver-{GeckoDriverVersion}-win32.zip", "geckodriver.exe");
        }

        static void Download(string savePath, string downloadUrl, string zipName, string driverName)
        {
            try
            {
                RunnerInterface.Log($"Started downloading {zipName}");
                Try.Retry(3, 1000, () => DownloadCore(savePath, downloadUrl, zipName, driverName));
            }
            catch(Exception ex)
            {
                RunnerInterface.Log($"Download failed : {ex.Message}");
            }
            finally
            {
                RunnerInterface.Log($"Ended downloading {zipName}");
            }
        }

        static void DownloadCore(string savePath, string downloadUrl, string zipName, string driverName)
        {
            var zipPath = Path.Combine(savePath, zipName);
            var driverPath = Path.Combine(savePath, driverName);
            if (!File.Exists(zipPath))
            {
                using (var webClient = new WebClient())
                {
                    webClient.DownloadFile(downloadUrl, Path.Combine(savePath, zipPath));
                }

                File.Delete(driverPath);

                ZipFile.ExtractToDirectory(zipPath, savePath);
            }
            else if (!File.Exists(driverPath))
            {
                ZipFile.ExtractToDirectory(zipPath, savePath);
            }
        }
    }
}
