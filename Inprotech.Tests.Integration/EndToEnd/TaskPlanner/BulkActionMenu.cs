using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class BulkActionMenu : IntegrationTest
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
        [TestCase(BrowserType.Ie)]
        public void VerifyDismissReminders(BrowserType browserType)
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
            var grid = resultPage.Grid;
            Assert.AreEqual(3, grid.Rows.Count);
           
            Assert.IsTrue(resultPage.FilterButton.Enabled);
            resultPage.FilterButton.Click();
            var page = new TaskPlannerSearchBuilderPageObject(driver);
            page.IncludeAdHocDatesCheckbox.Click();
            page.SearchButton.Click();
            driver.WaitForGridLoader();

            grid.ActionMenu.OpenOrClose();
            driver.WaitForAngular();
            grid.ActionMenu.SelectAll();
            Assert.False(grid.ActionMenu.Option("dismiss-reminders").GetAttribute("class").Contains("disabled"));
            grid.ActionMenu.ClearAll();
            resultPage.SelectGridRow(1);
            grid.ActionMenu.OpenOrClose();
            grid.ActionMenu.Option("dismiss-reminders").Click();
            driver.WaitForAngular();
            Assert.AreEqual("The Reminders have been successfully dismissed.", resultPage.SuccessMessage.Text);
            Assert.AreEqual(2, resultPage.Grid.Rows.Count);

            resultPage.SelectGridRow(1);
            resultPage.SelectGridRow(2);
            grid.ActionMenu.OpenOrClose();
            grid.ActionMenu.Option("dismiss-reminders").Click();
            var alertMessage = resultPage.AlertMessage.Text;
            Assert.True(alertMessage.Contains("One or more of the selected tasks cannot be dismissed because either the Due Date is in the future, there are no Reminders or you do not have permission. They are highlighted in red."));
            Assert.True(alertMessage.Contains("The remaining tasks have been successfully dismissed."));
            resultPage.AlertOkButton.Click();
            driver.WaitForAngular();
            Assert.AreEqual(1, resultPage.Grid.Rows.Count);
            
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyDeferReminders(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            DbSetup.Do(setup =>
            {
                var siteControl = setup.DbContext.Set<SiteControl>().FirstOrDefault(sc => sc.ControlId == SiteControls.HOLDEXCLUDEDAYS);
                if (siteControl != null) siteControl.IntegerValue = 2;
                setup.DbContext.SaveChanges();
            });

            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(-2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(7), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(10), taskPlannerData.User);

            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            var grid = resultPage.Grid;
            driver.WaitForGridLoader();
            Assert.AreEqual(4, resultPage.Grid.Rows.Count);
            resultPage.SelectGridRow(1);
            resultPage.SelectGridRow(2);
            grid.ActionMenu.OpenOrClose();
            resultPage.OpenDeferBulkOption("defer-to-next-calculated-date");
            driver.WaitForAngular();
            Assert.AreEqual("None of the selected tasks can be deferred because either the Next Calculated Date is close to or past the Due Date, or they have no Reminders.", resultPage.AlertMessage.Text);
            resultPage.AlertOkButton.Click();

            grid.ActionMenu.OpenOrClose();
            grid.ActionMenu.ClearAll();
            resultPage.SelectGridRow(2);
            resultPage.SelectGridRow(3);
            resultPage.SelectGridRow(4);
            grid.ActionMenu.OpenOrClose();
            resultPage.OpenDeferBulkOption("defer-to-entered-date");
            driver.WaitForAngular();
            resultPage.DeferEnteredDate.GoToDate(6);
            driver.WaitForAngular();
            resultPage.EnteredDateDeferButton.ClickWithTimeout();
            Assert.True(resultPage.AlertMessage.Text.Contains($"One or more of the selected tasks cannot be deferred because either the entered date {today.AddDays(6):dd-MMM-yyyy} is close to or past the Due Date, or they have no Reminders. They are highlighted in red."));
            Assert.True(resultPage.AlertMessage.Text.Contains("The remaining tasks have been successfully deferred."));
            resultPage.AlertOkButton.Click();
            driver.WaitForGridLoader();
            Assert.True(resultPage.HasGridRowError(2));
            Assert.True(resultPage.HasGridRowError(3));
            Assert.False(resultPage.HasGridRowError(4));

            grid.ActionMenu.OpenOrClose();
            grid.ActionMenu.ClearAll();
            resultPage.SelectGridRow(3);
            resultPage.SelectGridRow(4);
            grid.ActionMenu.OpenOrClose();
            resultPage.OpenDeferBulkOption("defer-to-next-calculated-date");
            driver.WaitForAngular();
            Assert.AreEqual("The Reminders have been successfully deferred.", resultPage.SuccessMessage.Text);
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
            var grid = resultPage.Grid;
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
            resultPage.SelectGridRow(2);
            resultPage.SelectGridRow(3);
            grid.ActionMenu.OpenOrClose();
            resultPage.OpenMarkAsBulkOption("mark-as-unread");
            driver.WaitForGridLoader();
            Assert.True(resultPage.IsGridRowBold(2));
            Assert.True(resultPage.IsGridRowBold(3));
            resultPage.SelectGridRow(2);
            resultPage.SelectGridRow(3);
            grid.ActionMenu.OpenOrClose();
            resultPage.OpenMarkAsBulkOption("mark-as-read");
            driver.WaitForGridLoader();
            Assert.False(resultPage.IsGridRowBold(2));
            Assert.False(resultPage.IsGridRowBold(3));
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
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today.AddDays(2), taskPlannerData.User);

            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForGridLoader();
            Assert.AreEqual(2, resultPage.Grid.Rows.Count);

            resultPage.SelectGridRow(1);
            resultPage.SelectGridRow(2);
            resultPage.Grid.ActionMenu.OpenOrClose();
            resultPage.Grid.ActionMenu.Option("forward-reminders").Click();
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
            Assert.AreEqual("The Reminders have been successfully forwarded.", resultPage.SuccessMessage.Text);
            driver.WaitForGridLoader();
            Assert.AreEqual(4, resultPage.Grid.Rows.Count);
            
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifySelectAll(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            DbSetup.Do(setup =>
            {
                var siteControl = setup.DbContext.Set<SiteControl>().FirstOrDefault(sc => sc.ControlId == SiteControls.ReminderDeleteButton);
                if (siteControl != null) siteControl.IntegerValue = 0;
                setup.DbContext.SaveChanges();
            });

            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(-1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today.AddDays(3), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(4), taskPlannerData.User);

            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            var grid = resultPage.Grid;
            Assert.AreEqual(6, grid.Rows.Count);
            grid.ActionMenu.OpenOrClose();
            driver.WaitForAngular();
            grid.ActionMenu.SelectAll();
            Assert.False(grid.ActionMenu.Option("dismiss-reminders").GetAttribute("class").Contains("disabled"));
            Assert.False(grid.ActionMenu.Option("defer-reminders").GetAttribute("class").Contains("disabled"));
            Assert.False(grid.ActionMenu.Option("mark-as-read-unread").GetAttribute("class").Contains("disabled"));
            Assert.False(grid.ActionMenu.Option("change-due-date-responsibility").GetAttribute("class").Contains("disabled"));
            Assert.False(grid.ActionMenu.Option("forward-reminders").GetAttribute("class").Contains("disabled"));

            resultPage.OpenMarkAsBulkOption("mark-as-read");
            driver.WaitForGridLoader();
            Assert.False(resultPage.IsGridRowBold(1));
            Assert.False(resultPage.IsGridRowBold(2));
            Assert.False(resultPage.IsGridRowBold(3));
            Assert.False(resultPage.IsGridRowBold(4));
            Assert.False(resultPage.IsGridRowBold(5));
            Assert.False(resultPage.IsGridRowBold(6));
            
            grid.ActionMenu.OpenOrClose();
            grid.ActionMenu.SelectAll();
            grid.ActionMenu.OpenOrClose();
            resultPage.SelectGridRow(1);
            resultPage.SelectGridRow(2);
            grid.ActionMenu.OpenOrClose();
            resultPage.OpenMarkAsBulkOption("mark-as-unread");
            driver.WaitForGridLoader();
            Assert.False(resultPage.IsGridRowBold(1));
            Assert.False(resultPage.IsGridRowBold(2));
            Assert.True(resultPage.IsGridRowBold(3));
            Assert.True(resultPage.IsGridRowBold(4));
            Assert.True(resultPage.IsGridRowBold(5));
            Assert.True(resultPage.IsGridRowBold(6));
            
            grid.ActionMenu.OpenOrClose();
            grid.ActionMenu.SelectAll();
            grid.ActionMenu.Option("dismiss-reminders").Click();
            driver.WaitForAngular();
            Assert.AreEqual("The Reminders have been successfully dismissed.", resultPage.SuccessMessage.Text);
            Assert.True(resultPage.NoRecordFound.Displayed);
        }
    }
}