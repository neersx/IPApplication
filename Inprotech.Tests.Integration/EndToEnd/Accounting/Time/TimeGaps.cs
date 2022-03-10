using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Authentication;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;
using System.Linq;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeGaps : IntegrationTest
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
        string _funcUserDisplayName;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ForCurrentUser(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var staffName = page.StaffName.GetText();
            VerifyElements(page, driver, staffName);
            
            driver.With<QuickLinks>(slider =>
            {
                slider.Open("timeGaps");

                var container = slider.SlideContainer;
                var gapsPage = new TimeGapsPage(driver, container);

                Assert.AreEqual("08:00", gapsPage.RangeFrom.Input.Value());
                Assert.AreEqual("18:00", gapsPage.RangeTo.Input.Value());

                var list = gapsPage.Gaps;

                Assert.AreEqual(1, list.Rows.Count, "Only one gap displayed");
                Assert.AreEqual("13:30", list.CellText(0, 1), $"One time gap with start time: {list.CellText(0, 1)}");
                Assert.AreEqual("18:00", list.CellText(0, 2), $"One time gap with finish time: {list.CellText(0, 2)}");
                Assert.AreEqual("04:30", list.CellText(0, 3), $"One time gap with duration : {list.CellText(0, 3)}");

                gapsPage.RangeFrom.SetValue("0500");
                gapsPage.RangeTo.SetValue("1830");

                Assert.AreEqual(3, list.Rows.Count, "Three time gaps displayed after change in time");
            });

            driver.Navigate().Refresh();
            var entriesList = page.Timesheet;
            var oldCount = entriesList.Rows.Count;
            entriesList = page.Timesheet;
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();
            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.Notes.SendKeys(Fixture.AlphaNumericString(5));

            driver.With<QuickLinks>(slider =>
            {
                slider.Open("timeRecordingPreferences");

                var is12HourFormat = new AngularCheckbox(driver).ById("userPreference_32");
                var applyButton = page.ApplyButton();

                is12HourFormat.Click();
                driver.WaitForAngularWithTimeout();

                applyButton.Click();

                var infoModal = new InfoModal(driver);
                infoModal.Ok();

                slider.Close();
            });

            driver.With<QuickLinks>(slider =>
            {
                slider.Open("timeGaps");

                var gapsPage = new TimeGapsPage(driver, slider.SlideContainer);

                Assert.AreEqual("05:00 AM", gapsPage.RangeFrom.Input.Value().ToUpper());
                Assert.AreEqual("06:30 PM", gapsPage.RangeTo.Input.Value().ToUpper());
                var list = gapsPage.Gaps;
                Assert.AreEqual(3, list.Rows.Count, "Three time gaps displayed after change in time");

                list.SelectRow(0);
                list.SelectRow(2);

                gapsPage.Add();
                var confirmModal = new ConfirmModal(driver);
                confirmModal.Cancel().Click();
                
                gapsPage.Add();
                confirmModal = new ConfirmModal(driver);
                confirmModal.Proceed();

                slider.Close();
            });

            entriesList = page.Timesheet;
            var newCount = oldCount + 2;
            const int firstRecord = 0;
            var lastRecord = newCount - 1;

            entriesList.Rows[lastRecord].WithJs().ScrollIntoView();
            var detailsOfLastRecord = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            detailsOfLastRecord.RevertButton().Click();

            Assert.AreEqual(newCount, entriesList.MasterRows.Count, "Two new entries are added");
            
            Assert.True(page.IncompleteIcon(firstRecord).Displayed, "Expected Incomplete icon to be displayed for the new row");
            Assert.AreEqual("01:30 PM", entriesList.MasterCellText(firstRecord, 4).ToUpper());
            Assert.AreEqual("06:30 PM", entriesList.MasterCellText(firstRecord, 5).ToUpper());
            Assert.AreEqual("05:00", entriesList.MasterCellText(firstRecord, 6));

            Assert.True(page.IncompleteIcon(lastRecord ).WithJs().IsVisible(), "Expected Incomplete icon to be displayed for the new row");
            Assert.AreEqual("05:00 AM", entriesList.MasterCellText(lastRecord, 4).ToUpper());
            Assert.AreEqual("07:00 AM", entriesList.MasterCellText(lastRecord, 5).ToUpper());
            Assert.AreEqual("02:00", entriesList.MasterCellText(lastRecord, 6));

            driver.With<AuthenticationPage>(_ =>
            {
                _.Logout();
            });

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);
            driver.With<QuickLinks>(slider =>
            {
                slider.Open("timeGaps");

                var container = slider.SlideContainer;
                var gapsPage = new TimeGapsPage(driver, container);

                Assert.AreEqual("05:00 AM", gapsPage.RangeFrom.Input.Value().ToUpperInvariant(), "Expected 'Time Gaps - From' to be retained");
                Assert.AreEqual("06:30 PM", gapsPage.RangeTo.Input.Value().ToUpperInvariant(), "Expected 'Time Gaps - To' to be retained");
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ForOtherStaff(BrowserType browserType)
        {
            _funcUserDisplayName = TimeRecordingDbHelper.SetupFunctionSecurity(new[]
            {
                FunctionSecurityPrivilege.CanRead,
                FunctionSecurityPrivilege.CanInsert
            }, _dbData.User.NameId);

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            page.StaffName.EnterAndSelect("Func");
            page.PreviousButton.Click();
            VerifyElements(page, driver, _funcUserDisplayName);

            page.TodayButton.Click();
            VerifyElements(page, driver, _funcUserDisplayName);

            driver.With<QuickLinks>(slider =>
            {
                slider.Open("timeGaps");

                var container = slider.SlideContainer;
                var panel = new TimeGapsPage(driver, container);
                var list = panel.Gaps;

                Assert.AreEqual("08:00", list.CellText(0, 1));
                Assert.AreEqual("10:30", list.CellText(0, 2));
                Assert.AreEqual("02:30", list.CellText(0, 3));

                Assert.AreEqual("11:30", list.CellText(1, 1));
                Assert.AreEqual("18:00", list.CellText(1, 2));
                Assert.AreEqual("06:30", list.CellText(1, 3));

                list.SelectRow(0);
                panel.Add();
                slider.Close();
            });

            var entriesList = page.Timesheet;
            var detailsOfLastRecord = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            detailsOfLastRecord.RevertButton().Click();
            
            Assert.AreEqual("10:30", entriesList.MasterCellText(0, 4));
            Assert.AreEqual("11:30", entriesList.MasterCellText(0, 5));
            Assert.AreEqual("01:00", entriesList.MasterCellText(0, 6));

            Assert.AreEqual("08:00", entriesList.MasterCellText(1, 4));
            Assert.AreEqual("10:30", entriesList.MasterCellText(1, 5));
            Assert.AreEqual("02:30", entriesList.MasterCellText(1, 6));
        }

        static void VerifyElements(TimeRecordingPage page, NgWebDriver driver, string staffName)
        {
            var selectedDate = page.SelectedDate.Value;
            var entriesList = page.Timesheet;
            Assert.IsTrue(entriesList.MasterRows.All(_ => _.Displayed), "Expected continued rows to be displayed");
            driver.With<QuickLinks>(slider =>
            {
                slider.Open("timeGaps");

                var container = slider.SlideContainer;
                var panel = new TimeGapsPage(driver, container);
                var timeGapStaff = panel.StaffName.WithJs().GetInnerText();
                var timeGapDate = panel.SelectedDate.WithJs().GetInnerText();
                Assert.AreEqual(staffName, timeGapStaff, "Expected selected staff name to be displayed");
                Assert.AreEqual(selectedDate, timeGapDate, "Expected selected date to be displayed");

                var list = panel.Gaps;

                Assert.IsTrue(list.MasterRows.All(_ => _.Displayed), "Expected continued rows to be displayed");

                slider.Close();
            });
        }
    }

    public class TimeGapsPage : PageObject
    {
        public TimeGapsPage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public AngularKendoGrid Gaps => new AngularKendoGrid(Driver, "timeGaps");
        public NgWebElement StaffName => Driver.FindElement(By.CssSelector("div[name='staffName'] > span"));
        public NgWebElement SelectedDate => Driver.FindElement(By.CssSelector("div[name='selectedDate'] > span"));
        public AngularTimePicker RangeFrom => new AngularTimePicker(Driver, Container).FindElement(By.Id("rangeFrom"));
        public AngularTimePicker RangeTo => new AngularTimePicker(Driver, Container).FindElement(By.Id("rangeTo"));

        public void Add()
        {
            Driver.FindElement(By.CssSelector("button[name='add']")).WithJs().Click();
        }
    }
}