using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Configuration.TaskPlanner;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.TaskPlanner;
using NUnit.Framework;
using OpenQA.Selenium;
using MenuItemsPageObject = Inprotech.Tests.Integration.PageObjects.MenuItems;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class TaskPlannerReadOnly : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void TaskPlannerEntryPoint(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");

            var menu = new MenuItemsPageObject(driver);
            menu.TogglElement.Click();

            var taskPlannerSearch = menu.TaskPlanner;
            taskPlannerSearch.FindElement(By.TagName("a")).WithJs().Click();
            Assert.IsTrue(driver.Url.Contains("#/task-planner"), "Expected Task Planner Landing Pagen to be opened");
            var element = driver.FindElement(By.XPath("//div[@class='page-title']//span[contains(text(),'Task Planner')]"));
            Assert.AreEqual("Task Planner", element.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void TaskDetailSummaryPanel(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            TaskPlannerService.InsertAdHocDate(data[1].Case.Id, today.AddDays(2), user);
            TaskPlannerService.InsertAdHocDate(data[2].Case.Id, today.AddDays(4), user);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);

            var page = new TaskPlannerPageObject(driver);

            Assert.True(page.TogglePreviewSwitch.Displayed);
            page.TogglePreviewSwitch.Click();
            driver.WaitForAngular();

            var rightPane = page.ShowPreviewPane();
            Assert.True(rightPane.Displayed);

            driver.FindElement(By.XPath("//tbody//tr[1]//td[9]")).ClickWithTimeout();

            var dueDate = driver.FindElement(By.XPath("//tbody//tr[1]//td[8]"));
            var reminderMessage = driver.FindElement(By.XPath("//tbody//tr[1]//td[9]"));

            Assert.True(page.TaskDetailsPanel.Displayed);
            Assert.True(page.TaskDetailsType.Displayed);
            Assert.True(page.TaskDetailsDueDate.Displayed);
            Assert.AreEqual(page.TaskDetailsDueDate.Text, dueDate.Text);
            Assert.True(page.TaskDetailsEventDesc.Displayed);
            Assert.AreEqual(page.TaskDetailsEventDesc.Text, reminderMessage.Text);
            Assert.True(page.TaskDetailsNameSignatory.Displayed);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void Filters(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            TaskPlannerService.InsertAdHocDate(data[1].Case.Id, today.AddDays(2), user);
            TaskPlannerService.InsertAdHocDate(data[2].Case.Id, today.AddDays(4), user);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);

            var page = new TaskPlannerPageObject(driver);

            Assert.True(page.TogglePreviewSwitch.Displayed);
            page.TogglePreviewSwitch.Click();
            driver.WaitForAngular();

            var rightPane = page.ShowPreviewPane();
            Assert.True(rightPane.Displayed);

            driver.FindElement(By.XPath("//tbody//tr[1]//td[7]")).ClickWithTimeout();

            Assert.True(page.CaseSummaryPanel.Displayed);
            Assert.True(page.CaseNamePanel.Displayed);
            Assert.True(page.CriticalDates.Displayed);

            Assert.AreEqual(driver.FindElement(By.XPath("//a[@id='caseReference']")).Text, data[1].Case.Irn);

            page.TogglePreviewSwitch.Click();
            driver.WaitForAngular();
            Assert.Throws<NoSuchElementException>(() => page.ShowPreviewPane());

            var filterText = data[0].Case.Irn;
            Assert.AreEqual(page.Grid.Rows.Count, 3);
            page.Grid.FilterColumnByName("Case Ref.");
            page.Grid.FilterOption(filterText);
            page.Grid.DoFilter();

            Assert.AreEqual(page.Grid.Rows.Count, 1);
            page.Grid.FilterColumnByName("Case Ref.");
            page.Grid.ClearFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 3);

            filterText = data[1].Case.Country.Name;
            page.Grid.FilterColumnByName("Jurisdiction");
            page.Grid.FilterOption(filterText);
            page.Grid.DoFilter();

            Assert.AreEqual(page.Grid.Rows.Count, 1);
            page.Grid.FilterColumnByName("Jurisdiction");
            page.Grid.ClearFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 3);

            filterText = data[1].Case.PropertyType.Name;
            page.Grid.FilterColumnByName("Property Type");
            page.Grid.FilterOption(filterText);
            page.Grid.DoFilter();

            Assert.AreEqual(page.Grid.Rows.Count, 1);
            page.Grid.FilterColumnByName("Property Type");
            page.Grid.ClearFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 3);

            filterText = data[2].Case.CaseNames.Single(_ => _.NameTypeId == "EMP").Name.Formatted();
            page.Grid.FilterColumnByName("Staff Member");
            page.Grid.FilterOption(filterText);
            page.Grid.DoFilter();

            Assert.AreEqual(page.Grid.Rows.Count, 3);
            page.Grid.FilterColumnByName("Staff Member");
            page.Grid.ClearFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 3);

            filterText = data[2].Case.CaseNames.Single(_ => _.NameTypeId == "SIG").Name.Formatted();
            page.Grid.FilterColumnByName("Signatory");
            page.Grid.FilterOption(filterText);
            page.Grid.DoFilter();

            Assert.AreEqual(page.Grid.Rows.Count, 1);
            page.Grid.FilterColumnByName("Signatory");
            page.Grid.ClearFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 3);
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ReminderForFilter(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today.AddDays(2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);

            var page = new TaskPlannerPageObject(driver);

            Assert.IsTrue(page.SavedSearchPicklist.Enabled);
            page.SavedSearchPicklist.Clear();
            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).Click();
            page.SearchPicklistText.SendKeys("My Team's Tasks");
            page.SearchButton(driver).ClickWithTimeout();
            var tabsGrid = page.ResultGrid;
            Assert.True(tabsGrid.Rows.Count < 2);
            tabsGrid.ClickRow(0);
            driver.WaitForGridLoader();
            page.OpenTaskPlannerTab(1).ClickWithTimeout();
            driver.WaitForGridLoader();
            page.OpenTaskPlannerTab(0).ClickWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual("Reminder For", page.Grid.HeaderColumns[6].Text);

            Assert.True(page.Grid.Rows.Count >= 3);
            var filterText = $"{taskPlannerData.Staff.LastName}, {taskPlannerData.Staff.FirstName}";
            page.Grid.FilterColumnByName("Reminder For");
            page.Grid.FilterOption(filterText);
            page.Grid.DoFilter();

            Assert.AreEqual(page.Grid.Rows.Count, 3);
            page.Grid.FilterColumnByName("Reminder For");
            page.Grid.ClearFilter();
            Assert.True(page.Grid.Rows.Count >= 3);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifySavedSearchPicklist(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            TaskPlannerService.InsertAdHocDate(data[1].Case.Id, today.AddDays(2), user);
            TaskPlannerService.InsertAdHocDate(data[2].Case.Id, today.AddDays(4), user);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);

            Assert.IsTrue(page.SavedSearchPicklist.Enabled);
            page.SavedSearchPicklist.Clear();
            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).Click();
            page.SearchPicklistText.SendKeys("My Team's Tasks");
            page.SearchButton(driver).ClickWithTimeout();
            var tabsGrid = page.ResultGrid;
            Assert.True(tabsGrid.Rows.Count < 2);
            tabsGrid.ClickRow(0);
            driver.WaitForGridLoader();
            page.Grid.HeaderColumns[2].ClickWithTimeout();
            Assert.AreEqual("Reminder For", page.Grid.HeaderColumns[6].Text);

            page.SavedSearchPicklist.Clear();
            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).Click();
            page.SearchPicklistText.SendKeys("My Tasks");
            page.SearchButton(driver).ClickWithTimeout();
            tabsGrid = page.ResultGrid;
            Assert.True(tabsGrid.Rows.Count < 2);
            tabsGrid.ClickRow(0);
            driver.WaitForGridLoader();

            page.FromDate.Input.Clear();
            driver.WaitForGridLoader();
            page.ToDate.Input.Clear();
            driver.WaitForGridLoader();

            page.FromDate.Input.SendKeys(today.ToString("dd-MMM-yyyy"));
            driver.WaitForGridLoader();
            page.ToDate.Input.SendKeys(today.ToString("dd-MMM-yyyy"));
            driver.WaitForGridLoader();
            page.FromDate.GoToDate(2);
            driver.WaitForGridLoader();
            page.ToDate.GoToDate(5);
            driver.WaitForGridLoader();
            page.Grid.HeaderColumns[5].ClickWithTimeout();
            var filterText = data[0].Case.Irn;
            Assert.AreEqual(page.Grid.Rows.Count, 3);
            page.Grid.FilterColumnByName("Case Ref.");
            page.Grid.FilterOption(filterText);
            page.Grid.DoFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 1);
            Assert.True(page.Grid.Rows[0].Text.StartsWith(filterText));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyDateRangeQuickFilter(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today.AddDays(1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var page = new TaskPlannerPageObject(driver);

            Assert.IsTrue(page.FromDate.Input.Enabled);
            Assert.IsTrue(page.ToDate.Input.Enabled);
            Assert.AreEqual(3, page.Grid.Rows.Count);
            
            page.TimePeriodSelect.SelectByText("Today");
            Assert.AreEqual(today.ToString("dd-MMM-yyyy"), page.FromDate.Value);
            Assert.AreEqual(today.ToString("dd-MMM-yyyy"), page.ToDate.Value);

            page.FromDate.GoToDate(1);
            page.ToDate.GoToDate(-2);
            var errorIcon = page.ToDate.FindElement(By.XPath("//span[contains(@class,'cpa-icon-exclamation-triangle')]"));
            Assert.NotNull(errorIcon);

            page.ToDate.GoToDate(1, DateTime.Parse(page.ToDate.Value));
            page.RefreshButton.Click();
            driver.WaitForAngular();
            Assert.AreEqual(1, page.Grid.Rows.Count);

            page.ToDate.GoToDate(2);
            page.RefreshButton.Click();
            driver.WaitForAngular();
            Assert.AreEqual(2, page.Grid.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyDateRangeOptions(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();

            var today = DateTime.Today;
            var thisWeekFrom = today.AddDays(-((int)today.DayOfWeek - 1));
            var thisWeekTo = thisWeekFrom.AddDays(6);
            var nextWeekFrom = thisWeekFrom.AddDays(7);
            var nextWeekTo = thisWeekFrom.AddDays(13);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, thisWeekFrom, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, thisWeekFrom.AddDays(1), taskPlannerData.User);

            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, nextWeekFrom, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, nextWeekFrom.AddDays(1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, nextWeekFrom.AddDays(2), taskPlannerData.User);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var page = new TaskPlannerPageObject(driver);

            Assert.IsTrue(page.TimePeriod.Enabled);

            page.TimePeriodSelect.SelectByText("This Week");
            driver.WaitForGridLoader();
            page.Grid.HeaderColumns[0].ClickWithTimeout();
            Assert.AreEqual(thisWeekFrom.ToString("dd-MMM-yyyy"), page.FromDate.Value);
            Assert.AreEqual(thisWeekTo.ToString("dd-MMM-yyyy"), page.ToDate.Value);

            page.TimePeriodSelect.SelectByText("Next Week");
            driver.WaitForGridLoader();
            page.Grid.HeaderColumns[0].ClickWithTimeout();
            Assert.AreEqual(nextWeekFrom.ToString("dd-MMM-yyyy"), page.FromDate.Value);
            Assert.AreEqual(nextWeekTo.ToString("dd-MMM-yyyy"), page.ToDate.Value);
            page.RefreshButton.Click();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, page.Grid.Rows.Count);

            Assert.IsFalse(page.RefreshButton.IsDisabled());
            page.RefreshButton.Click();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, page.Grid.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyNameQuickFilter(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today.AddDays(2), taskPlannerData.User);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var page = new TaskPlannerPageObject(driver);

            Assert.IsTrue(page.NameKeyPicklist.Enabled);
            page.NameKeyPicklist.Clear();
            page.NameKeyPicklist.SendKeys(taskPlannerData.OtherStaff.LastName);
            page.Grid.HeaderColumns[0].ClickWithTimeout();
            driver.WaitForGridLoader();
            page.RefreshButton.Click();
            driver.WaitForGridLoader();
            page.Grid.HeaderColumns[0].ClickWithTimeout();
            Assert.AreEqual("No results found.", page.NoRecordFound.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyExpandCollapseSection(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainTaskPlannerApplication).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);

            Assert.True(page.FilterAreaExpander.Displayed);
            Assert.True(page.DateRangeDropDown.Displayed);
            page.FilterAreaExpander.Click();
            Assert.False(page.DateRangeDropDown.Displayed);
            page.FilterAreaExpander.Click();
            Assert.NotNull(page.DateRangeDropDown);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyTaskPlannerTabsAndPersistence(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            TaskPlannerService.InsertAdHocDate(data[1].Case.Id, today.AddDays(2), user);
            TaskPlannerService.InsertAdHocDate(data[2].Case.Id, today.AddDays(4), user);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);

            Assert.AreEqual(page.TabList.FindElements(By.TagName("li")).Count, 3);
            Assert.IsTrue(page.GetTaskPlannerTab(0).Displayed);
            Assert.IsTrue(page.GetTaskPlannerTab(1).Displayed);
            Assert.IsTrue(page.GetTaskPlannerTab(2).Displayed);

            page.OpenTaskPlannerTab(1).ClickWithTimeout();

            Assert.IsTrue(page.FindElements(By.CssSelector(".ng-star-inserted .active")).Any());

            page.TimePeriodSelect.SelectByText("This Week");
            driver.WaitForGridLoader();
            var tabsDataCount = page.Grid.Rows.Count;

            page.OpenTaskPlannerTab(0).ClickWithTimeout();
            driver.WaitForGridLoader();

            page.OpenTaskPlannerTab(1).ClickWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual(tabsDataCount, page.Grid.Rows.Count);
            Assert.AreEqual("This Week", page.TimePeriodSelect.SelectedOption.Text.Trim());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyTaskPlannerSavedSearchPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner");
            var page = new TaskPlannerPageObject(driver);

            Assert.IsTrue(page.SavedSearchPicklist.Enabled);
            page.SavedSearchPicklist.Clear();
            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).Click();
            page.SearchPicklistText.SendKeys("My Team's Tasks");
            page.SearchButton(driver).ClickWithTimeout();
            var tabsGrid = page.ResultGrid;

            Assert.AreEqual(tabsGrid.Rows[0].FindElements(By.TagName("td"))[0].Text, "My Team's Tasks");

            page.SearchPicklistText.Clear();
            page.SearchPicklistText.SendKeys("My Tasks");
            page.SearchButton(driver).ClickWithTimeout();
            tabsGrid = page.ResultGrid;
            Assert.AreEqual(tabsGrid.Rows[0].FindElements(By.TagName("td"))[0].Text, "My Tasks");

            page.SearchPicklistText.Clear();
            page.SearchPicklistText.SendKeys("My Due Dates");
            page.SearchButton(driver).ClickWithTimeout();
            tabsGrid = page.ResultGrid;
            Assert.AreEqual(tabsGrid.Rows[0].FindElements(By.TagName("td"))[0].Text, "My Due Dates");

            page.SearchPicklistText.Clear();
            page.SearchPicklistText.SendKeys("My Reminders");
            page.SearchButton(driver).ClickWithTimeout();
            tabsGrid = page.ResultGrid;
            Assert.AreEqual(tabsGrid.Rows[0].FindElements(By.TagName("td"))[0].Text, "My Reminders");
            page.SavedSearchPicklist.Close();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyProfileDefaultsToTaskPlannerTabs(BrowserType browserType)
        {
            var user = DbSetup.Do(x => new Users(x.DbContext).WithPermission(ApplicationTask.MaintainTaskPlannerConfiguration).Create());
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);
            Assert.AreEqual("My Reminders", page.GetTaskPlannerTabSearchName(0), "'My Reminders' saved search should be selected in tab1 picklist");
            Assert.AreEqual("My Due Dates", page.GetTaskPlannerTabSearchName(1), "'My Due Dates' saved search should be selected in tab2 picklist");
            Assert.AreEqual("My Team's Tasks", page.GetTaskPlannerTabSearchName(2), "'My Team's Tasks' saved search should be selected in tab3 picklist");

            driver.Visit(Env.RootUrl + "#/configuration/task-planner-configuration");
            var configPage = new TaskPlannerConfigurationPageObject(driver);
            configPage.Grid.ClickEdit(0);
            configPage.SelectPickListItem(0, "tab1", "My Team's Tasks");
            configPage.SaveButton.WithJs().Click();
            driver.WaitForAngular();

            driver.Visit(Env.RootUrl + "/#/task-planner");
            driver.WaitForAngular();
            Assert.AreEqual("My Team's Tasks", page.GetTaskPlannerTabSearchName(0));
            Assert.AreEqual("My Due Dates", page.GetTaskPlannerTabSearchName(1));
            Assert.AreEqual("My Team's Tasks", page.GetTaskPlannerTabSearchName(2));
            driver.Visit(Env.RootUrl + "#/configuration/task-planner-configuration");
            configPage.Grid.ClickEdit(0);
            configPage.SelectPickListItem(0, "tab1", "My Reminders");
            configPage.SaveButton.WithJs().Click();
            driver.WaitForAngular();
            Assert.IsTrue(configPage.SuccessMessage.Text.Contains("Your changes have been successfully saved."));
            driver.Visit(Env.RootUrl + "/#/task-planner");
            driver.WaitForAngular();
            Assert.AreEqual("My Reminders", page.GetTaskPlannerTabSearchName(0), "'My Reminders' saved search should be selected in tab1 picklist");
        }
    }
}