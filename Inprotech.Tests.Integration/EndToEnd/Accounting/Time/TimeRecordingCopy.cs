using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingCopy : IntegrationTest
    {
        TimeRecordingData _dbData;

        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(withHoursOnlyTime: true);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CopyTimeEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            page.CopyButton.ClickWithTimeout();

            var modal = new CopyTimeModal(driver);
            Assert.True(modal.Modal.Displayed, "Recent entries modal is displayed");
            Assert.AreEqual(10, modal.Grid.Rows.Count, "Recent records are displayed");
            Assert.True(modal.Grid.ColumnValues(modal.Grid.FindColByText("Date")).All(_ => !string.IsNullOrWhiteSpace(_)), "Expected entry dates to be displayed");

            var instructorName = modal.Grid.CellText(1, 2); 
            var activity = modal.Grid.CellText(1, 3); 
            var narrative = modal.Grid.CellText(1, 4); 
            modal.Grid.ClickRow(1);

            var warnings = new WipWarningsModal(driver);
            Assert.True(warnings.Modal.Displayed, "FinancialWarnings warnings popup");
            warnings.Proceed();

            var activeRow = new TimeRecordingPage.EditableRow(driver, page.Timesheet, 0);

            Assert.AreEqual(_dbData.Case.Irn, activeRow.CaseRef.InputValue);
            Assert.AreEqual(instructorName, activeRow.Name.InputValue, $"Instructor name is {instructorName}" );
            Assert.AreEqual(activity, activeRow.Activity.InputValue, $"Activity is {activity}" );
            var details = new TimeRecordingPage.DetailSection(driver, page.Timesheet, 0);

            Assert.AreEqual(narrative, details.NarrativeText.Value(), $"Narrative is {narrative}" );
            Assert.False(page.CopyButton.Enabled, "Copy button is disabled while a new record is being added");
            details.SaveButton().WithJs().Click();
            var popup = new CommonPopups(driver);
            Assert.IsTrue(popup.FlashAlertIsDisplayed());
        }
    }
}