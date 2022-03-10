using System;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DateComparisonTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddDateComparison(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                var caseRelationBuilder = new CaseRelationBuilder(setup.DbContext);

                var vEvent = eventBuilder.Create("Event");
                var eventA = eventBuilder.Create("EventA");
                var eventB = eventBuilder.Create("EventB", 2);
                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, vEvent, "Apple")
                {
                    Inherited = 1,
                    NumberOfCyclesAllowed = 1,
                    Importance = importance,
                    DatesLogicComparison = 0
                };
                setup.Insert(validEvent);

                setup.Insert(new ValidEvent(criteria, eventA, "EventA"));
                setup.Insert(new ValidEvent(criteria, eventB, "EventB"));

                var relationship = caseRelationBuilder.Create("E2ERelationship");

                return new
                {
                    Event = vEvent.Description,
                    EventId = vEvent.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    EventA = eventA,
                    EventB = eventB,
                    Relationship = relationship
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);

            eventControlPage.DateComparison.NavigateTo();
            eventControlPage.DateComparison.Add();

            var modal = new DateComparisonModal(driver);

            Assert.IsTrue(modal.EventAEventDate.IsChecked);
            Assert.IsTrue(modal.CompareEventBOption.IsChecked);
            Assert.IsTrue(modal.EventBEventDate.IsChecked);

            Assert.AreEqual(string.Empty, modal.EventARelativeCycle.Value);
            modal.EventA.EnterAndSelect(data.EventA.Description);

            modal.EventAEventOrDue.Click();
            modal.EventADueDate.Click();
            modal.EventAEventDate.Click();

            modal.ComparisonOperator.Input.SelectByText("Exists");
            Assert.True(modal.CompareOptionsHidden());
            Assert.True(modal.EventBOptionsHidden());
            Assert.True(modal.CompareDateHidden());

            modal.ComparisonOperator.Input.SelectByText(">");

            modal.CompareDateOption.Click();
            modal.CompareDate.Enter(DateTime.Now);

            modal.CompareSystemDateOption.Click();
            Assert.True(modal.EventBOptionsHidden());
            Assert.True(modal.CompareDateHidden());

            modal.CompareEventBOption.Click();
            Assert.AreEqual(string.Empty, modal.EventBRelativeCycle.Value);
            modal.EventB.EnterAndSelect(data.EventB.Description);

            modal.EventBDueDate.Click();
            modal.EventBEventOrDue.Click();
            modal.EventBEventDate.Click();
            modal.CompareRelationship.EnterAndSelect(data.Relationship.Description);

            modal.Apply();

            eventControlPage.DateComparison.AllDueDateCalcsOption.Click();

            eventControlPage.Save();

            var dateComparison = eventControlPage.DateComparison;

            Assert.IsTrue(eventControlPage.DateComparison.AllDueDateCalcsOption.IsChecked);
            Assert.AreEqual(1, dateComparison.GridRowsCount);
            Assert2.WaitTrue(5, 200, () => dateComparison.EventA.Contains(data.EventA.Id.ToString()));
            Assert2.WaitTrue(5, 200, () => dateComparison.EventA.Contains(data.EventA.Description));
            Assert.AreEqual("Event Date", eventControlPage.DateComparison.EventAUseDate);
            Assert.AreEqual("Cycle 1", eventControlPage.DateComparison.EventACycle);
            Assert.AreEqual(">", dateComparison.ComparisonOperator);
            Assert2.WaitTrue(5, 200, () => dateComparison.EventB.Contains(data.EventB.Id.ToString()));
            Assert2.WaitTrue(5, 200, () => dateComparison.EventB.Contains(data.EventB.Description));
            Assert.AreEqual("Event Date", eventControlPage.DateComparison.EventBUseDate);
            Assert.AreEqual("Current Cycle", eventControlPage.DateComparison.EventBCycle);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateDateComparison(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);

                var @event = eventBuilder.Create();
                var fromEvent = eventBuilder.Create();
                var compareEventId = eventBuilder.Create();
                var criteria = criteriaBuilder.Create();
                var importance = importanceBuilder.Create();

                var validEvent = setup.Insert(new ValidEvent(criteria, @event, "Apple")
                {
                    NumberOfCyclesAllowed = 1,
                    Importance = importance,
                    DatesLogicComparison = 0
                });

                setup.Insert(new DueDateCalc(validEvent, 0)
                {
                    FromEventId = fromEvent.Id,
                    RelativeCycle = 0,
                    EventDateFlag = 1,
                    Comparison = "=",
                    CompareEventId = compareEventId.Id,
                    CompareCycle = 0,
                    CompareEventFlag = 1
                });

                var newFromEvent = eventBuilder.Create();
                var newCompareEvent = eventBuilder.Create();

                setup.Insert(new ValidEvent(criteria, newFromEvent, "Orange"));
                setup.Insert(new ValidEvent(criteria, newCompareEvent, "Banana"));

                return new
                {
                    EventId = @event.Id,
                    CriteriaId = criteria.Id,
                    ImportanceLevel = importance.Level,
                    NewFromEvent = newFromEvent,
                    NewComparison = ">",
                    NewCompareEvent = newCompareEvent
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DateComparison.NavigateTo();
            eventControlPage.DateComparison.Grid.ClickEdit(0);

            var modal = new DateComparisonModal(driver);

            modal.EventA.EnterAndSelect(data.NewFromEvent.Description);
            modal.EventADueDate.Click();
            modal.EventARelativeCycle.Text = "Next Cycle";
            modal.ComparisonOperator.Text = "<>";
            modal.EventB.EnterAndSelect(data.NewCompareEvent.Description);
            modal.EventBDueDate.Click();
            modal.EventBRelativeCycle.Text = "Next Cycle";

            modal.Apply();
            eventControlPage.Save();

            var dateComparison = eventControlPage.DateComparison;

            Assert2.WaitTrue(5, 200, () => dateComparison.EventA.Contains(data.NewFromEvent.Id.ToString()));
            Assert2.WaitTrue(5, 200, () => dateComparison.EventA.Contains(data.NewFromEvent.Description));
            Assert.AreEqual("<>", dateComparison.ComparisonOperator);
            Assert2.WaitTrue(5, 200, () => dateComparison.EventB.Contains(data.NewCompareEvent.Id.ToString()));
            Assert2.WaitTrue(5, 200, () => dateComparison.EventB.Contains(data.NewCompareEvent.Description));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteDateComparisonCalc(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var criteria = criteriaBuilder.Create("criteria");
                var evt = eventBuilder.Create("event");
                var evt1 = eventBuilder.Create("event1");

                var importance = importanceBuilder.Create();
                setup.Insert(new ValidEvent(criteria, evt, "event1")
                {
                    NumberOfCyclesAllowed = 2,
                    Importance = importance
                });

                setup.Insert(new DueDateCalc
                {
                    Sequence = 0,
                    Comparison = ">",
                    CriteriaId = criteria.Id,
                    EventId = evt.Id,
                    FromEventId = evt.Id
                });

                setup.Insert(new DueDateCalc
                {
                    Sequence = 1,
                    Comparison = "<",
                    CriteriaId = criteria.Id,
                    EventId = evt.Id,
                    FromEventId = evt1.Id,
                    RelativeCycle = 1
                });

                return new
                {
                    CriteriaId = criteria.Id.ToString(),
                    EventId = evt.Id.ToString(),
                    Event1Id = evt1.Id.ToString()
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DateComparison.NavigateTo();
            eventControlPage.DateComparison.Grid.ToggleDelete(0);
            eventControlPage.Save();

            var dateComparison = eventControlPage.DateComparison;

            Assert.AreEqual(1, eventControlPage.DateComparison.GridRowsCount, "only deletes the first row which was marked as deleted");
            Assert2.WaitTrue(5, 200, () => dateComparison.EventA.Contains(data.Event1Id), "the second row should still stay in the grid");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void Navigation(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var criteria = criteriaBuilder.Create();
                var evt = eventBuilder.Create();
                var fromEvent1 = eventBuilder.Create("from-event1");
                var fromEvent2 = eventBuilder.Create("from-event2");
                var fromEvent3 = eventBuilder.Create("from-event3");

                var importance = importanceBuilder.Create();
                setup.Insert(new ValidEvent(criteria, evt, "event1")
                {
                    NumberOfCyclesAllowed = 2,
                    Importance = importance
                });

                setup.Insert(new DueDateCalc
                {
                    Sequence = 0,
                    Comparison = ">",
                    CriteriaId = criteria.Id,
                    EventId = evt.Id,
                    FromEventId = fromEvent1.Id
                });

                setup.Insert(new DueDateCalc
                {
                    Sequence = 1,
                    Comparison = "<",
                    CriteriaId = criteria.Id,
                    EventId = evt.Id,
                    FromEventId = fromEvent2.Id,
                    RelativeCycle = 1
                });

                setup.Insert(new DueDateCalc
                {
                    Sequence = 2,
                    Comparison = "=",
                    CriteriaId = criteria.Id,
                    EventId = evt.Id,
                    FromEventId = fromEvent3.Id,
                    RelativeCycle = 1
                });

                return new
                {
                    CriteriaId = criteria.Id.ToString(),
                    EventId = evt.Id.ToString(),
                    FromEvent1 = fromEvent1,
                    FromEvent2 = fromEvent2,
                    FromEvent3 = fromEvent3
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DateComparison.NavigateTo();
            eventControlPage.DateComparison.Grid.ClickEdit(0);

            var modal = new DateComparisonModal(driver);

            Assert.AreEqual($"({data.FromEvent1.Id}) {data.FromEvent1.Description}", modal.EventA.InputValue);

            modal.NavigateToLast();

            Assert.AreEqual($"({data.FromEvent3.Id}) {data.FromEvent3.Description}", modal.EventA.InputValue);

            modal.NavigateToPrevious();

            Assert.AreEqual($"({data.FromEvent2.Id}) {data.FromEvent2.Description}", modal.EventA.InputValue);
        }
    }
}
