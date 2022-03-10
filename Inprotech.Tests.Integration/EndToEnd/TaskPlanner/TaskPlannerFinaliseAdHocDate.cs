using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    class TaskPlannerFinaliseAdHocDate : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void FinaliseAdHocDateFromTaskMenu(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(-2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User);

            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);

            resultPage.OpenTaskMenuOption(0, "finalise");
            driver.WaitForAngular();
            resultPage.ReasonDropDownSelect.SelectByText("Approximate date event occurred");
            resultPage.FinaliseButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual("The Ad Hoc Date has been successfully finalised.", resultPage.SuccessMessage.Text);
            driver.WaitForGridLoader();
            Assert.AreEqual(2, resultPage.Grid.Rows.Count);
            resultPage.FilterButton.ClickWithTimeout();
            var sbpo = new TaskPlannerSearchBuilderPageObject(driver);
            sbpo.AdhocDateIncludeFinalizedItemsCheckbox.Click();
            sbpo.SearchButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void FinaliseAdHocDateFromBulkActionMenu(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var today = DateTime.Now;
            var taskPlannerData = TaskPlannerService.SetupData();
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(-2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User);
            
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            resultPage.OpenTaskPlannerTab(1).ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(6, resultPage.Grid.Rows.Count);

            resultPage.Grid.SelectRow(4);
            resultPage.Grid.SelectRow(5);
            resultPage.Grid.ActionMenu.OpenOrClose();
            resultPage.Grid.ActionMenu.Option("finalise").ClickWithTimeout();
            driver.WaitForAngular();
            resultPage.ReasonDropDownSelect.SelectByText("Approximate date event occurred");
            resultPage.FinaliseButton.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.AreEqual("The Ad Hoc Date has been successfully finalised.", resultPage.SuccessMessage.Text);
            driver.WaitForGridLoader();
            Assert.AreEqual(4, resultPage.Grid.Rows.Count);
            
            resultPage.Grid.ActionMenu.OpenOrClose();
            driver.WaitForAngular();
            resultPage.Grid.ActionMenu.SelectAll();
            resultPage.Grid.ActionMenu.Option("finalise").ClickWithTimeout();
            driver.WaitForAngular();
            resultPage.ReasonDropDownSelect.SelectByText("Approximate date event occurred");
            resultPage.FinaliseButton.ClickWithTimeout();
            driver.WaitForAngular();
            var alertMessage = resultPage.AlertMessage.Text;
            Assert.True(alertMessage.Contains("One or more of the selected tasks cannot be finalised because they are not Ad Hoc Dates. They are highlighted in red."));
            Assert.True(alertMessage.Contains("The remaining tasks have been successfully finalised."));
            resultPage.AlertOkButton.Click();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);

            resultPage.Grid.ActionMenu.OpenOrClose();
            driver.WaitForAngular();
            resultPage.Grid.ActionMenu.SelectAll();
            resultPage.Grid.ActionMenu.Option("finalise").ClickWithTimeout();
            driver.WaitForAngular();
            resultPage.ReasonDropDownSelect.SelectByText("Approximate date event occurred");
            resultPage.FinaliseButton.ClickWithTimeout();
            driver.WaitForAngular();
            alertMessage = resultPage.AlertMessage.Text;
            Assert.True(alertMessage.Contains("None of the selected tasks can be finalised because they are not Ad Hoc Dates."));
            resultPage.AlertOkButton.Click();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
        }
        
    }
}

