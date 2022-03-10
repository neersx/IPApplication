using System.Data.Entity;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class WorkflowDetailEvents : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteEvents(BrowserType browserType)
        {
            CriteriaDetailDbSetup.ScenarioData scenario;

            using (var setup = new CriteriaDetailDbSetup())
            {
                scenario = setup.SetUp();
            }

            var driver = BrowserProvider.Get(browserType);
            var workflowDetails = new CriteriaDetailPage(driver);
            var eventsTopic = workflowDetails.EventsTopic;
            var actionMenu = new ActionMenu(driver, "events");

            SignIn(driver, "/#/configuration/rules/workflows/" + scenario.CriteriaId);

            var rowCount = eventsTopic.EventsGrid.Rows.Count;
            eventsTopic.EventsGrid.SelectIpCheckbox(0);

            actionMenu.OpenOrClose();
            actionMenu.Option("delete").ClickWithTimeout();

            workflowDetails.EventsForCaseModal.Proceed();
            workflowDetails.InheritanceDeleteModal.WithoutApplyToChildren();
            workflowDetails.InheritanceDeleteModal.Delete();

            Assert.AreNotEqual(CriteriaDetailDbSetup.ExistingEvent, eventsTopic.EventsGrid.CellText(0, 3));
            Assert.AreEqual(rowCount - 1, eventsTopic.EventsGrid.Rows.Count);
        }

        [Category(Categories.E2E)]
        [TestFixture]
        public class AddEventsAndEntries : IntegrationTest
        {
            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            [TestCase(BrowserType.FireFox)]
            public void AddEvents(BrowserType browserType)
            {
                CriteriaDetailDbSetup.ScenarioData scenario;

                using (var setup = new CriteriaDetailDbSetup())
                {
                    scenario = setup.SetUp();
                }

                var driver = BrowserProvider.Get(browserType);
                var popups = new CommonPopups(driver);
                var workflowDetails = new CriteriaDetailPage(driver);
                var eventsTopic = workflowDetails.EventsTopic;

                SignIn(driver, "/#/configuration/rules/workflows/" + scenario.CriteriaId);

                eventsTopic.Add();
                Assert.AreEqual("Actions", eventsTopic.EventsPickList.SearchGrid.Headers.Last().Text, "Event picklist should be maintenable");
                eventsTopic.EventsPickList.SearchFor(CriteriaDetailDbSetup.EventToBeAdded);
                eventsTopic.EventsPickList.SelectFirstGridRow();

                workflowDetails.InheritanceModal.WithoutApplyToChildren();
                workflowDetails.InheritanceModal.Proceed();

                Assert.AreEqual(CriteriaDetailDbSetup.EventToBeAdded, eventsTopic.EventsGrid.CellText(eventsTopic.EventsGrid.Rows.Count - 1, 3),
                                "since there was no selection, new event should be added last");

                eventsTopic.Add();
                Assert.IsTrue(eventsTopic.EventsPickList.ModalDisplayed, "Pick list opens from add item button below grid");
                eventsTopic.EventsPickList.Close();

                eventsTopic.Add();
                eventsTopic.EventsPickList.SearchFor(CriteriaDetailDbSetup.EventToBeAdded);
                eventsTopic.EventsPickList.SelectFirstGridRow();

                Assert.True(popups.AlertModal.Modal.Displayed, "Event Already Exists");
                popups.AlertModal.Ok();

                // click somewhere on the row (not checkbox), then row becomes selected
                eventsTopic.EventsGrid.Cell(0, "Event No.").ClickWithTimeout();

                eventsTopic.Add();
                eventsTopic.EventsPickList.SearchFor(CriteriaDetailDbSetup.EventToBeAdded2);
                eventsTopic.EventsPickList.SelectFirstGridRow();
                workflowDetails.InheritanceModal.Proceed();

                Assert.AreEqual(CriteriaDetailDbSetup.EventToBeAdded2, eventsTopic.EventsGrid.CellText(1, 3),
                                "since the first row was selected, new event should be added as second row");
            }

            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            [TestCase(BrowserType.FireFox)]
            public void AddEventsDirectlyAfterSearch(BrowserType browserType)
            {
                CriteriaDetailDbSetup.ScenarioData scenario;

                using (var setup = new CriteriaDetailDbSetup())
                {
                    scenario = setup.SetUp();
                }

                var driver = BrowserProvider.Get(browserType);
                var workflowDetails = new CriteriaDetailPage(driver);
                var eventsTopic = workflowDetails.EventsTopic;
                var eventPickList = workflowDetails.EventsTopic.FindEventPickList;

                SignIn(driver, "/#/configuration/rules/workflows/" + scenario.CriteriaId);

                eventPickList.EnterAndSelect(CriteriaDetailDbSetup.EventToBeAdded);

                driver.FindElement(By.CssSelector(".addevent-btn")).Click();
                workflowDetails.InheritanceModal.Proceed();

                Assert.AreEqual(CriteriaDetailDbSetup.EventToBeAdded, eventsTopic.EventsGrid.CellText(2, 3), "adds event to the end");

                eventPickList.EnterAndSelect(CriteriaDetailDbSetup.EventToBeAdded);
                Assert.IsEmpty(driver.FindElements(By.CssSelector(".addevent-btn")), "add event button should be hidden");
            }

            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            [TestCase(BrowserType.FireFox)]
            public void AddEntry(BrowserType browserType)
            {
                CriteriaDetailDbSetup.ScenarioData scenario;

                using (var setup = new CriteriaDetailDbSetup())
                {
                    scenario = setup.SetUp();
                }

                var driver = BrowserProvider.Get(browserType);
                var workflowDetails = new CriteriaDetailPage(driver);
                var eventsTopic = workflowDetails.EventsTopic;
                var entriesTopic = workflowDetails.EntriesTopic;
                var actionMenu = new ActionMenu(driver, "events");
                var entryTobeAdded = Fixture.Prefix("test");

                SignIn(driver, "/#/configuration/rules/workflows/" + scenario.CriteriaId);

                eventsTopic.EventsGrid.SelectIpCheckbox(0);

                actionMenu.OpenOrClose();
                actionMenu.Option("createEntry").ClickWithTimeout();

                entriesTopic.CreateEntryModal.EntryDescription.Input(entryTobeAdded);

                entriesTopic.CreateEntryModal.Save();

                workflowDetails.InheritanceModal.Proceed();

                Assert.AreEqual(entryTobeAdded, entriesTopic.Grid.CellText(entriesTopic.Grid.Rows.Count - 1, 2),
                                "since there was no selection, new entry should be added last");
                DataEntryTask savedEntry;
                DataEntryTask savedChildEntry;
                using (var setup = new CriteriaDetailDbSetup())
                {
                    savedEntry = setup.DbContext.Set<DataEntryTask>().Include(_ => _.AvailableEvents).Single(_ => _.CriteriaId == scenario.CriteriaId && _.Description == entryTobeAdded);
                    savedChildEntry = setup.DbContext.Set<DataEntryTask>().Include(_ => _.AvailableEvents).Single(_ => _.CriteriaId == scenario.ChildCriteriaId && _.Description == entryTobeAdded);
                }

                Assert.True(savedEntry.AvailableEvents.Any(_ => _.EventId == scenario.EventId));
                Assert.True(savedChildEntry.AvailableEvents.Any(_ => _.EventId == scenario.EventId));
            }
        }

        [Category(Categories.E2E)]
        [TestFixture]
        public class ViewEventsAndInheritanceFlags : IntegrationTest
        {
            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            [TestCase(BrowserType.FireFox)]
            public void InheritanceFlags(BrowserType browserType)
            {
                Criteria criteria;

                using (var setup = new CriteriaDetailDbSetup())
                {
                    criteria = setup.AddCriteriaWithEventsInheritance();
                }

                var driver = BrowserProvider.Get(browserType);

                SignIn(driver, "/#/configuration/rules/workflows/" + criteria.Id);

                var eventsGrid = new KendoGrid(driver, "eventResults");

                var fullInheritsCell = eventsGrid.Cell(0, 1).FindElement(By.TagName("span"));
                Assert.True(fullInheritsCell.WithJs().HasClass("cpa-icon-inheritance"));

                var partialInheritsCell = eventsGrid.Cell(1, 1).FindElement(By.TagName("span"));
                Assert.True(partialInheritsCell.WithJs().HasClass("cpa-icon-inheritance-partial"));

                var noInheritanceCell = eventsGrid.Cell(2, 1).FindElement(By.TagName("span"));
                Assert.False(noInheritanceCell.WithJs().HasClass("cpa-icon-inheritance"));
                Assert.False(noInheritanceCell.WithJs().HasClass("cpa-icon-inheritance-partial"));
            }

            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            [TestCase(BrowserType.FireFox)]
            public void FindEvent(BrowserType browserType)
            {
                CriteriaDetailDbSetup.ScenarioData scenario;
                int[] events;
                int referencedEventId, requiredEventId;
                using (var setup = new CriteriaDetailDbSetup())
                {
                    scenario = setup.SetUp();
                    events = setup.AddValidEvents(scenario.Criteria, 30).ToArray();
                    setup.AddDueDateCalc(scenario.Criteria.ValidEvents.Last());

                    var requiredEvent = setup.AddEvent("RequiredEventsEvent");
                    requiredEventId = requiredEvent.Id;
                    setup.AddRequiredEvent(scenario.Criteria.ValidEvents.Skip(15).First(), requiredEvent);

                    referencedEventId = setup.AddEvent("DueDateRefEvent").Id;
                    scenario.Criteria.ValidEvents.Last().DueDateCalcs.First().FromEventId = referencedEventId;
                    setup.DbContext.SaveChanges();
                }

                var driver = BrowserProvider.Get(browserType);
                var workflowDetails = new CriteriaDetailPage(driver);
                var eventsTopic = workflowDetails.EventsTopic;

                SignIn(driver, "/#/configuration/rules/workflows/" + scenario.CriteriaId);

                eventsTopic.TopicContainer.WithJs().ScrollIntoView();
                eventsTopic.FindEventPickList.Typeahead.WithJs().ScrollIntoView();
                eventsTopic.FindEventPickList.EnterAndSelect(events[1].ToString());
                Assert.AreEqual(events[1].ToString(), eventsTopic.EventsGrid.FindElement(By.CssSelector("tr.found.bold")).FindElement(By.CssSelector("td a")).Text, "Highlights direct match");

                eventsTopic.FindEventPickList.EnterAndSelect(events[11].ToString());
                Assert.AreEqual(events[11].ToString(), eventsTopic.EventsGrid.FindElement(By.CssSelector("tr.found.bold")).FindElement(By.CssSelector("td a")).Text, "Pages to and highlights direct match");

                eventsTopic.FindEventPickList.EnterAndSelect(requiredEventId.ToString());
                Assert.AreEqual(scenario.Criteria.ValidEvents.Skip(15).First().EventId.ToString(), eventsTopic.EventsGrid.FindElement(By.CssSelector("tr.found")).FindElement(By.CssSelector("td a")).Text, "Pages to and highlights indirect match");
                Assert.IsEmpty(eventsTopic.EventsGrid.FindElements(By.CssSelector("tr.found.bold")), "Highlights as indirect match and not direct match");

                eventsTopic.FindEventPickList.EnterAndSelect(referencedEventId.ToString());
                Assert.AreEqual(scenario.Criteria.ValidEvents.Last().EventId.ToString(), eventsTopic.EventsGrid.FindElement(By.CssSelector("tr.found")).FindElement(By.CssSelector("td a")).Text, "Pages to and highlights indirect match");
                Assert.IsEmpty(eventsTopic.EventsGrid.FindElements(By.CssSelector("tr.found.bold")), "Highlights as indirect match and not direct match");
            }
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyPagingIsAvailableAfterSearch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);
            var workflowDetails = new CriteriaDetailPage(driver);
            var eventsTopic = workflowDetails.EventsTopic;
            SignIn(driver, "/#/portal2");
            workflowDetails.WorkflowDesignerButton.Click();
            workflowDetails.CriteriaLabel.Click(); 
            workflowDetails.SearchButton.Click();
            StringAssert.Contains("1 - 20", workflowDetails.PageInfo.Text);
            workflowDetails.NextPageButton.Click();
            StringAssert.Contains("21 - 40", workflowDetails.PageInfo.Text);
            workflowDetails.CharacteristicsLabel.Click(); 
            workflowDetails.SearchButton.Click();
            StringAssert.Contains("1 - 20", workflowDetails.PageInfo.Text);
            workflowDetails.NextPageButton.Click();
            StringAssert.Contains("21 - 40", workflowDetails.PageInfo.Text);
        }
    }
}