using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EditPostedTimeDateChange : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(withValueOnEntryPreference: true);
            AccountingDbHelper.SetupPeriod();
            TimeRecordingDbHelper.SetAccessForEditPostedTask(_dbData.User);
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
        public void ChangeDateForPostedTime(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            driver.WaitForAngularWithTimeout();

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();
            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            editableRow.Duration.Input.Clear();
            editableRow.Duration.SetValue("00:30");
            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().Click();

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Post();
            new PostTimePopup(driver, "postTimeModal").PostButton.Click();
            driver.WaitForAngular();

            new PostFeedbackDlg(driver, "postTimeResDlg").OkButton.WithJs().Click();
            driver.WaitForAngular();

            var entryData = TimeEntryDataFor(0, entriesList);
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.ChangeEntryDate();
            var changeEntryDateDialog = new ChangeEntryDateModal(driver);
            changeEntryDateDialog.NewDate().GoToDate(1);
            Assert.IsTrue(changeEntryDateDialog.NewDate().ErrorIcon.Displayed, "Expected error to display for future dates");
            changeEntryDateDialog.Cancel().ClickWithTimeout();

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.ChangeEntryDate();
            changeEntryDateDialog = new ChangeEntryDateModal(driver);
            changeEntryDateDialog.NewDate().GoToDate(-3);
            changeEntryDateDialog.Save();
            driver.WaitForAngularWithTimeout();

            page.SelectedDate.GoToDate(-3);
            driver.WaitForAngularWithTimeout();
            entriesList = page.Timesheet;
            Assert.AreEqual(1, entriesList.Rows.Count, "Expected time entry to be moved to new date");
            Assert.AreEqual(entryData, TimeEntryDataFor(0, entriesList));
        }

        static dynamic TimeEntryDataFor(int rowIndex, AngularKendoGrid grid)
        {
            return new
            {
                Start = grid.CellText(rowIndex, "Start"),
                Finish = grid.CellText(rowIndex, "Finish"),
                Duration = grid.CellText(rowIndex, "Duration"),
                Case = grid.CellText(rowIndex, "Case Ref."),
                Name = grid.CellText(rowIndex, "Name"),
                Activity = grid.CellText(rowIndex, "Activity"),
                LocalValue = grid.CellText(rowIndex, "Local Value")
            };
        }
    }
}