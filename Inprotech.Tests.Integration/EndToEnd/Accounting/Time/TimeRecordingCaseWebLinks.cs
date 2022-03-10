using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingCaseWebLinks : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        TimeRecordingData _dbData;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void OpenCaseWebLinksExistsForTimeEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            // un-posted entry - should be enabled for case row
            entriesList.OpenTaskMenuFor(0);
            Assert.False(page.ContextMenu.OpenCaseWebLinksMenu.WithJs().HasClass("disabled"));
            Assert.AreEqual(driver.FindElement(By.Id("caseWebLinks")).Text, "Open Case Web Links");
            var displayOverlaps = page.DisplayOverlaps();
            displayOverlaps.Click();

            // posted entry - should be enabled for case row
            entriesList.OpenTaskMenuFor(4);
            Assert.False(page.ContextMenu.OpenCaseWebLinksMenu.WithJs().HasClass("disabled"));
            displayOverlaps.Click();

            // incomplete entry - should be disabled if case not present
            entriesList.OpenTaskMenuFor(5);
            Assert.True(page.ContextMenu.OpenCaseWebLinksMenu.WithJs().HasClass("disabled"));
        }
    }
}