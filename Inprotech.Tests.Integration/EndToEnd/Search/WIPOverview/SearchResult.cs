using System;
using System.Linq;
using System.Threading;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Search.Export;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Search.WIPOverview
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SearchResult : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie, Ignore = "Fails consistently ni IE only")]
        public void VerifyBillingWorksheet(BrowserType browserType)
        {
            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);

            ExportHelper.DeleteFilesFromDirectory(downloadsFolder, new[] {"BillingWorksheetExtended.pdf"});

            var user = new Users().WithPermission(ApplicationTask.BillingWorksheet).Create();

            DbSetup.Do(x =>
            {
                var settingString = @"5UYNwOPkrq6FJOUSs/SFLLHBzTPeYJe9RhXgPjsAhpbsd8ISQdT1M0hzsP/MiSkUU41uINBym3QRKfjv08Ftyow1m9IbvbDP/kzyfLmKvCgnCAXeIidnIWz9p01v6yF8DQuJ0RrgUcWFtciu7WL0AL1hVNqHhvhPMDaL5si0Tb0Y8hN8v6YrQJeGS95/VC959sMgcaAXas9dSTHMLW0AGh1+k5WK3gVsY81jru2X3bIeVLl7LlVZ1XfsbGX/jKl+";
                var setting = x.DbContext.Set<ExternalSettings>().SingleOrDefault(_ => _.ProviderName == "ReportingServicesSetting");

                if (setting != null)
                {
                    setting.Settings = settingString;
                    setting.IsComplete = true;
                }
                else
                {
                    x.DbContext.Set<ExternalSettings>().Add(new ExternalSettings("ReportingServicesSetting")
                    {
                        Settings = settingString,
                        IsComplete = true
                    });
                }

                x.DbContext.SaveChanges();
            });
            
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/search-result?queryKey=41&queryContext=200", user.Username, user.Password);

            new WIPOverviewSearchPageObject(driver);
            var grid = new AngularKendoGrid(driver, "searchResults", "a123");
            grid.ActionMenu.OpenOrClose();
            Assert.IsTrue(grid.ActionMenu.Option("create-billing-worksheet").Disabled());
            grid.SelectRow(0);
            grid.ActionMenu.OpenOrClose();
            Assert.IsFalse(grid.ActionMenu.Option("create-billing-worksheet").Disabled());
            driver.Hover(grid.ActionMenu.Option("create-billing-worksheet").FindElement(By.ClassName("cpa-icon-right")));
            driver.WaitForAngularWithTimeout();
            grid.ActionMenu.Option("pdf").WithJs().Click();
            new CommonPopups(driver).WaitForFlashAlert();

            var currentLastFinished = DbSetup.Do(x => x.DbContext.Set<ReportContentResult>()
                                                .Where(_ => _.Finished != null)
                                                .Max(_ => _.Finished));
            
            while (true)
            {
                var lastFinished = DbSetup.Do(x => x.DbContext.Set<ReportContentResult>()
                                                    .Where(_ => _.Finished != null)
                                                    .Max(_ => _.Finished));
                
                if (currentLastFinished == null && lastFinished != null)
                    break;

                if (currentLastFinished != null && lastFinished != null && lastFinished > currentLastFinished)
                    break;

                Thread.Sleep(TimeSpan.FromSeconds(1));
            }

            var pdf = ExportHelper.GetDownloadedFile(driver, "BillingWorksheet.pdf");
            Assert.AreEqual($"{downloadsFolder}\\BillingWorksheet.pdf", pdf);
            
            DbSetup.Do(x =>
            {
                var setting = x.DbContext.Set<SettingValues>().Single(_ => _.SettingId == 34);
                setting.IntegerValue = 15;
                x.DbContext.SaveChanges();
            });
        }
    }
}
