using System.IO;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd
{
    public static class ExportHelper
    {
        public static string GetDownloadedFile(NgWebDriver driver, string fileName)
        {
            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);
            var filePath = string.Empty;
            var count = 0;
            while (count < 40)
            {
                driver.WaitForAngularWithTimeout(1000);

                var files = Directory.GetFiles(downloadsFolder, fileName);

                if (files.Any())
                {
                    filePath = files[0];
                    break;
                }

                count++;
            }

            return filePath;
        }

        public static void DeleteFilesFromDirectory(string directoryPath, string[] fileNames)
        {
            if (!Directory.Exists(directoryPath)) return;

            foreach (var fileName in fileNames)
            {
                var filePath = $"{directoryPath}\\{fileName}";
                if (File.Exists(filePath))
                {
                    File.Delete(filePath); //delete the downloaded file
                }
            }
        }
    }
}
