using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerCreateAdHocDates : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CreateAdHocDateFromTaskMenuForCase(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
            SignIn(driver, "/#/task-planner", taskPlannerData.User.Username, taskPlannerData.User.Password);
            var resultPage = new TaskPlannerPageObject(driver);
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            resultPage.OpenTaskPlannerTab(1).ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);

            resultPage.OpenTaskMenuOption(0, "createAdhoc");
            driver.WaitForAngular();
            Assert.AreEqual(resultPage.CaseReferencePicklist.GetText(), taskPlannerData.Data[0].Case.Irn);
            Assert.IsFalse(resultPage.DueDateTextBox.IsDisabled());
            Assert.IsTrue(resultPage.EventPicklist.Enabled);
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
            resultPage.EventPicklist.EnterAndSelect("Clients filing deadline");
            Assert.IsTrue(resultPage.DueDateTextBox.IsDisabled());
            resultPage.AutomaticDeleteOnDate.GoToDate(4);
            resultPage.MessageTextArea.SendKeys("e2e reminder");
            resultPage.ImportanceLevelDropDownSelect.SelectByText("Critical");
            resultPage.SendReminderTextBox.Clear();
            resultPage.SendReminderTextBox.SendKeys("1");
            resultPage.SendReminderDropDownSelect.SelectByText("Months");
            Assert.IsTrue(resultPage.EndOnTextBox.IsDisabled());
            Assert.IsTrue(resultPage.RepeatEveryTextBox.IsDisabled());
            resultPage.RecurringCheckBox.Click();
            Assert.IsFalse(resultPage.EndOnTextBox.IsDisabled());
            Assert.IsFalse(resultPage.RepeatEveryTextBox.IsDisabled());
            Assert.AreEqual("1", resultPage.RepeatEveryTextBox.Value());
            Assert.IsTrue(resultPage.RepeatEveryMonthLabel.Displayed);
            resultPage.RepeatEveryTextBox.Clear();
            resultPage.RepeatEveryTextBox.SendKeys("2");
            resultPage.EndOnDate.GoToDate(3);
            resultPage.RepeatEveryTextBox.Click();
            resultPage.CriticalCheckBox.Click();
            resultPage.NameTypePicklist.EnterAndSelect("Agent");
            Assert.IsTrue(resultPage.RelationshipPicklist.Enabled);
            resultPage.RelationshipPicklist.EnterAndSelect("Employs");
            resultPage.AdditionalNamesPicklist.OpenPickList();
            resultPage.AdditionalNamesPicklist.ModalSearchButton().ClickWithTimeout();
            resultPage.AdditionalNamesGrid.Rows[1].Click();
            resultPage.AdditionalNamesGrid.Rows[2].Click();
            resultPage.AdditionalNamesGrid.Rows[3].Click();
            resultPage.ApplyButton.ClickWithTimeout();
            Assert.IsFalse(resultPage.EmailCheckBox.IsChecked);
            Assert.IsFalse(resultPage.EmailSubjectTextArea.Enabled);
            resultPage.EmailCheckBox.Click();
            Assert.IsTrue(resultPage.EmailSubjectTextArea.Enabled);
            resultPage.EmailSubjectTextArea.SendKeys("e2e reminder email");
            resultPage.ModalSaveButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.IsTrue(resultPage.SuccessMessage.Text.Contains("Your changes have been successfully saved."));
            Assert.AreEqual(3, resultPage.Grid.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CreateAdHocDateCase(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
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
            resultPage.AutomaticDeleteOnDate.GoToDate(4);
            resultPage.MessageTextArea.SendKeys("e2e reminder");
            resultPage.ImportanceLevelDropDownSelect.SelectByText("Critical");
            resultPage.SendReminderTextBox.Clear();
            resultPage.SendReminderTextBox.SendKeys("1");
            resultPage.SendReminderDropDownSelect.SelectByText("Months");
            Assert.IsTrue(resultPage.EndOnTextBox.IsDisabled());
            Assert.IsTrue(resultPage.RepeatEveryTextBox.IsDisabled());
            resultPage.RecurringCheckBox.Click();
            Assert.IsFalse(resultPage.EndOnTextBox.IsDisabled());
            Assert.IsFalse(resultPage.RepeatEveryTextBox.IsDisabled());
            Assert.AreEqual("1", resultPage.RepeatEveryTextBox.Value());
            Assert.IsTrue(resultPage.RepeatEveryMonthLabel.Displayed);
            resultPage.RepeatEveryTextBox.Clear();
            resultPage.RepeatEveryTextBox.SendKeys("2");
            resultPage.EndOnDate.GoToDate(3);
            resultPage.RepeatEveryTextBox.Click();
            resultPage.CriticalCheckBox.Click();
            resultPage.NameTypePicklist.EnterAndSelect("Agent");
            Assert.IsTrue(resultPage.RelationshipPicklist.Enabled);
            resultPage.RelationshipPicklist.EnterAndSelect("Employs");
            resultPage.AdditionalNamesPicklist.OpenPickList();
            resultPage.AdditionalNamesPicklist.ModalSearchButton().ClickWithTimeout();
            resultPage.AdditionalNamesGrid.Rows[1].Click();
            resultPage.AdditionalNamesGrid.Rows[2].Click();
            resultPage.AdditionalNamesGrid.Rows[3].Click();
            resultPage.ApplyButton.ClickWithTimeout();
            Assert.IsFalse(resultPage.EmailCheckBox.IsChecked);
            Assert.IsFalse(resultPage.EmailSubjectTextArea.Enabled);
            resultPage.EmailCheckBox.Click();
            Assert.IsTrue(resultPage.EmailSubjectTextArea.Enabled);
            resultPage.EmailSubjectTextArea.SendKeys("e2e reminder email");
            resultPage.ModalSaveButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.IsTrue(resultPage.SuccessMessage.Text.Contains("Your changes have been successfully saved."));
            Assert.AreEqual(9, resultPage.Grid.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CreateAdHocDateName(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
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
            resultPage.AutomaticDeleteOnDate.GoToDate(4);
            resultPage.MessageTextArea.SendKeys("e2e reminder");
            resultPage.ImportanceLevelDropDownSelect.SelectByText("Critical");
            resultPage.SendReminderTextBox.Clear();
            resultPage.SendReminderTextBox.SendKeys("1");
            resultPage.SendReminderDropDownSelect.SelectByText("Months");
            Assert.IsTrue(resultPage.EndOnTextBox.IsDisabled());
            Assert.IsTrue(resultPage.RepeatEveryTextBox.IsDisabled());
            resultPage.RecurringCheckBox.Click();
            Assert.IsFalse(resultPage.EndOnTextBox.IsDisabled());
            Assert.IsFalse(resultPage.RepeatEveryTextBox.IsDisabled());
            Assert.AreEqual("1", resultPage.RepeatEveryTextBox.Value());
            Assert.IsTrue(resultPage.RepeatEveryMonthLabel.Displayed);
            resultPage.RepeatEveryTextBox.Clear();
            resultPage.RepeatEveryTextBox.SendKeys("2");
            resultPage.EndOnDate.GoToDate(3);
            resultPage.RepeatEveryTextBox.Click();
            resultPage.AdditionalNamesPicklist.OpenPickList();
            resultPage.AdditionalNamesPicklist.ModalSearchButton().ClickWithTimeout();
            resultPage.AdditionalNamesGrid.Rows[1].Click();
            resultPage.AdditionalNamesGrid.Rows[2].Click();
            resultPage.AdditionalNamesGrid.Rows[3].Click();
            resultPage.ApplyButton.ClickWithTimeout();
            Assert.IsFalse(resultPage.EmailCheckBox.IsChecked);
            Assert.IsFalse(resultPage.EmailSubjectTextArea.Enabled);
            resultPage.EmailCheckBox.Click();
            Assert.IsTrue(resultPage.EmailSubjectTextArea.Enabled);
            resultPage.EmailSubjectTextArea.SendKeys("e2e reminder email");
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
        public void CreateAdHocDateGeneral(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var taskPlannerData = TaskPlannerService.SetupData();
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
            resultPage.AutomaticDeleteOnDate.GoToDate(4);
            resultPage.MessageTextArea.SendKeys("e2e reminder");
            resultPage.ImportanceLevelDropDownSelect.SelectByText("Critical");
            resultPage.SendReminderTextBox.Clear();
            resultPage.SendReminderTextBox.SendKeys("1");
            Assert.IsTrue(resultPage.EndOnTextBox.IsDisabled());
            Assert.IsTrue(resultPage.RepeatEveryTextBox.IsDisabled());
            resultPage.RecurringCheckBox.Click();
            Assert.IsFalse(resultPage.EndOnTextBox.IsDisabled());
            Assert.IsFalse(resultPage.RepeatEveryTextBox.IsDisabled());
            Assert.AreEqual("1", resultPage.RepeatEveryTextBox.Value());
            resultPage.RepeatEveryTextBox.Clear();
            resultPage.RepeatEveryTextBox.SendKeys("2");
            resultPage.EndOnDate.GoToDate(3);
            resultPage.RepeatEveryTextBox.Click();
            resultPage.AdditionalNamesPicklist.OpenPickList();
            resultPage.AdditionalNamesPicklist.ModalSearchButton().ClickWithTimeout();
            resultPage.AdditionalNamesGrid.Rows[1].Click();
            resultPage.AdditionalNamesGrid.Rows[2].Click();
            resultPage.AdditionalNamesGrid.Rows[3].Click();
            resultPage.ApplyButton.ClickWithTimeout();
            Assert.IsFalse(resultPage.EmailCheckBox.IsChecked);
            Assert.IsFalse(resultPage.EmailSubjectTextArea.Enabled);
            resultPage.EmailCheckBox.Click();
            Assert.IsTrue(resultPage.EmailSubjectTextArea.Enabled);
            resultPage.EmailSubjectTextArea.SendKeys("e2e reminder email");
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
        public void CreateAdHocDateCaseFromEventNotes(BrowserType browserType)
        {
            var today = DateTime.Now;
            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.AlphaNumericString(15);
                var property = setup.InsertWithNewId(new PropertyType
                {
                    Name = RandomString.Next(5)
                }, x => x.Code);
                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "TaskPlanner", true, propertyType: property);

                var mainRenewalActionSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.MainRenewalAction);
                var renewalAction = setup.DbContext.Set<InprotechKaizen.Model.Cases.Action>().Single(_ => _.Code == mainRenewalActionSiteControl.StringValue);
                var criticalDatesSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CriticalDates_Internal);
                var criticalDatesCriteria = setup.DbContext.Set<Criteria>().First(_ => _.ActionId == criticalDatesSiteControl.StringValue);

                setup.Insert(new OpenAction(renewalAction, @case1, 1, null, criticalDatesCriteria, true));
                setup.Insert(new CaseEvent(@case1.Id, (int)KnownEvents.NextRenewalDate, 1) { EventDueDate = DateTime.Today.AddDays(-1), IsOccurredFlag = 0, CreatedByCriteriaKey = criticalDatesCriteria.Id });
                setup.Insert(new EventNoteType("Event note type 1", false, sharingAllowed: false));
                setup.Insert(new TableCode(Int32.MaxValue, -508, "Predefined notes 1"));
                return new
                {
                    CasePrefix = casePrefix,
                    CaseIrn = case1.Irn
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner");
            var resultPage = new TaskPlannerPageObject(driver);
            var page1 = new TaskPlannerSearchBuilderPageObject(driver);
            resultPage.FilterButton.ClickWithTimeout();
            page1.IncludeDueDatesCheckbox.Click();
            resultPage.Cases.CaseReference.SendKeys(data.CaseIrn);
            resultPage.AllNamesInBelongingToDropDown.Click();
            resultPage.AdvancedSearchButton.ClickWithTimeout();
            resultPage.EventNotesExpandButton.Click();
            resultPage.AddNewEventNotesLink.Click();
            Assert.AreEqual("0", driver.FindElement(By.XPath("//span[text()='Event Notes']/following-sibling::span")).Text);
            driver.FindElement(By.XPath("//ipx-dropdown[@name='eventNoteType']//select/option[text()=' Event note type 1 ']")).Click();
            driver.FindElement(By.XPath("//input[@placeholder='Select Predefined Notes']")).SendKeys("Predefined notes 1");
            resultPage.EventNotesTextArea.Click();
            resultPage.CreateAdHocCheckBox.Click();
            resultPage.EventNotesSaveButton.ClickWithTimeout();
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
            Assert.AreEqual(data.CaseIrn, resultPage.CaseReferencePicklist.GetText());
            Assert.AreEqual(resultPage.DueDate.Value, today.ToString("dd-MMM-yyyy"));
            StringAssert.Contains("Predefined notes 1", resultPage.MessageTextArea.Value(), "Ensure Message");
            resultPage.AutomaticDeleteOnDate.GoToDate(4);
            resultPage.ImportanceLevelDropDownSelect.SelectByText("Critical");
            resultPage.SendReminderTextBox.Clear();
            resultPage.SendReminderTextBox.SendKeys("1");
            resultPage.SendReminderDropDownSelect.SelectByText("Months");
            Assert.IsTrue(resultPage.EndOnTextBox.IsDisabled());
            Assert.IsTrue(resultPage.RepeatEveryTextBox.IsDisabled());
            resultPage.RecurringCheckBox.Click();
            Assert.IsFalse(resultPage.EndOnTextBox.IsDisabled());
            Assert.IsFalse(resultPage.RepeatEveryTextBox.IsDisabled());
            Assert.AreEqual("1", resultPage.RepeatEveryTextBox.Value());
            Assert.IsTrue(resultPage.RepeatEveryMonthLabel.Displayed);
            resultPage.RepeatEveryTextBox.Clear();
            resultPage.RepeatEveryTextBox.SendKeys("2");
            resultPage.EndOnDate.GoToDate(3);
            resultPage.RepeatEveryTextBox.Click();
            resultPage.CriticalCheckBox.Click();
            resultPage.AdditionalNamesPicklist.OpenPickList();
            resultPage.AdditionalNamesPicklist.ModalSearchButton().ClickWithTimeout();
            resultPage.AdditionalNamesGrid.Rows[1].Click();
            resultPage.AdditionalNamesGrid.Rows[2].Click();
            resultPage.AdditionalNamesGrid.Rows[3].Click();
            resultPage.ApplyButton.ClickWithTimeout();
            Assert.IsFalse(resultPage.EmailCheckBox.IsChecked);
            Assert.IsFalse(resultPage.EmailSubjectTextArea.Enabled);
            resultPage.EmailCheckBox.Click();
            Assert.IsTrue(resultPage.EmailSubjectTextArea.Enabled);
            resultPage.EmailSubjectTextArea.SendKeys("e2e reminder email");
            resultPage.ModalSaveButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.IsTrue(resultPage.SuccessMessage.Text.Contains("Your changes have been successfully saved."));
            Assert.AreEqual(5, resultPage.Grid.Rows.Count);
        }
    }
}
