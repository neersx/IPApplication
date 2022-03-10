using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SatisfyingEvents : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddSatisfyingEvent(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var vEvent = eventBuilder.Create("Event");
                var satisfyingEvent = eventBuilder.Create("EventA", 2);
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

                setup.Insert(new ValidEvent(criteria, satisfyingEvent, "SatisfyingEvent"));

                return new
                {
                    Event = vEvent.Description,
                    EventId = vEvent.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    SatisfyingEvent = satisfyingEvent.Description,
                    SatisfyingEventId = satisfyingEvent.Id
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);

            eventControlPage.SatisfyingEvents.NavigateTo();
            eventControlPage.SatisfyingEvents.Add();

            Assert.AreEqual(1, eventControlPage.SatisfyingEvents.GridRowsCount, "New Row Added");

            eventControlPage.SatisfyingEvents.EventPicklist.EnterAndSelect(data.SatisfyingEventId.ToString());
            Assert.AreEqual("0", eventControlPage.SatisfyingEvents.RelativeCycleDropDown.Value);
            eventControlPage.SatisfyingEvents.RelativeCycleDropDown.Input.SelectByText("Highest Cycle");

            eventControlPage.Save();

            eventControlPage.SatisfyingEvents.NavigateTo();
            Assert.AreEqual($"({data.SatisfyingEventId}) {data.SatisfyingEvent}", eventControlPage.SatisfyingEvents.EventPicklist.InputValue);
            Assert.AreEqual("Highest Cycle", eventControlPage.SatisfyingEvents.RelativeCycleDropDown.Text);

            eventControlPage.SatisfyingEvents.Add();
            eventControlPage.SatisfyingEvents.NewlyAddedEventPicklist().EnterAndSelect(data.SatisfyingEventId.ToString());
            eventControlPage.SatisfyingEvents.RelativeCycleDropDown.Input.SelectByText("Current Cycle");
            var error = driver.FindElements(By.ClassName("cpa-icon-exclamation-triangle")).First();
            Assert.True(error.Displayed, "Expect duplicates to be flagged.");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateSatisfyingEvent(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var vEvent = eventBuilder.Create("Event");
                var satisfyingEvent = eventBuilder.Create("Satisfy", 2);
                var updateSatisfyingEvent = eventBuilder.Create("NewSatisfy", 1);
                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, vEvent, "Apple")
                {
                    NumberOfCyclesAllowed = 1,
                    Importance = importance
                };
                setup.Insert(validEvent);
                setup.Insert(new RelatedEventRule(validEvent, 0) { IsSatisfyingEvent = true, RelatedEventId = satisfyingEvent.Id, RelativeCycleId = 0 });

                setup.Insert(new ValidEvent(criteria, satisfyingEvent, "SatisfyingEvent"));
                setup.Insert(new ValidEvent(criteria, updateSatisfyingEvent, "NewSatisfyingEvent"));

                return new
                {
                    Event = vEvent.Description,
                    EventId = vEvent.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    SatisfyingEvent = satisfyingEvent.Description,
                    SatisfyingEventId = satisfyingEvent.Id,
                    NewSatisfyingEvent = updateSatisfyingEvent.Description,
                    NewSatisfyingEventId = updateSatisfyingEvent.Id
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.SatisfyingEvents.NavigateTo();

            eventControlPage.SatisfyingEvents.EventPicklist.EnterAndSelect(data.NewSatisfyingEventId.ToString());
            Assert.AreEqual("3", eventControlPage.SatisfyingEvents.RelativeCycleDropDown.Value);
            Assert.AreEqual(data.NewSatisfyingEventId.ToString(), eventControlPage.SatisfyingEvents.GetEventNo(0), "Updates event no. column");
            eventControlPage.SatisfyingEvents.RelativeCycleDropDown.Input.SelectByText("Highest Cycle");

            eventControlPage.Save();

            eventControlPage.SatisfyingEvents.NavigateTo();
            Assert.AreEqual($"({data.NewSatisfyingEventId}) {data.NewSatisfyingEvent}", eventControlPage.SatisfyingEvents.EventPicklist.InputValue);
            Assert.AreEqual("Highest Cycle", eventControlPage.SatisfyingEvents.RelativeCycleDropDown.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteSatisfyingEvent(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {

                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var vEvent = eventBuilder.Create("Event");
                var satisfyingEvent = eventBuilder.Create("Satisfy", 2);
                var satisfyingEvent1 = eventBuilder.Create("Satisfy1", 1);
                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, vEvent, "Apple")
                {
                    NumberOfCyclesAllowed = 1,
                    Importance = importance
                };
                setup.Insert(validEvent);
                setup.Insert(new RelatedEventRule(validEvent, 0) { IsSatisfyingEvent = true, RelatedEventId = satisfyingEvent.Id, RelativeCycleId = 0 });
                setup.Insert(new RelatedEventRule(validEvent, 1) { IsSatisfyingEvent = true, RelatedEventId = satisfyingEvent1.Id, RelativeCycleId = 3 });

                return new
                {
                    EventId = vEvent.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    NotDeleted = satisfyingEvent1.Description,
                    NotDeletedId = satisfyingEvent1.Id
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);

            eventControlPage.SatisfyingEvents.NavigateTo();
            eventControlPage.SatisfyingEvents.Grid.ToggleDelete(0);

            eventControlPage.Save();

            eventControlPage.SatisfyingEvents.NavigateTo();
            Assert.AreEqual(1, eventControlPage.SatisfyingEvents.GridRowsCount, "only deletes the first row which was marked as deleted");
            Assert.AreEqual($"({data.NotDeletedId}) {data.NotDeleted}", eventControlPage.SatisfyingEvents.EventPicklist.InputValue, "the non deleted row should still stay in the grid");

        }
    }
}
