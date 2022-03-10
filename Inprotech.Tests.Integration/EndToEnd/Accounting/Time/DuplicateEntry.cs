using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DuplicateEntry : IntegrationTest
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
        public void DuplicateTimeEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);
            Duplicate(driver, 0);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        public void DuplicatePostedTime(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);
            Duplicate(driver, 4);
        }

        static void Duplicate(NgWebDriver driver, int rowIndex)
        {
            var page = new TimeRecordingPage(driver);
            var popup = new CommonPopups(driver);
            var entriesList = page.Timesheet;
            var values = new List<string>();
            Enumerable.Range(4, 6).ToList().ForEach(i => { values.Add(entriesList.CellText(rowIndex, i)); });
            entriesList.OpenTaskMenuFor(rowIndex);
            page.ContextMenu.DuplicateEntry();

            var dialog = new DuplicateDlg(driver);
            for (var i = 0; i < 10; i++)
            {
                if (string.IsNullOrWhiteSpace(dialog.StartDatePicker.Value))
                    SetDates(dialog);
                else
                    break;
            }

            dialog.Apply();

            popup.WaitForFlashAlert();
            var alertMessage = popup.FlashAlert().Text;
            Assert.True(alertMessage.Contains("5"), $"Expected alert to contain '5' but was '{alertMessage}'");

            var difference = DateTime.Today.DayOfWeek - DayOfWeek.Monday;
            var lastMonday = difference > 0 ? -1 * difference : -1 * (7 + difference);

            page.SelectedDate.GoToDate(lastMonday);
            driver.WaitForAngular();
            Assert.GreaterOrEqual(page.Timesheet.Rows.Count, 1);

            if (page.Timesheet.Rows.Count == 1)
            {
                Enumerable.Range(4, 6).ToList().ForEach(i => { Assert.AreEqual(values[i - 4], entriesList.CellText(0, i)); });
            }
        }

        static void SetDates(DuplicateDlg dialog)
        {
            dialog.StartDatePicker.GoToDate(-7);
            dialog.EndDatePicker.GoToDate(-1);
        }
    }
}
