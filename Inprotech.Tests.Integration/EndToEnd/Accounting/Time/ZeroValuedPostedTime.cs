using Inprotech.Tests.Integration;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Accounting;
using Inprotech.Tests.Integration.EndToEnd.Accounting.Time;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ZeroValuedPostedTime : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(withEntriesToday: false);
            AccountingDbHelper.SetupPeriod();
            TimeRecordingDbHelper.SetAccessForEditPostedTask(_dbData.User, Allow.Modify | Allow.Delete);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        TimeRecordingData _dbData;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void Delete(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            AddAndPost(page, entriesList, driver);
            var totalEntries = page.Timesheet.MasterRows.Count;
            page.DeleteEntry(0);

            Assert.AreEqual(totalEntries - 1, page.Timesheet.MasterRows.Count, "Expected row to be deleted");
        }

        void AddAndPost(TimeRecordingPage page, AngularKendoGrid entriesList, NgWebDriver driver)
        {
            page.AddButton.ClickWithTimeout();
            var activeRow = entriesList.MasterRows[0];
            var durationPicker = activeRow.FindElement(By.Id("elapsedTime"));
            durationPicker.FindElement(By.TagName("input")).SendKeys("1234");
            durationPicker.FindElement(By.TagName("input")).SendKeys(Keys.Tab);
            var editableRow = new TimeRecordingPage.EditableRow(driver, page.Timesheet, 0);
            editableRow.CaseRef.EnterAndSelect(_dbData.Case.Irn);
            var wipWarningsModal = new WipWarningsModal(driver);
            wipWarningsModal.Proceed();
            editableRow.Activity.EnterExactSelectAndBlur("FREE");
            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().WithJs().Click();

            ReloadPage(driver);
            page = new TimeRecordingPage(driver);
            entriesList = page.Timesheet;
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Post();
            new PostTimePopup(driver, "postTimeModal").PostButton.Click();
            driver.WaitForAngular();
            new PostFeedbackDlg(driver, "postTimeResDlg").OkButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void Edit(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            AddAndPost(page, entriesList, driver);

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();
            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.ConfirmModal, "Confirmation to edit posted entry is displayed");
            popups.ConfirmModal.Proceed();

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            var newNarrative = Fixture.AlphaNumericString(50);
            details.NarrativeText.WithJs().Focus();
            details.NarrativeText.Clear();
            details.NarrativeText.SendKeys(newNarrative);
            details.SaveButton().WithJs().Click();
            driver.WaitForAngularWithTimeout();

            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.AreEqual(newNarrative, details.NarrativeText.Value(), "Expected Narrative Text to be updated");

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();
            popups = new CommonPopups(driver);
            Assert.NotNull(popups.ConfirmModal, "Confirmation to edit posted entry is displayed");
            popups.ConfirmModal.Proceed();

            var editableRow = new TimeRecordingPage.EditableRow(driver, page.Timesheet, 0);
            editableRow.Activity.Clear();
            editableRow.Activity.EnterExactSelectAndBlur("E2E");
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().WithJs().Click();
            Assert.NotNull(popups.AlertModal, "Error is displayed when changing activity");
            popups.AlertModal.Ok();

            editableRow.Activity.Clear();
            editableRow.Activity.EnterExactSelectAndBlur("FREE");
            editableRow.CaseRef.Clear();
            editableRow.CaseRef.EnterAndSelect(_dbData.NewCaseSameDebtor.Irn);
            var wipWarningsModal = new WipWarningsModal(driver);
            wipWarningsModal.Proceed();
            details.SaveButton().WithJs().Click();
            Assert.NotNull(popups.AlertModal, "Error is displayed when changing case");
            popups.AlertModal.Ok();
        }
    }
}