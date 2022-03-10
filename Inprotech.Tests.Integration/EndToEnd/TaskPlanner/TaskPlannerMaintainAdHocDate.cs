using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerMaintainAdHocDate : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void MaintainAdHocDateForCase(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(-2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
            resultPage.OpenTaskMenuOption(1, "maintainAdhocDate");
            driver.WaitForAngular();

            Assert.IsFalse(resultPage.DueDateTextBox.IsDisabled());
            Assert.IsFalse(resultPage.EventPicklist.Enabled);
            Assert.IsFalse(resultPage.MyselfCheckBox.IsDisabled);
            Assert.IsFalse(resultPage.StaffCheckBox.IsDisabled);
            Assert.IsFalse(resultPage.SignatoryCheckBox.IsDisabled);
            Assert.IsFalse(resultPage.CriticalCheckBox.IsDisabled);
            Assert.IsFalse(resultPage.MyselfCheckBox.IsChecked);
            Assert.IsTrue(resultPage.StaffCheckBox.IsChecked);
            Assert.IsFalse(resultPage.SignatoryCheckBox.IsChecked);
            Assert.IsFalse(resultPage.CriticalCheckBox.IsChecked);
            Assert.IsFalse(resultPage.RecipientsNamesPicklist.Enabled);
            Assert.IsTrue(resultPage.NameTypePicklist.Enabled);
            Assert.IsFalse(resultPage.RelationshipPicklist.Enabled);
            Assert.AreEqual(taskPlannerData.Data[1].Case.Irn, resultPage.CaseReferencePicklist.GetText());
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("additionalNames")), "Ensure Additional Names picklist is not visible");
            Assert.AreEqual(resultPage.DueDate.Value, today.ToString("dd-MMM-yyyy"));
            StringAssert.Contains("E2E Test Message", resultPage.MessageTextArea.Value(), "Ensure Message");
            resultPage.FinalisedOn.GoToDate(1);
            resultPage.ReasonDropDownSelect.SelectByText("Approximate date event occurred");
            resultPage.ImportanceLevelDropDownSelect.SelectByText("Critical");
            resultPage.ModalSaveButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.IsTrue(resultPage.SuccessMessage.Text.Contains("Your changes have been successfully saved."));
            Assert.AreEqual(2, resultPage.Grid.Rows.Count);
            resultPage.FilterButton.ClickWithTimeout();
            resultPage.IncludeFinalisedAdHocDatesCheckBox.Click();
            resultPage.AdvancedSearchButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void DeleteAdHocDateForCase(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today.AddDays(-2), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
            resultPage.OpenTaskMenuOption(1, "maintainAdhocDate");
            driver.WaitForAngular();
            resultPage.DeleteAdHocButton.ClickWithTimeout();
            resultPage.DeleteButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.IsTrue(resultPage.SuccessMessage.Text.Contains("Your changes have been successfully saved."));
            Assert.AreEqual(2, resultPage.Grid.Rows.Count);
        }
    }
}
