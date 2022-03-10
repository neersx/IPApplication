using System;
using Inprotech.Contracts;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public interface IDataExtractionLogger : ILogger
    {

    }
    public class DataExtractionLogger : IDataExtractionLogger
    {
        readonly IBackgroundProcessLogger<DataExtractionLogger> _logger;

        public DataExtractionLogger(IBackgroundProcessLogger<DataExtractionLogger> logger)
        {
            _logger = logger;
        }

        public void SetContext(Guid contextId)
        {
        }

        public void Trace(string message, object data = null)
        {
            _logger.Trace(message, data);
        }

        public void Debug(string message, object data = null)
        {
            _logger.Debug(message, data);
        }

        public void Information(string message, object data = null)
        {
            _logger.Information(message, data);
        }

        public void Warning(string message, object data = null)
        {
            _logger.Warning(message, data);
        }
        
        public void Exception(Exception exception, string message = null)
        {
            _logger.Exception(exception, message);
        }
    }
}
