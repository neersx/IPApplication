using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using NUnit.Framework;
using OpenQA.Selenium.Interactions;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.SavedSearch.Case
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseSavedSearchEventsActionsAndDueDates : CaseSavedSearchTest
    {
        [TestCase(BrowserType.Chrome)]
        //[TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LoadEventsAndActionTopic(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            var menu1 = (NgWebElement)menuObjects.GetMenuItemAnchor(data.eventActionsTopic.Name);
            Assert.IsTrue(menu1.Displayed);

            var builder = new Actions (driver);
            builder.MoveToElement(menu1).Build().Perform();

            NgWebElement editIcon = menuObjects.GetEditIcon(data.eventActionsTopic.Name);
            Assert.IsTrue(editIcon.Displayed);
            editIcon.WithJs().Click();

            Assert.AreEqual("/case/search?queryKey=" + data.eventActionsTopic.Id, driver.Location, "Should navigate to case search page");
            driver.WaitForAngularWithTimeout();

            var topicRef = new ReferencesTopic(driver);
            topicRef.CaseReference.Click();

            var topic = new EventAndActionsTopic(driver);
            topic.NavigateTo();
           
            Assert.NotNull(topic);
            var events = topic.Event.Tags.ToArray();
            Assert.AreEqual(2, events.Length);
            Assert.AreEqual("Acceptance 18 month deadline", events[0]);
            Assert.True(topic.OccurredEvent.Selected);
            Assert.True(topic.DueEvent.Selected);
            Assert.True(topic.IncludeClosedActions.Selected);
            Assert.AreEqual(Operators.NotEqualTo, topic.ActionOperator.Value);
            Assert.NotNull(topic.ActionValue);
            Assert.AreEqual("Filing", topic.ActionValue.GetText());
            Assert.True(topic.ActionIsOpen.Selected);
            Assert.True(topic.IsRenewals.Selected);
            Assert.True(topic.IsNonRenewals.Selected);
            Assert.AreEqual(Operators.Contains, topic.EventNotesOperator.Value);
            Assert.AreEqual("xyz", topic.EventNotesText.Value());
            Assert.AreEqual(string.Empty,topic.EventNoteType.GetText());
            Assert.AreEqual(string.Empty,topic.EventNoteTypeOperator.Value);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LoadDueDateModal(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            var menu1 = (NgWebElement)menuObjects.GetMenuItemAnchor(data.dueDateModal.Name);
            Assert.IsTrue(menu1.Displayed);

            var builder = new Actions(driver);
            builder.MoveToElement(menu1).Build().Perform();

            NgWebElement editIcon = menuObjects.GetEditIcon(data.dueDateModal.Name);
            editIcon.WithJs().Click();

            Assert.AreEqual("/case/search?queryKey=" + data.dueDateModal.Id, driver.Location, "Should navigate to case search page");
            driver.WaitForAngularWithTimeout();

            var dueDate = new DueDate(driver);
            dueDate.DueDateButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(dueDate.EventCheckbox.IsChecked, true);
            Assert.AreEqual(dueDate.AdHocsCheckbox.IsChecked, true);
            Assert.AreEqual(dueDate.RangeRadioButton.IsChecked, true);
            Assert.AreEqual(dueDate.PeriodRadioButton.IsChecked, false);
            Assert.AreEqual(dueDate.SearchByDueDateCheckbox.IsChecked, true);
            Assert.AreEqual(dueDate.SearchByReminderDateCheckbox.IsChecked, true);

            Assert.AreEqual(dueDate.RenewalsCheckbox.IsChecked, true);
            Assert.AreEqual(dueDate.NonRenewalsCheckbox.IsChecked, true);
            Assert.AreEqual(dueDate.ClosedActionsCheckbox.IsChecked, true);
            Assert.AreEqual(dueDate.StaffCheckbox.IsChecked, true);
            Assert.AreEqual(dueDate.SignatoryCheckbox.IsChecked, true);
            Assert.AreEqual(dueDate.AnyNameCheckbox.IsChecked, true);

            Assert.AreEqual(dueDate.RangeStartDate.Input.Value(), "01-Oct-2019");
            Assert.AreEqual(dueDate.RangeEndDate.Input.Value(), "31-Oct-2019");
            var nameType = dueDate.DueDateNameType.Tags.ToArray();
            Assert.AreEqual("Signatory", nameType[0]);
            Assert.AreEqual(Operators.NotEqualTo, dueDate.DueDateNameTypeOperator.Value);
        }
    }
}