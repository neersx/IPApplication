using System;
using Inprotech.Contracts;
using Inprotech.Contracts.Messages.PtoAccess.DmsIntegration;
using Inprotech.Infrastructure.Messaging;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public class DmsIntegrationLogger : IHandle<DmsIntegrationMessage>, IHandle<DmsIntegrationFailedMessage>
    {
        readonly IBackgroundProcessLogger<DmsIntegrationLogger> _logger;

        public DmsIntegrationLogger(IBackgroundProcessLogger<DmsIntegrationLogger> logger)
        {
            _logger = logger;
        }

        public void Handle(DmsIntegrationMessage message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            _logger.Information(message.MessageId + " " + message.Message, message);
        }

        public void Handle(DmsIntegrationFailedMessage message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            _logger.Exception(message.Exception);
        }
    }
}
