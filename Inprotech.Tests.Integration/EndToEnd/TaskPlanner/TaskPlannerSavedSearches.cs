using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [NUnit.Framework.Category(Categories.E2E)]
    [TestFixture]
    class TaskPlannerSavedSearches : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyTitleForSavedSearchesInTaskPlanner(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner");
            var page = new TaskPlannerPageObject(driver);
            page.SavedSearchPicklist.Clear();
            page.SavedSearchPicklist.EnterAndSelect("My Due Dates");
            page.RefreshButton.Click();
            page.PresentationButton.ClickWithTimeout();
            Assert.True(page.SavedSearchHeading.Contains("My Due Dates"));
            page.BackButton.ClickWithTimeout();
            page.FilterButton.Click();
            Assert.True(page.SavedSearchHeading.Contains("My Due Dates"));
            page.PresentationButton.Click();
            Assert.True(page.SavedSearchHeading.Contains("My Due Dates"));
            page.BackButton.ClickWithTimeout();
            page.SavedSearchPicklist.Clear();
            page.SavedSearchPicklist.EnterAndSelect("My Reminders");
            page.RefreshButton.Click();
            page.PresentationButton.ClickWithTimeout();
            Assert.True(page.SavedSearchHeading.Contains("My Reminders"));
            page.BackButton.Click();
            page.FilterButton.Click();
            Assert.True(page.SavedSearchHeading.Contains("My Reminders"));
            page.PresentationButton.Click();
            Assert.True(page.SavedSearchHeading.Contains("My Reminders"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifySaveEditAndDeleteFunctionalityForExistingSavedSearch(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;
            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);
            page.SavedSearchPicklist.Clear();
            page.SavedSearchPicklist.EnterAndSelect("My Reminders");
            page.RefreshButton.Click();
            page.FilterButton.ClickWithTimeout();
            page.Cases.CaseReference.Clear();
            page.Cases.CaseReference.SendKeys("TaskPlanner1");
            Assert.IsTrue(page.BackButton.Displayed);
            page.PresentationButton.Click();
            page.UseDefaultCheckbox.WithJs().Click();
            page.SearchColumnTextBox.SendKeys("Case Status");
            var jsExecutable = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable = jsExecutable + "$('#availableColumns li span').simulateDragDrop({ dropTarget: '#KendoGrid tbody'});";
            ((IJavaScriptExecutor)driver).ExecuteScript(jsExecutable);
            page.PresentationPageSaveButton.Click();
            Assert.IsTrue(page.BackButton.Displayed);
            page.AdvancedSearchButton.ClickWithTimeout();
            var caseStatusColumn = driver.FindElement(By.XPath("//span[contains(text(),'Case Status')]"));
            Assert.IsTrue(caseStatusColumn.Displayed);
            Assert.AreEqual(page.Grid.Rows.Count, 1);
            Assert.IsTrue(page.SavedSearchPicklist.InputValue.Contains("My Reminders"));
            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("My Reminders");
            page.SearchButton(driver).ClickWithTimeout();
            page.EditButton(driver).ClickWithTimeout();
            page.SearchName.Clear();
            page.SearchName.SendKeys("My Reminders E2E Updated");
            page.EditSearchSaveButton.ClickWithTimeout();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("My Reminders E2E Updated");
            page.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(driver.FindElement(By.XPath("//td[contains(text(),'My Reminders E2E Updated')]")).Displayed);
            driver.FindElement(By.XPath("//td[contains(text(),'My Reminders E2E Updated')]")).ClickWithTimeout();
            Assert.AreEqual(page.Grid.Rows.Count, 1);
            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("My Reminders E2E Updated");
            page.SearchButton(driver).ClickWithTimeout();
            page.DeleteIcon(driver).ClickWithTimeout();
            var popup = new CommonPopups(driver);
            page.DeleteButton.ClickWithTimeout();
            Assert.NotNull(popup.AlertModal);
            Assert.AreEqual(popup.AlertModal.Description, "This saved search cannot be deleted because the system administrator or another user has set it as the default search on a tab.");
            popup.AlertModal.Ok();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("My Reminders E2E Updated");
            page.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(driver.FindElement(By.XPath("//td[contains(text(),'My Reminders E2E Updated')]")).Displayed);
            page.EditButton(driver).ClickWithTimeout();
            page.SearchName.Clear();
            page.SearchName.SendKeys("My Reminders");
            page.EditSearchSaveButton.ClickWithTimeout();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("My Reminders");
            page.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(driver.FindElement(By.XPath("//td[contains(text(),'My Reminders')]")).Displayed);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifySaveEditAndDeleteFunctionalityForNewSaveSearch(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;
            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);
            var builderPage = new TaskPlannerSearchBuilderPageObject(driver);
            page.SavedSearchPicklist.OpenPickList();
            Assert.IsTrue(page.PublicColumn.Displayed);
            page.NewSearchButton.ClickWithTimeout();
            page.Cases.CaseReference.Clear();
            page.Cases.CaseReference.SendKeys("TaskPlanner1");
            builderPage.EventNotesTextbox.Input.SendKeys("E2E Test Message");
            page.PresentationButton.ClickWithTimeout();
            Assert.IsTrue(page.PresentationPageSaveButton.Displayed);
            page.PresentationPageSaveButton.ClickWithTimeout();
            page.SearchInputField.SendKeys("e2e search");
            page.SaveButton.Click();
            Assert.True(page.SavedSearchHeading.Contains("e2e search"));
            Assert.IsTrue(page.BackButton.Displayed);
            page.PresentationButton.Click();
            page.UseDefaultCheckbox.WithJs().Click();
            page.SearchColumnTextBox.SendKeys("Case Status");
            var jsExecutable = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable = jsExecutable + "$('#availableColumns li span').simulateDragDrop({ dropTarget: '#KendoGrid tbody'});";
            ((IJavaScriptExecutor)driver).ExecuteScript(jsExecutable);
            page.PresentationPageSaveButton.Click();
            Assert.True(page.SavedSearchHeading.Contains("e2e search"));
            Assert.IsTrue(page.BackButton.Displayed);
            page.AdvancedSearchButton.ClickWithTimeout();
            var caseStatusColumn = driver.FindElement(By.XPath("//span[contains(text(),'Case Status')]"));
            Assert.IsTrue(caseStatusColumn.Displayed);
            Assert.AreEqual(page.Grid.Rows.Count, 1);
            Assert.IsTrue(page.SavedSearchPicklist.InputValue.Contains("e2e search"));
            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("e2e search");
            page.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(driver.FindElement(By.XPath("//td[contains(text(),'e2e search')]")).Displayed);
            driver.FindElement(By.XPath("//td[contains(text(),'e2e search')]")).ClickWithTimeout();
            page.FilterButton.ClickWithTimeout();
            Assert.True(page.SavedSearchHeading.Contains("e2e search"));
            page.MoreItemButton.Click();
            driver.FindElement(By.XPath("//span[contains(.,'Edit saved search details')]")).WithJs().Click();
            page.SearchInputField.Clear();
            page.SearchInputField.SendKeys("e2e search updated");
            page.SaveButton.ClickWithTimeout();
            Assert.True(page.SavedSearchHeading.Contains("e2e search updated"));
            page.PresentationButton.ClickWithTimeout();
            page.MoreItemButton.Click();
            driver.FindElement(By.XPath("//span[contains(.,'Edit saved search details')]")).WithJs().Click();
            page.SearchInputField.Clear();
            page.SearchInputField.SendKeys("e2e search updated presentation");
            page.SaveButton.ClickWithTimeout();
            Assert.True(page.SavedSearchHeading.Contains("e2e search updated presentation"));
            page.AdvancedSearchButton.ClickWithTimeout();
            Assert.AreEqual(page.Grid.Rows.Count, 1);
            Assert.IsTrue(page.SavedSearchPicklist.InputValue.Contains("e2e search updated presentation"));
            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("e2e search updated presentation");
            page.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(driver.FindElement(By.XPath("//td[contains(text(),'e2e search updated presentation')]")).Displayed);
            driver.FindElement(By.XPath("//td[contains(text(),'e2e search updated presentation')]")).ClickWithTimeout();
            Assert.AreEqual(page.Grid.Rows.Count, 1);
            page.FilterButton.ClickWithTimeout();
            page.MoreItemButton.Click();
            driver.FindElement(By.XPath("//span[contains(.,'Delete saved search')]")).WithJs().Click();
            page.DeleteButton.ClickWithTimeout();
            page.AdvancedSearchButton.ClickWithTimeout();
            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("e2e search updated presentation");
            page.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(driver.FindElement(By.XPath("//ipx-inline-alert//div//span[contains(text(),'No results found.')]")).Displayed);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifySaveAsFunctionality(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;
            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);
            page.SavedSearchPicklist.Clear();
            page.SavedSearchPicklist.EnterAndSelect("My Reminders");
            page.RefreshButton.Click();
            page.FilterButton.ClickWithTimeout();   
            page.Cases.CaseReference.Clear();
            page.Cases.CaseReference.SendKeys("TaskPlanner1");
            page.PresentationButton.ClickWithTimeout();
            page.TaskMenuButton.ClickWithTimeout();
            driver.FindElement(By.XPath("//span[contains(.,'Save as')]")).WithJs().Click();
            page.SearchInputField.SendKeys("e2e search");
            page.SaveButton.ClickWithTimeout();
            Assert.True(page.SavedSearchHeading.Contains("e2e search"));
            Assert.IsTrue(page.BackButton.Displayed);
            page.PresentationButton.Click();
            Assert.True(page.SavedSearchHeading.Contains("e2e search"));
            page.UseDefaultCheckbox.WithJs().Click();
            page.SearchColumnTextBox.SendKeys("Case Status");
            var jsExecutable = From.EmbeddedAssets("drag_and_drop_helper.js");
            jsExecutable = jsExecutable + "$('#availableColumns li span').simulateDragDrop({ dropTarget: '#KendoGrid tbody'});";
            ((IJavaScriptExecutor)driver).ExecuteScript(jsExecutable);
            page.PresentationPageSaveButton.ClickWithTimeout();
            page.AdvancedSearchButton.ClickWithTimeout();
            var caseStatusColumn = driver.FindElement(By.XPath("//span[contains(text(),'Case Status')]"));
            Assert.IsTrue(caseStatusColumn.Displayed);
            Assert.AreEqual(page.Grid.Rows.Count, 1);
            Assert.IsTrue(page.SavedSearchPicklist.InputValue.Contains("e2e search"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyEditAndDeleteFunctionalityFromSavedSearchPicklist(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;
            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);
            var builderPage = new TaskPlannerSearchBuilderPageObject(driver);
            page.SavedSearchPicklist.OpenPickList();
            Assert.IsTrue(page.PublicColumn.Displayed);
            page.NewSearchButton.ClickWithTimeout();
            page.Cases.CaseReference.Clear();
            page.Cases.CaseReference.SendKeys("TaskPlanner1");
            builderPage.EventNotesTextbox.Input.SendKeys("E2E Test Message");
            page.PresentationButton.ClickWithTimeout();
            Assert.IsTrue(page.PresentationPageSaveButton.Displayed);
            page.PresentationPageSaveButton.ClickWithTimeout();
            page.SearchInputField.SendKeys("e2e search");
            page.SaveButton.Click();
            Assert.True(page.SavedSearchHeading.Contains("e2e search"));
            page.AdvancedSearchButton.ClickWithTimeout();
            Assert.AreEqual(page.Grid.Rows.Count, 1);
            Assert.IsTrue(page.SavedSearchPicklist.InputValue.Contains("e2e search"));
            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("e2e search");
            page.SearchButton(driver).ClickWithTimeout();
            page.EditButton(driver).ClickWithTimeout();
            page.SearchName.Clear();
            page.SearchName.SendKeys("e2e search Updated");
            page.EditSearchSaveButton.ClickWithTimeout();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("e2e search Updated");
            page.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(driver.FindElement(By.XPath("//td[contains(text(),'e2e search Updated')]")).Displayed);
            driver.FindElement(By.XPath("//td[contains(text(),'e2e search Updated')]")).ClickWithTimeout();
            Assert.AreEqual(page.Grid.Rows.Count, 1);
            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("e2e search Updated");
            page.SearchButton(driver).ClickWithTimeout();
            page.DeleteIcon(driver).ClickWithTimeout();
            page.DeleteButton.ClickWithTimeout();
            page.ClearButton(driver).ClickWithTimeout();
            page.SearchPicklistText.SendKeys("e2e search Updated");
            page.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(driver.FindElement(By.XPath("//ipx-inline-alert//div//span[contains(text(),'No results found.')]")).Displayed);
        }
    }
}
