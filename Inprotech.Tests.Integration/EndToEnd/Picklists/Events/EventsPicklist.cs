using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl;
using Inprotech.Tests.Integration.EndToEnd.Picklists.EventGroup;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Events
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EventsPicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainEventDetailsFromPicklist(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();

            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(scenario.Event.Id.ToString());

            var importanceFilter = new MultiSelectGridFilter(driver, "picklistResults-events", "importance");
            importanceFilter.Open();
            Assert.AreEqual(1, importanceFilter.ItemCount,
                            "Ensure that correct number of importances filters are retrieved");

            importanceFilter.SelectAll();
            importanceFilter.FilterButton().ClickWithTimeout();
            var searchResults = new KendoGrid(driver, "picklistResults-events");
            Assert.AreEqual(1, searchResults.Rows.Count,
                            "Ensure that importance filter is correctly filtering");

            eventsPicklist.ColumnMenuButton().Click();
            if (!searchResults.HeaderColumn("eventCategory").Displayed)
            {
                eventsPicklist.ToggleGridColumn("eventCategory");
            }
            if (!searchResults.HeaderColumn("eventGroup").Displayed)
            {
                eventsPicklist.ToggleGridColumn("eventGroup");
            }
            if (!searchResults.HeaderColumn("eventNotesGroup").Displayed)
            {
                eventsPicklist.ToggleGridColumn("eventNotesGroup");
            }

            Assert.AreEqual("E2E Event Category", searchResults.CellText(0, 6),
                            "Ensure Event Category is returned");
            Assert.AreEqual("E2E Event Group", searchResults.CellText(0, 7),
                            "Ensure Event Group is returned");
            Assert.AreEqual("E2E Notes Group", searchResults.CellText(0, 8),
                            "Ensure Event Notes Group is returned");

            eventsPicklist.ColumnMenuButton().Click();
            if (searchResults.HeaderColumn("eventCategory").Displayed)
            {
                eventsPicklist.ToggleGridColumn("eventCategory");
            }
            if (searchResults.HeaderColumn("eventGroup").Displayed)
            {
                eventsPicklist.ToggleGridColumn("eventGroup");
            }
            if (searchResults.HeaderColumn("eventNotesGroup").Displayed)
            {
                eventsPicklist.ToggleGridColumn("eventNotesGroup");
            }

            eventsPicklist.EditRow(0);
            driver.WaitForAngularWithTimeout();

            var maintenance = new EventPicklistModal(driver);

            var newCode = Fixture.String(10);
            const string newNotes = "E2E Updated Event Notes";

            maintenance.EventNotes.Clear();
            maintenance.EventNotes.SendKeys(newNotes);
            maintenance.EventCode.Clear();
            maintenance.EventCode.SendKeys(newCode);
            maintenance.InternalImportance.SelectByText(scenario.InternalImportance.Description);
            maintenance.ClientImportance.SelectByText(scenario.ClientImportance.Description);

            Assert.AreEqual(scenario.Event.Id.ToString(), maintenance.EventNumber.Text,
                            "Ensure correct event is retrieved");

            maintenance.Save();
            maintenance.Discard();

            eventsPicklist.EditRow(0);
            driver.WaitForAngularWithTimeout();

            var updatedEventNotes = driver.FindElement(By.Name("notes")).FindElement(By.TagName("textarea")).Value();
            var updatedEventCode = driver.FindElement(By.Name("code")).FindElement(By.TagName("input")).Value();

            Assert.AreEqual(newNotes, updatedEventNotes,
                            "Ensure Event Notes are correctly saved and retrieved");
            Assert.AreEqual(newCode, updatedEventCode,
                            "Ensure Event Code is correctly saved and retrieved");
            Assert.AreEqual(scenario.InternalImportance.Description, maintenance.InternalImportance.SelectedOption.Text,
                            "Ensure internal importance level is correctly saved");
            Assert.AreEqual(scenario.ClientImportance.Description, maintenance.ClientImportance.SelectedOption.Text,
                            "Ensure client importance level is correctly saved");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void NavigateEventInEditableMode(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
                                  {
                                      var eventBuilder = new EventBuilder(setup.DbContext);
                                      var event1 = eventBuilder.Create("event");
                                      var event2 = eventBuilder.Create("event1");
                                      var event3 = eventBuilder.Create("event2");

                                      return new
                                      {
                                          Event1 = event1.Description,
                                          Event2 = event2.Description,
                                          Event3 = event3.Description
                                      };
                                  });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();

            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(data.Event1);

            eventsPicklist.EditRow(0);

            var modal = new EventPicklistModal(driver);

            Assert.AreEqual(data.Event1, modal.EventDescription.Value());

            Assert.IsTrue(driver.FindElement(By.CssSelector(".modal-nav")).Displayed, "Navigation buttons are available after opening a modal");

            var internalImportance = new SelectElement(driver.FindElement(By.Name("internalImportance")));
            var clientImportance = new SelectElement(driver.FindElement(By.Name("clientImportance")));
            internalImportance.SelectByIndex(1);
            clientImportance.SelectByIndex(1);

            modal.Save();

            Assert.IsTrue(driver.FindElement(By.CssSelector(".modal-nav")).Displayed, "Navigation buttons are available after saving");

            eventsPicklist.NavigateToNext();
            Assert.AreEqual(data.Event2, modal.EventDescription.Value());

            eventsPicklist.NavigateToLast();
            Assert.AreEqual(data.Event3, modal.EventDescription.Value());

            eventsPicklist.NavigateToFirst();
            Assert.AreEqual(data.Event1, modal.EventDescription.Value());

            eventsPicklist.NavigateToNext();
            Assert.AreEqual(data.Event2, modal.EventDescription.Value());

            eventsPicklist.NavigateToNext();
            Assert.AreEqual(data.Event3, modal.EventDescription.Value());

            eventsPicklist.NavigateToFirst();
            Assert.AreEqual(data.Event1, modal.EventDescription.Value());

            eventsPicklist.NavigateToLast();
            Assert.AreEqual(data.Event3, modal.EventDescription.Value());
            modal.Discard();
            Assert.IsTrue(eventsPicklist.SearchGrid.RowIsHighlighted(2), "recently viewed row should be highlighted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainEventNotesAndEventGroups(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();

            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");

            eventsPicklist.OpenPickList();
            eventsPicklist.AddPickListItem();
            driver.WaitForAngularWithTimeout();

            var eventGroup = new PickList(driver).ByName("ip-picklist-modal-maintenance", "eventGroup");

            eventGroup.OpenPickList();
            eventGroup.SearchFor(scenario.ExistingGroup);
            eventGroup.EditRow(0);

            var maintenance = new EventGroupPickListModal(driver);

            maintenance.Description.Clear();
            maintenance.Description.SendKeys("Updated E2E Event Group Description");
            maintenance.UserCode.SendKeys("Updated E2E Event Group Code");
            maintenance.Save();
            maintenance.Discard();

            eventGroup.SearchFor("Updated E2E Event Group Description");
            var eventGroupResult = new KendoGrid(driver, "picklistResults-tablecodes");
            Assert.AreEqual("Updated E2E Event Group Code", eventGroupResult.CellText(0, 1),
                            "Ensure that the event group code has updated correctly");
            Assert.AreEqual("Updated E2E Event Group Description", eventGroupResult.CellText(0, 0),
                            "Ensure that the event group description has updated correctly");

            maintenance = new EventGroupPickListModal(driver);
            maintenance.Discard();

            driver.Wait();

            var eventNoteGroup = new PickList(driver).ByName("ip-picklist-modal-maintenance", "notesGroup");
            eventNoteGroup.OpenPickList();
            eventNoteGroup.SearchFor(scenario.ExistingNotesGroup);
            eventNoteGroup.EditRow(0);

            maintenance = new EventGroupPickListModal(driver);

            maintenance.Description.Clear();
            maintenance.Description.SendKeys("Updated E2E Event Group Note Description");
            maintenance.UserCode.SendKeys("Updated E2E Event Group Note Code");
            maintenance.Save();
            maintenance.Discard();

            eventGroup.SearchFor("Updated E2E Event Group Note Description");
            var eventGroupNoteResult = new KendoGrid(driver, "picklistResults-tablecodes");
            Assert.AreEqual("Updated E2E Event Group Note Code", eventGroupNoteResult.CellText(0, 1),
                            "Ensure that the event group note code has updated correctly");
            Assert.AreEqual("Updated E2E Event Group Note Description", eventGroupNoteResult.CellText(0, 0),
                            "Ensure that the event group note description has updated correctly");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void OnlyUsersWithUpdatePermissionCanUpdate(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows", scenario.UpdateLogin.Username, scenario.UpdateLogin.Password);
            driver.FindRadio("search-by-event").Click();
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList();
            eventsPicklist.AddPickListItem();
            var eventGroup = new PickList(driver).ByName("ip-picklist-modal-maintenance", "eventGroup");
            eventGroup.OpenPickList();
            var editButtonShown = eventGroup.IsRowButtonAvailable(0, "pencil-square-o");
            var viewButtonShown = eventGroup.IsRowButtonAvailable(0, "info-circle");
            var deleteButtonShown = eventGroup.IsRowButtonAvailable(0, "trash");

            Assert.True(editButtonShown);
            Assert.False(viewButtonShown);
            Assert.False(deleteButtonShown);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchEventPicklist(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();

            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList();

            var searchResults = new KendoGrid(driver, "picklistResults-events");

            Assert.AreEqual(scenario.FirstEvent.Description, searchResults.CellText(0, 2),
                            "Ensure Events ordered correctly");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class EventsPicklistAddUpdate : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateEventControlFromBaseEvent(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup(true);
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();

            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(scenario.BaseEvent.Id.ToString());
            eventsPicklist.EditRow(0);

            var maintenance = new EventPicklistModal(driver);

            var originalDescription = scenario.BaseEvent.Description;
            var newDescription = Fixture.String(20);
            var originalImportance = maintenance.InternalImportance.Options.IndexOf(maintenance.InternalImportance.SelectedOption);
            var newInternalImportance = originalImportance + 1;

            maintenance.EventDescription.Clear();
            maintenance.EventDescription.SendKeys(newDescription);
            maintenance.UnlimitedCycles.Click();
            maintenance.InternalImportance.SelectByIndex(newInternalImportance + 1);
            maintenance.RecalcEventDate.Click();
            maintenance.SuppressDueDateCalc.Click();

            maintenance.Save();

            var confirmationModal = new ConfirmPropagateChangesModal(driver);
            Assert.IsTrue(confirmationModal != null, "Confirmation dialog is displayed");
            Assert.AreEqual(5, confirmationModal.UpdatedFields.FindElements(By.TagName("li")).Count, "Display complete list of updated fields");
            Assert.IsFalse(confirmationModal.ActionOption.IsChecked, "Propagate Changes option is unchecked by default");

            confirmationModal.ProceedButton.Click();
            maintenance.Discard();

            var updatedEventControl = ApiClient.Get<WorkflowEventControlModel>("configuration/rules/workflows/" + scenario.UpdatableEventControl.CriteriaId + "/eventcontrol/" + scenario.BaseEvent.Id);
            Assert.AreEqual(originalDescription, updatedEventControl.Overview.Data.Description, "Event Control has not been updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddAndDuplicateEventsFromPicklist(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();

            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");

            eventsPicklist.OpenPickList("New E2E Event Description");
            eventsPicklist.AddPickListItem();
            driver.WaitForAngularWithTimeout();

            var sharedByCurrentCycle = driver.FindElement(By.Name("sharedByCurrentCycle")).FindElement(By.TagName("input"));
            Assert.AreEqual(true, sharedByCurrentCycle.GetAttribute("checked").Equals("true"),
                            "Select \"Shared by current cycle only\" by default");

            var description = driver.FindElement(By.Name("description")).FindElement(By.TagName("input"));
            Assert.AreEqual("New E2E Event Description", description.Value(), "Ensure Event Description is automatically populated from picklist search");
            driver.FindElement(By.Name("description")).FindElement(By.TagName("input")).SendKeys(" Amended After Add");

            var modal = new EventPicklistModal(driver);
            modal.Save();
            driver.WaitForAngularWithTimeout();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("description")), "Ensure maintenance view is closed on succesful Add");
            Assert.IsTrue(eventsPicklist.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            eventsPicklist.SearchFor("New E2E Event Description Amended After Add");
            eventsPicklist.EditRow(0);
            driver.WaitForAngularWithTimeout();

            var newEventDescription = driver.FindElement(By.Name("description")).FindElement(By.TagName("input")).Value();
            Assert.AreEqual("New E2E Event Description Amended After Add", newEventDescription,
                            "Ensure Event is added");

            eventsPicklist.Close();
            eventsPicklist.Close();

            eventsPicklist.OpenPickList(scenario.Event.Id.ToString());
            eventsPicklist.DuplicateRow(0);
            driver.WaitForAngularWithTimeout();

            var eventNotes = driver.FindElement(By.Name("notes")).FindElement(By.TagName("textarea"));
            var eventCode = driver.FindElement(By.Name("code")).FindElement(By.TagName("input"));
            var internalImportance = new SelectElement(driver.FindElement(By.Name("internalImportance")));
            var clientImportance = new SelectElement(driver.FindElement(By.Name("clientImportance")));
            description = driver.FindElement(By.Name("description")).FindElement(By.TagName("input"));
            var recalcEventDate = driver.FindElement(By.Name("recalcEventDate")).FindElement(By.TagName("input"));
            var isAccountingEvent = driver.FindElement(By.Name("isAccountingEvent")).FindElement(By.TagName("input"));
            var allowPoliceImmediate = driver.FindElement(By.Name("allowPoliceImmediate")).FindElement(By.TagName("input"));
            var suppressCalculation = driver.FindElement(By.Name("suppressCalculation")).FindElement(By.TagName("input"));
            var eventGroup = new PickList(driver).ByName("ip-picklist-modal-maintenance", "eventGroup");
            var eventNoteGroup = new PickList(driver).ByName("ip-picklist-modal-maintenance", "notesGroup");
            var eventCategory = new PickList(driver).ByName("ip-picklist-modal-maintenance", "category");
            var controllingAction = new PickList(driver).ByName("ip-picklist-modal-maintenance", "controllingAction");
            sharedByCurrentCycle = driver.FindElement(By.Name("sharedByCurrentCycle")).FindElement(By.TagName("input"));
            var copiedDescription = scenario.Description += " - Copy";
            var newCode = Fixture.String(10);
            const string newNotes = "E2E Updated Event Notes";

            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("eventNumber")),
                                                  "Ensure Event Number is not displayed.");
            Assert.AreEqual(copiedDescription, description.Value(),
                            "Ensure description has Copy appended to the existing event description");
            Assert.AreEqual(scenario.Code, eventCode.Value(),
                            "Ensure code is equal to the existing event being copied");
            Assert.AreEqual(scenario.ExistingInternalImportance.Description, internalImportance.SelectedOption.Text,
                            "Ensure internal importance level is equal to the existing event being copied");
            Assert.AreEqual(scenario.ExistingClientImportance.Description, clientImportance.SelectedOption.Text,
                            "Ensure client importance level is equal to the existing event being copied");
            Assert.AreEqual(scenario.Notes, eventNotes.Value(), "Ensure notes is equal to the existing event being copied");
            Assert.AreEqual(true, recalcEventDate.GetAttribute("checked").Equals("true"));
            Assert.AreEqual(true, isAccountingEvent.GetAttribute("checked").Equals("true"));
            Assert.AreEqual(true, allowPoliceImmediate.GetAttribute("checked").Equals("true"));
            Assert.AreEqual(true, suppressCalculation.GetAttribute("checked").Equals("true"));
            Assert.AreEqual(scenario.ExistingGroup, eventGroup.InputValue,
                            "Ensure event group is equal to the existing event being copied");
            Assert.AreEqual(scenario.ExistingNotesGroup, eventNoteGroup.InputValue,
                            "Ensure notes sharing group is equal to the existing event being copied");
            Assert.AreEqual(scenario.ExistingCategory, eventCategory.InputValue,
                            "Ensure event category is equal to the existing event being copied");
            Assert.AreEqual(scenario.ExistingAction, controllingAction.InputValue,
                            "Ensure controlling action is equal to the existing event being copied");
            Assert.AreEqual(true, sharedByCurrentCycle.GetAttribute("checked").Equals("true"),
                            "Ensure \"Shared by current cycle only\" is equal to the existing event being copied");

            eventNotes.Clear();
            eventNotes.SendKeys(newNotes);
            eventCode.Clear();
            eventCode.SendKeys(newCode);
            internalImportance.SelectByText(scenario.InternalImportance.Description);
            clientImportance.SelectByText(scenario.ClientImportance.Description);

            modal = new EventPicklistModal(driver);
            modal.Save();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("description")), "Ensure maintenance view is closed on succesful Duplicate");
            Assert.IsTrue(eventsPicklist.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            eventsPicklist.SearchFor(newCode);
            driver.WaitForAngularWithTimeout();
            eventsPicklist.EditRow(0);
            driver.WaitForAngularWithTimeout();

            var updatedEventNotes = driver.FindElement(By.Name("notes")).FindElement(By.TagName("textarea")).Value();
            var updatedEventCode = driver.FindElement(By.Name("code")).FindElement(By.TagName("input")).Value();
            internalImportance = new SelectElement(driver.FindElement(By.Name("internalImportance")));
            clientImportance = new SelectElement(driver.FindElement(By.Name("clientImportance")));
            description = driver.FindElement(By.Name("description")).FindElement(By.TagName("input"));

            Assert.AreEqual(newNotes, updatedEventNotes,
                            "Ensure Event Notes are correctly saved and retrieved");
            Assert.AreEqual(newCode, updatedEventCode,
                            "Ensure Event Code is correctly saved and retrieved");
            Assert.AreEqual(scenario.InternalImportance.Description, internalImportance.SelectedOption.Text,
                            "Ensure internal importance level is equal to the existing event being copied");
            Assert.AreEqual(scenario.ClientImportance.Description, clientImportance.SelectedOption.Text,
                            "Ensure client importance level is equal to the existing event being copied");
            Assert.AreEqual(copiedDescription, description.Value(),
                            "Ensure updated Event Description is correctly saved and retrieved");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddEventNotesAndEventGroups(BrowserType browserType)
        {
            using (var setup = new EventsPicklistDbSetup())
            {
                setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();

            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");

            eventsPicklist.OpenPickList();
            eventsPicklist.AddPickListItem();
            driver.WaitForAngularWithTimeout();

            var eventGroup = new PickList(driver).ByName("ip-picklist-modal-maintenance", "eventGroup");

            eventGroup.OpenPickList();
            eventGroup.AddPickListItem();

            var maintenance = new EventGroupPickListModal(driver);
            maintenance.Description.SendKeys("New E2E Event Group Description");
            maintenance.UserCode.SendKeys("New E2E Event Group Code");
            maintenance.Save();

            driver.WaitForAngularWithTimeout();

            eventGroup.SearchFor("New E2E Event Group Description");
            var eventGroupResult = new KendoGrid(driver, "picklistResults-tablecodes");
            Assert.AreEqual("New E2E Event Group Code", eventGroupResult.CellText(0, 1),
                            "Ensure that the event group code has updated correctly");
            Assert.AreEqual("New E2E Event Group Description", eventGroupResult.CellText(0, 0),
                            "Ensure that the event group description has updated correctly");

            maintenance.Discard();

            driver.Wait();

            var eventNoteGroup = new PickList(driver).ByName("ip-picklist-modal-maintenance", "notesGroup");
            eventNoteGroup.OpenPickList();
            eventNoteGroup.AddPickListItem();
            var eventNoteGroupDescription = driver.FindElement(By.Name("value")).FindElement(By.TagName("textarea"));
            eventNoteGroupDescription.Clear();
            eventNoteGroupDescription.SendKeys("New E2E Event Group Note Description");
            var eventNoteGroupCode = driver.FindElement(By.Name("code")).FindElement(By.TagName("textarea"));
            eventNoteGroupCode.SendKeys("New E2E Event Group Note Code");
            var saveNoteButton = driver.FindElement(By.CssSelector(".btn-save"));
            saveNoteButton.WithJs().Click();

            eventGroup.SearchFor("New E2E Event Group Note Description");
            var eventGroupNoteResult = new KendoGrid(driver, "picklistResults-tablecodes");
            Assert.AreEqual("New E2E Event Group Note Code", eventGroupNoteResult.CellText(0, 1),
                            "Ensure that the event group note code has updated correctly");
            Assert.AreEqual("New E2E Event Group Note Description", eventGroupNoteResult.CellText(0, 0),
                            "Ensure that the event group note description has updated correctly");
        }

    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class EventsPicklistDelete : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteEventFromPicklist(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);
            var searchResults = new KendoGrid(driver, "picklistResults");
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");

            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();
            eventsPicklist.OpenPickList(scenario.Event.Id.ToString());
            eventsPicklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            eventsPicklist.SearchFor(scenario.Event.Id.ToString());

            Assert.AreEqual(0, searchResults.Rows.Count, "Event has been deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteEventNotesAndEventGroups(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);

            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();

            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");

            eventsPicklist.OpenPickList();
            eventsPicklist.AddPickListItem();
            driver.WaitForAngularWithTimeout();

            var maintenance = new EventPicklistModal(driver);

            maintenance.EventGroup.OpenPickList();
            maintenance.EventGroup.SearchFor(scenario.DeleteEventGroup);
            maintenance.EventGroup.DeleteRow(0);
            popups.ConfirmDeleteModal.Delete().Click();

            maintenance.EventGroup.SearchFor(scenario.DeleteEventGroup);
            var eventGroupResult = new KendoGrid(driver, "picklistResults-tablecodes");

            Assert.AreEqual(0, eventGroupResult.Rows.Count, "Ensure that the event group is correctly deleted");

            maintenance.Discard();

            driver.Wait();

            maintenance.EventNoteGroup.OpenPickList();
            maintenance.EventNoteGroup.SearchFor(scenario.DeleteEventNotesGroup);
            maintenance.EventNoteGroup.DeleteRow(0);
            popups.ConfirmDeleteModal.Delete().Click();

            maintenance.EventGroup.SearchFor(scenario.DeleteEventNotesGroup);
            var eventGroupNoteResult = new KendoGrid(driver, "picklistResults-tablecodes");
            Assert.AreEqual(0, eventGroupNoteResult.Rows.Count, "Ensure that the event group note is correctly deleted");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class EventPicklistWithinEventControl : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ReturnEventsWithinCriteria(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup(true);
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");

            var radio = driver.FindElement(By.CssSelector("label[for='search-by-criteria']"));
            radio.WithJs().Click();

            var searchOptions = new SearchOptions(driver);
            var searchResults = new KendoGrid(driver, "searchResults");
            var criteriaPl = new PickList(driver).ByName("ip-search-by-criteria", "criteria");
            criteriaPl.SendKeys(scenario.ExistingEventControl.CriteriaId.ToString()).Blur();
            searchOptions.SearchButton.ClickWithTimeout();

            searchResults.LockedCell(0, 3).FindElement(By.TagName("a")).ClickWithTimeout();

            var detailsPage = new CriteriaDetailPage(driver);
            detailsPage.EventsTopic.EventsGrid.Cell(0, "Event No.").FindElement(By.TagName("a")).ClickWithTimeout();
            var eventControlPage = new EventControlPage(driver);

            // Satisfying Events
            eventControlPage.SatisfyingEvents.NavigateTo();
            eventControlPage.SatisfyingEvents.Add();
            eventControlPage.SatisfyingEvents.EventPicklist.SendKeys(Keys.ArrowDown);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(3, eventControlPage.SatisfyingEvents.EventPicklist.TypeAheadList.Count,
                "Expected only events within the criteria are displayed in the typeahead list");

            eventControlPage.SatisfyingEvents.EventPicklist.OpenPickList();
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            var eventSearchResult = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(3, eventSearchResult.Rows.Count,
                            "Ensure that the event picklist shows only the events for this criteria");
            Assert.NotNull(eventSearchResult.CellText(0, 3),
                           "Alias is returned when doing a criteria search");
            Assert.NotNull(eventSearchResult.CellText(1, 3),
                           "Alias is returned when doing a criteria search");
            Assert.NotNull(eventSearchResult.CellText(2, 3),
                           "Alias is returned when doing a criteria search");

            eventsPicklist.SearchFor(scenario.BaseEvent.Description);
            eventSearchResult = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, eventSearchResult.Rows.Count,
                            "Ensure that the event picklist shows only the matching events searched for within this criteria");
            Assert.AreEqual(scenario.ExistingEventControl.Description, eventSearchResult.CellText(0, 3),
                            "Alias is returned when doing a criteria search");

            eventsPicklist.Close();
            eventControlPage.SatisfyingEvents.EventPicklist.Clear();
            eventControlPage.SatisfyingEvents.EventPicklist.SendKeys(Keys.ArrowDown);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(3, eventControlPage.SatisfyingEvents.EventPicklist.TypeAheadList.Count,
                            "Expected only events within the criteria are displayed in the typeahead list");

            // Event to Update
            var eventsToUpdate = eventControlPage.EventsToUpdate;
            eventsToUpdate.NavigateTo();
            eventsToUpdate.Add();
            eventsToUpdate.EventPicklist.SendKeys(Keys.ArrowDown);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(3, eventsToUpdate.EventPicklist.TypeAheadList.Count,
                            "Expected only events within the criteria are displayed in the typeahead list");
            eventsToUpdate.EventPicklist.OpenPickList(scenario.BaseEvent.Description);
            eventSearchResult = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, eventSearchResult.Rows.Count,
                            "Ensure that the event picklist shows only the matching events searched for within this criteria");
            Assert.AreEqual(scenario.ExistingEventControl.Description, eventSearchResult.CellText(0, 3),
                            "Alias is returned when doing a criteria search");
            eventsToUpdate.EventPicklist.SelectFirstGridRow();

            eventsToUpdate.EventPicklist.Clear();
            eventsToUpdate.EventPicklist.SendKeys(Keys.ArrowDown);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(3, eventsToUpdate.EventPicklist.TypeAheadList.Count,
                            "Expected only events within the criteria are displayed in the typeahead list");

            // Due Date Calculation
            eventControlPage.DueDateCalc.NavigateTo();
            eventControlPage.DueDateCalc.Add();
            var dueDateCalcModal = new DueDateCalcModal(driver);
            dueDateCalcModal.Event.SendKeys(Keys.ArrowDown);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(3, dueDateCalcModal.Event.TypeAheadList.Count,
                            "Expected only events within the criteria are displayed in the typeahead list");
            dueDateCalcModal.Event.OpenPickList(scenario.BaseEvent.Description);
            eventSearchResult = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, eventSearchResult.Rows.Count,
                            "Ensure that the event picklist shows only the matching events searched for within this criteria");
            Assert.AreEqual(scenario.ExistingEventControl.Description, eventSearchResult.CellText(0, 3),
                            "Alias is returned when doing a criteria search");
            dueDateCalcModal.Event.SelectFirstGridRow();

            dueDateCalcModal.Event.Clear();
            dueDateCalcModal.Event.SendKeys(Keys.ArrowDown);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(3, dueDateCalcModal.Event.TypeAheadList.Count,
                            "Expected only events within the criteria are displayed in the typeahead list");
            dueDateCalcModal.Close();
            var confirmationModal = new CommonPopups(driver).DiscardChangesModal;
            confirmationModal.Discard();

            // Date Comparison
            eventControlPage.DateComparison.NavigateTo();
            eventControlPage.DateComparison.Add();
            var dateComparisonModal = new DateComparisonModal(driver);
            dateComparisonModal.EventA.SendKeys(Keys.ArrowDown);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(3, dateComparisonModal.EventA.TypeAheadList.Count,
                            "Expected only events within the criteria are displayed in the typeahead list");

            dateComparisonModal.Close();
            new CommonPopups(driver).DiscardChangesModal.Discard();
            eventControlPage.DateComparison.Add();

            dateComparisonModal.EventA.OpenPickList(scenario.BaseEvent.Description);
            eventSearchResult = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, eventSearchResult.Rows.Count,
                            "Ensure that the event picklist shows only the matching events searched for within this criteria");
            Assert.AreEqual(scenario.ExistingEventControl.Description, eventSearchResult.CellText(0, 3),
                            "Alias is returned when doing a criteria search");
            dateComparisonModal.EventA.SelectFirstGridRow();
            dateComparisonModal.EventA.Clear();
            dateComparisonModal.EventA.SendKeys(Keys.ArrowDown);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(3, dateComparisonModal.EventA.TypeAheadList.Count,
                            "Expected only events within the criteria are displayed in the typeahead list");
            dateComparisonModal.EventB.SendKeys(Keys.ArrowDown);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(3, dateComparisonModal.EventB.TypeAheadList.Count,
                            "Expected only events within the criteria are displayed in the typeahead list");
            dateComparisonModal.EventB.OpenPickList(scenario.BaseEvent.Description);
            eventSearchResult = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, eventSearchResult.Rows.Count,
                            "Ensure that the event picklist shows only the matching events searched for within this criteria");
            Assert.AreEqual(scenario.ExistingEventControl.Description, eventSearchResult.CellText(0, 3),
                            "Alias is returned when doing a criteria search");
            dateComparisonModal.EventB.SelectFirstGridRow();
            dateComparisonModal.EventB.Clear();
            dateComparisonModal.EventB.SendKeys(Keys.ArrowDown);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(3, dateComparisonModal.EventB.TypeAheadList.Count,
                            "Expected only events within the criteria are displayed in the typeahead list");
            dateComparisonModal.Close();
            new CommonPopups(driver).DiscardChangesModal.Discard();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainEventsWithinEventControl(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup(true);
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");

            var radio = driver.FindElement(By.CssSelector("label[for='search-by-criteria']"));
            radio.WithJs().Click();

            var searchOptions = new SearchOptions(driver);
            var searchResults = new KendoGrid(driver, "searchResults");
            var criteriaPl = new PickList(driver).ByName("ip-search-by-criteria", "criteria");
            criteriaPl.SendKeys(scenario.ExistingEventControl.CriteriaId.ToString()).Blur();
            searchOptions.SearchButton.ClickWithTimeout();

            searchResults.LockedCell(0, 3).FindElement(By.TagName("a")).ClickWithTimeout();

            var detailsPage = new CriteriaDetailPage(driver);
            detailsPage.EventsTopic.AddNewEventControlButton.ClickWithTimeout();
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.AddPickListItem();
            driver.WaitForAngularWithTimeout();

            var maintenance = new EventPicklistModal(driver);
            maintenance.EventDescription.SendKeys("New E2E Event From Event Control");
            maintenance.Save();

            driver.WaitForAngularWithTimeout();

            eventsPicklist.SelectFirstGridRow();

            driver.WaitForAngularWithTimeout();

            detailsPage.EventsTopic.FindEventPickList.EnterAndSelect("New E2E Event From Event Control");
            detailsPage.EventsTopic.EventsGrid.Cell(0, "Event No.").FindElement(By.TagName("a")).ClickWithTimeout();

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DueDateCalc.NavigateTo();
            eventControlPage.DueDateCalc.Add();

            eventsPicklist = new PickList(driver).ByName(string.Empty, "fromEvent");
            eventsPicklist.OpenPickList();
            driver.WaitForAngularWithTimeout();

            // Testing of Filter By Criteria checkbox
            var filterByCriteria = new Checkbox(driver).ByLabel("workflows.common.filterByThisCriteria");
            Assert.IsTrue(filterByCriteria.IsChecked, "Expected Filter By Criteria to be initially ticked when opened within a criteria");
            filterByCriteria.Click();
            driver.WaitForAngularWithTimeout();
            var searchField = driver.FindElement(By.CssSelector("div.modal-dialog div.modal-content ip-picklist-modal-search div.modal-body ip-picklist-modal-search-field input[type=text]"));
            searchField.Clear();
            var searchButton = driver.FindElement(By.CssSelector(".modal-body .cpa-icon-search"));
            searchButton.ClickWithTimeout();
            Assert.IsFalse(filterByCriteria.IsChecked, "Expected Filter By Criteria to remain unticked even when re-searching without query");
            searchField.Clear();
            searchField.SendKeys("e2e");
            searchButton.ClickWithTimeout();
            Assert.IsFalse(filterByCriteria.IsChecked, "Expected Filter By Criteria to remain unticked when searching with a query");
            filterByCriteria.Click();
            driver.WaitForAngularWithTimeout();
            searchField.Clear();
            searchField.SendKeys("New E2E Event From Event Control");
            searchButton.ClickWithTimeout();
            Assert.IsTrue(filterByCriteria.IsChecked, "Expected Filter By Criteria to remain ticked when re-searching with a query");

            eventsPicklist.EditRow(0);

            var eventMaintenance = new EventPicklistModal(driver);
            eventMaintenance.EventDescription.Clear();
            eventMaintenance.EventDescription.SendKeys("Updated E2E Event From Event Control");
            eventMaintenance.Save();
            driver.WaitForAngularWithTimeout();

            var confirmationModal = new ConfirmPropagateChangesModal(driver);
            confirmationModal.ProceedButton.Click();

            eventMaintenance.Discard();

            eventsPicklist.SearchFor("Updated E2E Event From Event Control");
            eventsPicklist.EditRow(0);
            driver.WaitForAngularWithTimeout();

            eventMaintenance = new EventPicklistModal(driver);

            var newEventDescription = eventMaintenance.EventDescription.Value();
            Assert.AreEqual("Updated E2E Event From Event Control", newEventDescription,
                            "Expected Event Description to have been updated");

            eventMaintenance.Discard();

            eventsPicklist.DuplicateRow(0);
            driver.WaitForAngularWithTimeout();

            eventMaintenance = new EventPicklistModal(driver);
            newEventDescription = eventMaintenance.EventDescription.Value();

            Assert.AreEqual("Updated E2E Event From Event Control - Copy", newEventDescription,
                            "Expected Event Description to be appended with '- Copy'");

            eventMaintenance.Save();

            driver.FindElement(By.CssSelector("ip-checkbox[ng-model='vm.externalScope.filterByCriteria'] label")).ClickWithTimeout();

            var popups = new CommonPopups(driver);

            eventsPicklist.SearchFor("Updated E2E Event From Event Control");
            eventsPicklist.DeleteRow(0);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            popups.AlertModal.Ok();

            eventsPicklist.DeleteRow(1);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(1, eventsPicklist.SearchGrid.Rows.Count, "Expected Event to have been deleted");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class EventsPicklistTranslated : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DisplayTranslationsCorrectly(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            const string culture = "de-DE";
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup(false, culture);
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();

            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(scenario.Event.Id.ToString());

            Assert.AreEqual(culture + scenario.Description, eventsPicklist.SearchGrid.CellText(0, 2, true), "Expected translated Description to be displayed in search results");

            eventsPicklist.EditRow(0);
            driver.WaitForAngularWithTimeout();

            var maintenance = new EventPicklistModal(driver);

            Assert.AreEqual(scenario.Description, maintenance.EventDescription.Value(), "Expected Description to be in the base language where editable");

            maintenance.Discard();

            eventsPicklist.Clear();
            eventsPicklist.SearchFor(culture + scenario.Description);

            Assert.IsTrue(eventsPicklist.SearchGrid.Rows.Count == 1, "Expected search to match on translated description");
            Assert.AreEqual(culture + scenario.Description, eventsPicklist.SearchGrid.CellText(0, 2, true), "Expected matching record to display translated description");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchOnTranslatedData(BrowserType browserType)
        {
            EventsPicklistDbSetup.ScenarioData scenario;
            const string culture = "de-DE";
            using (var setup = new EventsPicklistDbSetup())
            {
                scenario = setup.DataSetup(true, culture);
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();

            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(culture + scenario.ExistingEventControl.Description);
            Assert.IsTrue(eventsPicklist.SearchGrid.Rows.Count == 1, "Expected search to match on translated description");
            Assert.AreEqual(culture + scenario.BaseEvent.Description, eventsPicklist.SearchGrid.CellText(0, 2, true), "Expected matching record to display translated base description");
            Assert.IsTrue(eventsPicklist.SearchGrid.CellText(0, 3, true).Contains(culture + scenario.ExistingEventControl.Description), "Expected matching record to display all translated Alias");
            Assert.IsTrue(eventsPicklist.SearchGrid.CellText(0, 3, true).Contains(scenario.UpdatableEventControl.Description), "Expected matching record to display all translated Alias");

            eventsPicklist.EditRow(0);
            driver.WaitForAngularWithTimeout();

            var maintenance = new EventPicklistModal(driver);

            Assert.AreEqual(scenario.BaseEvent.Description, maintenance.EventDescription.Value(), "Expected Description to be in the base language where editable");

            maintenance.Discard();

            eventsPicklist.Clear();
            eventsPicklist.SearchFor(scenario.ExistingEventControl.Description);

            Assert.IsTrue(eventsPicklist.SearchGrid.Rows.Count == 1, "Expected search to match on translated description");
            Assert.AreEqual(culture + scenario.BaseEvent.Description, eventsPicklist.SearchGrid.CellText(0, 2, true), "Expected matching record to display translated base description");
            Assert.IsTrue(eventsPicklist.SearchGrid.CellText(0, 3, true).Contains(culture + scenario.ExistingEventControl.Description), "Expected matching record to display all translated Alias");
            Assert.IsTrue(eventsPicklist.SearchGrid.CellText(0, 3, true).Contains(scenario.UpdatableEventControl.Description), "Expected matching record to display all translated Alias");

        }
    }
}