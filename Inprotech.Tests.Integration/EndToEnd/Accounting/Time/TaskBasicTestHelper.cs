using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portal;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    public static class TaskBasicTestHelper
    {
        public static void CheckAddition(NgWebDriver driver)
        {
            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            var totalEntries = entriesList.MasterRows.Count;
            page.AddButton.ClickWithTimeout();

            var activeRow = entriesList.MasterRows[0];
            var activityPicker = new AngularPicklist(driver, activeRow).ByName("wipTemplates");
            activityPicker.Typeahead.SendKeys(Keys.ArrowDown);
            activityPicker.Typeahead.SendKeys(Keys.ArrowDown);
            activityPicker.Typeahead.SendKeys(Keys.Enter);
            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.NarrativeText.SendKeys("edited narrative text");
            Assert.AreEqual(string.Empty, details.Narrative.InputValue, "Expect Narrative Title to be emptied when Narrative is edited.");
            activityPicker.Typeahead.SendKeys(Keys.ArrowDown);
            activityPicker.Typeahead.SendKeys(Keys.ArrowDown);
            activityPicker.Typeahead.SendKeys(Keys.Enter);
            Assert.True(details.NarrativeText.WithJs().GetValue().Contains("edited narrative text"), "Expect Narrative Text to not have been overriden.");
            details.SaveButton().WithJs().Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(totalEntries + 1, entriesList.MasterRows.Count, "Expected row to be added with activity only");
        }

        public static void CheckUpdate(NgWebDriver driver, TimeRecordingData dbData)
        {
            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            var newNotes = Fixture.String(20);
            var oldLocalValue = entriesList.MasterCellText(0, 10);
            entriesList.ToggleDetailsRow(0);
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();
            driver.WaitForAngularWithTimeout();

            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);

            editableRow.CaseRef.EnterAndSelect(dbData.Case2.Irn);
            driver.WaitForAngular();
            var newLocalValue = entriesList.MasterCellText(0, 10);
            Assert.AreNotEqual(newLocalValue, oldLocalValue, $"Time valuation done immediately on edit. Checking Local Value: OldValue-{oldLocalValue}, NewValue-{newLocalValue}");

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.Notes.Clear();
            details.Notes.SendKeys(newNotes);
            details.SaveButton().ClickWithTimeout();

            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.AreEqual(newNotes, details.Notes.Value(), "Expected notes to have been updated");
        }   

        public static void PostAll(NgWebDriver driver, TimeRecordingData dbData, PostAllResultExpected expected)
        {
            var page = new TimeRecordingPage(driver);
            page.PostButton.Click();

            var postTimePopup = new PostTimePopup(driver, "postTimeModal");

            Assert.AreEqual(expected.SelectedUserName, postTimePopup.TimeFor, $"Staff name displayed correctly as {expected.SelectedUserName}");
            Assert.AreEqual(dbData.HomeName, postTimePopup.Entity.Text, $"Entity is defaulted to home name i.e. {dbData.HomeName}");

            postTimePopup.Entity.Text = dbData.EntityName;
            postTimePopup.PostAllRadio.WithJs().Click();

            Assert.False(postTimePopup.PostButton.IsDisabled());

            PostAndCheckResults(driver, expected, postTimePopup, true);
        }

        public static void PostSelectedEntries(NgWebDriver driver, TimeRecordingData dbData, PostAllResultExpected expected)
        {
            var postTimePopup = new PostTimePopup(driver, "postTimeModal");

            Assert.AreEqual(expected.SelectedUserName, postTimePopup.TimeFor, $"Staff name displayed correctly as {expected.SelectedUserName}");
            Assert.AreEqual(dbData.HomeName, postTimePopup.Entity.Text, $"Entity is defaulted to home name i.e. {dbData.HomeName}");

            postTimePopup.Entity.Text = dbData.EntityName;
            
            Assert.False(postTimePopup.PostButton.IsDisabled());

            PostAndCheckResults(driver, expected, postTimePopup, false);
        }

        static void PostAndCheckResults(NgWebDriver driver, PostAllResultExpected expected, PostTimePopup postTimePopup, bool forBackGround)
        {
            postTimePopup.PostButton.Click();

            ProceedWithWarning(driver);

            if (forBackGround)
            {
                driver.WaitForAngularWithTimeout();
                var slider = new PageObjects.QuickLinks(driver);
                slider.Open("backgroundNotification");
            
                var backgroundNotificationPageObject = new BackgroundNotificationPageObject(driver);
                driver.Wait().ForTrue(() => backgroundNotificationPageObject.NotificationCount.Text.Equals("1"));
                backgroundNotificationPageObject.RowLink(0).WithJs().Click();
            }

            var postTimeFeedbackDlg = new PostFeedbackDlg(driver, "postTimeResDlg");
            var entriesPostedLabel = postTimeFeedbackDlg.TimeEntriesPostedLbl;
            var entriesPostedValue = postTimeFeedbackDlg.TimeEntriesPostedValue;
            var remainingIncompleteLbl = postTimeFeedbackDlg.IncompleteEntriesRemainingLbl;
            var remainingIncompleteValue = postTimeFeedbackDlg.IncompleteEntriesRemainingSpan;

            Assert.True(entriesPostedLabel.WithJs().GetInnerText().Contains("entries posted"), "Time entries posted");
            Assert.AreEqual(expected.PostedEntryCount.ToString(), entriesPostedValue.WithJs().GetInnerText(), $"Expected posted count to be {expected.PostedEntryCount}");
            if (expected.UnpostedEntryCount.HasValue)
            {
                Assert.AreEqual(expected.UnpostedEntryCount.ToString(), remainingIncompleteValue.WithJs().GetInnerText(), $"Expected incomplete count to be {expected.UnpostedEntryCount}");
                Assert.True(remainingIncompleteLbl.WithJs().GetInnerText().Contains("entries remaining"), "Incomplete time entries label is displayed");
            }
            else
            {
                Assert.False(remainingIncompleteLbl.WithJs().GetInnerText().Contains("entries remaining"), "Incomplete time entries label is not displayed");
            }
            postTimeFeedbackDlg.OkButton.WithJs().Click();
        }

        static void ProceedWithWarning(NgWebDriver driver)
        {
            var popups = new CommonPopups(driver);
            var confirm = popups.ConfirmModal;
            if (confirm != null)
            {
                var proceed = confirm.FindElements(By.XPath("//button[@type='button' and contains(text(),'Proceed')]"));
                var ngWebElements = proceed as NgWebElement[] ?? proceed.ToArray();
                if (ngWebElements.Any())
                    ngWebElements.First().ClickWithTimeout();
            }
        }
    }

    public class PostAllResultExpected
    {
        public string SelectedUserName { get; set; }
        public int PostedEntryCount { get; set; }
        public int? UnpostedEntryCount { get; set; }
    }
}