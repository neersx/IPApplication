using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ExportValidCombination : IntegrationTest
    {
        [OneTimeSetUp]
        [TearDown]
        public void TestCleanup()
        {
            CleanDownloaded();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ValidCombinationsDownload(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/validcombination");
            
            var downloadTypes = new Dictionary<string, string>
                                {
                                    {"Action", "action"},
                                    {"Basis", "basis"},
                                    {"Category", "category"},
                                    {"Checklist", "checklist"},
                                    {"Property Type", "propertyType"},
                                    {"Case Relationship", "relationship"},
                                    {"Status", "status"},
                                    {"Sub Type", "subtype"}
                                };

            foreach (var option in downloadTypes)
            {
                driver.Navigate().Refresh();

                var searchTypeCombo = new SelectElement(driver.FindElement(By.Name("searchcharacteristic")));
                var bulkActions = new ActionMenu(driver, option.Value);
                var search = new SearchOptions(driver);
                var grid = new KendoGrid(driver, "validCombinationSearchResults");

                searchTypeCombo.SelectByText(option.Key);
                search.SearchButton.WithJs().Click();
                driver.WaitForAngular();

                grid.SelectRow(0);

                bulkActions.OpenOrClose();

                bulkActions.Option("export-excel").WithJs().Click();

                Thread.Sleep(TimeSpan.FromSeconds(2)); // should we consider file system watcher?

                Assert.AreEqual(1, Downloaded().Count(), "Downloaded excel export for " + option.Key);
                CleanDownloaded();
            }
        }

        static List<string> Downloaded()
        {
            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);
            return Directory.GetFiles(downloadsFolder, "Search Result*.xlsx").ToList();
        }

        static void CleanDownloaded()
        {
            var searchResults = Downloaded();
            while (searchResults.Any())
            {
                var thisOne = searchResults.First();
                File.Delete(thisOne);
                searchResults.Remove(thisOne);
            }
        }
    }
}