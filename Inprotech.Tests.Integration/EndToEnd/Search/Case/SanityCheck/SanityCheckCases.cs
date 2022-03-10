using System;
using System.IO;
using System.Linq;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Search.Case.BulkUpdate;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;
using OpenQA.Selenium.Interactions;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.SanityCheck
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SanityCheckCases : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AbilityToSubmitSanityCheckForMultipleCases(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                var caseOne = new CaseBuilder(x.DbContext).Create("e2e_bu1irn", true, null, ct, pt);
                new CaseBuilder(x.DbContext).Create("e2e_bu2", true, null, ct, pt);
                var caseName = caseOne.CaseNames.First(y => y.NameTypeId == "I");
                var internalUser = new Users().Create();
                var backgroundProcess = new BackgroundProcess
                {
                    Id = Fixture.Integer(),
                    IdentityId = internalUser.Id,
                    ProcessType = BackgroundProcessType.SanityCheck.ToString(),
                    Status = (int) StatusType.Completed,
                    StatusDate = DateTime.Now,
                    StatusInfo = string.Empty
                };

                var sanityCheckResult = new SanityCheckResult
                {
                    Id = Fixture.Integer(),
                    ProcessId = backgroundProcess.Id,
                    CaseId = caseOne.Id,
                    IsWarning = false,
                    CanOverride = false,
                    DisplayMessage = "Instructor is mandatory for the Case but is missing."
                };
                x.DbContext.Set<BackgroundProcess>().Add(backgroundProcess);
                x.DbContext.Set<SanityCheckResult>().Add(sanityCheckResult);
                x.DbContext.Set<CaseName>().Remove(caseName);
                x.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.ResultsGrid.SelectRow(1);
            page.BulkOperationButton.Click();
            page.SanityCheckButton.Click();
            var notificationCount = page.NotificationButton.Count == 0 ? 0 : page.NotificationTextCount;
            page.NotificationCount(notificationCount);
            page.NotificationButton.First().Click();
            Assert.IsTrue(page.LatestSanityCheckLink.Displayed);

            page.LatestSanityCheckLink.Click();
            Assert.IsTrue(page.StatusHeading.Displayed);
            Assert.IsTrue(page.CaseRefHeading.Displayed);
            Assert.IsTrue(page.CaseOfficeHeading.Displayed);
            Assert.IsTrue(page.CaseStaffHeading.Displayed);
            Assert.IsTrue(page.CaseSignatoryHeading.Displayed);
            Assert.IsTrue(page.DisplayMessageHeading.Displayed);
            Assert.IsTrue(page.MessageText.Displayed);
            Assert.IsTrue(page.CaseLinkText.Displayed);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyExportSanityCheckResults(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                var caseOne = new CaseBuilder(x.DbContext).Create("e2e_bu1irn", true, null, ct, pt);
                new CaseBuilder(x.DbContext).Create("e2e_bu2", true, null, ct, pt);
                var caseName = caseOne.CaseNames.First(y => y.NameTypeId == "I");
                var internalUser = new Users().Create();
                var backgroundProcess = new BackgroundProcess
                {
                    Id = Fixture.Integer(),
                    IdentityId = internalUser.Id,
                    ProcessType = BackgroundProcessType.SanityCheck.ToString(),
                    Status = (int) StatusType.Completed,
                    StatusDate = DateTime.Now,
                    StatusInfo = string.Empty
                };

                var sanityCheckResult = new SanityCheckResult
                {
                    Id = Fixture.Integer(),
                    ProcessId = backgroundProcess.Id,
                    CaseId = caseOne.Id,
                    IsWarning = false,
                    CanOverride = false,
                    DisplayMessage = "Instructor is mandatory for the Case but is missing."
                };
                x.DbContext.Set<BackgroundProcess>().Add(backgroundProcess);
                x.DbContext.Set<SanityCheckResult>().Add(sanityCheckResult);
                x.DbContext.Set<CaseName>().Remove(caseName);
                x.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.ResultsGrid.SelectRow(1);
            page.BulkOperationButton.Click();
            page.SanityCheckButton.Click();
            var notificationCount = page.NotificationButton.Count == 0 ? 0 : page.NotificationTextCount;
            page.NotificationCount(notificationCount);
            page.NotificationButton.First().Click();
            page.LatestSanityCheckLink.Click();
            Assert.True(page.ExportToExcel.Displayed);
            Assert.True(page.ExportToPdf.Displayed);
            Assert.True(page.ExportToWord.Displayed);

            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);

            DeleteFilesFromDirectory(downloadsFolder, new[] {"SanityCheckResults.xlsx", "SanityCheckResults.docx", "SanityCheckResults.pdf"});

            page.ExportToExcel.Click();
            var xlsx = GetDownloadedFile(driver, "SanityCheckResults.xlsx");
            Assert.AreEqual($"{downloadsFolder}\\SanityCheckResults.xlsx", xlsx);

            page.ExportToWord.Click();
            var docx = GetDownloadedFile(driver, "SanityCheckResults.docx");
            Assert.AreEqual($"{downloadsFolder}\\SanityCheckResults.docx", docx);

            page.ExportToPdf.Click();
            var pdf = GetDownloadedFile(driver, "SanityCheckResults.pdf");
            Assert.AreEqual($"{downloadsFolder}\\SanityCheckResults.pdf", pdf);
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
                    File.Delete(filePath); //delete the downloaded file
                }
            }
        }
    }
}