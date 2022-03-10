using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.BatchEventUpdate.Miscellaneous;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Cases.Events
{
    public class AvailableEventModelBuilder : IBuilder<AvailableEventModel>
    {
        public DataEntryTask DataEntryTask { get; set; }
        public CaseEvent CaseEvent { get; set; }
        public AvailableEvent AvailableEvent { get; set; }
        public Event Event { get; set; }
        public string SiteDateFormat { get; set; }

        public AvailableEventModel Build()
        {
            var @event = Event ?? new EventBuilder().Build();

            return new AvailableEventModel(
                                           AvailableEvent ?? new AvailableEventBuilder
                                           {
                                               DataEntryTask = DataEntryTask ?? new DataEntryTaskBuilder().Build(),
                                               Event = @event
                                           }.Build(),
                                           CaseEvent ?? new CaseEventBuilder
                                           {
                                               EventNo = @event.Id
                                           }.Build(),
                                           @event.Description);
        }
    }
}