using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Reminders;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerApplyAdHocDateTemplates : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ApplyAdHocDateTemplateCase(BrowserType browserType)
        {
            short daysLead = 3;
            short daysFrequency = 5;
            var taskPlannerData = TaskPlannerService.SetupData();
            using (var db = new DbSetup())
            {

                var empNo = taskPlannerData.Staff.Id;
                var adHocTemplate = new AlertTemplate() {AlertTemplateCode = "e2e", StaffId = empNo, Importance = "9", AlertMessage = "e2e template", SendElectronically = true, EmailSubject = "e2e email", EmployeeFlag = true, SignatoryFlag = true, DaysLead = daysLead, DailyFrequency = daysFrequency, StopAlert = daysLead, DeleteAlert = daysLead, NameTypeId = "A", Relationship = "EMP"};
                db.DbContext.Set<AlertTemplate>().Add(adHocTemplate);

                db.DbContext.SaveChanges();
            }
            var todaysDate = DateTime.Today;
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            resultPage.OpenTaskPlannerTab(1).ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
            resultPage.AdhocDateButton.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.IsFalse(resultPage.DueDateTextBox.IsDisabled());
            Assert.IsFalse(resultPage.EventPicklist.Enabled);
            Assert.IsFalse(resultPage.MyselfCheckBox.IsDisabled);
            Assert.IsFalse(resultPage.StaffCheckBox.IsDisabled);
            Assert.IsFalse(resultPage.SignatoryCheckBox.IsDisabled);
            Assert.IsFalse(resultPage.CriticalCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.MyselfCheckBox.IsChecked);
            Assert.IsTrue(resultPage.StaffCheckBox.IsChecked);
            Assert.IsTrue(resultPage.SignatoryCheckBox.IsChecked);
            Assert.IsFalse(resultPage.CriticalCheckBox.IsChecked);
            Assert.IsFalse(resultPage.RecipientsNamesPicklist.Enabled);
            Assert.IsTrue(resultPage.NameTypePicklist.Enabled);
            Assert.IsFalse(resultPage.RelationshipPicklist.Enabled);
            Assert.IsTrue(resultPage.AdditionalNamesPicklist.Enabled);
            resultPage.CaseReferencePicklist.EnterAndSelect(taskPlannerData.Data[0].Case.Irn);
            resultPage.DueDate.GoToDate(2);
            resultPage.AdHocTemplatePicklist.EnterAndSelect("e2e");
            resultPage.ApplyTemplate.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.AreEqual(resultPage.AdHocResponsibleNamePicklist.GetText(), taskPlannerData.Staff.Formatted());
            Assert.AreEqual(resultPage.AutomaticDeleteOnDate.Value, todaysDate.AddDays(5).ToString("dd-MMM-yyyy"));
            Assert.AreEqual(resultPage.MessageTextArea.Value(), "e2e template");
            Assert.AreEqual( "Critical", resultPage.ImportanceLevelDropDownSelect.SelectedOption.Text.Trim());
            Assert.AreEqual(resultPage.SendReminderTextBox.Value(), "3");
            Assert.IsTrue(resultPage.RecurringCheckBox.IsChecked);
            Assert.AreEqual(resultPage.RepeatEveryTextBox.Value(), "5");
            Assert.IsTrue(resultPage.RepeatEveryDayLabel.Displayed);
            Assert.AreEqual(resultPage.EndOnDate.Value, todaysDate.AddDays(5).ToString("dd-MMM-yyyy"));
            Assert.IsTrue(resultPage.MyselfCheckBox.IsChecked);
            Assert.IsTrue(resultPage.StaffCheckBox.IsChecked);
            Assert.IsTrue(resultPage.SignatoryCheckBox.IsChecked);
            Assert.IsFalse(resultPage.CriticalCheckBox.IsChecked);
            Assert.AreEqual(resultPage.NameTypePicklist.GetText(), "Agent");
            Assert.AreEqual(resultPage.RelationshipPicklist.GetText(), "Employs");
            Assert.IsFalse(resultPage.RecipientsNamesPicklist.Enabled);
            Assert.IsTrue(resultPage.EmailCheckBox.IsChecked);
            Assert.AreEqual(resultPage.EmailSubjectTextArea.Value(), "e2e email");
            resultPage.AdditionalNamesPicklist.OpenPickList();
            resultPage.AdditionalNamesPicklist.ModalSearchButton().ClickWithTimeout();
            resultPage.AdditionalNamesGrid.Rows[1].Click();
            resultPage.AdditionalNamesGrid.Rows[2].Click();
            resultPage.AdditionalNamesGrid.Rows[3].Click();
            resultPage.ApplyButton.ClickWithTimeout();
            resultPage.ModalSaveButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.IsTrue(resultPage.SuccessMessage.Text.Contains("Your changes have been successfully saved."));
            Assert.AreEqual(8, resultPage.Grid.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ApplyAdHocDateTemplateName(BrowserType browserType)
        {
            short months = 3;
            short monthsFrequency = 5;
            var taskPlannerData = TaskPlannerService.SetupData();
            using (var db = new DbSetup())
            {

                var empNo = taskPlannerData.Staff.Id;
                var adHocTemplate = new AlertTemplate() {AlertTemplateCode = "e2e", StaffId = empNo, Importance = "9", AlertMessage = "e2e template", SendElectronically = true, EmailSubject = "e2e email", EmployeeFlag = true, SignatoryFlag = true, MonthsLead = months, MonthlyFrequency = monthsFrequency, StopAlert = months, DeleteAlert = months, NameTypeId = "A", Relationship = "EMP"};
                db.DbContext.Set<AlertTemplate>().Add(adHocTemplate);

                db.DbContext.SaveChanges();
            }
            var todaysDate = DateTime.Today;
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            resultPage.OpenTaskPlannerTab(1).ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
            resultPage.AdhocDateButton.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.IsFalse(resultPage.DueDateTextBox.IsDisabled());
            Assert.IsFalse(resultPage.EventPicklist.Enabled);
            resultPage.NameRadioButton.Click();
            var name = taskPlannerData.Data[0].Case.CaseNames.First(_ => _.NameType.NameTypeCode == "SIG");
            resultPage.NamePicklist.EnterAndSelect(name.Name.FormattedNameOrNull());
            Assert.IsFalse(resultPage.EventPicklist.Enabled);
            Assert.IsFalse(resultPage.MyselfCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.StaffCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.SignatoryCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.CriticalCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.MyselfCheckBox.IsChecked);
            Assert.IsFalse(resultPage.StaffCheckBox.IsChecked);
            Assert.IsFalse(resultPage.SignatoryCheckBox.IsChecked);
            Assert.IsFalse(resultPage.CriticalCheckBox.IsChecked);
            Assert.IsFalse(resultPage.RecipientsNamesPicklist.Enabled);
            Assert.IsFalse(resultPage.NameTypePicklist.Enabled);
            Assert.IsFalse(resultPage.RelationshipPicklist.Enabled);
            Assert.IsTrue(resultPage.AdditionalNamesPicklist.Enabled);
            resultPage.DueDate.GoToDate(2);
            resultPage.AdHocTemplatePicklist.EnterAndSelect("e2e");
            resultPage.ApplyTemplate.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.AreEqual(resultPage.AdHocResponsibleNamePicklist.GetText(), taskPlannerData.Staff.Formatted());
            Assert.AreEqual(resultPage.AutomaticDeleteOnDate.Value, todaysDate.AddDays(5).ToString("dd-MMM-yyyy"));
            Assert.AreEqual(resultPage.MessageTextArea.Value(), "e2e template");
            Assert.AreEqual("Critical", resultPage.ImportanceLevelDropDownSelect.SelectedOption.Text.Trim());
            Assert.AreEqual(resultPage.SendReminderTextBox.Value(), "3");
            Assert.IsTrue(resultPage.RecurringCheckBox.IsChecked);
            Assert.AreEqual(resultPage.RepeatEveryTextBox.Value(), "5");
            Assert.IsTrue(resultPage.RepeatEveryMonthLabel.Displayed);
            Assert.AreEqual(resultPage.EndOnDate.Value, todaysDate.AddDays(5).ToString("dd-MMM-yyyy"));
            Assert.IsTrue(resultPage.MyselfCheckBox.IsChecked);
            Assert.IsFalse(resultPage.StaffCheckBox.IsChecked);
            Assert.IsFalse(resultPage.SignatoryCheckBox.IsChecked);
            Assert.IsFalse(resultPage.CriticalCheckBox.IsChecked);
            Assert.IsFalse(resultPage.MyselfCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.StaffCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.SignatoryCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.CriticalCheckBox.IsDisabled);
            Assert.IsFalse(resultPage.NameTypePicklist.Enabled);
            Assert.IsFalse(resultPage.RelationshipPicklist.Enabled);
            Assert.IsFalse(resultPage.RecipientsNamesPicklist.Enabled);
            Assert.IsTrue(resultPage.EmailCheckBox.IsChecked);
            Assert.IsTrue(resultPage.AdditionalNamesPicklist.Enabled);
            resultPage.AdditionalNamesPicklist.OpenPickList();
            resultPage.AdditionalNamesPicklist.ModalSearchButton().ClickWithTimeout();
            resultPage.AdditionalNamesGrid.Rows[1].Click();
            resultPage.AdditionalNamesGrid.Rows[2].Click();
            resultPage.AdditionalNamesGrid.Rows[3].Click();
            resultPage.ApplyButton.ClickWithTimeout();
            Assert.AreEqual(resultPage.EmailSubjectTextArea.Value(), "e2e email");
            resultPage.ModalSaveButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.IsTrue(resultPage.SuccessMessage.Text.Contains("Your changes have been successfully saved."));
            resultPage.FilterButton.ClickWithTimeout();
            resultPage.AllNamesInBelongingToDropDown.Click();
            resultPage.DueDatesCheckBox.Click();
            resultPage.AdvancedSearchButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(4, resultPage.Grid.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ApplyAdHocDateTemplateGeneral(BrowserType browserType)
        {
            short daysLead = 3;
            short daysFrequency = 5;
            short monthsLead = 4;
            short monthsFrequency = 6;
            var taskPlannerData = TaskPlannerService.SetupData();
            using (var db = new DbSetup())
            {

                var empNo = taskPlannerData.Staff.Id;
                var adHocTemplate = new AlertTemplate() {AlertTemplateCode = "e2e", StaffId = empNo, Importance = "9", AlertMessage = "e2e template", SendElectronically = true, EmailSubject = "e2e email", EmployeeFlag = true, SignatoryFlag = true, DaysLead = daysLead, DailyFrequency = daysFrequency, MonthsLead = monthsLead, MonthlyFrequency = monthsFrequency, StopAlert = daysLead, DeleteAlert = daysLead, NameTypeId = "A", Relationship = "EMP"};
                db.DbContext.Set<AlertTemplate>().Add(adHocTemplate);

                db.DbContext.SaveChanges();
            }
            var todaysDate = DateTime.Today;
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            resultPage.OpenTaskPlannerTab(1).ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
            resultPage.AdhocDateButton.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.IsFalse(resultPage.DueDateTextBox.IsDisabled());
            Assert.IsFalse(resultPage.EventPicklist.Enabled);
            resultPage.GeneralRadioButton.Click();
            resultPage.GeneralTextBox.SendKeys("E2e general");
            Assert.IsFalse(resultPage.EventPicklist.Enabled);
            Assert.IsFalse(resultPage.MyselfCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.StaffCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.SignatoryCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.CriticalCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.MyselfCheckBox.IsChecked);
            Assert.IsFalse(resultPage.StaffCheckBox.IsChecked);
            Assert.IsFalse(resultPage.SignatoryCheckBox.IsChecked);
            Assert.IsFalse(resultPage.CriticalCheckBox.IsChecked);
            Assert.IsFalse(resultPage.RecipientsNamesPicklist.Enabled);
            Assert.IsFalse(resultPage.NameTypePicklist.Enabled);
            Assert.IsFalse(resultPage.RelationshipPicklist.Enabled);
            Assert.IsTrue(resultPage.AdditionalNamesPicklist.Enabled);
            resultPage.DueDate.GoToDate(2);
            resultPage.AdHocTemplatePicklist.EnterAndSelect("e2e");
            resultPage.ApplyTemplate.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.AreEqual(resultPage.AdHocResponsibleNamePicklist.GetText(), taskPlannerData.Staff.Formatted());
            Assert.AreEqual(resultPage.AutomaticDeleteOnDate.Value, todaysDate.AddDays(5).ToString("dd-MMM-yyyy"));
            Assert.AreEqual(resultPage.MessageTextArea.Value(), "e2e template");
            Assert.AreEqual("Critical", resultPage.ImportanceLevelDropDownSelect.SelectedOption.Text.Trim());
            Assert.AreEqual(resultPage.SendReminderTextBox.Value(), "3");
            Assert.IsTrue(resultPage.RecurringCheckBox.IsChecked);
            Assert.AreEqual(resultPage.RepeatEveryTextBox.Value(), "5");
            Assert.IsTrue(resultPage.RepeatEveryDayLabel.Displayed);
            Assert.AreEqual(resultPage.EndOnDate.Value, todaysDate.AddDays(5).ToString("dd-MMM-yyyy"));
            Assert.IsTrue(resultPage.MyselfCheckBox.IsChecked);
            Assert.IsFalse(resultPage.StaffCheckBox.IsChecked);
            Assert.IsFalse(resultPage.SignatoryCheckBox.IsChecked);
            Assert.IsFalse(resultPage.CriticalCheckBox.IsChecked);
            Assert.IsFalse(resultPage.MyselfCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.StaffCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.SignatoryCheckBox.IsDisabled);
            Assert.IsTrue(resultPage.CriticalCheckBox.IsDisabled);
            Assert.IsFalse(resultPage.NameTypePicklist.Enabled);
            Assert.IsFalse(resultPage.RelationshipPicklist.Enabled);
            Assert.IsFalse(resultPage.RecipientsNamesPicklist.Enabled);
            Assert.IsTrue(resultPage.EmailCheckBox.IsChecked);
            Assert.IsTrue(resultPage.AdditionalNamesPicklist.Enabled);
            resultPage.AdditionalNamesPicklist.OpenPickList();
            resultPage.AdditionalNamesPicklist.ModalSearchButton().ClickWithTimeout();
            resultPage.AdditionalNamesGrid.Rows[1].Click();
            resultPage.AdditionalNamesGrid.Rows[2].Click();
            resultPage.AdditionalNamesGrid.Rows[3].Click();
            resultPage.ApplyButton.ClickWithTimeout();
            Assert.AreEqual(resultPage.EmailSubjectTextArea.Value(), "e2e email");
            
            resultPage.ModalSaveButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.IsTrue(resultPage.SuccessMessage.Text.Contains("Your changes have been successfully saved."));
            resultPage.FilterButton.ClickWithTimeout();
            resultPage.AllNamesInBelongingToDropDown.Click();
            resultPage.DueDatesCheckBox.Click();
            resultPage.AdvancedSearchButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(4, resultPage.Grid.Rows.Count);
        }
    }
}
