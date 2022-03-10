using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class TaskPlannerFilters : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void StatusAndInstructorFilters(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var page = new TaskPlannerPageObject(driver);
            var taskPlannerData = TaskPlannerService.SetupData();
            TestUser user = taskPlannerData.User;
            var today = DateTime.Today;
            var data = taskPlannerData.Data;
            var presentationPage = new CaseSearchPageObject(driver);
            TaskPlannerService.InsertAdHocDate(data[1].Case.Id, today.AddDays(1), taskPlannerData.User);

            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            driver.WaitForGridLoader();

            var builderPage = new TaskPlannerSearchBuilderPageObject(driver);
            page.FilterButton.ClickWithTimeout();
            builderPage.IncludeDueDatesCheckbox.Click();
            builderPage.IncludeRemindersCheckbox.Click();
            builderPage.IncludeAdHocDatesCheckbox.Click();
            builderPage.ActingAsDueDateCheckbox.Click();
            builderPage.ActingAsReminderCheckbox.Click();
            builderPage.CaseReferenceOperatorDropdown.Input.SelectByText("Starts With");
            builderPage.CaseReferenceTextbox.Input.SendKeys("TaskPlanner");
            builderPage.SearchButton.Click();
            driver.WaitForGridLoader();

            page.PresentationButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            presentationPage.Presentation.SearchColumnTextBox.SendKeys("Case Status");
            presentationPage.SimulateDragDrop(presentationPage.AvailableColumns, presentationPage.SelectedColumnsGrid);
            presentationPage.Presentation.SearchColumnTextBox.Clear();
            presentationPage.Presentation.SearchColumnTextBox.SendKeys("Instructor");
            presentationPage.SimulateDragDrop(presentationPage.AvailableColumns, presentationPage.SelectedColumnsGrid);

            presentationPage.CaseSearchButton.Click();

            driver.WaitForGridLoader();
            Assert.AreEqual(3, page.Grid.Rows.Count);

            var @case = data[1].Case;
            page.Grid.FilterColumnByName("Case Status");
            page.Grid.FilterOption(@case.CaseStatus.Name);
            page.Grid.DoFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 1, "Row with matching filter value is returned");

            page.Grid.FilterColumnByName("Case Status");
            page.Grid.ClearFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 3, "Row with matching filter value is returned");

            DbSetup.Do(x =>
            {
                var instructor = x.DbContext.Set<CaseName>().Single(_ => _.CaseId == @case.Id && _.NameTypeId == "I");
                page.Grid.FilterColumnByName("Instructor");
                page.Grid.FilterOption(instructor.Name.Formatted());
                page.Grid.DoFilter();
                Assert.AreEqual(page.Grid.Rows.Count, 1, "Filter is cleared and all rows are returned");
            });

            page.Grid.FilterColumnByName("Instructor");
            page.Grid.ClearFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 3, "Row with matching filter value is returned");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ImportanceAndDueDateResponsibilityFilters(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            TestUser user = null;
            DbSetup.Do(x =>
            {
                user = new Users(x.DbContext)
                       .WithPermission(ApplicationTask.ChangeDueDateResponsibility)
                       .Create();
            });
            var page = new TaskPlannerPageObject(driver);
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Today;
            var data = taskPlannerData.Data;
            var presentationPage = new CaseSearchPageObject(driver);
            TaskPlannerService.InsertAdHocDate(data[1].Case.Id, today.AddDays(1), taskPlannerData.User);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            driver.WaitForGridLoader();

            var builderPage = new TaskPlannerSearchBuilderPageObject(driver);
            page.FilterButton.ClickWithTimeout();
            builderPage.IncludeDueDatesCheckbox.Click();
            builderPage.IncludeRemindersCheckbox.Click();
            builderPage.IncludeAdHocDatesCheckbox.Click();
            builderPage.ActingAsDueDateCheckbox.Click();
            builderPage.ActingAsReminderCheckbox.Click();
            builderPage.CaseReferenceOperatorDropdown.Input.SelectByText("Starts With");
            builderPage.CaseReferenceTextbox.Input.SendKeys("TaskPlanner");
            builderPage.SearchButton.Click();
            driver.WaitForGridLoader();

            page.PresentationButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            presentationPage.Presentation.SearchColumnTextBox.SendKeys("importance");
            presentationPage.SimulateDragDrop(presentationPage.AvailableColumns, presentationPage.SelectedColumnsGrid);
            presentationPage.Presentation.SearchColumnTextBox.Clear();
            presentationPage.Presentation.SearchColumnTextBox.SendKeys("due date resp.");
            presentationPage.SimulateDragDrop(presentationPage.AvailableColumns, presentationPage.SelectedColumnsGrid);

            presentationPage.CaseSearchButton.Click();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, page.Grid.Rows.Count);

            page.OpenTaskMenuOption(0, "changeDueDateResponsibility");
            driver.WaitForAngular();
            page.AssignToMe.Click();
            driver.WaitForAngular();
            page.ModalSaveButton.Click();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            page.OpenTaskMenuOption(1, "changeDueDateResponsibility");
            driver.WaitForAngular();
            page.NamePicklist.EnterAndSelect("Baston, Ann");
            page.ModalSaveButton.Click();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            page.OpenTaskMenuOption(2, "changeDueDateResponsibility");
            driver.WaitForAngular();
            page.NamePicklist.EnterAndSelect("Cork, Colleen C");
            page.ModalSaveButton.Click();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual(page.Grid.Rows.Count, 3);
            page.Grid.FilterColumnByName("Due Date Resp.");
            page.Grid.FilterOption("Cork, Colleen C");
            page.Grid.DoFilter();

            Assert.AreEqual(page.Grid.Rows.Count, 1, "Row with matching filter value is returned");
            page.Grid.FilterColumnByName("Due Date Resp.");
            page.Grid.ClearFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 3, "Filter is cleared and all rows are returned");

            page.FilterButton.ClickWithTimeout();
            builderPage.IncludeAdHocDatesCheckbox.Click();
            builderPage.SearchButton.Click();
            driver.WaitForGridLoader();

            page.Grid.FilterColumnByName("Importance");
            page.Grid.FilterOption("Critical");
            page.Grid.DoFilter();

            Assert.AreEqual(page.Grid.Rows.Count, 3, "Row with Importance level as Critical are returned");
            page.Grid.FilterColumnByName("Importance");
            page.Grid.ClearFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 5, "Filter is cleared and all rows are returned");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void TitleColumnFilters(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            TestUser user = null;
            DbSetup.Do(x =>
            {
                user = new Users(x.DbContext)
                       .WithPermission(ApplicationTask.MaintainTaskPlannerApplication)
                       .Create();
            });
            var page = new TaskPlannerPageObject(driver);
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Today;
            var data = taskPlannerData.Data;
            var presentationPage = new CaseSearchPageObject(driver);
            TaskPlannerService.InsertAdHocDate(data[1].Case.Id, today.AddDays(1), taskPlannerData.User);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            driver.WaitForGridLoader();

            var builderPage = new TaskPlannerSearchBuilderPageObject(driver);
            page.FilterButton.ClickWithTimeout();
            builderPage.IncludeDueDatesCheckbox.Click();
            builderPage.IncludeRemindersCheckbox.Click();
            builderPage.IncludeAdHocDatesCheckbox.Click();
            builderPage.ActingAsDueDateCheckbox.Click();
            builderPage.ActingAsReminderCheckbox.Click();
            builderPage.CaseReferenceOperatorDropdown.Input.SelectByText("Starts With");
            builderPage.CaseReferenceTextbox.Input.SendKeys("TaskPlanner");
            builderPage.SearchButton.Click();
            driver.WaitForGridLoader();

            page.PresentationButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            presentationPage.Presentation.SearchColumnTextBox.SendKeys("Title");
            presentationPage.SimulateDragDrop(presentationPage.AvailableColumns, presentationPage.SelectedColumnsGrid);
           
            presentationPage.CaseSearchButton.Click();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, page.Grid.Rows.Count);

            page.Grid.FilterColumnByName("Title");
            page.Grid.FilterOption(data[1].Case.Title);
            page.Grid.DoFilter();

            driver.WaitForGridLoader();
            Assert.AreEqual(1, page.Grid.Rows.Count);

            page.Grid.FilterColumnByName("Title");
            page.Grid.ClearFilter();
            Assert.AreEqual(page.Grid.Rows.Count, 3, "Filter is cleared and all rows are returned");
        }
    }
}
