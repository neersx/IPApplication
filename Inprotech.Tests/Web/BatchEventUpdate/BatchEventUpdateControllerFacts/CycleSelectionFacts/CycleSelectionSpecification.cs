using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    CycleSelectionFacts
{
    public class CycleSelectionFixture : BatchEventUpdateControllerFixture
    {
        public CycleSelectionFixture(InMemoryDbContext db) : base(db)
        {
            ExistingDataEntryTask = ExistingOpenAction.Criteria.DataEntryTasks.First();

            NextRenewalDateEvent = EventBuilder
                                   .ForCyclicEvent(3).Build().In(db);

            OtherCyclicEvent = EventBuilder
                               .ForCyclicEvent(2).Build().In(db);

            OtherNonCyclicEvent = EventBuilder
                                  .ForNonCyclicEvent().Build().In(db);

            ExistingDataEntryTask.AvailableEvents.Clear();
            ExistingDataEntryTask.AvailableEvents.Add(
                                                      new AvailableEventBuilder
                                                      {
                                                          DataEntryTask = ExistingDataEntryTask,
                                                          Event = NextRenewalDateEvent,
                                                          EventAttribute = EntryAttribute.DefaultToSystemDate,
                                                          DisplaySequence = 0
                                                      }.Build().In(db));

            ExistingDataEntryTask.AvailableEvents.Add(
                                                      new AvailableEventBuilder
                                                      {
                                                          DataEntryTask = ExistingDataEntryTask,
                                                          Event = OtherCyclicEvent,
                                                          EventAttribute = EntryAttribute.DefaultToSystemDate,
                                                          DisplaySequence = 1
                                                      }.Build().In(db));

            ExistingDataEntryTask.AvailableEvents.Add(
                                                      new AvailableEventBuilder
                                                      {
                                                          DataEntryTask = ExistingDataEntryTask,
                                                          Event = OtherNonCyclicEvent,
                                                          EventAttribute = EntryAttribute.DefaultToSystemDate,
                                                          DisplaySequence = 2
                                                      }.Build().In(db));

            RequestModel = new CycleSelectionRequestModel
            {
                TempStorageId = TempStorageId,
                CriteriaId = ExistingDataEntryTask.Criteria.Id,
                DataEntryTaskId = ExistingDataEntryTask.Id
            };
        }

        public CycleSelectionModel Result { get; set; }
        public DataEntryTask ExistingDataEntryTask { get; }
        public Event NextRenewalDateEvent { get; }
        protected Event OtherNonCyclicEvent { get; }
        public Event OtherCyclicEvent { get; }
        public CycleSelectionRequestModel RequestModel { get; }

        public async Task Run()
        {
            try
            {
                Result = await Subject.CycleSelection(RequestModel);
            }
            catch (Exception ex)
            {
                Exception = ex;
            }
        }
    }
}