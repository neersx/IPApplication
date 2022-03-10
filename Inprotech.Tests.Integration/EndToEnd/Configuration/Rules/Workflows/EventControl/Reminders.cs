using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class RemindersTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainReminderRules(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                var nameBuilder = new NameBuilder(setup.DbContext);
                var nameTypeBuilder = new NameTypeBuilder(setup.DbContext);
                var nameRelationBuilder = new NameRelationBuilder(setup.DbContext);

                var evet = eventBuilder.Create("event");
                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, evet, "Apple")
                {
                    NumberOfCyclesAllowed = 2,
                    Inherited = 1,
                    Importance = importance
                };
                setup.Insert(validEvent);

                var name = nameBuilder.CreateStaff("e2e", "e2e_Reminder");
                var nameType1 = nameTypeBuilder.Create();
                var nameType2 = nameTypeBuilder.Create();
                var relation = nameRelationBuilder.Create();

                return new
                {
                    Event = evet.Description,
                    EventId = evet.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    name.NameCode,
                    name.LastName,
                    NameType1 = nameType1.Name,
                    NameType2 = nameType2.Name,
                    Relationship = relation.RelationDescription
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.Reminders.NavigateTo();

            // add
            eventControlPage.Reminders.Add();
            var modal = new RemindersModal(driver);

            modal.StandardMessage.Text = "Don't forget to buy a can of beans after work.";
            modal.AlternateMessage.Text = "Where are my beans?";
            modal.UseOnAndAfterDueDate.Click();

            Assert.IsTrue(modal.EmailSubject.Input.IsDisabled());
            modal.AlsoSendEmail.Click();
            modal.EmailSubject.Text = "Bean Reminder";

            modal.StartSending.Text = "1";
            modal.StartSending.SelectElement.SelectByText("Days");
            
            Assert.IsTrue(modal.RepeatEvery.TextInput.IsDisabled());
            Assert.IsTrue(modal.StopAfter.TextInput.IsDisabled());

            modal.Recurring.Click();
            modal.RepeatEvery.Text = "2";
            modal.RepeatEvery.SelectElement.SelectByText("Weeks");
            modal.StopAfter.Text = "3";
            modal.StopAfter.SelectElement.SelectByText("Years");
            
            Assert.IsTrue(modal.StaffCheckbox.IsChecked);
            Assert.IsTrue(modal.SignatoryCheckbox.IsChecked);
            modal.CriticalListCheckbox.Click();
            modal.Name.EnterAndSelect(data.NameCode);
            modal.NameType.EnterAndSelect(data.NameType1);
            driver.Wait().ForTrue(modal.NameType.Tags.Any, 1000);
            
            modal.Relationship.EnterAndSelect(data.Relationship);

            modal.Apply();

            eventControlPage.Save();
            
            var reminders = eventControlPage.Reminders;
            reminders.NavigateTo();

            Assert.AreEqual(1, reminders.GridRowsCount);
            Assert.AreEqual("Don't forget to buy a can of beans after work.", reminders.StandardMessage);
            Assert.IsTrue(reminders.SendAsEmail);
            Assert.AreEqual("1 Days", reminders.StartBefore);
            Assert.AreEqual("2 Weeks", reminders.RepeatEvery);
            Assert.AreEqual("3 Years", reminders.StopAfter);

            // edit
            eventControlPage.Reminders.Grid.ClickEdit(0);
            modal = new RemindersModal(driver);
            Assert.AreEqual("Don't forget to buy a can of beans after work.", modal.StandardMessage.Text);
            Assert.AreEqual("Where are my beans?", modal.AlternateMessage.Text);
            Assert.IsTrue(modal.UseOnAndAfterDueDate.IsChecked);
            Assert.IsTrue(modal.AlsoSendEmail.IsChecked);
            Assert.AreEqual("Bean Reminder", modal.EmailSubject.Text);
            Assert.AreEqual("1", modal.StartSending.Text);
            Assert.AreEqual("Days", modal.StartSending.SelectElement.SelectedOption.Text);
            Assert.IsTrue(modal.Recurring.IsChecked);
            Assert.AreEqual("2", modal.RepeatEvery.Text);
            Assert.AreEqual("Weeks", modal.RepeatEvery.SelectElement.SelectedOption.Text);

            Assert.AreEqual("3", modal.StopAfter.Text);
            Assert.AreEqual("Years", modal.StopAfter.SelectElement.SelectedOption.Text);

            Assert.IsTrue(modal.StaffCheckbox.IsChecked);
            Assert.IsTrue(modal.SignatoryCheckbox.IsChecked);
            Assert.IsTrue(modal.CriticalListCheckbox.IsChecked);

            Assert.IsTrue(modal.Name.GetText().Contains(data.LastName));
            Assert.IsTrue(modal.NameType.Tags.Any(_ => _.Equals(data.NameType1, StringComparison.InvariantCulture)));

            modal.NameType.EnterAndSelect(data.NameType2);
            driver.Wait().ForTrue(() => modal.NameType.Tags.Count()==2, 1000);

            Assert.AreEqual(data.Relationship, modal.Relationship.GetText());

            modal.StandardMessage.Text = "Do you have any more of those onions?";
            modal.AlternateMessage.Text = "Onions.";

            modal.AlsoSendEmail.Click();
            Assert.IsTrue(modal.EmailSubject.Input.IsDisabled());

            modal.StartSending.Text = "2";
            modal.StartSending.SelectElement.SelectByText("Weeks");

            modal.Recurring.Click();
            Assert.IsTrue(modal.RepeatEvery.TextInput.IsDisabled());
            Assert.IsTrue(modal.StopAfter.TextInput.IsDisabled());
            modal.Recurring.Click();
            modal.RepeatEvery.Text = "3";
            modal.RepeatEvery.SelectElement.SelectByText("Months");
            modal.StopAfter.Text = "6";
            modal.StopAfter.SelectElement.SelectByText("Months");

            modal.Apply();
            eventControlPage.Save();

            reminders.NavigateTo();
            Assert.AreEqual(1, reminders.GridRowsCount);
            Assert.AreEqual("Do you have any more of those onions?", reminders.StandardMessage);
            Assert.IsFalse(reminders.SendAsEmail);
            Assert.AreEqual("2 Weeks", reminders.StartBefore);
            Assert.AreEqual("3 Months", reminders.RepeatEvery);
            Assert.AreEqual("6 Months", reminders.StopAfter);
            
            eventControlPage.Reminders.Grid.ClickEdit(0);
            modal = new RemindersModal(driver);
            Assert.IsTrue( modal.NameType.Tags.Count()==2);
            modal.Close();
            
            // delete
            reminders.Grid.ToggleDelete(0);
            eventControlPage.Save();
            reminders.NavigateTo();
            Assert.AreEqual(0, reminders.GridRowsCount);
        }
    }
}
