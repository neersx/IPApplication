using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EntryControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EntryControlActions : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ResetEntryInheritance(BrowserType browserType)
        {
            var entryDescription = "Entry 1";
            Criteria childWithNoDescendents, childWithDescendents, grandChild;
            using (var setup = new EntryControlDbSetup())
            {
                var parent = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("parent"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                var events = GenerateEvents(setup, parent, 1, 5);
                var documents = GenerateDocuments(setup, 1, 3);

                var parentEntry = setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 1) {Description = entryDescription});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[1].Id, DisplaySequence = 1});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[2].Id, DisplaySequence = 2});
                setup.Insert(new AvailableEvent {CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[3].Id, DisplaySequence = 3});

                setup.AddNameStepWithFilter(parent, parentEntry);

                setup.Insert(new DocumentRequirement(parent, parentEntry, documents[1]) {Inherited = 1});
                setup.Insert(new DocumentRequirement(parent, parentEntry, documents[2]) {Inherited = 1});

                childWithNoDescendents = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("child"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                var childWithNoDescendentsEntry = setup.Insert<DataEntryTask>(new DataEntryTask(childWithNoDescendents.Id, 1) {Description = entryDescription, Inherited = 1, ParentCriteriaId = parent.Id, ParentEntryId = parentEntry.Id});
                setup.Insert(new AvailableEvent {CriteriaId = childWithNoDescendents.Id, DataEntryTaskId = childWithNoDescendentsEntry.Id, EventId = events[4].Id, DisplaySequence = 1});
                setup.Insert(new AvailableEvent {CriteriaId = childWithNoDescendents.Id, DataEntryTaskId = childWithNoDescendentsEntry.Id, EventId = events[5].Id, DisplaySequence = 2});

                setup.Insert(new DocumentRequirement(childWithNoDescendents, childWithNoDescendentsEntry, documents[2]) {Inherited = 1});

                setup.Insert(new Inherits {Criteria = childWithNoDescendents, FromCriteria = parent});

                childWithDescendents = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("child2"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                var childWithDescendentsEntry = setup.Insert<DataEntryTask>(new DataEntryTask(childWithDescendents.Id, 1) {Description = entryDescription, Inherited = 1, ParentCriteriaId = parent.Id, ParentEntryId = parentEntry.Id});
                setup.Insert(new AvailableEvent {CriteriaId = childWithDescendents.Id, DataEntryTaskId = childWithDescendentsEntry.Id, EventId = events[4].Id, DisplaySequence = 1});
                setup.Insert(new AvailableEvent {CriteriaId = childWithDescendents.Id, DataEntryTaskId = childWithDescendentsEntry.Id, EventId = events[5].Id, DisplaySequence = 2});
                setup.Insert(new Inherits {Criteria = childWithDescendents, FromCriteria = parent});

                grandChild = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("grand child"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                setup.Insert<DataEntryTask>(new DataEntryTask(grandChild.Id, 1) {Description = entryDescription, Inherited = 1, ParentCriteriaId = childWithDescendents.Id, ParentEntryId = childWithDescendentsEntry.Id});
                setup.Insert(new Inherits {Criteria = grandChild, FromCriteria = childWithDescendents});
            }

            var driver = BrowserProvider.Get(browserType);

            GotoEntryControlPage(driver, childWithNoDescendents.Id);

            ReloadPage(driver);

            var entryControlPage = new EntryControlPage(driver);
            var popUps = new CommonPopups(driver);

            entryControlPage.ActivateActionsTab();
            entryControlPage.Actions.ResetInheritance();
            Assert.False(entryControlPage.SectionTabVisible());
            entryControlPage.ResetEntryInheritanceConfirmationModal.Proceed();

            Assert.True(popUps.FlashAlert() != null || entryControlPage.SectionTabVisible());
            AssertCounts(entryControlPage);

            driver.Visit(Env.RootUrl + $"/#/configuration/rules/workflows/{childWithDescendents.Id}/entrycontrol/{childWithDescendents.DataEntryTasks.First().Id}");

            entryControlPage.ActivateActionsTab();
            entryControlPage.Actions.ResetInheritance();
            Assert.False(entryControlPage.SectionTabVisible());
            entryControlPage.ResetEntryInheritanceConfirmationModal.Proceed();

            Assert.True(popUps.FlashAlert() != null || entryControlPage.SectionTabVisible());
            AssertCounts(entryControlPage);

            entryControlPage.ActivateActionsTab();
            Assert.False(entryControlPage.SectionTabVisible());

            entryControlPage.Actions.ResetInheritance();
            entryControlPage.ResetEntryInheritanceConfirmationModal.ApplyToChildren();
            entryControlPage.ResetEntryInheritanceConfirmationModal.Proceed();

            AssertCounts(entryControlPage);

            driver.Visit(Env.RootUrl + $"/#/configuration/rules/workflows/{grandChild.Id}/entrycontrol/{grandChild.DataEntryTasks.First().Id}");
            AssertCounts(entryControlPage);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void BreakEntryInheritance(BrowserType browserType)
        {
            var entryDescription = "Entry 1";
            Criteria childWithNoDescendents;
            using (var setup = new EntryControlDbSetup())
            {
                var parent = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("parent"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                var events = GenerateEvents(setup, parent, 1, 5);
                var documents = GenerateDocuments(setup, 1, 3);

                var parentEntry = setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 1) { Description = entryDescription });
                setup.Insert(new AvailableEvent { CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[1].Id, DisplaySequence = 1 });
                setup.Insert(new AvailableEvent { CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[2].Id, DisplaySequence = 2 });
                setup.Insert(new AvailableEvent { CriteriaId = parent.Id, DataEntryTaskId = parentEntry.Id, EventId = events[3].Id, DisplaySequence = 3 });

                setup.AddNameStepWithFilter(parent, parentEntry);

                setup.Insert(new DocumentRequirement(parent, parentEntry, documents[1]) { Inherited = 1 });
                setup.Insert(new DocumentRequirement(parent, parentEntry, documents[2]) { Inherited = 1 });

                childWithNoDescendents = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("child"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                var childWithNoDescendentsEntry = setup.Insert<DataEntryTask>(new DataEntryTask(childWithNoDescendents.Id, 1) { Description = entryDescription, Inherited = 1, ParentCriteriaId = parent.Id, ParentEntryId = parentEntry.Id });
                setup.Insert(new AvailableEvent { CriteriaId = childWithNoDescendents.Id, DataEntryTaskId = childWithNoDescendentsEntry.Id, EventId = events[4].Id, DisplaySequence = 1 });
                setup.Insert(new AvailableEvent { CriteriaId = childWithNoDescendents.Id, DataEntryTaskId = childWithNoDescendentsEntry.Id, EventId = events[5].Id, DisplaySequence = 2 });

                setup.Insert(new DocumentRequirement(childWithNoDescendents, childWithNoDescendentsEntry, documents[2]) { Inherited = 1 });

                setup.Insert(new Inherits { Criteria = childWithNoDescendents, FromCriteria = parent });
            }

            var driver = BrowserProvider.Get(browserType);

            GotoEntryControlPage(driver, childWithNoDescendents.Id);

            ReloadPage(driver);

            var entryControlPage = new EntryControlPage(driver);
            var popUps = new CommonPopups(driver);

            entryControlPage.ActivateActionsTab();
            entryControlPage.Actions.BreakInheritance();

            // break inheritance confirmation modal
            driver.FindElement(By.CssSelector("[data-ng-click='vm.proceed()']")).Click();

            Assert.True(popUps.FlashAlert() != null || entryControlPage.SectionTabVisible());

            Assert.Null(entryControlPage.InheritanceIcon);
            Assert.False(entryControlPage.Details.AnyInherited, "No Inherited event");
            Assert.False(entryControlPage.Steps.AnyInherited, "No Inherited steps");
            Assert.False(entryControlPage.Documents.AnyInherited, "No Inherited documents");
        }

        Dictionary<int, Event> GenerateEvents(EntryControlDbSetup setup, Criteria criteria, int start, int end)
        {
            var events = new Dictionary<int, Event>();
            Enumerable.Range(start, end)
                      .ToList()
                      .ForEach(x =>
                      {
                          var @event = setup.AddEvent("E2e Event " + x);
                          events.Add(x, @event);
                          setup.AddValidEventFor(criteria, @event, "E2e Valid Event" + x);
                      });
            return events;
        }

        Dictionary<int, Document> GenerateDocuments(EntryControlDbSetup setup, int start, int end)
        {
            var documents = new Dictionary<int, Document>();
            Enumerable.Range(start, end)
                      .ToList()
                      .ForEach(x =>
                      {
                          var document = setup.InsertWithNewId(new Document
                          {
                              Name = Fixture.Prefix("document" + x),
                              DocumentType = 1
                          });
                          documents.Add(x, document);
                      });
            return documents;
        }

        void AssertCounts(EntryControlPage entryControlPage)
        {
            Assert.AreEqual(entryControlPage.Details.GridRowsCount, 3, "Non Inherited event should be deleted");
            Assert.AreEqual(entryControlPage.Steps.GridRowsCount, 1, "Inherit steps from parent");
            Assert.AreEqual(entryControlPage.Documents.GridRowsCount, 2, "Non Inherited documents should be deleted");
        }

        void GotoEntryControlPage(NgWebDriver driver, int criteriaId)
        {
            SignIn(driver, "/#/configuration/rules/workflows");

            driver.FindRadio("search-by-criteria").Label.ClickWithTimeout();

            var searchResults = new KendoGrid(driver, "searchResults");
            var searchOptions = new SearchOptions(driver);
            var pl = new PickList(driver).ByName("ip-search-by-criteria", "criteria");
            pl.EnterAndSelect(criteriaId.ToString());

            searchOptions.SearchButton.ClickWithTimeout();

            driver.WaitForAngular();

            Assert2.WaitTrue(3, 500, () => searchResults.LockedRows.Count > 0, "Search should return some results");

            searchResults.LockedCell(0, 3).FindElement(By.TagName("a")).ClickWithTimeout();

            var workflowDetailsPage = new CriteriaDetailPage(driver);

            workflowDetailsPage.EntriesTopic.NavigateToDetailByRowIndex(0);
        }
    }
}