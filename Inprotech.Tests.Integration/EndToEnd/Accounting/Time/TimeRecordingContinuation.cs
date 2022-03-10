using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingContinuationBase : IntegrationTest
    {
        protected TimeRecordingData DbData { get; set; }

        [SetUp]
        public void Setup()
        {
            DbData = TimeRecordingDbHelper.Setup(withStartTime: true);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ContinueTimeEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            if (browserType == BrowserType.Chrome) // TODO: Investigate how to display inline dialog in IE
            {
                var continuedColumn = entriesList.MasterCell(1, 2);
                var continuedIcon = continuedColumn.FindElement(By.CssSelector("ipx-inline-dialog > span.inline-dialog > span.cpa-icon-clock-o"));
                continuedIcon.Click();
                driver.WaitForAngular();
                var popup = driver.FindElement(By.TagName("popover-container"));
                Assert.IsTrue(popup.Displayed, "Expected continuation summary to be displayed");
            }

            var duration = entriesList.CellText(1, "Duration");
            Assert.AreEqual("02:00", duration, "Expected duration for continued time to display accumulated time");

            entriesList.OpenTaskMenuFor(1);
            page.ContextMenu.Continue();
            driver.WaitForAngular();

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.True(details.SaveButton().Displayed, "Expected Save button to be available");
            Assert.True(details.RevertButton().Displayed, "Expected Discard button to be available");
            Assert.True(details.ClearButton().Displayed, "Expected Reset button to be available");
            Assert.True(details.Narrative.Enabled, "Expected Narrative picklist to be available");
            Assert.True(details.NarrativeText.Enabled, "Expected Narrative picklist to be available");
            Assert.True(details.Notes.Enabled, "Expected Notes to be available");

            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            Assert.False(editableRow.CaseRef.Enabled, "Expected case typeahead to be disabled");
            Assert.AreEqual(DbData.Case.Irn, editableRow.CaseRef.GetText(), "Expected case to be defaulted");
            Assert.False(editableRow.Name.Enabled, "Expected name typeahead to be disabled");
            Assert.False(editableRow.Activity.Enabled, "Expected activity typeahead to be disabled");
            Assert.True(editableRow.Activity.GetText().StartsWith("CONTINUED"), "Expected Activity to be defaulted");
            editableRow.Duration.SetValue("1");
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("03:00", details.AccumulatedDuration, "Expected Accumulated Duration to be reflected in details section");
            details.SaveButton().WithJs().Click();
            driver.WaitForAngularWithTimeout();

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();
            driver.WaitForAngular();

            var continuedEntryEditRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            duration = continuedEntryEditRow.Duration.Input.Value();
            Assert.AreEqual("01:00", duration, "Expected Duration to reflect value only for child entry");
            Assert.AreEqual("03:00", details.AccumulatedDuration, "Expected Accumulated Duration to be reflected in details section");
            continuedEntryEditRow.Duration.SetValue("10");
            continuedEntryEditRow.Activity.Clear();
            continuedEntryEditRow.Activity.EnterAndSelect(DbData.NewActivity.WipCode);
            Assert2.WaitTrue(3, 800, () => DbData.NewActivity.Description.Equals(continuedEntryEditRow.Activity.GetText()), "Search should return some results");
            var continuedEntryDetails = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            var notes = "Changing notes for continued entry, expect to propagate!";
            continuedEntryDetails.Notes.Clear();
            continuedEntryDetails.Notes.SendKeys(notes);
            continuedEntryDetails.SaveButton().ClickWithTimeout();
            driver.WaitForAngular();

            var entriesWithNewActivity = page.Timesheet.ColumnValues(9, 8, true).Count(_ => _ == DbData.NewActivity.Description);
            Assert.AreEqual(3, entriesWithNewActivity, "All the entries belonging to the child continued entry, are updated with the new activity");

            var detailChild = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.AreEqual(notes, detailChild.DisabledNotesText);
            detailChild.ClickDisabledNotes(browserType);
            driver.WaitForAngularWithTimeout();
            var newNotes = "Now the notes are completely different!! ";
            var detailsEditableRow = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            detailsEditableRow.Notes.Clear();
            detailsEditableRow.Notes.SendKeys(newNotes);
            detailsEditableRow.SaveButton().Click();
            driver.WaitForAngular();

            page.Timesheet.ToggleDetailsRow(2);
            var detailParent = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.AreEqual(newNotes, detailParent.DisabledNotesText);

            page.SearchButton.Click();
            new TimeSearchPage(driver).VerifyInSearchResults(6);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ContinueIncompleteTimeEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            entriesList.OpenTaskMenuFor(6);
            page.ContextMenu.Continue();
            driver.WaitForAngular();

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            details.Notes.SendKeys(Keys.Enter);
            editableRow.Duration.SetValue("1");
            driver.WaitForAngularWithTimeout();
            details.SaveButton().WithJs().Click();
            driver.WaitForAngularWithTimeout();

            entriesList = page.Timesheet;
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();
            driver.WaitForAngular();

            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.True( details.AccumulatedDuration.StartsWith("01:00"), "Expected Accumulated Duration to be reflected in details section");

            details.RevertButton().Click();
        }
    }
}