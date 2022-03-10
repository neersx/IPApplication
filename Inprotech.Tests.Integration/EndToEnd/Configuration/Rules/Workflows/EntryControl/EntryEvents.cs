using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EntryControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EntryEvents : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddEntryEventsAndPropagateToChildren(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            Criteria parent, child;
            var events = new Dictionary<int, Event>();
            var eventParentDescriptions = new Dictionary<int, string>();
            var eventChildDescriptions = new Dictionary<int, string>();
            using (var setup = new EntryControlDbSetup())
            {
                parent = setup.InsertWithNewId(new Criteria
                                               {
                                                   Description = Fixture.Prefix("parent"),
                                                   PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                               });

                Enumerable.Range(1, 5)
                          .ToList()
                          .ForEach(x =>
                                   {
                                       var @event = setup.AddEvent("E2e Event " + x);
                                       events.Add(x, @event);
                                       eventChildDescriptions.Add(x, @event.Description);

                                       setup.AddValidEventFor(parent, @event, "E2e Valid Event" + x);
                                       eventParentDescriptions.Add(x, "E2e Valid Event" + x);
                                   });

                var parentEntry = setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 1) {Description = "Entry 1"});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[1].Id, DisplaySequence = 1});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[2].Id, DisplaySequence = 2});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[3].Id, DisplaySequence = 3});

                child = setup.InsertWithNewId(new Criteria
                                              {
                                                  Description = Fixture.Prefix("child"),
                                                  PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                              });
                var childEntry = setup.Insert<DataEntryTask>(new DataEntryTask(child.Id, 1) {Description = "Entry- 1", Inherited = 1, ParentCriteriaId = parent.Id, ParentEntryId = parentEntry.Id});
                setup.Insert(new AvailableEvent {CriteriaId = child.Id, DataEntryTaskId = childEntry.Id, EventId = events[2].Id, DisplaySequence = 1});
                setup.Insert(new AvailableEvent {CriteriaId = child.Id, DataEntryTaskId = childEntry.Id, EventId = events[4].Id, DisplaySequence = 2});
                setup.Insert(new AvailableEvent {CriteriaId = child.Id, DataEntryTaskId = childEntry.Id, EventId = events[1].Id, DisplaySequence = 3});

                setup.Insert(new Inherits {Criteria = child, FromCriteria = parent});
            }

            SignIn(driver, $"#/configuration/rules/workflows/{parent.Id}/entrycontrol/{1}");

            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              Assert.AreEqual(3, entrycontrol.Details.GridRowsCount);

                                              entrycontrol.Details.SelectEventRow(1);
                                              entrycontrol.Details.Add();
                                              entrycontrol.CreateOrEditEntryEventModal.EntryEvent.SelectItem(eventParentDescriptions[5]);
                                              entrycontrol.CreateOrEditEntryEventModal.UpdateEvent.SelectItem(eventParentDescriptions[1]);
                                              entrycontrol.CreateOrEditEntryEventModal.DueDate.Text = "Must Enter";
                                              entrycontrol.CreateOrEditEntryEventModal.DueDateResp.Text = "Display Only";
                                              entrycontrol.CreateOrEditEntryEventModal.Apply();

                                              entrycontrol.Details.Add();
                                              entrycontrol.CreateOrEditEntryEventModal.EntryEvent.SelectItem(eventParentDescriptions[4]);
                                              entrycontrol.CreateOrEditEntryEventModal.EventDate.Text = "Optional Entry";
                                              entrycontrol.CreateOrEditEntryEventModal.OverrideEventDate.Text = "Must Enter";
                                              entrycontrol.CreateOrEditEntryEventModal.OverrideDueDate.Text = "Hide";
                                              entrycontrol.CreateOrEditEntryEventModal.Apply();

                                              entrycontrol.Save();
                                              entrycontrol.EntryInheritanceConfirmationModal.Proceed(false);
                                          });

            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              popups.WaitForFlashAlert();
                                              Assert.AreEqual(5, entrycontrol.Details.GridRowsCount);

                                              var row1 = entrycontrol.Details.GetEventDataForRow(0);
                                              Assert.AreEqual(CombinedColumns(eventParentDescriptions[1], events[1].Id.ToString()), row1.EntryEvent);

                                              var row2 = entrycontrol.Details.GetEventDataForRow(1);
                                              Assert.AreEqual(CombinedColumns(eventParentDescriptions[2], events[2].Id.ToString()), row2.EntryEvent);

                                              var row3 = entrycontrol.Details.GetEventDataForRow(2);
                                              Assert.AreEqual(CombinedColumns(eventParentDescriptions[5], events[5].Id.ToString()), row3.EntryEvent);

                                              Assert.AreEqual("Must Enter", row3.DueDateAttribute);
                                              Assert.AreEqual("Display Only", row3.DueDateResp);
                                              Assert.AreEqual(CombinedColumns(eventParentDescriptions[1], events[1].Id.ToString()), row3.UpdateEvent);

                                              var row4 = entrycontrol.Details.GetEventDataForRow(3);
                                              Assert.AreEqual(CombinedColumns(eventParentDescriptions[4], events[4].Id.ToString()), row4.EntryEvent);
                                              Assert.AreEqual("Optional Entry", row4.EventDateAttribute);
                                              Assert.AreEqual("Must Enter", row4.OverrideEvent);
                                              Assert.AreEqual("Hide", row4.OverrideDue);
                                              
                                              var row5 = entrycontrol.Details.GetEventDataForRow(4);
                                              Assert.AreEqual(CombinedColumns(eventParentDescriptions[3], events[3].Id.ToString()), row5.EntryEvent);
                                          });

            driver.Visit($"/#/configuration/rules/workflows/{child.Id}/entrycontrol/{1}");

            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              Assert.AreEqual(4, entrycontrol.Details.GridRowsCount);

                                              var row1 = entrycontrol.Details.GetEventDataForRow(0);
                                              Assert.AreEqual(CombinedColumns(eventChildDescriptions[2], events[2].Id.ToString()), row1.EntryEvent);

                                              var row2 = entrycontrol.Details.GetEventDataForRow(1);
                                              Assert.AreEqual(CombinedColumns(eventChildDescriptions[5], events[5].Id.ToString()), row2.EntryEvent);
                                              Assert.True(row2.Inherited);
                                              Assert.AreEqual("Must Enter", row2.DueDateAttribute);
                                              Assert.AreEqual(CombinedColumns(eventChildDescriptions[1], events[1].Id.ToString()), row2.UpdateEvent);

                                              var row3 = entrycontrol.Details.GetEventDataForRow(2);
                                              Assert.AreEqual(CombinedColumns(eventChildDescriptions[4], events[4].Id.ToString()), row3.EntryEvent);

                                              var row4 = entrycontrol.Details.GetEventDataForRow(3);
                                              Assert.AreEqual(CombinedColumns(eventChildDescriptions[1], events[1].Id.ToString()), row4.EntryEvent);
                                          });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateEntryEventsAndPropagateToChildren(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            Criteria parent, child;
            var events = new Dictionary<int, Event>();
            var eventDescriptions = new Dictionary<int, string>();
            using (var setup = new EntryControlDbSetup())
            {
                parent = setup.InsertWithNewId(new Criteria
                                               {
                                                   Description = Fixture.Prefix("parent"),
                                                   PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                               });

                child = setup.InsertWithNewId(new Criteria
                                              {
                                                  Description = Fixture.Prefix("child"),
                                                  PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                              });

                Enumerable.Range(1, 10)
                          .ToList()
                          .ForEach(x =>
                                   {
                                       var @event = setup.AddEvent("E2e Event " + x);
                                       events.Add(x, @event);
                                       eventDescriptions.Add(x, @event.Description);

                                       setup.AddValidEventFor(parent, @event);
                                       setup.AddValidEventFor(child, @event);
                                   });

                var parentEntry = setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 1) {Description = "Entry 1"});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[1].Id, DisplaySequence = 1});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[2].Id, DisplaySequence = 2});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[3].Id, DisplaySequence = 3, DueAttribute = 1});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[5].Id, DisplaySequence = 4, PeriodAttribute = 0});

                var childEntry = setup.Insert<DataEntryTask>(new DataEntryTask(child.Id, 1) {Description = "Entry- 1", Inherited = 1, ParentCriteriaId = parent.Id, ParentEntryId = parentEntry.Id});
                setup.Insert(new AvailableEvent
                             {
                                 CriteriaId = child.Id,
                                 DataEntryTaskId = childEntry.Id,
                                 EventId = events[1].Id,
                                 DisplaySequence = 1,
                                 Inherited = 1,
                                 AlsoUpdateEventId = events[9].Id,
                                 EventAttribute = 0,
                                 DueAttribute = 1,
                                 PeriodAttribute = 2,
                                 PolicingAttribute = 3
                             });

                setup.Insert(new AvailableEvent {CriteriaId = child.Id, DataEntryTaskId = childEntry.Id, EventId = events[2].Id, DisplaySequence = 1, Inherited = 0});
                setup.Insert(new AvailableEvent {CriteriaId = child.Id, DataEntryTaskId = childEntry.Id, EventId = events[3].Id, DisplaySequence = 2, Inherited = 1});
                setup.Insert(new AvailableEvent {CriteriaId = child.Id, DataEntryTaskId = childEntry.Id, EventId = events[4].Id, DisplaySequence = 3, Inherited = 0});
                setup.Insert(new AvailableEvent {CriteriaId = child.Id, DataEntryTaskId = childEntry.Id, EventId = events[5].Id, DisplaySequence = 4, Inherited = 1});

                setup.Insert(new Inherits {Criteria = child, FromCriteria = parent});
            }

            SignIn(driver, $"#/configuration/rules/workflows/{parent.Id}/entrycontrol/{1}");

            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              Assert.AreEqual(4, entrycontrol.Details.GridRowsCount);
                                              entrycontrol.Details.Grid.ClickEdit(0);

                                              entrycontrol.CreateOrEditEntryEventModal.UpdateEvent.SelectItem(eventDescriptions[10]);
                                              entrycontrol.CreateOrEditEntryEventModal.EventDate.Text = "Default to System Date";
                                              entrycontrol.CreateOrEditEntryEventModal.DueDate.Text = "Optional Entry";
                                              entrycontrol.CreateOrEditEntryEventModal.Period.Text = "Hide";
                                              entrycontrol.CreateOrEditEntryEventModal.StopPolicing.Text = "Must Enter";
                                              entrycontrol.CreateOrEditEntryEventModal.DueDateResp.Text = "Must Enter";
                                              entrycontrol.CreateOrEditEntryEventModal.NavigateToNext();

                                              entrycontrol.CreateOrEditEntryEventModal.DueDate.Text = "Display Only";
                                              entrycontrol.CreateOrEditEntryEventModal.OverrideEventDate.Text = "Display Only";
                                              entrycontrol.CreateOrEditEntryEventModal.OverrideDueDate.Text = "Must Enter";
                                              entrycontrol.CreateOrEditEntryEventModal.NavigateToNext();

                                              entrycontrol.CreateOrEditEntryEventModal.EntryEvent.Clear();
                                              entrycontrol.CreateOrEditEntryEventModal.EntryEvent.SelectItem(eventDescriptions[4]);
                                              entrycontrol.CreateOrEditEntryEventModal.NavigateToNext();

                                              entrycontrol.CreateOrEditEntryEventModal.EntryEvent.Clear();
                                              entrycontrol.CreateOrEditEntryEventModal.EntryEvent.SelectItem(eventDescriptions[10]);
                                              entrycontrol.CreateOrEditEntryEventModal.StopPolicing.Text = "Must Enter";
                                              entrycontrol.CreateOrEditEntryEventModal.Apply();

                                              entrycontrol.Save();

                                              entrycontrol.EntryInheritanceConfirmationModal.Proceed();

                                              var firstRow = entrycontrol.Details.GetEventDataForRow(0);
                                              Assert.AreEqual(CombinedColumns(eventDescriptions[10], events[10].Id.ToString()), firstRow.UpdateEvent);
                                              Assert.AreEqual(CombinedColumns(eventDescriptions[1], events[1].Id.ToString()), firstRow.EntryEvent);
                                              Assert.AreEqual("Default to System Date", firstRow.EventDateAttribute);
                                              Assert.AreEqual("Optional Entry", firstRow.DueDateAttribute);

                                              entrycontrol.Details.Grid.ClickEdit(0);
                                              Assert.AreEqual("Hide", entrycontrol.CreateOrEditEntryEventModal.Period.Text);
                                              Assert.AreEqual("Must Enter", entrycontrol.CreateOrEditEntryEventModal.StopPolicing.Text);
                                              Assert.AreEqual("Must Enter", entrycontrol.CreateOrEditEntryEventModal.DueDateResp.Text);
                                              entrycontrol.CreateOrEditEntryEventModal.Close();

                                              var secondRow = entrycontrol.Details.GetEventDataForRow(1);
                                              Assert.AreEqual("Display Only", secondRow.DueDateAttribute);
                                              Assert.AreEqual("Display Only", secondRow.OverrideEvent);
                                              Assert.AreEqual("Must Enter", secondRow.OverrideDue);

                                              var thirdRow = entrycontrol.Details.GetEventDataForRow(2);
                                              Assert.AreEqual(CombinedColumns(eventDescriptions[4], events[4].Id.ToString()), thirdRow.EntryEvent);

                                              var forthRow = entrycontrol.Details.GetEventDataForRow(3);
                                              Assert.AreEqual(CombinedColumns(eventDescriptions[10], events[10].Id.ToString()), forthRow.EntryEvent);
                                          });

            driver.Visit($"/#/configuration/rules/workflows/{child.Id}/entrycontrol/{1}");
            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              Assert.AreEqual(5, entrycontrol.Details.GridRowsCount);

                                              entrycontrol.Details.Grid.ClickEdit(0);
                                              Assert.AreEqual($"({events[1].Id}) {eventDescriptions[1]}", entrycontrol.CreateOrEditEntryEventModal.EntryEvent.GetText());
                                              Assert.AreEqual($"({events[10].Id}) {eventDescriptions[10]}", entrycontrol.CreateOrEditEntryEventModal.UpdateEvent.GetText());
                                              Assert.AreEqual("Default to System Date", entrycontrol.CreateOrEditEntryEventModal.EventDate.Text);
                                              Assert.AreEqual("Optional Entry", entrycontrol.CreateOrEditEntryEventModal.DueDate.Text);
                                              Assert.AreEqual("Hide", entrycontrol.CreateOrEditEntryEventModal.Period.Text);
                                              Assert.AreEqual("Must Enter", entrycontrol.CreateOrEditEntryEventModal.StopPolicing.Text);
                                              entrycontrol.CreateOrEditEntryEventModal.Close();

                                              var secondRow = entrycontrol.Details.GetEventDataForRow(1);
                                              Assert.AreEqual(string.Empty, secondRow.DueDateAttribute);

                                              var thirdRow = entrycontrol.Details.GetEventDataForRow(2);
                                              Assert.False(thirdRow.Inherited);

                                              var forthRow = entrycontrol.Details.GetEventDataForRow(3);
                                              Assert.AreEqual(CombinedColumns(eventDescriptions[4], events[4].Id.ToString()), forthRow.EntryEvent);

                                              var fifthRow = entrycontrol.Details.GetEventDataForRow(4);
                                              Assert.AreEqual(CombinedColumns(eventDescriptions[10], events[10].Id.ToString()), fifthRow.EntryEvent);
                                          });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteEntryEventAndPropagateToChildren(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            Criteria parent, child, grandChild;
            DataEntryTask parentEntry, childEntry, grandChildEntry;
            var events = new Dictionary<int, Event>();
            var eventParentDescriptions = new Dictionary<int, string>();
            var eventChildDescriptions = new Dictionary<int, string>();
            using (var setup = new EntryControlDbSetup())
            {
                parent = setup.InsertWithNewId(new Criteria
                                               {
                                                   Description = Fixture.Prefix("parent"),
                                                   PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                               });

                Enumerable.Range(1, 3)
                          .ToList()
                          .ForEach(x =>
                                   {
                                       var @event = setup.AddEvent("E2e Event " + x);
                                       events.Add(x, @event);
                                       eventChildDescriptions.Add(x, @event.Description);

                                       setup.AddValidEventFor(parent, @event, "E2e Valid Event" + x);
                                       eventParentDescriptions.Add(x, "E2e Valid Event" + x);
                                   });

                parentEntry = setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 1) {Description = "Entry 1"});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[1].Id, DisplaySequence = 1});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[2].Id, DisplaySequence = 2});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[3].Id, DisplaySequence = 3});

                child = setup.InsertWithNewId(new Criteria
                                              {
                                                  Description = Fixture.Prefix("child"),
                                                  PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                              });
                childEntry = setup.Insert<DataEntryTask>(new DataEntryTask(child.Id, 1) {Description = "Entry- 1", Inherited = 1, ParentCriteriaId = parent.Id, ParentEntryId = parentEntry.Id});
                setup.Insert(new AvailableEvent {CriteriaId = child.Id, DataEntryTaskId = childEntry.Id, EventId = events[1].Id, DisplaySequence = 1, Inherited = 1});
                setup.Insert(new AvailableEvent {CriteriaId = child.Id, DataEntryTaskId = childEntry.Id, EventId = events[2].Id, DisplaySequence = 2, Inherited = 0});
                setup.Insert(new AvailableEvent {CriteriaId = child.Id, DataEntryTaskId = childEntry.Id, EventId = events[3].Id, DisplaySequence = 3, Inherited = 1});

                setup.Insert(new Inherits {Criteria = child, FromCriteria = parent});

                grandChild = setup.InsertWithNewId(new Criteria
                                                   {
                                                       Description = Fixture.Prefix("grandChild"),
                                                       PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                                   });
                grandChildEntry = setup.Insert<DataEntryTask>(new DataEntryTask(grandChild.Id, 1) {Description = "Entry- 1", Inherited = 1, ParentCriteriaId = child.Id, ParentEntryId = childEntry.Id});
                setup.Insert(new AvailableEvent {CriteriaId = grandChild.Id, DataEntryTaskId = grandChildEntry.Id, EventId = events[1].Id, DisplaySequence = 1, Inherited = 1});
                setup.Insert(new AvailableEvent {CriteriaId = grandChild.Id, DataEntryTaskId = grandChildEntry.Id, EventId = events[2].Id, DisplaySequence = 2, Inherited = 1});
                setup.Insert(new AvailableEvent {CriteriaId = grandChild.Id, DataEntryTaskId = grandChildEntry.Id, EventId = events[3].Id, DisplaySequence = 3, Inherited = 1});

                setup.Insert(new Inherits {Criteria = grandChild, FromCriteria = child});
            }

            SignIn(driver, $"/#/configuration/rules/workflows/{parent.Id}/entrycontrol/{parentEntry.Id}");

            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              Assert.AreEqual(3, entrycontrol.Details.GridRowsCount, "Initially 3 events are added to parent criteria");
                                              entrycontrol.Details.Grid.ToggleDelete(0);
                                              entrycontrol.Details.Grid.ToggleDelete(1);

                                              entrycontrol.SaveButton.ClickWithTimeout();
                                              entrycontrol.EntryInheritanceConfirmationModal.Proceed(false);
                                          });

            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              popups.WaitForFlashAlert();
                                              Assert.AreEqual(1, entrycontrol.Details.GridRowsCount, "2 events should have been deleted, leaving only 1 event in parent criteria");

                                              var row1 = entrycontrol.Details.GetEventDataForRow(0);
                                              Assert.AreEqual(CombinedColumns(eventParentDescriptions[3], events[3].Id.ToString()), row1.EntryEvent, "Remaining event");
                                          });

            driver.Visit($"/#/configuration/rules/workflows/{child.Id}/entrycontrol/{childEntry.Id}");

            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              Assert.AreEqual(2, entrycontrol.Details.GridRowsCount, "The inherited event that was deleted at parent level should have been deleted from child as well");

                                              var row1 = entrycontrol.Details.GetEventDataForRow(0);
                                              Assert.AreEqual(CombinedColumns(eventChildDescriptions[2], events[2].Id.ToString()), row1.EntryEvent, "This event should be here because its inherited flag was set to 0");

                                              var row2 = entrycontrol.Details.GetEventDataForRow(1);
                                              Assert.AreEqual(CombinedColumns(eventChildDescriptions[3], events[3].Id.ToString()), row2.EntryEvent, "This event wasnt deleted at parent level so should be available here");
                                              Assert.True(row2.Inherited);
                                          });

            driver.Visit($"/#/configuration/rules/workflows/{grandChild.Id}/entrycontrol/{grandChildEntry.Id}");

            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              Assert.AreEqual(2, entrycontrol.Details.GridRowsCount, "The inherited event that was deleted at parent level should have been deleted from child as well");

                                              var row1 = entrycontrol.Details.GetEventDataForRow(0);
                                              Assert.AreEqual(CombinedColumns(eventChildDescriptions[2], events[2].Id.ToString()), row1.EntryEvent, "This event should be here because eventhough it was not deleted from its parent");
                                              Assert.True(row1.Inherited);

                                              var row2 = entrycontrol.Details.GetEventDataForRow(1);
                                              Assert.AreEqual(CombinedColumns(eventChildDescriptions[3], events[3].Id.ToString()), row2.EntryEvent, "This event wasnt deleted at parent level so should be available here");
                                              Assert.True(row2.Inherited);
                                          });
        }

        string CombinedColumns(string field, string fieldInBrackets)
        {
            return $"{field} ({fieldInBrackets})";
        }
    }
}