using System.IO;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.PriorArt
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "16.0")]
    [TestFrom(DbCompatLevel.Release16)]
    public class PriorArtSearch : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        public void ExportSmallData(BrowserType browserType)
        {
            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);

            DeleteFilesFromDirectory(downloadsFolder, new[] {"PriorArtList.pdf"});
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/search-result?queryContext=900");

            var searchPage = new PriorArtSearchPageObject(driver);
            var grid = new AngularKendoGrid(driver, "searchResults", "a123");
            grid.SelectRow(0);
            grid.ActionMenu.OpenOrClose();
            searchPage.ExportToPdf.Click();
            new CommonPopups(driver).WaitForFlashAlert();
            var pdf = GetDownloadedFile(driver, "PriorArtList.pdf");
            Assert.AreEqual($"{downloadsFolder}\\PriorArtList.pdf", pdf);
        }

        static string GetDownloadedFile(NgWebDriver driver, string fileName)
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

        static void DeleteFilesFromDirectory(string directoryPath, string[] fileNames)
        {
            if (!Directory.Exists(directoryPath)) return;

            foreach (var fileName in fileNames)
            {
                var filePath = $"{directoryPath}\\{fileName}";
                if (File.Exists(filePath))
                {
                    File.Delete(filePath); 
                }
            }
        }
    }
}