using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.EventGroup
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Scenario)]
    public class MaintainableEventGroupPicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddNewEventGroup(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(Fixture.String(10));
            eventsPicklist.AddPickListItem();

            var eventGroupPl = new PickList(driver).ByName("ip-picklist-modal-maintenance", "eventGroup");
            eventGroupPl.OpenPickList();
            eventGroupPl.AddPickListItem();

            var maintenance = new EventGroupPickListModal(driver);
            
            var newDescription = Fixture.String(20);
            var userCode = Fixture.String(5);
            
            maintenance.Description.SendKeys(newDescription);
            maintenance.UserCode.SendKeys(userCode);
            maintenance.Save();
            
            Assert.AreEqual(newDescription, eventGroupPl.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual(userCode, eventGroupPl.SearchGrid.CellText(0, 1), "Ensure the text is updated");
            Assert.IsTrue(eventGroupPl.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");
            
            eventGroupPl.SearchFor(newDescription);
            
            Assert.AreEqual(1, eventGroupPl.SearchGrid.Rows.Count);
            Assert.AreEqual(newDescription, eventGroupPl.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual(userCode, eventGroupPl.SearchGrid.CellText(0, 1), "Ensure the text is updated");
            
            //https://github.com/mozilla/geckodriver/issues/1151
            maintenance.Discard(); // discard event group picklist.
            maintenance.Discard(); // discard add event picklist
            maintenance.Discard(); // discard confirm.
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditEventGroup(BrowserType browserType)
        {
            EventGroupDbSetup.ScenarioData data;
            using (var setup = new EventGroupDbSetup())
            {
                data = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(Fixture.String(10));
            eventsPicklist.AddPickListItem();

            var eventGroupPl = new PickList(driver).ByName("ip-picklist-modal-maintenance", "eventGroup");
            eventGroupPl.OpenPickList(data.ExistingEventGroup);
            eventGroupPl.EditRow(0);

            var maintenance = new EventGroupPickListModal(driver);

            var updatedDescription = Fixture.String(20);
            var updatedUserCode = Fixture.String(5);

            maintenance.Description.Clear();
            maintenance.Description.SendKeys(updatedDescription);
            maintenance.UserCode.Clear();
            maintenance.UserCode.SendKeys(updatedUserCode);
            maintenance.Save();
            maintenance.Discard();

            Assert.AreEqual(updatedDescription, eventGroupPl.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual(updatedUserCode, eventGroupPl.SearchGrid.CellText(0, 1), "Ensure the text is updated");
            Assert.IsTrue(eventGroupPl.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            eventGroupPl.SearchFor(updatedDescription);

            Assert.AreEqual(1, eventGroupPl.SearchGrid.Rows.Count);
            Assert.AreEqual(updatedDescription, eventGroupPl.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual(updatedUserCode, eventGroupPl.SearchGrid.CellText(0, 1), "Ensure the text is updated");

            //https://github.com/mozilla/geckodriver/issues/1151
            maintenance.Discard(); // discard event group picklist.
            maintenance.Discard(); // discard add event picklist
            maintenance.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteEventGroup(BrowserType browserType)
        {
            EventGroupDbSetup.ScenarioData data;
            using (var setup = new EventGroupDbSetup())
            {
                data = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(Fixture.String(10));
            eventsPicklist.AddPickListItem();

            var eventGroupPl = new PickList(driver).ByName("ip-picklist-modal-maintenance", "eventGroup");
            eventGroupPl.OpenPickList(data.ExistingEventGroup);
            Assert.AreEqual(1, eventGroupPl.SearchGrid.Rows.Count);

            eventGroupPl.DeleteRow(0);
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().Click();

            Assert.AreEqual(0, eventGroupPl.SearchGrid.Rows.Count);

            //https://github.com/mozilla/geckodriver/issues/1151
            var maintenance = new EventGroupPickListModal(driver);
            
            maintenance.Discard(); // discard event group picklist.
            maintenance.Discard(); // discard add event picklist
            maintenance.Discard(); // discard confirm.
        }
    }
}