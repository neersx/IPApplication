using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EditPostedContinuedTime : TimeRecordingEditPostedTimeBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditPostedContinuedTimeSuccessfully(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            entriesList.OpenTaskMenuFor(1);
            page.ContextMenu.Post();

            var postTimePopup = new PostTimePopup(driver, "postTimeModal");
            postTimePopup.PostButton.Click();
            var postTimeFeedbackDlg = new PostFeedbackDlg(driver, "postTimeResDlg");
            postTimeFeedbackDlg.OkButton.WithJs().Click();

            entriesList = page.Timesheet;
            entriesList.OpenTaskMenuFor(1);
            page.ContextMenu.Edit();
            driver.WaitForAngular();
            
            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.ConfirmModal, "Confirmation to edit posted entry is displayed");
            popups.ConfirmModal.Proceed();

            driver.WaitForAngular();
            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 1);
            editableRow.Duration.SetValue("0200");

            editableRow.Activity.EnterAndSelect("NEW");
            var newActivity = editableRow.Activity.InputValue;

            Assert.IsFalse(editableRow.Name.Enabled, "Expected Name to be disabled when editing posted entries");
            var instructorName = editableRow.Name.InputValue;

            editableRow.CaseRef.Clear();
            editableRow.CaseRef.EnterAndSelect(DbData.Case2.Irn);
            Assert.AreEqual(instructorName, editableRow.Name.InputValue, "Expected Name to be unchanged.");
            Assert.IsTrue(editableRow.CaseRef.HasError, "Expected Case to be invalid for a different instructor");

            editableRow.CaseRef.Clear();
            editableRow.CaseRef.EnterAndSelect(DbData.NewCaseSameDebtor.Irn);

            var wipWarningsModal = new WipWarningsModal(driver);
            wipWarningsModal.Proceed();
            driver.WaitForAngular();
            var newCase = editableRow.CaseRef.InputValue;

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.NarrativeText.Clear();
            details.NarrativeText.SendKeys("New narrative text!!");

            details.SaveButton().Click();
            Assert.True(popups.FlashAlertIsDisplayed(), "Success message displayed about edit success");

            Assert.AreEqual("03:00", entriesList.CellText(1, "Duration"), "Expected new Duration to be saved");
            Assert.AreEqual(newCase, entriesList.CellText(1, "Case Ref."), "Expected new Case to be saved.");
            Assert.AreEqual(newActivity, entriesList.CellText(1, "Activity"), "Expected new Activity to be saved.");
            Assert.AreEqual(instructorName, entriesList.CellText(1, "Name"), "Expected Name to be unchanged.");

            var detailsNew = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.AreEqual("New narrative text!!", detailsNew.NarrativeText.GetAttribute("value"));
        }
    }

    public class TimeRecordingEditPostedTimeBase : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            DbData = TimeRecordingDbHelper.Setup(withValueOnEntryPreference: true);
            AccountingDbHelper.SetupPeriod();
            TimeRecordingDbHelper.SetAccessForEditPostedTask(DbData.User);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        protected TimeRecordingData DbData { get; set; }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingEditingPostedTime : TimeRecordingEditPostedTimeBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditPostedTimeEntryUnableEditAlert(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            driver.WaitForAngularWithTimeout();

            entriesList.OpenTaskMenuFor(4);
            page.ContextMenu.Edit();

            var popups = new CommonPopups(driver);
            driver.WaitForAngular();
            Assert.AreEqual("Unable to Complete", popups.AlertModal.Title, "Entry not editable due to the entry being billed");
            Assert.AreEqual("The WIP item generated by this posted time entry has been billed. This posted time entry cannot be edited or deleted.", popups.AlertModal.Description, "Entry not editable due to the entry being billed");

            popups.AlertModal.Ok();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditPostedTimeEntrySuccessfully(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            driver.WaitForAngularWithTimeout();

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Post();
            new PostTimePopup(driver, "postTimeModal").PostButton.Click();
            driver.WaitForAngular();

            new PostFeedbackDlg(driver, "postTimeResDlg").OkButton.WithJs().Click();
            driver.WaitForAngular();

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();

            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.ConfirmModal, "Confirmation to edit posted entry is displayed");
            popups.ConfirmModal.Proceed();

            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            editableRow.Duration.SetValue("0200");

            editableRow.Activity.EnterAndSelect("NEW");
            var newActivity = editableRow.Activity.InputValue;

            Assert.IsFalse(editableRow.Name.Enabled, "Expected Name to be disabled when editing posted entries");
            var instructorName = editableRow.Name.InputValue;

            editableRow.CaseRef.Clear();
            editableRow.CaseRef.SendKeys(DbData.Case2.Irn);
            editableRow.CaseRef.Blur();
            Assert.AreEqual(instructorName, editableRow.Name.InputValue, "Expected Name to be unchanged.");
            Assert.IsTrue(editableRow.CaseRef.HasError, "Expected Case to be invalid for a different instructor");

            editableRow.CaseRef.Clear();
            editableRow.CaseRef.EnterAndSelect(DbData.NewCaseSameDebtor.Irn);

            var wipWarningsModal = new WipWarningsModal(driver);
            wipWarningsModal.Proceed();
            driver.WaitForAngular();
            var newCase = editableRow.CaseRef.InputValue;

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.NarrativeText.Clear();
            details.NarrativeText.SendKeys("New narrative text!!");

            details.SaveButton().Click();
            Assert.True(popups.FlashAlertIsDisplayed(), "Success message displayed about edit success");

            Assert.AreEqual("02:00", entriesList.CellText(0, "Duration"), "Expected new Duration to be saved");
            Assert.AreEqual(newCase, entriesList.CellText(0, "Case Ref."), "Expected new Case to be saved.");
            Assert.AreEqual(newActivity, entriesList.CellText(0, "Activity"), "Expected new Activity to be saved.");
            Assert.AreEqual(instructorName, entriesList.CellText(0, "Name"), "Expected Name to be unchanged.");

            var detailsNew = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.AreEqual("New narrative text!!", detailsNew.NarrativeText.GetAttribute("value"));
        }
    }
}