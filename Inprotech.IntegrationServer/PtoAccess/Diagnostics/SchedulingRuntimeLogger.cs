using System;
using Dependable.Diagnostics;
using Inprotech.Integration.Diagnostics.PtoAccess;

namespace Inprotech.IntegrationServer.PtoAccess.Diagnostics
{
    public class SchedulingRuntimeLogger : IExceptionLogger
    {
        readonly IDataExtractionLogger _dataExtractionLogger;

        public SchedulingRuntimeLogger(IDataExtractionLogger dataExtractionLogger)
        {
            _dataExtractionLogger = dataExtractionLogger;
        }

        public void Log(Exception exception)
        {
            _dataExtractionLogger.Exception(exception);
        }
    }
}