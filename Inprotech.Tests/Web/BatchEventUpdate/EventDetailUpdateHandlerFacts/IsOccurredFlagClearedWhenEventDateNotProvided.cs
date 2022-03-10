using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using InprotechKaizen.Model.Documents;
using Xunit;
using AvailableEventModelBuilder = Inprotech.Tests.Web.BatchEventUpdate.DataEntryTaskHandlersFacts.AvailableEventModelBuilder;

namespace Inprotech.Tests.Web.BatchEventUpdate.EventDetailUpdateHandlerFacts
{
    public class IsOccurredFlagDependsOnEventDate : FactBase
    {
        [Fact]
        public void IsOccurredFlagClearedWhenEventDateNotProvided()
        {
            var fixture = new EventDetailUpdateHandlerFixture(Db);

            var event1 = new EventBuilder().Build().In(Db);
            var availableEvent1 = new AvailableEventBuilder {Event = event1, DataEntryTask = fixture.ExistingDataEntryTask}.Build().In(Db);
           
            fixture.ExistingDataEntryTask.AvailableEvents.Add(availableEvent1);

            var availableEvents = new[]
            {
                new AvailableEventModelBuilder
                {
                    AvailableEvent = availableEvent1,
                    Event = event1,
                    DataEntryTask = fixture.ExistingDataEntryTask,
                }.Build()
            }.In(Db);
            var eventDate = availableEvents[0].EventDate;
            fixture.ExistingCase.CaseEvents.Add(new CaseEventBuilder
            {
                EventNo = availableEvents[0].EventId,
                Cycle = availableEvents[0].Cycle,
                EventDate = eventDate,
                IsOccurredFlag = 1
            }.Build());

            availableEvents[0].EventDate = null;
            availableEvents[0].EventText = string.Empty;
            
            var documents = new List<Document>().ToArray();
            fixture.Subject.ApplyChanges(fixture.ExistingCase,
                                                                fixture.ExistingDataEntryTask,
                                                                Fixture.String(),
                                                                null,
                                                                Fixture.Today(),
                                                                availableEvents,
                                                                documents);

            Assert.Null(fixture.ExistingCase.CaseEvents.First().IsOccurredFlag);
        }

        [Fact]
        public void IsOccurredFlagNotClearedWhenEventDateProvided()
        {
            var fixture = new EventDetailUpdateHandlerFixture(Db);

            var event1 = new EventBuilder().Build().In(Db);
            var availableEvent1 = new AvailableEventBuilder {Event = event1, DataEntryTask = fixture.ExistingDataEntryTask}.Build().In(Db);
           
            fixture.ExistingDataEntryTask.AvailableEvents.Add(availableEvent1);

            var availableEvents = new[]
            {
                new AvailableEventModelBuilder
                {
                    AvailableEvent = availableEvent1,
                    Event = event1,
                    DataEntryTask = fixture.ExistingDataEntryTask,
                }.Build()
            }.In(Db);
            var eventDate = availableEvents[0].EventDate;
            fixture.ExistingCase.CaseEvents.Add(new CaseEventBuilder
            {
                EventNo = availableEvents[0].EventId,
                Cycle = availableEvents[0].Cycle,
                EventDate = eventDate,
                IsOccurredFlag = 1
            }.Build());

            availableEvents[0].EventDate =Fixture.FutureDate();
            availableEvents[0].EventText = Fixture.String();
            
            var documents = new List<Document>().ToArray();
            fixture.Subject.ApplyChanges(fixture.ExistingCase,
                                                                fixture.ExistingDataEntryTask,
                                                                Fixture.String(),
                                                                null,
                                                                Fixture.Today(),
                                                                availableEvents,
                                                                documents);

            Assert.NotNull(fixture.ExistingCase.CaseEvents.First().IsOccurredFlag);
        }
    }
}
