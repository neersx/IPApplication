using System;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration.AutomaticDocketing;

namespace Inprotech.IntegrationServer.PtoAccess.Diagnostics
{
    public class BackgroundAutomationLogger : IHandle<BackgroundDocumentMappingFailed>
    {
        readonly IBackgroundProcessLogger<BackgroundAutomationLogger> _logger;

        public BackgroundAutomationLogger(IBackgroundProcessLogger<BackgroundAutomationLogger> logger)
        {
            _logger = logger;
        }

        public void Handle(BackgroundDocumentMappingFailed message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            _logger.Information($"Failed mapping {message.Description} in {message.Structure} for {message.Structure}.");
        }
    }
}
