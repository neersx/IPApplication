using System;
using Inprotech.Tests.Integration.Extensions;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerQuickFilter : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyNameQuickFilter(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData(createOtherStaffCase: true);

            var today = DateTime.Today;
            var thisWeekFrom = today.AddDays(-((int)today.DayOfWeek - 1));
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, thisWeekFrom.AddDays(1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, thisWeekFrom.AddDays(2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[3].Case.Id, thisWeekFrom.AddDays(1), taskPlannerData.User, nameId: taskPlannerData.OtherStaff.Id);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[3].Case.Id, thisWeekFrom.AddDays(2), taskPlannerData.User, nameId: taskPlannerData.OtherStaff.Id);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var page = new TaskPlannerPageObject(driver);

            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(taskPlannerData.Data[0].Case.Irn, page.Grid.Rows[0].FindElement(By.XPath("//ipx-hosted-url/a")).Text, "First row case ref should be Case 1 case ref");
            Assert.AreEqual(taskPlannerData.Data[0].Case.Irn, page.Grid.Rows[1].FindElement(By.XPath("//ipx-hosted-url/a")).Text, "Second row case ref should be Case 1 case ref");
            page.NameKeyPicklist.Clear();
            page.RefreshButton.Click();
            driver.WaitForAngular();
            page.Grid.FindElement(By.XPath("//thead/tr/th[6]/span[1]")).Click();
            driver.WaitForAngular();
            Assert.AreEqual(4, page.Grid.Rows.Count, "Total rows of result grid should be 4");
            Assert.AreEqual(taskPlannerData.Data[0].Case.Irn, page.Grid.CellText(0, 5), "First row case ref should be Case 1 case ref");
            Assert.AreEqual(taskPlannerData.Data[0].Case.Irn, page.Grid.CellText(1, 5), "Second row case ref should be Case 1 case ref");
            Assert.AreEqual(taskPlannerData.Data[3].Case.Irn, page.Grid.CellText(2, 5), "Third row case ref should be Case 4 case ref");
            Assert.AreEqual(taskPlannerData.Data[3].Case.Irn, page.Grid.CellText(3, 5), "Fourth row case ref should be Case 4 case ref");
        }
    }
}