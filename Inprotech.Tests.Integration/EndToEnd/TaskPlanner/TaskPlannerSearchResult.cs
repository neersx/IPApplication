using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using MenuItemsPageObject = Inprotech.Tests.Integration.PageObjects.MenuItems;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class TaskPlannerSearchResult : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyRevertQuickFilters(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();

            var today = DateTime.Today;
            var thisWeekFrom = today.AddDays(-((int)today.DayOfWeek - 1));
            var nextWeekFrom = thisWeekFrom.AddDays(7);
            var nextWeekTo = thisWeekFrom.AddDays(13);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, thisWeekFrom.AddDays(1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, thisWeekFrom.AddDays(2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, nextWeekFrom.AddDays(1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, nextWeekFrom.AddDays(2), taskPlannerData.User);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var page = new TaskPlannerPageObject(driver);
            
            driver.WaitForAngularWithTimeout();
            Assert.IsTrue(page.RevertButton.IsDisabled(), "Revert Button should be disabled initially");
            Assert.AreEqual(4, page.Grid.Rows.Count, "Total rows of result grid should be 4");
            var fromDateText = page.FromDate.Value;
            var toDateText = page.ToDate.Value;

            page.TimePeriodSelect.SelectByText("Next Week");
            Assert.AreEqual(nextWeekFrom.ToString("dd-MMM-yyyy"), page.FromDate.Value, "From date should be first day of next week");
            Assert.AreEqual(nextWeekTo.ToString("dd-MMM-yyyy"), page.ToDate.Value, "To date should be last day of next week");
            Assert.IsFalse(page.RevertButton.IsDisabled());
            page.RefreshButton.Click();
            driver.WaitForGridLoader();
            Assert.AreEqual(2, page.Grid.Rows.Count, "Total rows of result grid should be 2");

            page.RevertButton.Click();
            driver.WaitForGridLoader();
            Assert.IsTrue(page.RevertButton.IsDisabled(), "Revert Button should be disabled");
            Assert.AreEqual(4, page.Grid.Rows.Count, "Total rows of result grid should be 4");
            Assert.AreEqual(fromDateText, page.FromDate.Value, "From date should be default from date of saved search");
            Assert.AreEqual(toDateText, page.ToDate.Value, "To date should be default to date of saved search");
        }
    }
}