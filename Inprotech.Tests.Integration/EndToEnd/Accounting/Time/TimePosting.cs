using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Names;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class PostAll : TimeRecordingReadOnly
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void PostAllWithWarning(BrowserType browserType)
        {
            AccountingDbHelper.SetupPeriod(withWarning: true);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);

            TaskBasicTestHelper.PostAll(driver, DbData, new PostAllResultExpected {SelectedUserName = DbData.StaffName.FormattedWithDefaultStyle(), PostedEntryCount = 5, UnpostedEntryCount = 2});

            ReloadPage(driver, true);
            var page = new TimeRecordingPage(driver);
            Enumerable.Range(0, 5).ToList()
                      .ForEach(i => Assert.True(page.PostedIcon(i).WithJs().IsVisible(), $"Row {i} entry is posted"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CheckDefaultsAndPostAll(BrowserType browserType)
        {
            AccountingDbHelper.SetupPeriod();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);

            TaskBasicTestHelper.PostAll(driver, DbData, new PostAllResultExpected {SelectedUserName = DbData.StaffName.FormattedWithDefaultStyle(), PostedEntryCount = 5, UnpostedEntryCount = 2});

            ReloadPage(driver, true);
            var page = new TimeRecordingPage(driver);
            Enumerable.Range(0, 5).ToList()
                      .ForEach(i => Assert.True(page.PostedIcon(i).WithJs().IsVisible(), $"Row {i} entry is posted"));
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class TimePosting : TimeRecordingReadOnly
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CheckPostSelected(BrowserType browserType)
        {
            AccountingDbHelper.SetupPeriod();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.PostButton.Click();
            var postTimePopup = new PostTimePopup(driver, "postTimeModal");

            postTimePopup.Entity.Text = DbData.EntityName;
            postTimePopup.PostSelectedRadio.WithJs().Click();
            driver.WaitForAngularWithTimeout();

            Assert.True(postTimePopup.PostButton.IsDisabled());
            Assert.AreEqual(3, postTimePopup.DatesWithDetails.Rows.Count, "3 days are displayed which has postable time entries");
            Assert.AreEqual("04:00", postTimePopup.DatesWithDetails.CellText(0, 2), "Total time for row 0 is: 4 hours");
            Assert.AreEqual("04:00", postTimePopup.DatesWithDetails.CellText(0, 3), "Total chargeable time for row 0 is: 4 hours");
            Assert.AreEqual("01:00", postTimePopup.DatesWithDetails.CellText(2, 2), "Total chargeable time for row 2 is: 1 hour");
            Assert.AreEqual("00:00", postTimePopup.DatesWithDetails.CellText(2, 3), "Total chargeable time for row 2 is: 0 hours");

            postTimePopup.DatesWithDetails.SelectRow(0);
            postTimePopup.DatesWithDetails.SelectRow(1);

            Assert.False(postTimePopup.PostButton.IsDisabled());

            postTimePopup.PostButton.Click();
            var postTimeFeedbackDlg = new PostFeedbackDlg(driver, "postTimeResDlg");
            var entriesPostedLabel = postTimeFeedbackDlg.TimeEntriesPostedLbl;
            var entriesPostedValue = postTimeFeedbackDlg.TimeEntriesPostedValue;
            var remainingIncompleteLbl = postTimeFeedbackDlg.IncompleteEntriesRemainingLbl;
            var remainingIncompleteValue = postTimeFeedbackDlg.IncompleteEntriesRemainingSpan;

            Assert.True(entriesPostedLabel.WithJs().GetInnerText().Contains("entries posted"), "Time entries posted");
            Assert.AreEqual("4", entriesPostedValue.WithJs().GetInnerText(), "Expected 4 records to have been posted");
            Assert.True(remainingIncompleteLbl.WithJs().GetInnerText().Contains("entries remaining"), "Incomplete time entries remaining");
            Assert.AreEqual("2", remainingIncompleteValue.WithJs().GetInnerText(), "Expected 2 incomplete records not posted");

            postTimeFeedbackDlg.OkButton.WithJs().Click();
            Assert.AreEqual(1, postTimePopup.DatesWithDetails.Rows.Count, "Posted days are no longer displayed when successful");

            postTimePopup.CloseModal();

            driver.WaitForAngular();

            page = new TimeRecordingPage(driver);
            Assert.True(page.IsRowMarkedAsPosted(1), "Child row is marked as posted");
            Assert.True(page.IsRowMarkedAsPosted(3), "Parent row is marked as posted");
            Enumerable.Range(0, 5).ToList()
                      .ForEach(i => Assert.True(page.PostedIcon(i).WithJs().IsVisible(), $"Row {i} entry is posted"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void PostIndividualEntry(BrowserType browserType)
        {
            AccountingDbHelper.SetupPeriod();
            DbSetup.Do(db =>
            {
                var today = DateTime.Today.AddDays(1);
                var currentPeriod = db.DbContext.Set<Period>().SingleOrDefault(_ => _.StartDate <= today && _.EndDate >= today);
                if (currentPeriod == null) return;
                currentPeriod.PostingCommenced = currentPeriod.StartDate.AddDays(-1);
                db.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            driver.WaitForAngularWithTimeout();

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Post();
            var postTimePopup = new PostTimePopup(driver, "postTimeModal");
            postTimePopup.PostButton.Click();

            var postTimeFeedbackDlg = new PostFeedbackDlg(driver, "postTimeResDlg");
            postTimeFeedbackDlg.OkButton.WithJs().Click();

            driver.WaitForAngular();

            page = new TimeRecordingPage(driver);
            Assert.True(page.IsRowMarkedAsPosted(0), "Child row is marked as posted");

            page.NextButton.ClickWithTimeout();
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Post();
            postTimePopup = new PostTimePopup(driver, "postTimeModal");
            postTimePopup.PostButton.Click();
            var alert = new AlertModal(driver);
            Assert.IsNotNull(alert, "Expected future date error to be displayed");
            var message = alert.FindElement(By.CssSelector("div.modal-body > p")).Text;
            Assert.IsTrue(message.Contains("future"), $"Expected future date error message to be displayed but was: {message}");
            alert.Ok();

            Assert.False(page.IsRowMarkedAsPosted(0), "Row has not been posted");
        }

        [TestCase(BrowserType.Chrome)]
        public void PostForAllStaff(BrowserType browserType)
        {
            AccountingDbHelper.SetupPeriod();
            DbSetup.Do(db =>
            {
                var today = DateTime.Today.AddDays(1);
                var currentPeriod = db.DbContext.Set<Period>().SingleOrDefault(_ => _.StartDate <= today && _.EndDate >= today);
                if (currentPeriod == null) return;
                currentPeriod.PostingCommenced = currentPeriod.StartDate.AddDays(-1);
                db.DbContext.SaveChanges();
                var driver = BrowserProvider.Get(browserType);
                SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
                var page = new TimeRecordingPage(driver);
                page.PostButton.Click();
                var postTimePopup = new PostTimePopup(driver, "postTimeModal")
                {
                    Entity =
                    {
                        Text = DbData.EntityName
                    }
                };

                Assert.True(postTimePopup.TimeForField.Displayed, "Displays name when Post For All Staff is OFF.");

                postTimePopup.PostForAllStaff.Click();
                postTimePopup.PostSelectedRadio.WithJs().Click();

                Assert.Throws<NoSuchElementException>(() =>
                {
                    var unused = postTimePopup.TimeForField.Displayed;
                }, "Expected name field to be hidden when Post For All Staff is ON.");
                Assert.True(postTimePopup.FromDatePicker.Input.Displayed, "Displays From Date when Post All Staff checkbox checked.");
                Assert.True(postTimePopup.ToDatePicker.Input.Displayed, "Displays To Date when Post All Staff checkbox checked.");

                postTimePopup.FromDatePicker.Open();
                postTimePopup.FromDatePicker.PreviousMonth();
                postTimePopup.DatesWithDetails.SelectRow(0);
                postTimePopup.PostButton.Click();
            });
        }
    }
}