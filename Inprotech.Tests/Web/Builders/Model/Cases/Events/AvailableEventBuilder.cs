using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Cases.Events
{
    public class AvailableEventBuilder : IBuilder<AvailableEvent>
    {
        public DataEntryTask DataEntryTask { get; set; }
        public Event Event { get; set; }
        public Event AlsoUpdateEvent { get; set; }
        public EntryAttribute? EventAttribute { get; set; }
        public EntryAttribute? EventDueAttribute { get; set; }
        public short? DisplaySequence { get; set; }
        public bool? IsInherited { get; set; }

        public AvailableEvent Build()
        {
            var dataEntryTask = DataEntryTask ?? new DataEntryTaskBuilder().Build();
            var ae = new AvailableEvent(dataEntryTask, Event ?? new EventBuilder().Build(), AlsoUpdateEvent);
            if (EventAttribute.HasValue) ae.EventAttribute = (short) EventAttribute.Value;
            if (EventDueAttribute.HasValue) ae.DueAttribute = (short) EventDueAttribute.Value;
            if (DisplaySequence.HasValue) ae.DisplaySequence = DisplaySequence;
            if (IsInherited.HasValue) ae.IsInherited = IsInherited.Value;
            return ae;
        }

        public static AvailableEventBuilder For(DataEntryTask dataEntryTask)
        {
            return new AvailableEventBuilder {DataEntryTask = dataEntryTask};
        }
    }

    public static class AvailableEventBuilderEx
    {
        public static AvailableEventBuilder With(this AvailableEventBuilder builder, Event @event)
        {
            builder.Event = @event;
            return builder;
        }
    }
}