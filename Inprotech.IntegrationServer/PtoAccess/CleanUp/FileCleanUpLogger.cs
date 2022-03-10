using System;
using Inprotech.Contracts;
using Inprotech.Contracts.Messages.PtoAccess.CleanUp;
using Inprotech.Infrastructure.Messaging;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public class FileCleanUpLogger : IHandle<CleanedUp>, IHandle<FileCleanUpFailedBase>
    {
        readonly IBackgroundProcessLogger<FileCleanUpLogger> _logger;

        public FileCleanUpLogger(IBackgroundProcessLogger<FileCleanUpLogger> logger)
        {
            _logger = logger;
        }

        public void Handle(CleanedUp message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            var sessionGuid = message.SessionGuid != Guid.Empty ? string.Format(" for session {0}", message.SessionGuid) : string.Empty;
            var msg = $"{message.GetType().Name} - \"{message.Path}\"{sessionGuid} because {message.Reason}";
            _logger.Information(msg);
        }

        public void Handle(FileCleanUpFailedBase message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            var sessionGuid = message.SessionGuid != Guid.Empty ? $" for session {message.SessionGuid}" : string.Empty;
            var msg = $"{message.GetType().Name} - \"{message.Path}\"{sessionGuid} because {message.Reason}, exception: {message.Exception.Message}";
            _logger.Information(msg, message.Exception);
        }
    }
}