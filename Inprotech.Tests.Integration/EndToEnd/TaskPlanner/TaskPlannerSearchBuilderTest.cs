using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class TaskPlannerSearchBuilderTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyDueDateSavedSearch(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var user = taskPlannerData.User;
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);

            var page = new TaskPlannerPageObject(driver);
            var builderPage = new TaskPlannerSearchBuilderPageObject(driver);

            page.SavedSearchPicklist.OpenPickList();
            page.ClearButton(driver).Click();
            page.SearchPicklistText.SendKeys("My Due Dates");
            page.SearchButton(driver).ClickWithTimeout();
            var tabsGrid = page.ResultGrid;
            tabsGrid.ClickRow(0);
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            page.FilterButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(true,  builderPage.SearchByDueDateCheckbox.IsChecked, "Due Date checkbox should be checked");
            Assert.AreEqual(false,  builderPage.SearchByReminderDateCheckbox.IsChecked, "Reminder Date checkbox should be unchecked");
        }
    }
}
