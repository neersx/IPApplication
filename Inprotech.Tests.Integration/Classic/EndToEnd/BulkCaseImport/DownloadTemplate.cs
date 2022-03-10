using System.Collections.Generic;
using System.IO;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    [TestFixture]
    [Category(Categories.E2E)]
    public class DownloadTemplate : IntegrationTest
    {
        [SetUp]
        public void EnsureDefault()
        {
            CleanupFiles();

            StorageFolder.MakeAvailable("PatentImport.xltx", @"bulkCaseImport-templates\standard");
            StorageFolder.MakeAvailable("TrademarkImport.xltx", @"bulkCaseImport-templates\standard");
        }

        [TearDown]
        public void CleanupFiles()
        {
            CleanDownloaded();

            StorageFolder.DeleteFrom(@"bulkCaseImport-templates\custom");
            StorageFolder.DeleteFrom(@"bulkCaseImport-templates\standard");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void WorkingWithTemplates(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var user = new Users().WithPermission(ApplicationTask.BulkCaseImport).Create();

            SignIn(driver, "/#/bulkcaseimport/import", user.Username, user.Password);

            driver.With<ImportCasePageObject>(page =>
                                              {
                                                  var original = Downloaded().Count;

                                                  Assert.AreEqual(2, page.StandardTemplates.Count(), "Should contain 2 standard templates to start with");

                                                  Assert.True(new[] {"PatentImport.xltx", "TrademarkImport.xltx"}.SequenceEqual(page.StandardTemplates.Select(_ => _.Text)), "should contain standard templates PatentImport.xltx, Trademark.xltx");

                                                  Assert.IsEmpty(page.CustomTemplates);

                                                  page.StandardTemplates.ClickByName("TrademarkImport.xltx");

                                                  Try.Wait(10, 1000, () => Downloaded().Count > original);
                                                  
                                                  Assert.AreEqual(Downloaded().Count, original + 1, "should have downloaded TrademarkImport");
                                              });

            // Administrator deletes CPA supplied templates
            StorageFolder.DeleteFrom(@"bulkCaseImport-templates\standard");

            ReloadBulkCaseImportPage(driver);

            driver.With<ImportCasePageObject>(page =>
                                              {
                                                  Assert.IsEmpty(page.StandardTemplates, "Should not have any more standard templates");

                                                  Assert.IsEmpty(page.CustomTemplates, "Should not have any more custom templates");
                                              });

            // Administrator adds Firm supplied templates for Case Import
            StorageFolder.MakeAvailable("PatentImport.xltx", @"bulkCaseImport-templates\custom", "Fabrikam Patent Portfolio.csv");
            StorageFolder.MakeAvailable("PatentImport.xltx", @"bulkCaseImport-templates\custom", "Fabrikam Trademark Portfolio.csv");

            ReloadBulkCaseImportPage(driver);

            driver.With<ImportCasePageObject>(page =>
                                              {
                                                  var original = Downloaded().Count;

                                                  Assert.IsEmpty(page.StandardTemplates, "Should not have any more standard templates");

                                                  Assert.True(new[] {"Fabrikam Patent Portfolio.csv", "Fabrikam Trademark Portfolio.csv"}.SequenceEqual(page.CustomTemplates.Select(_ => _.Text)), "should contain custom templates Fabrikam Portfolios.csv");

                                                  page.CustomTemplates.ClickByName("Fabrikam Patent Portfolio.csv");

                                                  Try.Wait(10, 1000, () => Downloaded().Count > original);

                                                  Assert.AreEqual(Downloaded().Count, original + 1, "should have downloaded Fabrikam Patent Portfolio.csv");
                                              });
        }

        static void ReloadBulkCaseImportPage(NgWebDriver driver)
        {
            driver.Visit("/#/bulkcaseimport");
            driver.Visit("/#/bulkcaseimport/import");
        }

        static List<string> Downloaded()
        {
            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);

            var xltx = Directory.GetFiles(downloadsFolder, "*.xltx");

            var csv= Directory.GetFiles(downloadsFolder, "*.csv");
            
            return xltx.Union(csv)
                .Where(_ => MatchesStandardTemplates(_) || MatchesFabrikam(_))
                .ToList();
        }

        static void CleanDownloaded()
        {
            var importTemplates = Downloaded();
            while (importTemplates.Any())
            {
                var thisOne = importTemplates.First();
                FileSetup.DeleteFile(thisOne);
                importTemplates.Remove(thisOne);
            }
        }

        static bool MatchesFabrikam(string path)
        {
            return Path.GetFileName(path).StartsWith("Fabrikam") && Path.GetExtension(path) == ".csv";
        }
        static bool MatchesStandardTemplates(string path)
        {
            return (Path.GetFileName(path).StartsWith("TrademarkImport") || Path.GetFileName(path).StartsWith("PatentImport")) 
                && Path.GetExtension(path) == ".xltx";
        }

    }
}