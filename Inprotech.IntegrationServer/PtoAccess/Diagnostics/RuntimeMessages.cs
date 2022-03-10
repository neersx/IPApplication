using System;
using Inprotech.Integration.Diagnostics.PtoAccess;

namespace Inprotech.IntegrationServer.PtoAccess.Diagnostics
{
    public interface IRuntimeMessages
    {
        void Display(string message);

        void Warn(string message, object data = null);
    }
    public class RuntimeMessages : IRuntimeMessages
    {
        readonly IDataExtractionLogger _logger;

        public RuntimeMessages(IDataExtractionLogger logger)
        {
            _logger = logger;
        }

        public void Display(string message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));
            _logger.Information(message);
        }

        public void Warn(string message, object data = null)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));
            _logger.Warning(message, data);
        }
    }
}
