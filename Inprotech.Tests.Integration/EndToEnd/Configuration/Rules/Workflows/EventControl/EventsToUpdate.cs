using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EventsToUpdate : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddEventToUpdate(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var evt = eventBuilder.Create();
                var eventToUpdate = eventBuilder.Create("clear", 2);
                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();
                var adjustDate = setup.InsertWithNewId(new DateAdjustment { Description = Fixture.Prefix("test") });

                var validEvent = new ValidEvent(criteria, evt, "Apple")
                {
                    Inherited = 1,
                    NumberOfCyclesAllowed = 1,
                    Importance = importance,
                    DatesLogicComparison = 0
                };

                setup.Insert(validEvent);

                setup.Insert(new ValidEvent(criteria, eventToUpdate, "EventToUpdate"));

                return new
                {
                    EventId = evt.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    UpdateEvent = eventToUpdate.Description,
                    UpdateEventId = eventToUpdate.Id.ToString(),
                    AdjustDate = adjustDate.Description
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            var topic = eventControlPage.EventsToUpdate;

            topic.NavigateTo();
            topic.Add();

            Assert.AreEqual(1, topic.GridRowsCount, "New Row Added");

            topic.EventPicklist.EnterAndSelect(data.UpdateEventId.ToString());
            topic.RelativeCycleDropDown.Input.SelectByText("Highest Cycle");
            topic.AdjustDateDropDown.Input.SelectByText(data.AdjustDate);
            eventControlPage.Save();

            topic.NavigateTo();

            Assert.AreEqual($"({data.UpdateEventId}) {data.UpdateEvent}", topic.Event);
            Assert.AreEqual(data.UpdateEventId, topic.EventNo);
            Assert.AreEqual("Highest Cycle", topic.RelativeCycleDropDown.Text);       
            Assert.AreEqual(data.AdjustDate, topic.AdjustDateDropDown.Text);     
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateEventToClear(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);                
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                var validEventBuilder = new ValidEventBuilder(setup.DbContext);

                var evt = eventBuilder.Create();
                var criteria = criteriaBuilder.Create();
                var validEvent = validEventBuilder.Create(criteria, evt);

                setup.Insert(new RelatedEventRule(validEvent, 0)
                {
                    RelatedEventId = evt.Id,
                    RelativeCycleId = 0,
                    UpdateEvent = 1
                });
                
                return new
                {
                    EventId = evt.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    UpdateEvent = evt.Description,
                    UpdateEventId = evt.Id
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            var topic = eventControlPage.EventsToUpdate;

            topic.NavigateTo();

            topic.RelativeCycleDropDown.Input.SelectByText("Highest Cycle");            

            eventControlPage.Save();

            topic.NavigateTo();

            Assert.AreEqual("Highest Cycle", topic.RelativeCycleDropDown.Text);            
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteEventToClear(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                var validEventBuilder = new ValidEventBuilder(setup.DbContext);

                var evt = eventBuilder.Create();
                var eventToClear1 = eventBuilder.Create();
                var eventToClear2 = eventBuilder.Create("clear2");
                var criteria = criteriaBuilder.Create();
                var validEvent = validEventBuilder.Create(criteria, evt);
                
                setup.Insert(new RelatedEventRule(validEvent, 0)
                {
                    RelatedEventId = eventToClear1.Id,
                    RelativeCycleId = 0,
                    UpdateEvent = 1
                });

                setup.Insert(new RelatedEventRule(validEvent, 1)
                {
                    RelatedEventId = eventToClear2.Id,
                    RelativeCycleId = 0,
                    UpdateEvent = 1
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
            var topic = eventControlPage.EventsToUpdate;

            topic.NavigateTo();

            topic.Grid.ToggleDelete(0);

            eventControlPage.Save();

            topic.NavigateTo();
            Assert.AreEqual(1, topic.GridRowsCount, "only deletes the first row which was marked as deleted");
            Assert.AreEqual($"({data.NotDeletedId}) {data.NotDeleted}", topic.EventPicklist.InputValue, "the non deleted row should still stay in the grid");
        }
    }
}
