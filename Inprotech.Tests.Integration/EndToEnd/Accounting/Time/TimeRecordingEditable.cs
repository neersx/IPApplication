using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingEditable : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(withValueOnEntryPreference: true);
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
        public void EditTimeEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            driver.WaitForAngularWithTimeout();

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();

            // renew reference as grid row is re-drawn
            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.True(details.SaveButton().Displayed, "Expected Save button to be available");
            Assert.True(details.RevertButton().Displayed, "Expected Discard button to be available");

            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            editableRow.CaseRef.EnterAndSelect("e2e");

            var wipWarningsModal = new WipWarningsModal(driver);
            wipWarningsModal.Cancel();

            details.RevertButton().Click();
            var confirmDiscardModal = new DiscardChangesModal(driver);
            confirmDiscardModal.CancelDiscard();
            Assert.AreEqual(string.Empty, editableRow.CaseRef.Typeahead.Text, "Expected interim changes to be retained");

            details.RevertButton().Click();
            confirmDiscardModal = new DiscardChangesModal(driver);
            confirmDiscardModal.Discard();
            Assert.AreEqual(_dbData.Case.Irn, entriesList.Cell(0, "Case Ref.").Text, "Expected record to be reverted to original state");

            TaskBasicTestHelper.CheckUpdate(driver, _dbData);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ChangeEntryDate(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);

            var entriesCount = page.Timesheet.MasterRows.Count;

            page.ChangeEntryDate(0, "2000", 5);

            var newCount = page.Timesheet.MasterRows.Count;
            Assert.AreEqual(entriesCount - 1, newCount, "Expected entries to be refreshed after save.");
        }
    }
}