using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.TaskPlanner;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.TaskPlanner;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerConfiguration : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyTaskPlannerConfiguration(BrowserType browserType)
        {
            var user = DbSetup.Do(x => new Users(x.DbContext).WithPermission(ApplicationTask.MaintainTaskPlannerConfiguration).Create());
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "#/configuration/task-planner-configuration", user.Username, user.Password);
            var page = new TaskPlannerConfigurationPageObject(driver);
            Assert.True(page.RevertButton.IsDisabled());
            Assert.True(page.SaveButton.IsDisabled());
            Assert.AreEqual(1, page.Grid.Rows.Count);
            var defaultRow = page.Grid.Rows.First();
            Assert.AreEqual(string.Empty, defaultRow.FindElements(By.TagName("td")).First().Text);
            Assert.False(defaultRow.FindElements(By.CssSelector("input[type=checkbox]"))[0].IsChecked());
            page.Grid.AddButton.ClickWithTimeout();
            page.SelectPickListItem(0, "profile", "Accounts");
            page.SelectPickListItem(0, "tab1", "My Due Dates");
            page.SelectPickListItem(0, "tab2", "My Tasks");
            page.SelectPickListItem(0, "tab3", "My Reminders");
            page.GetLockedCheckBox(0).Click();
            page.SaveButton.WithJs().Click();
            driver.WaitForAngular();
            Assert.IsTrue(page.SuccessMessage.Text.Contains("Your changes have been successfully saved."));
            Assert.True(page.Grid.Rows[1].FindElements(By.CssSelector("input[type=checkbox]"))[0].IsChecked());
            Assert.AreEqual(2, page.Grid.Rows.Count);
            page.Grid.ClickEdit(1);
            page.SelectPickListItem(0, "profile", "Customer Relations");
            page.SelectPickListItem(0, "tab1", "My Team's Tasks");
            page.SaveButton.WithJs().Click();
            driver.WaitForAngular();
            Assert.IsTrue(page.SuccessMessage.Text.Contains("Your changes have been successfully saved."));

            page.Grid.ClickDelete(1);
            page.SaveButton.WithJs().Click();
            driver.WaitForAngular();
            Assert.IsTrue(page.SuccessMessage.Text.Contains("Your changes have been successfully saved."));
            Assert.AreEqual(1, page.Grid.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyTaskPlannerUserPreference(BrowserType browserType)
        {
            SetTabLocked(2, true);

            var user = DbSetup.Do(x => new Users(x.DbContext).WithPermission(ApplicationTask.MaintainTaskPlannerSearch).Create());
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            driver.WaitForGridLoader();
            driver.With<QuickLinks>(slider =>
            {
                slider.Open("contextTaskPlanner");

                var page = new TaskPlannerConfigurationPageObject(driver);
                var tab1Picklist = page.GetTabPickList(1);
                var tab2Picklist = page.GetTabPickList(2);
                var tab3Picklist = page.GetTabPickList(3);
                Assert.True(tab1Picklist.Enabled, "Expected tab1 picklist to be enabled initially");
                Assert.False(tab2Picklist.Enabled, "Expected tab2 picklist to be disabled initially");
                Assert.True(tab3Picklist.Enabled, "Expected tab3 picklist to be enabled initially");

                tab1Picklist.Clear();
                tab1Picklist.Typeahead.Clear();
                tab1Picklist.Typeahead.SendKeys("My Due Dates");
                tab1Picklist.Blur();
                page.ResetToDefaultButton.Click();
                driver.WaitForAngular();
                Assert.AreEqual(tab1Picklist.GetText(), "My Reminders", "'My Reminders' saved search should be selected in tab1 picklist");
                Assert.AreEqual(tab2Picklist.GetText(), "My Due Dates", "'My Due Dates' saved search should be selected in tab2 picklist");
                Assert.AreEqual(tab3Picklist.GetText(), "My Team's Tasks", "'My Team's Tasks' saved search should be selected in tab3 picklist");

                tab1Picklist.Clear();
                tab1Picklist.Typeahead.Clear();
                tab1Picklist.Typeahead.SendKeys("My Due Dates");
                tab1Picklist.Blur();
                page.ApplyButton.Click();
                driver.WaitForAngular();
                Assert.AreEqual(page.ConfirmMessage.Text, "The changes to your personal preferences have been saved. If you proceed, the current browser tab will be automatically refreshed. Note that this will mean any unsaved changes will be lost.");
                page.ConfirmButton.Click();
            });

            driver.WaitForAngular();
            var resultPage = new TaskPlannerPageObject(driver);
            Assert.AreEqual(resultPage.SavedSearchPicklist.GetText(), "My Due Dates", "'My Due Dates' saved search should be selected in tab3 picklist");

            SetTabLocked(2, false);
        }

        void SetTabLocked(int tabSequence, bool isLocked)
        {
            DbSetup.Do(x =>
            {
                var defaultTab = x.DbContext.Set<TaskPlannerTabsByProfile>().Single(_ => !_.ProfileId.HasValue && _.TabSequence == tabSequence);
                defaultTab.IsLocked = isLocked;
                x.DbContext.SaveChanges();
            });
        }
    }
}
