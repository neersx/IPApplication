using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core
{
    public class NullEventStream : IEventStream
    {
        public void Publish(Event actionEvent)
        {
        }
    }
}