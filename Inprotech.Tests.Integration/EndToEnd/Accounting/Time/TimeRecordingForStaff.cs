using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingForStaff : IntegrationTest
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
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ViewForOtherStaff(BrowserType browserType)
        {
            TimeRecordingDbHelper.SetupFunctionSecurity(new []{FunctionSecurityPrivilege.CanRead}, _dbData.User.NameId);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password); 

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            Assert.NotNull(entriesList, "Expected the time entries list to be available");

            var timeForStaff = new AngularPicklist(driver).ByName("timeForStaff");
            timeForStaff.EnterAndSelect("Func");
            driver.WaitForAngular();
            entriesList = page.Timesheet;
            Assert.AreEqual(1, entriesList.MasterRows.Count, "Expected time entries to be returned for staff");
            entriesList.ToggleDetailsRow(0);
            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            var narrative = details.NarrativeText;
            var notes = details.Notes;
            Assert.True(narrative.Value().StartsWith("e2e-func"), "Expected entry with matching narrative to be displayed");
            Assert.True(notes.Value().StartsWith("e2e-func"), "Expected entry with matching notes to be displayed");
            
            timeForStaff.EnterAndSelect("NoFunc");
            Assert.True(timeForStaff.HasError, "Expected staff to not be found in the picklist");

            entriesList = page.Timesheet;
            Assert.AreEqual(0, entriesList.MasterRows.Count, "Expected no time entries to be returned");
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("btnPost")), "Expected Post Button to be hidden");
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.CssSelector("ipx-add-button button")), "Expected Add Button to be hidden");
            Assert.True(timeForStaff.HasError, "Expected Time For Staff typeahead to indicate error");
        }
    }
}
