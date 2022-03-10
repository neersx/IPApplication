using System;
using System.IO;
using System.Net;
using Inprotech.Tests.Integration.Utils._7z;

namespace Inprotech.Tests.Integration.Utils
{
    static class BrowserDownload
    {
        const string FireFoxReleasesUrl = "https://ftp.mozilla.org/pub/firefox/releases/{0}/win64/en-US/Firefox Setup {0}.exe";

        const string FireFoxReleaseVersion = Runtime.Browser.FireFoxReleaseVersion;

        public static void DownloadFireFox()
        {
            Download(Runtime.Browser.FireFox, string.Format(FireFoxReleasesUrl, FireFoxReleaseVersion), $"Firefox {FireFoxReleaseVersion}.zip", Runtime.Browser.FireFoxBinaryLocation);
        }

        static void Download(string savePath, string downloadUrl, string zipName, string browserBinary)
        {
            try
            {
                RunnerInterface.Log($"Retrieving {zipName}");
                Try.Retry(3, 1000, () => DownloadCore(savePath, downloadUrl, zipName, browserBinary));
            }
            catch(Exception ex)
            {
                RunnerInterface.Log($"Failed : {ex.Message}{Environment.NewLine}{ex.StackTrace}");
            }
            finally
            {
                RunnerInterface.Log($"{zipName} retrieved");
            }
        }

        static void DownloadCore(string savePath, string downloadUrl, string zipName, string browserBinary)
        {
            var zipPath = Path.Combine(savePath, zipName);
            var browserPath = Path.Combine(savePath, browserBinary);
            var extractPath = Path.Combine(savePath, Path.GetFileNameWithoutExtension(zipName));

            if (!File.Exists(zipPath))
            {
                using (var webClient = new WebClient())
                {
                    webClient.DownloadFile(downloadUrl, zipPath);
                }
                
                SevenZipHelper.ExtractToDirectory(zipPath, extractPath);
            }
            else if (!File.Exists(browserPath))
            {
                SevenZipHelper.ExtractToDirectory(zipPath, extractPath);
            }
        }
    }
}
