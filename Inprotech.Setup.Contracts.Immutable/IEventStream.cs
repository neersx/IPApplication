namespace Inprotech.Setup.Contracts.Immutable
{
    public interface IEventStream
    {
        void Publish(Event actionEvent);        
    }

    public static class EventStreamExtensions
    {
        public static void Publish(this IEventStream eventStream, EventType eventType, string message)
        {
            eventStream.Publish(new Event
                                 {
                                     Type = eventType,
                                     Details = message
                                 });
        }

        public static void PublishInformation(this IEventStream eventStream, string message)
        {
            eventStream.Publish(EventType.Information, message);
        }
        
        public static void PublishWarning(this IEventStream eventStream, string message)
        {
            eventStream.Publish(EventType.Warning, message);
        }

        public static void PublishError(this IEventStream eventStream, string message)
        {
            eventStream.Publish(EventType.Error, message);
        }
    }
}