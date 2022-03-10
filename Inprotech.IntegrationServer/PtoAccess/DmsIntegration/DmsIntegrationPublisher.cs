using System;
using Inprotech.Contracts.Messages.PtoAccess.DmsIntegration;
using Inprotech.Infrastructure.Messaging;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public interface IDmsIntegrationPublisher
    {
        void Publish(DmsIntegrationMessage message);
    }

    public class DmsIntegrationPublisher : IDmsIntegrationPublisher
    {
        readonly IBus _bus;

        public DmsIntegrationPublisher(IBus bus)
        {
            _bus = bus;
        }

        public void Publish(DmsIntegrationMessage message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            _bus.Publish(message);
        }
    }
}
