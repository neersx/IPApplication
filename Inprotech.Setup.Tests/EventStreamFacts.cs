using Inprotech.Setup.Contracts.Immutable;
using Xunit;

namespace Inprotech.Setup.Tests
{
    public class EventStreamFacts
    {
        [Fact]
        public void ShouldInvokeTheCurrentListener()
        {
            Event receivedEvent = null;
            var eventStream = new EventStream();
            eventStream.EventReveived += e => receivedEvent = e;
            var publishedEvent = new Event {Type = EventType.Information, Details = "a"};

            eventStream.Publish(publishedEvent);

            Assert.Equal(publishedEvent, receivedEvent);
        }

        [Fact]
        public void ShouldNotFailWhenThereIsNoListener()
        {
            new EventStream().Publish(new Event {Type = EventType.Information, Details = "a"});
        }
    }
}