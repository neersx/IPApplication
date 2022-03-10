using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class TaskMenu : IntegrationTest
    {
        [TearDown]
        public void CleanupFiles()
        {
            DbSetup.Do(setup =>
            {
                var alertSpawningBlocked = setup.DbContext.Set<SiteControl>().Single(sc => sc.ControlId == SiteControls.AlertSpawningBlocked);
                alertSpawningBlocked.BooleanValue = false;

                setup.DbContext.SaveChanges();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyDismissReminder(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            DbSetup.Do(setup =>
            {
                var alertSpawningBlocked = setup.DbContext.Set<SiteControl>().Single(sc => sc.ControlId == SiteControls.AlertSpawningBlocked);
                alertSpawningBlocked.BooleanValue = true;

                var siteControl = setup.DbContext.Set<SiteControl>().FirstOrDefault(sc => sc.ControlId == SiteControls.ReminderDeleteButton);
                if (siteControl != null) siteControl.IntegerValue = 2;
                setup.DbContext.SaveChanges();
            });

            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(-2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User);

            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);

            Assert.IsTrue(resultPage.FilterButton.Enabled);
            resultPage.FilterButton.Click();
            var page = new TaskPlannerSearchBuilderPageObject(driver);
            page.IncludeAdHocDatesCheckbox.Click();
            page.SearchButton.Click();
            driver.WaitForGridLoader();

            resultPage.OpenTaskMenuOption(0, "dismissReminder");
            driver.WaitForAngular();
            Assert.AreEqual("The Reminder has been successfully dismissed.", resultPage.SuccessMessage.Text);
            Assert.AreEqual(2, resultPage.Grid.Rows.Count);

            //Verify case weblinks in task menu
            resultPage.OpenTaskMenuOption(0, "caseWebLinks");
            Assert.AreEqual(driver.FindElement(By.Id("caseWebLinks")).Text, "Open Case Web Links");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyDismissFutureReminder(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            DbSetup.Do(setup =>
            {
                var alertSpawningBlocked = setup.DbContext.Set<SiteControl>().Single(sc => sc.ControlId == SiteControls.AlertSpawningBlocked);
                alertSpawningBlocked.BooleanValue = true;

                var siteControl = setup.DbContext.Set<SiteControl>().FirstOrDefault(sc => sc.ControlId == SiteControls.ReminderDeleteButton);
                if (siteControl != null) siteControl.IntegerValue = 2;
                setup.DbContext.SaveChanges();
            });

            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(-2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User);

            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);

            resultPage.OpenTaskMenuOption(2, "dismissReminder");
            Assert.AreEqual("The Reminder cannot be dismissed because its Due Date is in the future.", resultPage.AlertMessage.Text);
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
            resultPage.AlertOkButton.Click();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyDeferReminder(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            DbSetup.Do(setup =>
            {
                var siteControl = setup.DbContext.Set<SiteControl>().FirstOrDefault(sc => sc.ControlId == SiteControls.HOLDEXCLUDEDAYS);
                if (siteControl != null) siteControl.IntegerValue = 3;
                setup.DbContext.SaveChanges();
            });

            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(-2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(8), taskPlannerData.User);

            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            Assert.AreEqual(2, resultPage.Grid.Rows.Count);

            resultPage.OpenTaskMenuOption(1, "deferReminder", "toNextCalculatedDate");
            Assert.AreEqual("The Reminder has been successfully deferred.", resultPage.SuccessMessage.Text);
            Assert.AreEqual(2, resultPage.Grid.Rows.Count);
            Assert.False(resultPage.IsGridRowBold(2));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyDeferReminderAlmostDue(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            DbSetup.Do(setup =>
            {
                var siteControl = setup.DbContext.Set<SiteControl>().FirstOrDefault(sc => sc.ControlId == SiteControls.HOLDEXCLUDEDAYS);
                if (siteControl != null) siteControl.IntegerValue = 3;
                setup.DbContext.SaveChanges();
            });

            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(-2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(8), taskPlannerData.User);

            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            Assert.AreEqual(2, resultPage.Grid.Rows.Count);

            resultPage.OpenTaskMenuOption(0, "deferReminder", "toNextCalculatedDate");
            Assert.AreEqual("The Reminder cannot be deferred because either the Next Calculated Date is close to or past the Due Date.", resultPage.AlertMessage.Text);
            resultPage.AlertOkButton.Click();
            driver.WaitForAngular();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyMarkAsReadOrUnreadReminders(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(-2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(7), taskPlannerData.User);

            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);

            resultPage.OpenTaskMenuOption(2, "readReminder");
            driver.WaitForGridLoader();
            Assert.False(resultPage.IsGridRowBold(3));

            ReloadPage(driver);
            resultPage = new TaskPlannerPageObject(driver);
            resultPage.OpenTaskMenuOption(2, "unreadReminder");
            driver.WaitForGridLoader();
            Assert.True(resultPage.IsGridRowBold(3));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyChangeDueDateResponsibility(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            TestUser user = null;
            DbSetup.Do(x =>
            {
                user = new Users(x.DbContext)
                           .WithPermission(ApplicationTask.ChangeDueDateResponsibility)
                           .Create();
            });
            //Add Due Date Reminder in Database
            var @case = TaskPlannerService.InsertDueDateReminder(DateTime.Today.AddDays(1));
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForGridLoader();
            var builderPage = new TaskPlannerSearchBuilderPageObject(driver);
            resultPage.FilterButton.ClickWithTimeout();
            builderPage.IncludeDueDatesCheckbox.Click();
            builderPage.IncludeAdHocDatesCheckbox.Click();
            builderPage.IncludeRemindersCheckbox.Click();
            builderPage.ActingAsDueDateCheckbox.Click();
            resultPage.Cases.CaseReference.SendKeys(@case.Irn);
            //Search the Reminder for the case so created
            builderPage.SearchButton.Click();
            driver.WaitForGridLoader();
            //Verify Change Due Date Responsibility from Task Menu option
            resultPage.OpenTaskMenuOption(0, "changeDueDateResponsibility");
            driver.WaitForAngular();
            //Save Button should be disabled till any modification is done
            Assert.IsFalse(resultPage.ModalSaveButton.Enabled, "Save Button is Disabled when the Due Date Responsibility is not modified");
            Assert.AreEqual("Unassigned", resultPage.NamePickListPlaceholder, "Due Date Responsibility Picklist shows Unassigned when blank");
            resultPage.AssignToMe.Click();
            driver.WaitForAngular();
            resultPage.ModalSaveButton.Click();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual("Due date responsibility has been successfully changed.", resultPage.SuccessMessage.Text, "Due Date Responsibility has been successfully changed");
            //Verify Change Due Date Responsibility from Bulk Menu option
            resultPage.Grid.ActionMenu.SelectAll();
            resultPage.Grid.ActionMenu.OpenOrClose();
            resultPage.ChangeDueDateResponsibilityBulkOption("change-due-date-responsibility");
            driver.WaitForAngular();
            //Save Button should be enabled to save and remove any existing Due Date Responsibility
            Assert.IsTrue(resultPage.ModalSaveButton.Enabled, "Save Button is enabled when Change DUe Date Responsibility action is performed from Bulk action Menu");
            Assert.AreEqual(string.Empty, resultPage.NamePickListPlaceholder, "Due Date Responsibility Picklist shows as blank when invoked from Bulk action menu");
            resultPage.ModalSaveButton.Click();
            driver.WaitForAngular();
            resultPage.ModalRemoveButton.Click();
            driver.WaitForGridLoader();
            Assert.AreEqual("Due date responsibility has been successfully changed.", resultPage.SuccessMessage.Text, "Due Date Responsibility gets successfully removed");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyForwardReminders(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            DbSetup.Do(setup =>
            {
                var alertSpawningBlocked = setup.DbContext.Set<SiteControl>().Single(sc => sc.ControlId == SiteControls.AlertSpawningBlocked);
                alertSpawningBlocked.BooleanValue = true;
                setup.DbContext.SaveChanges();
            });

            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today, taskPlannerData.User);

            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(1, resultPage.Grid.Rows.Count);

            resultPage.OpenTaskMenuOption(0, "forwardReminder");
            driver.WaitForAngular();
            resultPage.NamesPicklist.Clear();
            resultPage.NamesPicklist.OpenPickList();
            resultPage.ClearButton(driver).Click();
            resultPage.SearchPicklistText.SendKeys("CCC");
            resultPage.SearchButton(driver).ClickWithTimeout();
            resultPage.ResultGrid.ClickRow(0);
            resultPage.NamesPicklist.Apply();
            driver.WaitForAngular();

            resultPage.ModalSaveButton.Click();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual("The Reminder has been successfully forwarded.", resultPage.SuccessMessage.Text);
            driver.WaitForGridLoader();
            Assert.AreEqual(2, resultPage.Grid.Rows.Count);
            Assert.False(resultPage.IsGridRowBold(1));

        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifySendEmail(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today, taskPlannerData.User);

            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForGridLoader();
            Assert.AreEqual(1, resultPage.Grid.Rows.Count);

            resultPage.OpenTaskMenuOption(0, "sendEmail");
            driver.WaitForAngular();
            resultPage.NamesPicklist.Clear();
            resultPage.NamesPicklist.OpenPickList();
            resultPage.SearchPicklistText.SendKeys("JAB");
            resultPage.SearchButton(driver).ClickWithTimeout();
            resultPage.ResultGrid.ClickRow(0);
            resultPage.NamesPicklist.Apply();
            driver.WaitForAngular();
            Assert.AreEqual("Bernard, Julie does not have an email address in the system, so the email cannot be sent to that name.", resultPage.ModalEmailWarningMessage.Text);
            Assert.True(resultPage.ModalSaveButton.IsDisabled());

            resultPage.NamesPicklist.OpenPickList();
            resultPage.ClearButton(driver).Click();
            resultPage.SearchPicklistText.SendKeys("CCC");
            resultPage.SearchButton(driver).ClickWithTimeout();
            resultPage.ResultGrid.ClickRow(0);
            resultPage.NamesPicklist.Apply();
            driver.WaitForAngular();
            Assert.False(resultPage.ModalSaveButton.IsDisabled());
            resultPage.ModalSaveButton.Click();
        }
    }
}