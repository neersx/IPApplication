using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerReminderComments : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ViewExistingReminderComments(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDateWithComments(data[0].Case.Id, today.AddDays(5), user, "Test E2E Comments");
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);

            page.PresentationButton.ClickWithTimeout();
            page.UseDefaultCheckbox.WithJs().Click();
            page.SearchColumnTextBox.SendKeys("Reminder For");
            var jsExecutable = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable = jsExecutable + "$('#availableColumns li span').simulateDragDrop({ dropTarget: '#KendoGrid tbody'});";
            ((IJavaScriptExecutor)driver).ExecuteScript(jsExecutable);
            page.AdvancedSearchButton.ClickWithTimeout();
            page.FilterButton.ClickWithTimeout();
            page.Cases.CaseReference.SendKeys("TaskPlanner1");
            page.AdvancedSearchButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("Reminder For", page.Grid.HeaderColumns[5].Text);
            var reminderFor = driver.FindElement(By.XPath("//tbody//tr[1]//td[6]")).Text;
            driver.FindElement(By.XPath("//tbody/tr[1]/td[1]/a[1]")).ClickWithTimeout();
            Assert.AreEqual("Comments Of", driver.FindElement(By.XPath("//ipx-task-reminder-comments[1]/ipx-kendo-grid[1]/kendo-grid[1]/div[1]/table[1]/thead[1]/tr[1]/th[2]")).Text);
            Assert.AreEqual("Reminder Comments", driver.FindElement(By.XPath("//ipx-task-reminder-comments[1]/ipx-kendo-grid[1]/kendo-grid[1]/div[1]/table[1]/thead[1]/tr[1]/th[3]")).Text);
            Assert.AreEqual("Last Updated", driver.FindElement(By.XPath("//ipx-task-reminder-comments[1]/ipx-kendo-grid[1]/kendo-grid[1]/div[1]/table[1]/thead[1]/tr[1]/th[4]")).Text);
            Assert.AreEqual(reminderFor, driver.FindElement(By.XPath("//ipx-task-reminder-comments[1]/ipx-kendo-grid[1]/kendo-grid[1]/div[1]/table[1]/tbody[1]/tr[1]/td[2]")).Text);
            Assert.AreEqual("Test E2E Comments", driver.FindElement(By.XPath("//ipx-task-reminder-comments[1]/ipx-kendo-grid[1]/kendo-grid[1]/div[1]/table[1]/tbody[1]/tr[1]/td[3]")).Text);
            Assert.AreEqual("1", driver.FindElement(By.XPath("//span[text()='Reminder Comments']/following-sibling::span")).Text);
            page.CommentsEditButton.ClickWithTimeout();
            page.CommentsTextArea.Clear();
            page.CommentsTextArea.SendKeys("Updated E2E Comments");
            page.CommentsSaveButton.ClickWithTimeout();
            Assert.AreEqual("Updated E2E Comments", driver.FindElement(By.XPath("//ipx-task-reminder-comments[1]/ipx-kendo-grid[1]/kendo-grid[1]/div[1]/table[1]/tbody[1]/tr[1]/td[3]")).Text);
            Assert.AreEqual("1", driver.FindElement(By.XPath("//span[text()='Reminder Comments']/following-sibling::span")).Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AddEditReminderComments(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);

            page.PresentationButton.ClickWithTimeout();
            page.UseDefaultCheckbox.WithJs().Click();
            page.SearchColumnTextBox.SendKeys("Reminder For");
            var jsExecutable = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable = jsExecutable + "$('#availableColumns li span').simulateDragDrop({ dropTarget: '#KendoGrid tbody'});";
            ((IJavaScriptExecutor)driver).ExecuteScript(jsExecutable);
            page.AdvancedSearchButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            page.FilterButton.ClickWithTimeout();
            page.Cases.CaseReference.SendKeys("TaskPlanner1");
            page.AdvancedSearchButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("Reminder For", page.Grid.HeaderColumns[5].Text);
            var reminderFor = driver.FindElement(By.XPath("//tbody//tr[1]//td[6]")).Text;
            driver.FindElement(By.XPath("//tbody/tr[1]/td[1]/a[1]")).ClickWithTimeout();
            Assert.AreEqual("0", driver.FindElement(By.XPath("//span[text()='Reminder Comments']/following-sibling::span")).Text);
            page.CommentsAddButton.ClickWithTimeout();
            page.CommentsTextArea.SendKeys("Add E2E Comments");
            page.CommentsRevertButton.ClickWithTimeout();
            var popup = new CommonPopups(driver);
            popup.DiscardChangesModal.Discard();
            page.CommentsAddButton.ClickWithTimeout();
            page.CommentsTextArea.SendKeys("Add E2E Comments");
            page.CommentsSaveButton.ClickWithTimeout();
            Assert.AreEqual("Add E2E Comments", driver.FindElement(By.XPath("//ipx-task-reminder-comments[1]/ipx-kendo-grid[1]/kendo-grid[1]/div[1]/table[1]/tbody[1]/tr[1]/td[3]")).Text);
            Assert.AreEqual(reminderFor, driver.FindElement(By.XPath("//ipx-task-reminder-comments[1]/ipx-kendo-grid[1]/kendo-grid[1]/div[1]/table[1]/tbody[1]/tr[1]/td[2]")).Text);
            page.CommentsEditButton.ClickWithTimeout();
            page.CommentsTextArea.Clear();
            page.CommentsTextArea.SendKeys("Updated E2E Comments");
            page.CommentsSaveButton.ClickWithTimeout();
            Assert.AreEqual("Updated E2E Comments", driver.FindElement(By.XPath("//ipx-task-reminder-comments[1]/ipx-kendo-grid[1]/kendo-grid[1]/div[1]/table[1]/tbody[1]/tr[1]/td[3]")).Text);
            Assert.AreEqual("1", driver.FindElement(By.XPath("//span[text()='Reminder Comments']/following-sibling::span")).Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AddReminderCommentsFromTaskMenu(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);

            page.FilterButton.ClickWithTimeout();
            page.Cases.CaseReference.SendKeys("TaskPlanner1");
            page.AdvancedSearchButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            page.OpenTaskMenuOption(0, "maintainReminderComment");
            page.CommentsTextArea.SendKeys("Add E2E Comments");
            page.CommentsSaveButton.ClickWithTimeout();
            Assert.AreEqual("Add E2E Comments", driver.FindElement(By.XPath("//ipx-task-reminder-comments[1]/ipx-kendo-grid[1]/kendo-grid[1]/div[1]/table[1]/tbody[1]/tr[1]/td[3]")).Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyDiscardModalOnTabSelectionChange(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);

            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            page.FilterButton.ClickWithTimeout();
            page.Cases.CaseReference.SendKeys("TaskPlanner1");
            page.AdvancedSearchButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            driver.FindElement(By.XPath("//tbody/tr[1]/td[1]/a[1]")).ClickWithTimeout();
            page.CommentsAddButton.ClickWithTimeout();
            page.CommentsTextArea.SendKeys("Add E2E Comments");
            page.OpenTaskPlannerTab(1).ClickWithTimeout();
            var popup = new CommonPopups(driver);
            popup.ConfirmModal.Cancel().Click();
            Assert.True(page.IsTabSelected(0), "User should be stay on Tab 1.");

            page.OpenTaskPlannerTab(1).ClickWithTimeout();
            popup.ConfirmModal.PrimaryButton.Click();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            Assert.True(page.IsTabSelected(1), "Tab 2 should be selected");

            page.OpenTaskPlannerTab(0).ClickWithTimeout();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            Assert.True(page.IsTabSelected(0), "Tab 1 should be selected");

            driver.FindElement(By.XPath("//tbody/tr[1]/td[1]/a[1]")).ClickWithTimeout();
            page.CommentsAddButton.ClickWithTimeout();
            page.CommentsTextArea.SendKeys("Add E2E Comments new");
            page.CommentsSaveButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            page.OpenTaskPlannerTab(2).ClickWithTimeout();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            Assert.True(page.IsTabSelected(2), "Tab 3 should be selected");
        }
    }
}
