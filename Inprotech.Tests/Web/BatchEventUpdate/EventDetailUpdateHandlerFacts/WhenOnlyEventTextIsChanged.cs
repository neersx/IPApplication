using System;
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
    public class WhenOnlyEventTextIsChanged : FactBase
    {
        [Fact]
        public void Policing_Request_Not_Generated()
        {
            var fixture = new EventDetailUpdateHandlerFixture(Db);

            var event1 = new EventBuilder().Build().In(Db);
            var event2 = new EventBuilder().Build().In(Db);

            var availableEvent1 = new AvailableEventBuilder {Event = event1, DataEntryTask = fixture.ExistingDataEntryTask}.Build().In(Db);
            var availableEvent2 = new AvailableEventBuilder {Event = event2, DataEntryTask = fixture.ExistingDataEntryTask}.Build().In(Db);

            fixture.ExistingDataEntryTask.AvailableEvents.Add(availableEvent1);
            fixture.ExistingDataEntryTask.AvailableEvents.Add(availableEvent2);

            var availableEvents = new[]
            {
                new AvailableEventModelBuilder
                {
                    AvailableEvent = availableEvent1,
                    Event = event1,
                    DataEntryTask = fixture.ExistingDataEntryTask
                }.Build(),
                new AvailableEventModelBuilder
                {
                    AvailableEvent = availableEvent2,
                    Event = event2,
                    DataEntryTask = fixture.ExistingDataEntryTask
                }.Build()
            }.In(Db);

            availableEvents[0].DueDate = DateTime.Today.AddDays(10);
            availableEvents[0].EventText = string.Empty;

            fixture.ExistingCase.CaseEvents.Add(new CaseEventBuilder
            {
                EventNo = availableEvents[0].EventId,
                Cycle = availableEvents[0].Cycle,
                DueDate = availableEvents[0].DueDate,
                IsDateDueSaved = 1
            }.Build());

            var documents = new List<Document>().ToArray();
            fixture.ExistingCase.CaseEvents.First(v => v.EventNo == availableEvents[0].EventId).EventText = Fixture.String();

            var policingRequests = fixture.Subject.ApplyChanges(fixture.ExistingCase,
                                                                fixture.ExistingDataEntryTask,
                                                                Fixture.String(),
                                                                null,
                                                                Fixture.Today(),
                                                                availableEvents,
                                                                documents);

            Assert.False(policingRequests.Requests.Any());
        }
    }
}