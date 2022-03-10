using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Security;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingForStaffOperations : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(withValueOnEntryPreference: true);
            AccountingDbHelper.SetupPeriod();
            _funcUserDisplayName = TimeRecordingDbHelper.SetupFunctionSecurity(new[]
            {
                FunctionSecurityPrivilege.CanRead,
                FunctionSecurityPrivilege.CanInsert,
                FunctionSecurityPrivilege.CanPost,
                FunctionSecurityPrivilege.CanUpdate
            }, _dbData.User.NameId);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        TimeRecordingData _dbData;
        string _funcUserDisplayName;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void AddForOtherStaff(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            page.StaffName.EnterAndSelect("Func");
 
            page.Timesheet.OpenTaskMenuFor(0);
            Assert.NotNull(page.AddButton);
            Assert.NotNull(page.ContextMenu.ContinueMenu);
            Assert.NotNull(page.ContextMenu.EditMenu);
            Assert.NotNull(page.ContextMenu.ChangeEntryDateMenu);
            Assert.NotNull(page.ContextMenu.PostMenu);
            
            Assert.Null(page.ContextMenu.DeleteMenu);
            Assert.Null(page.ContextMenu.AdjustMenu);

            TaskBasicTestHelper.CheckAddition(driver);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateForOtherStaff(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            page.StaffName.EnterAndSelect("Func");
 
            TaskBasicTestHelper.CheckUpdate(driver, _dbData);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void PostAllForOtherStaff(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            page.StaffName.EnterAndSelect("Func");
 
            TaskBasicTestHelper.PostAll(driver, _dbData, new PostAllResultExpected{SelectedUserName = _funcUserDisplayName, PostedEntryCount = 0, UnpostedEntryCount = 1});
        }
    }
}