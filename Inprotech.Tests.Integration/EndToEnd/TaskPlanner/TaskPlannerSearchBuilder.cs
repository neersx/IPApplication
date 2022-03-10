using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using NUnit.Framework;
using OpenQA.Selenium;
using MenuItemsPageObject = Inprotech.Tests.Integration.PageObjects.MenuItems;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerSearchBuilder : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifySearchBuilderGeneralTopic(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            var rangeFrom = 0;
            var rangeTo = 2;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today.AddDays(1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User);
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);

            Assert.IsTrue(resultPage.FilterButton.Enabled);
            resultPage.FilterButton.Click();
            Assert.IsTrue(driver.Url.Contains("#/task-planner/search-builder"), "Expected Task Planner Search Builder Landing Page to be opened");
            var heading = driver.FindElement(By.XPath("//h2")).Text;
            Assert.IsTrue(heading.Contains("Task Planner Search"));
            var page = new TaskPlannerSearchBuilderPageObject(driver);
            AssertGeneralTopicDefaultValues(page);
            
            page.IncludeAdHocDatesCheckbox.Click();

            AssertValuesForReminderTicked(page);
            AssertValuesForRemindersOnlyTicked(page);

            page.IncludeDueDatesCheckbox.Click();
            page.IncludeRemindersCheckbox.Click();
            AssertValuesForDueDateOnlyTicked(page);

            page.IncludeAdHocDatesCheckbox.Click();
            page.IncludeDueDatesCheckbox.Click();
            AssertValuesForAdHocDateOnlyTicked(page);

            page.DatePeriodRadio.WithJs().Click();
            AssertValuesForPeriodRange(page);
            page.DatePeriodFromTextbox.Input.Clear();
            page.DatePeriodFromTextbox.Input.SendKeys(rangeFrom.ToString());
            page.DatePeriodToTextbox.Input.Clear();
            page.DatePeriodToTextbox.Input.SendKeys(rangeTo.ToString());
            page.DatePeriodFromTextbox.Input.WithJs().Focus();
            Assert.IsFalse(page.SearchButton.IsDisabled());

            page.DatePeriodRadio.WithJs().Click();
            page.DatePeriodFromTextbox.Input.Clear();
            page.DatePeriodToTextbox.Input.Clear();
            page.DatePeriodFromTextbox.Input.SendKeys(rangeFrom.ToString());
            page.DatePeriodToTextbox.Input.SendKeys(rangeTo.ToString());
            page.DatePeriodFromTextbox.Input.WithJs().Focus();
            driver.FindElement(By.XPath("//ipx-dropdown[@name='periodType']//select/option[@value='1: D']")).Click();

            page.SearchButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.IsTrue(driver.Url.Contains("#/task-planner"), "Expected Task Planner Landing Page to be opened");
            var title = driver.FindElement(By.XPath("//div[@class='page-title']//span[contains(text(),'Task Planner')]"));
            Assert.AreEqual("Task Planner", title.Text);

            Assert.AreEqual(DateTime.Today.AddDays(rangeFrom).ToString("dd-MMM-yyyy"), resultPage.FromDate.Value);
            Assert.AreEqual(DateTime.Today.AddDays(rangeTo).ToString("dd-MMM-yyyy"), resultPage.ToDate.Value);
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
            Assert.True(resultPage.Grid.Rows[0].Text.StartsWith(taskPlannerData.Data[0].Case.Irn));
            Assert.True(resultPage.Grid.Rows[1].Text.StartsWith(taskPlannerData.Data[1].Case.Irn));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifySearchBuilderCaseCharacteristicsTopic(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner/search-builder");

            var page = new TaskPlannerSearchBuilderPageObject(driver);
            AssertCaseCharacteristicsTopicDefaultValues(page);
            page.CaseReferenceOperatorDropdown.Input.SelectByText("Equal To");
            Assert.True(page.CaseRefCasesPicklist.Displayed);
            page.CaseReferenceOperatorDropdown.Input.SelectByText("Contains");
            Assert.True(page.CaseReferenceTextbox.Input.Displayed);
            page.CaseReferenceTextbox.Input.SendKeys("1234");

            Assert.True(page.CaseFamilyPicklist.Displayed);
            page.CaseFamilyOperatorDropdown.Input.SelectByText("Exists");
            Assert.Throws<NoSuchElementException>(() => { page.CaseFamilyPicklist.Clear(); });

            Assert.True(page.CaseListPicklist.Displayed);
            page.CaseListOperatorDropdown.Input.SelectByText("Exists");
            Assert.Throws<NoSuchElementException>(() => { page.CaseListPicklist.Clear(); });

            Assert.True(page.CaseOfficePicklist.Displayed);
            page.CaseOfficeOperatorDropdown.Input.SelectByText("Exists");
            Assert.Throws<NoSuchElementException>(() => { page.CaseOfficePicklist.Clear(); });

            page.CaseTypePicklist.SendKeys("Internal");
            page.CaseTypePicklist.Blur();
            Assert.True(page.CaseCategoryPicklist.Enabled);
            Assert.False(page.CaseCategoryOperatorDropdown.IsDisabled);

            page.ClearButton.WithJs().Click();
            AssertCaseCharacteristicsTopicDefaultValues(page);

            Assert.True(page.CaseReferencesSubHeading.Displayed);
            Assert.True(page.CaseDetailsSubHeading.Displayed);
            Assert.True(page.CaseNamesSubHeading.Displayed);
            Assert.True(page.CaseStatusSubHeading.Displayed);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyCaseNamesAndStatus(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today.AddDays(1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User);
            SignIn(driver, "/#/task-planner/search-builder", taskPlannerData.User.Username, taskPlannerData.User.Password);

            var page = new TaskPlannerSearchBuilderPageObject(driver);
            var resultPage = new TaskPlannerPageObject(driver);
            AssertCaseNamesAndStatusDefaultValues(page);

            page.StartDate.GoToDate(0);
            page.EndDate.GoToDate(0);

            page.InstructorOperatorDropdown.Input.SelectByText("Starts With");
            page.InstructorTextbox.Input.SendKeys("Test Instructor 1");
            Assert.True(page.InstructorTextbox.Element.Displayed);
            Assert.Throws<NoSuchElementException>(() => { page.InstructorNamesPicklist.Blur(); });

            page.OwnerOperatorDropdown.Input.SelectByText("Contains");
            page.OwnerTextbox.Input.SendKeys("Test owner 1");
            Assert.True(page.OwnerTextbox.Element.Displayed);
            Assert.Throws<NoSuchElementException>(() => { page.OwnerPicklist.Blur(); });

            page.OtherNameTypeOperatorDropdown.Input.SelectByText("Ends With");
            page.OtherNameTypesTextbox.Input.SendKeys("other type 1");
            Assert.True(page.OtherNameTypesTextbox.Element.Displayed);
            Assert.Throws<NoSuchElementException>(() => { page.OtherNameTypesPicklist.Click(); });

            page.CaseStatusOperatorDropdown.Input.SelectByText("Exists");
            Assert.Throws<NoSuchElementException>(() => { page.CaseStatusPicklist.Element.Click(); });
            page.RenewalStatusOperatorDropdown.Input.SelectByText("Not Exists");
            Assert.Throws<NoSuchElementException>(() => { page.RenewalStatusPicklist.Element.Click(); });

            page.PendingCheckbox.Click();
            page.RegisteredCheckbox.Click();
            page.DeadCheckbox.Click();

            page.SearchButton.WithJs().Click();
            resultPage.FilterButton.WithJs().Click();
            AssertRememberFields(page, today);

            page.ClearButton.WithJs().Click();
            AssertCaseNamesAndStatusDefaultValues(page);
            page.StartDate.GoToDate(1);
            page.EndDate.GoToDate(2);
            page.CaseReferenceTextbox.Input.SendKeys("TaskPlanner");
            page.SearchButton.WithJs().Click();
            driver.WaitForGridLoader();

            page.RefreshButton.ClickWithTimeout();
            driver.WaitForGridLoader();

            Assert.AreEqual(2, resultPage.Grid.Rows.Count);
            Assert.True(resultPage.Grid.Rows[0].Text.StartsWith(taskPlannerData.Data[1].Case.Irn));
            Assert.True(resultPage.Grid.Rows[1].Text.StartsWith(taskPlannerData.Data[2].Case.Irn));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyEventsAndActions(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today, taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today.AddDays(1), taskPlannerData.User);
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User);
            SignIn(driver, "/#/task-planner/search-builder", taskPlannerData.User.Username, taskPlannerData.User.Password);

            var page = new TaskPlannerSearchBuilderPageObject(driver);
            var resultPage = new TaskPlannerPageObject(driver);
            AssertEventsAndActionsDefaultValues(page);

            page.StartDate.GoToDate(0);
            page.EndDate.GoToDate(0);

            page.EventOperatorDropdown.Input.SelectByText("Equal To");
            Assert.True(page.EventPicklist.Displayed);
            page.EventOperatorDropdown.Input.SelectByText("Exists");
            Assert.Throws<NoSuchElementException>(() => { page.EventPicklist.Blur(); });

            page.EventCategoryOperatorDropdown.Input.SelectByText("Not Equal To");
            Assert.True(page.EventCategoryPicklist.Displayed);
            page.EventCategoryOperatorDropdown.Input.SelectByText("Exists");
            Assert.Throws<NoSuchElementException>(() => { page.EventCategoryPicklist.Blur(); });

            page.EventGroupOperatorDropdown.Input.SelectByText("Equal To");
            Assert.True(page.EventGroupPicklist.Displayed);
            page.EventGroupOperatorDropdown.Input.SelectByText("Not Exists");
            Assert.Throws<NoSuchElementException>(() => { page.EventGroupPicklist.Blur(); });

            page.EventNotesOperatorDropdown.Input.SelectByText("Starts With");
            Assert.True(page.EventNotesTextbox.Input.Displayed);
            page.EventNotesOperatorDropdown.Input.SelectByText("Not Exists");
            Assert.Throws<NoSuchElementException>(() => { page.EventNotesTextbox.Input.SendKeys("Note1"); });

            page.ActionOperatorDropdown.Input.SelectByText("Not Equal To");
            Assert.True(page.ActionPicklist.Displayed);
            page.ActionOperatorDropdown.Input.SelectByText("Not Exists");
            Assert.Throws<NoSuchElementException>(() => { page.ActionPicklist.Blur(); });

            page.RenewalsCheckbox.Click();
            page.NonRenewalsCheckbox.Click();
            page.ClosedCheckbox.Click();

            page.SearchButton.WithJs().Click();
            resultPage.FilterButton.WithJs().Click();

            Assert.AreEqual(Operators.Exists, page.EventOperatorDropdown.Value);
            Assert.AreEqual(Operators.Exists, page.EventCategoryOperatorDropdown.Value);
            Assert.AreEqual(Operators.NotExists, page.EventGroupOperatorDropdown.Value);
            Assert.AreEqual(Operators.NotExists, page.EventNotesOperatorDropdown.Value);
            Assert.AreEqual(Operators.NotExists, page.ActionOperatorDropdown.Value);
            Assert.Throws<NoSuchElementException>(() => { page.EventPicklist.Blur(); });
            Assert.Throws<NoSuchElementException>(() => { page.EventCategoryPicklist.Blur(); });
            Assert.Throws<NoSuchElementException>(() => { page.EventGroupPicklist.Blur(); });
            Assert.Throws<NoSuchElementException>(() => { page.ActionPicklist.Blur(); });
            Assert.Throws<NoSuchElementException>(() => { page.EventNotesTextbox.Input.SendKeys("Note1"); });

            Assert.False(page.RenewalsCheckbox.IsChecked);
            Assert.False(page.NonRenewalsCheckbox.IsChecked);
            Assert.True(page.ClosedCheckbox.IsChecked);

            page.ClearButton.WithJs().Click();
            AssertCaseNamesAndStatusDefaultValues(page);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyRemindersTopic(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today, taskPlannerData.User,"reminder");
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today.AddDays(1), taskPlannerData.User,"reminder message 1 ");
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User,"reminder message 2 ");
            SignIn(driver, "/#/task-planner/search-builder", taskPlannerData.User.Username, taskPlannerData.User.Password);

            var page = new TaskPlannerSearchBuilderPageObject(driver);
            var resultPage = new TaskPlannerPageObject(driver);
            AssertRemindersDefaultValues(page);

            page.StartDate.GoToDate(0);
            page.EndDate.GoToDate(0);

            page.RemindersOperatorDropdown.Input.SelectByText("Contains");
            page.ReminderMessageTextbox.Input.SendKeys("reminder message");

            page.OnHoldCheckbox.Click();
            page.ReadCheckbox.Click();

            page.SearchButton.WithJs().Click();
            
            Assert.AreEqual(2, resultPage.Grid.Rows.Count);
            resultPage.FilterButton.WithJs().Click();
            
            Assert.AreEqual(Operators.Contains, page.RemindersOperatorDropdown.Value);
            Assert.AreEqual("reminder message", page.ReminderMessageTextbox.Text);
            Assert.False(page.OnHoldCheckbox.IsChecked);
            Assert.True(page.NotOnHoldCheckbox.IsChecked);
            Assert.False(page.ReadCheckbox.IsChecked);
            Assert.True(page.NotReadCheckbox.IsChecked);

            page.ClearButton.WithJs().Click();
            AssertRemindersDefaultValues(page);
            page.RemindersOperatorDropdown.Input.SelectByText("Starts With");
            page.ReminderMessageTextbox.Input.SendKeys("reminder message 1");
            page.SearchButton.WithJs().Click();
            driver.WaitForGridLoader();

            Assert.AreEqual(1, resultPage.Grid.Rows.Count);
            Assert.True(resultPage.Grid.Rows[0].Text.StartsWith(taskPlannerData.Data[1].Case.Irn));
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyAdhocDatesTopic(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
            var today = DateTime.Now;
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[0].Case.Id, today, taskPlannerData.User,"adhoc message");
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[1].Case.Id, today.AddDays(1), taskPlannerData.User,"adhoc message 1 ");
            TaskPlannerService.InsertAdHocDate(taskPlannerData.Data[2].Case.Id, today.AddDays(2), taskPlannerData.User,"adhoc message 2 ");
            SignIn(driver, "/#/task-planner/search-builder", taskPlannerData.User.Username, taskPlannerData.User.Password);

            var page = new TaskPlannerSearchBuilderPageObject(driver);
            var resultPage = new TaskPlannerPageObject(driver);
            AssertAdhocDatesDefaultValues(page);

            page.StartDate.GoToDate(0);
            page.EndDate.GoToDate(0);
            
            page.AdhocDateIncludeNameCheckbox.Click();
            Assert.True(page.AdhocDateNamesOperatorDropdown.IsDisabled);
            Assert.False(page.AdhocDateNamesPicklist.Enabled);
            page.AdhocDateIncludeNameCheckbox.Click();
            
            page.AdhocDateIncludeGeneralCheckbox.Click();
            Assert.True(page.GeneralRefOperatorDropdown.IsDisabled);
            Assert.False(page.GeneralRefTextbox.Input.Enabled);
            page.AdhocDateIncludeGeneralCheckbox.Click();

            page.GeneralRefOperatorDropdown.Input.SelectByText("Contains");
            page.GeneralRefTextbox.Input.SendKeys("ref");
            page.EmailSubjectOperatorDropdown.Input.SelectByText("Ends With");
            page.EmailSubjectTextbox.Input.SendKeys("subject");
            page.AdhocDateMessageOperatorDropdown.Input.SelectByText("Not Equal To");
            page.AdhocDateMessageTextbox.Input.SendKeys("message 1");
            page.AdhocDateIncludeCaseCheckbox.Click();
            page.SearchButton.WithJs().Click();
            resultPage.FilterButton.WithJs().Click();
            
            Assert.AreEqual(Operators.Contains, page.GeneralRefOperatorDropdown.Value);
            Assert.AreEqual("ref", page.GeneralRefTextbox.Text);
            Assert.AreEqual(Operators.EndsWith, page.EmailSubjectOperatorDropdown.Value);
            Assert.AreEqual("subject", page.EmailSubjectTextbox.Text);
            Assert.AreEqual(Operators.NotEqualTo, page.AdhocDateMessageOperatorDropdown.Value);
            Assert.AreEqual("message 1", page.AdhocDateMessageTextbox.Text);
            Assert.False(page.AdhocDateIncludeCaseCheckbox.IsChecked);
            Assert.True(page.AdhocDateIncludeNameCheckbox.IsChecked);
            Assert.True(page.AdhocDateIncludeGeneralCheckbox.IsChecked);

            page.ClearButton.WithJs().Click();
            AssertAdhocDatesDefaultValues(page);
            page.IncludeDueDatesCheckbox.Click();
            page.IncludeRemindersCheckbox.Click();
            page.AdhocDateMessageOperatorDropdown.Input.SelectByText("Starts With");
            page.AdhocDateMessageTextbox.Input.SendKeys("adhoc message 1");
            page.SearchButton.WithJs().Click();
            driver.WaitForGridLoader();

            Assert.AreEqual(1, resultPage.Grid.Rows.Count);
            Assert.True(resultPage.Grid.Rows[0].Text.StartsWith(taskPlannerData.Data[1].Case.Irn));
        }

        void AssertGeneralTopicDefaultValues(TaskPlannerSearchBuilderPageObject page)
        {
            Assert.IsTrue(page.ClearButton.Enabled);
            Assert.IsTrue(page.SearchButton.Enabled);
            Assert.IsTrue(page.IncludeRemindersCheckbox.IsChecked);
            Assert.IsFalse(page.IncludeDueDatesCheckbox.IsChecked);
            Assert.IsTrue(page.IncludeAdHocDatesCheckbox.IsChecked);
            Assert.IsTrue(page.ActingAsReminderCheckbox.IsChecked);
            Assert.IsTrue(page.ActingAsDueDateCheckbox.IsChecked);
            Assert.IsTrue(page.SearchByReminderDateCheckbox.IsChecked);
            Assert.IsTrue(page.SearchByDueDateCheckbox.IsChecked);
            Assert.IsTrue(page.DatePeriodRadio.IsChecked());
            Assert.IsFalse(page.DateRangeRadio.IsChecked());            
        }

        void AssertValuesForReminderTicked(TaskPlannerSearchBuilderPageObject page)
        {
            Assert.IsTrue(page.SearchByReminderDateCheckbox.IsChecked);
            Assert.IsTrue(page.SearchByDueDateCheckbox.IsChecked);
        }

        void AssertValuesForRemindersOnlyTicked(TaskPlannerSearchBuilderPageObject page)
        {
            Assert.IsTrue(page.SearchByReminderDateCheckbox.IsChecked);
            Assert.IsFalse(page.SearchByReminderDateCheckbox.IsDisabled);
            Assert.IsTrue(page.SearchByDueDateCheckbox.IsChecked);
        }

        void AssertValuesForDueDateOnlyTicked(TaskPlannerSearchBuilderPageObject page)
        {
            Assert.IsFalse(page.SearchByReminderDateCheckbox.IsChecked);
            Assert.IsTrue(page.SearchByReminderDateCheckbox.IsDisabled);
            Assert.IsTrue(page.SearchByDueDateCheckbox.IsChecked);
        }

        void AssertValuesForAdHocDateOnlyTicked(TaskPlannerSearchBuilderPageObject page)
        {
            Assert.IsTrue(page.SearchByReminderDateCheckbox.IsChecked);
            Assert.IsTrue(page.SearchByDueDateCheckbox.IsChecked);
            Assert.IsTrue(page.ActingAsDueDateCheckbox.IsDisabled);
            Assert.IsFalse(page.ActingAsDueDateCheckbox.IsChecked);
        }

        void AssertValuesForPeriodRange(TaskPlannerSearchBuilderPageObject page)
        {
            Assert.IsTrue(page.DatePeriodFromTextbox.Element.Displayed);
            Assert.IsTrue(page.DatePeriodToTextbox.Element.Displayed);
            Assert.Throws<NoSuchElementException>(() => page.GetDateRangeStartDatePicker());
            Assert.Throws<NoSuchElementException>(() => page.GetDateRangeEndDatePicker());
            Assert.IsFalse(page.SearchButton.IsDisabled());
        }

        void AssertCaseCharacteristicsTopicDefaultValues(TaskPlannerSearchBuilderPageObject page)
        {
            Assert.AreEqual(Operators.StartsWith, page.CaseReferenceOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.OfficialNumberOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.CaseFamilyOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.CaseListOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.CaseOfficeOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.CaseTypeOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.JurisdictionOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.CaseCategoryOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.BasisOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.SubTypeOperatorDropdown.Value);
            Assert.False(page.CaseCategoryPicklist.Enabled);
        }

        void AssertCaseNamesAndStatusDefaultValues(TaskPlannerSearchBuilderPageObject page)
        {
            Assert.AreEqual(Operators.EqualTo, page.InstructorOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.OtherNameTypeOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.CaseStatusOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.RenewalStatusOperatorDropdown.Value);
            Assert.True(page.PendingCheckbox.IsChecked);
            Assert.True(page.RegisteredCheckbox.IsChecked);
            Assert.False(page.DeadCheckbox.IsChecked);
        }
        void AssertRememberFields(TaskPlannerSearchBuilderPageObject page, DateTime date)
        {
            Assert.AreEqual("Starts With", page.InstructorOperatorDropdown.Input.SelectedOption.Text.Trim());
            Assert.AreEqual("Contains", page.OwnerOperatorDropdown.Input.SelectedOption.Text.Trim());
            Assert.AreEqual("Ends With", page.OtherNameTypeOperatorDropdown.Input.SelectedOption.Text.Trim());
            Assert.AreEqual("Test Instructor 1", page.InstructorTextbox.Text.Trim());
            Assert.AreEqual("Test owner 1", page.OwnerTextbox.Text.Trim());
            Assert.AreEqual("other type 1", page.OtherNameTypesTextbox.Text.Trim());
            Assert.True(page.InstructorTextbox.Element.Displayed);
            Assert.True(page.OwnerTextbox.Element.Displayed);
            Assert.True(page.OtherNameTypesTextbox.Element.Displayed);
            Assert.False(page.PendingCheckbox.IsChecked);
            Assert.False(page.RegisteredCheckbox.IsChecked);
            Assert.True(page.DeadCheckbox.IsChecked);
        }

        void AssertEventsAndActionsDefaultValues(TaskPlannerSearchBuilderPageObject page)
        {
            Assert.AreEqual(Operators.EqualTo, page.EventOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.EventCategoryOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.EventGroupOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.EventTypeOperatorDropdown.Value);
            Assert.AreEqual(Operators.StartsWith, page.EventNotesOperatorDropdown.Value);
            Assert.AreEqual(Operators.EqualTo, page.ActionOperatorDropdown.Value);
            Assert.AreEqual(string.Empty, page.EventPicklist.GetText(), "Ensure Event Picklist is empty");
            Assert.AreEqual(string.Empty, page.EventCategoryPicklist.GetText(), "Ensure Event Category Picklist is empty");
            Assert.AreEqual(string.Empty, page.EventGroupPicklist.GetText(), "Ensure Event Group Picklist is empty");
            Assert.AreEqual(string.Empty, page.EventTypePicklist.GetText(), "Ensure Event Type Picklist is empty");
            Assert.AreEqual(string.Empty, page.ActionPicklist.GetText(), "Ensure Action Picklist is empty");
            Assert.AreEqual(string.Empty, page.EventNotesTextbox.Text, "Ensure Event Notes textbox is empty");
            Assert.True(page.RenewalsCheckbox.IsChecked);
            Assert.True(page.NonRenewalsCheckbox.IsChecked);
            Assert.False(page.ClosedCheckbox.IsChecked);
        }

        void AssertRemindersDefaultValues(TaskPlannerSearchBuilderPageObject page)
        {
            Assert.AreEqual(Operators.StartsWith, page.RemindersOperatorDropdown.Value);
            Assert.AreEqual(string.Empty, page.ReminderMessageTextbox.Text, "Ensure Reminder Message textbox is empty");
            Assert.True(page.OnHoldCheckbox.IsChecked);
            Assert.True(page.NotOnHoldCheckbox.IsChecked);
            Assert.True(page.ReadCheckbox.IsChecked);
            Assert.True(page.NotReadCheckbox.IsChecked);
        }
        
        void AssertAdhocDatesDefaultValues(TaskPlannerSearchBuilderPageObject page)
        {
            Assert.AreEqual(Operators.EqualTo, page.AdhocDateNamesOperatorDropdown.Value);
            Assert.AreEqual(string.Empty, page.AdhocDateNamesPicklist.GetText(), "Ensure adhoc dates names Picklist is empty");
            Assert.AreEqual(Operators.StartsWith, page.GeneralRefOperatorDropdown.Value);
            Assert.AreEqual(string.Empty, page.GeneralRefTextbox.Text, "Ensure General reference textbox is empty");
            Assert.AreEqual(Operators.StartsWith, page.AdhocDateMessageOperatorDropdown.Value);
            Assert.AreEqual(string.Empty, page.AdhocDateMessageTextbox.Text, "Ensure adhoc dates message textbox is empty");
            Assert.AreEqual(Operators.StartsWith, page.EmailSubjectOperatorDropdown.Value);
            Assert.AreEqual(string.Empty, page.EmailSubjectTextbox.Text, "Ensure email subject textbox is empty");
            
            Assert.True(page.AdhocDateIncludeCaseCheckbox.IsChecked);
            Assert.True(page.AdhocDateIncludeNameCheckbox.IsChecked);
            Assert.True(page.AdhocDateIncludeGeneralCheckbox.IsChecked);
        }
    }
}