using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DeletePostedTimeBase : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(withValueOnEntryPreference: true);
            AccountingDbHelper.SetupPeriod();
            TimeRecordingDbHelper.SetAccessForEditPostedTask(_dbData.User, Allow.Modify | Allow.Delete);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        protected TimeRecordingData _dbData;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void Delete(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            driver.WaitForAngularWithTimeout();

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Post();
            new PostTimePopup(driver, "postTimeModal").PostButton.Click();
            driver.WaitForAngular();

            new PostFeedbackDlg(driver, "postTimeResDlg").OkButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();

            var totalEntries = page.Timesheet.MasterRows.Count;

            page.DeleteEntry(0);

            Assert.AreEqual(totalEntries - 1, page.Timesheet.MasterRows.Count, "Expected row to be deleted");
        }
    }
}