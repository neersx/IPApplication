using Inprotech.Tests.Integration.DbHelpers;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeOverlaps : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            DbData = TimeRecordingDbHelper.Setup(withHoursOnlyTime: true);
        }

        TimeRecordingData DbData { get; set; }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ViewingTimeOverlaps(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            var displayOverlaps = page.DisplayOverlaps();

            var entriesList = page.Timesheet;
            Assert.IsEmpty(entriesList.FindElements(By.CssSelector("span.overlap")), "Expected no entries to be highlighted.");

            displayOverlaps.Click();
            Assert.True(page.IsRowMarkedAsOverlap(0), "Expected overlapping entry to be highlighted");
            Assert.True(page.IsRowMarkedAsOverlap(1), "Expected overlapping entry to be highlighted");
            for (var i = 2; i < entriesList.MasterRows.Count; i++)
            {
                Assert.False(page.IsRowMarkedAsOverlap(i), $"Expected non-overlapping row {i} to not be highlighted");    
            }

            displayOverlaps.Click();
            Assert.IsEmpty(entriesList.FindElements(By.CssSelector("span.overlap")), "Expected no entries to be highlighted.");
        }
    }
}