using System;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using MenuItemsPageObject = Inprotech.Tests.Integration.PageObjects.MenuItems;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerPresentation : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void SearchWithPresentationColumn(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(data[1].Case.Id, today.AddDays(1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(data[2].Case.Id, today.AddDays(2), taskPlannerData.User);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            var presentationPage = new CaseSearchPageObject(driver);
            var builderPage = new TaskPlannerSearchBuilderPageObject(driver);
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);

            resultPage.PresentationButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            presentationPage.Presentation.SearchColumnTextBox.SendKeys("Case Type");
            presentationPage.SimulateDragDrop(presentationPage.AvailableColumns, presentationPage.SelectedColumnsGrid);
            presentationPage.CaseSearchButton.Click();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
            driver.Visit(Env.RootUrl + "/#/task-planner");

            resultPage.OpenSavedSearch.Click();
            resultPage.ButtonNewSearch.ClickWithTimeout();
            builderPage.EventNotesTextbox.Input.SendKeys("E2E Test Message");
            resultPage.PresentationButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            presentationPage.UseDefaultCheckbox.WithJs().Click();

            var selectedCount = presentationPage.SelectedColumns.Count;
            var lastColumnText = presentationPage.GetColumnName(selectedCount);
            presentationPage.SimulateDragDrop(presentationPage.SelectedColumnLast, presentationPage.SelectedColumnFirst);
            Assert.AreEqual(lastColumnText, presentationPage.GetColumnName(1));
            presentationPage.SimulateDragDrop(presentationPage.SelectedColumnFourth, presentationPage.AvailableColumns);
            Assert.AreNotEqual(selectedCount, presentationPage.SelectedColumns.Count);
            var availableColumnFirstText = presentationPage.AvailableColumnFirst.Text;
            presentationPage.Presentation.SearchColumnTextBox.SendKeys(availableColumnFirstText);
            Assert.AreEqual(availableColumnFirstText, presentationPage.Presentation.SearchColumn.Text);
            var secondRowSelectedColumnText = presentationPage.GetColumnName(2);
            presentationPage.FirstSortOrderDropDown.SelectByText("1");
            presentationPage.SecondSortOrderDropDown.SelectByText("2");

            presentationPage.SimulateDragDrop(presentationPage.AvailableColumns, presentationPage.SelectedColumnsGrid);
            presentationPage.MoreItemButton.Click();
            presentationPage.MakeThisMyDefaultButton.WithJs().Click();
            Assert.IsTrue(presentationPage.UseDefaultCheckbox.IsChecked());

            presentationPage.CaseSearchButton.Click();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
            Assert.IsTrue(presentationPage.GetAvailableColumnOne(availableColumnFirstText).Displayed);

            resultPage.PresentationButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            presentationPage.MoreItemButton.Click();
            presentationPage.RevertToStandardDefaultButton.WithJs().Click();
            Assert.IsTrue(presentationPage.UseDefaultCheckbox.IsChecked());

            presentationPage.CaseSearchButton.Click();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
            Assert.IsTrue(presentationPage.GetAvailableColumnOne(secondRowSelectedColumnText).Displayed);
            Assert.Throws<NoSuchElementException>(() => { presentationPage.GetAvailableColumnOne(availableColumnFirstText); });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyMakeThisMyDefaultAndRevertToStandardDefaultFunctionality(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner");
            var page = new TaskPlannerPageObject(driver);
            var searchPage = new CaseSearchPageObject(driver);
            page.PresentationButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            searchPage.UseDefaultCheckbox.WithJs().Click();
            var selectedColumnsCount = searchPage.SelectedColumns.Count;
            var lastColumnText = searchPage.GetColumnName(selectedColumnsCount);
            searchPage.SimulateDragDrop(searchPage.SelectedColumnLast, searchPage.SelectedColumnFirst);
            Assert.AreEqual(lastColumnText, searchPage.GetColumnName(1));
            searchPage.SimulateDragDrop(searchPage.SelectedColumnFourth, searchPage.AvailableColumns);
            var newSelectedColumnsCount = searchPage.SelectedColumns.Count;
            Assert.AreNotEqual(selectedColumnsCount, newSelectedColumnsCount);

            var availableColumnName1 = searchPage.AvailableColumnFirst.Text;

            searchPage.Presentation.SearchColumnTextBox.SendKeys(availableColumnName1);
            Assert.AreEqual(availableColumnName1, searchPage.Presentation.SearchColumn.Text);

            var secondRowSelectedColumn = searchPage.GetColumnName(2);
            searchPage.FirstSortOrderDropDown.SelectByText("1");
            searchPage.SecondSortOrderDropDown.SelectByText("2");
            searchPage.Presentation.SecondHideCheckBox.Click();
            searchPage.SimulateDragDrop(searchPage.AvailableColumns, searchPage.SelectedColumnsGrid);
            searchPage.MoreItemButton.Click();
            searchPage.MakeThisMyDefaultButton.WithJs().Click();
            Assert.IsTrue(searchPage.UseDefaultCheckbox.IsChecked());
            page.PresentationPageSearchButton.Click();

            Assert.AreEqual("/task-planner", driver.Location, "Should navigate to task planner search result page");

            Assert.Throws<NoSuchElementException>(() => searchPage.GetAvailableColumnOne(secondRowSelectedColumn), "Ensure Reminder Date Column is not visible");
            Assert.IsTrue(searchPage.GetAvailableColumnOne(availableColumnName1).Displayed);
            page.PresentationButton.WithJs().Click();
            searchPage.MoreItemButton.Click();
            searchPage.RevertToStandardDefaultButton.WithJs().Click();
            Assert.IsTrue(searchPage.UseDefaultCheckbox.IsChecked());
            page.PresentationPageSearchButton.Click();
            Assert.AreEqual("/task-planner", driver.Location, "Should navigate to task planner search result page");
            Assert.IsTrue(searchPage.GetAvailableColumnOne(secondRowSelectedColumn).Displayed);
            Assert.Throws<NoSuchElementException>(() => searchPage.GetAvailableColumnOne(availableColumnName1), "Ensure Case Status Column is not visible");
        }
    }
}