using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EventsToClear : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddEventToClear(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var evt = eventBuilder.Create();
                var eventToClear = eventBuilder.Create("clear", 2);
                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, evt, "Apple")
                {
                    Inherited = 1,
                    NumberOfCyclesAllowed = 1,
                    Importance = importance,
                    DatesLogicComparison = 0
                };

                setup.Insert(validEvent);

                setup.Insert(new ValidEvent(criteria, eventToClear, "EventToClear"));

                return new
                {
                    EventId = evt.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    UpdateEvent = eventToClear.Description,
                    UpdateEventId = eventToClear.Id
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            var topic = eventControlPage.EventsToClear;

            topic.NavigateTo();
            topic.Add();

            Assert.AreEqual(1, topic.GridRowsCount, "New Row Added");

            topic.EventPicklist.EnterAndSelect(data.UpdateEventId.ToString());           
            topic.RelativeCycleDropDown.Input.SelectByText("Highest Cycle");

            Assert.IsTrue(topic.ClearEventOnEventChange.IsChecked, "Clear Event ticked by default.");

            topic.ClearEventOnEventChange.Click();
            topic.ClearDueDateOnEventChange.Click();
            topic.ClearEventOnDueDateChange.Click();
            topic.ClearDueDateOnDueDateChange.Click();
            eventControlPage.Save();

            topic.NavigateTo();

            Assert.AreEqual($"({data.UpdateEventId}) {data.UpdateEvent}", topic.EventPicklist.InputValue, "Event To Clear added.");
            Assert.AreEqual("Highest Cycle", topic.RelativeCycleDropDown.Text, "Event To Clear added.");
            Assert.IsFalse(topic.ClearEventOnEventChange.IsChecked, "Event To Clear added.");
            Assert.IsTrue(topic.ClearDueDateOnEventChange.IsChecked);
            Assert.IsTrue(topic.ClearEventOnDueDateChange.IsChecked);
            Assert.IsTrue(topic.ClearDueDateOnDueDateChange.IsChecked);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateEventToClear(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var evt = eventBuilder.Create();
                var eventToClear = eventBuilder.Create("clear", 2);
                var criteria = criteriaBuilder.Create();
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, evt, "Apple")
                {
                    Inherited = 1,
                    NumberOfCyclesAllowed = 1,
                    Importance = importance,
                    DatesLogicComparison = 0
                };

                setup.Insert(validEvent);
                setup.Insert(new RelatedEventRule(validEvent, 0)
                {
                    RelatedEventId = eventToClear.Id,
                    RelativeCycleId = 0,
                    ClearDue = 1
                });

                setup.Insert(new ValidEvent(criteria, eventToClear, "EventToClear"));

                return new
                {
                    EventId = evt.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    UpdateEvent = eventToClear.Description,
                    UpdateEventId = eventToClear.Id
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            var topic = eventControlPage.EventsToClear;

            topic.NavigateTo();

            topic.RelativeCycleDropDown.Input.SelectByText("Highest Cycle");
            topic.ClearEventOnEventChange.Click();
            topic.ClearDueDateOnEventChange.Click();
            topic.ClearEventOnDueDateChange.Click();
            topic.ClearDueDateOnDueDateChange.Click();

            eventControlPage.Save();

            topic.NavigateTo();

            Assert.AreEqual("Highest Cycle", topic.RelativeCycleDropDown.Text);
            Assert.IsTrue(topic.ClearEventOnEventChange.IsChecked);
            Assert.IsFalse(topic.ClearDueDateOnEventChange.IsChecked);
            Assert.IsTrue(topic.ClearEventOnDueDateChange.IsChecked);
            Assert.IsTrue(topic.ClearDueDateOnDueDateChange.IsChecked);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteEventToClear(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var evt = eventBuilder.Create();
                var eventToClear1 = eventBuilder.Create();
                var eventToClear2 = eventBuilder.Create("clear2");
                var criteria = criteriaBuilder.Create();
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, evt, "Apple")
                {
                    Inherited = 1,
                    NumberOfCyclesAllowed = 1,
                    Importance = importance,
                    DatesLogicComparison = 0
                };

                setup.Insert(validEvent);
                setup.Insert(new RelatedEventRule(validEvent, 0)
                {
                    RelatedEventId = eventToClear1.Id,
                    RelativeCycleId = 0,
                    ClearDue = 1
                });

                setup.Insert(new RelatedEventRule(validEvent, 1)
                {
                    RelatedEventId = eventToClear2.Id,
                    RelativeCycleId = 0,
                    ClearDue = 1
                });

                return new
                {
                    EventId = evt.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    NotDeleted = eventToClear2.Description,
                    NotDeletedId = eventToClear2.Id
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            var topic = eventControlPage.EventsToClear;

            topic.NavigateTo();

            topic.Grid.ToggleDelete(0);

            eventControlPage.Save();

            topic.NavigateTo();
            Assert.AreEqual(1, topic.GridRowsCount, "only deletes the first row which was marked as deleted");
            Assert.AreEqual($"({data.NotDeletedId}) {data.NotDeleted}", topic.EventPicklist.InputValue, "the non deleted row should still stay in the grid");

        }
    }
}
