using System;
using Dependable.Dispatcher;
using Inprotech.Integration.Artifacts;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public class ErrorLogger
    {
        readonly ILogEntry _logEntry;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;

        public ErrorLogger(ILogEntry logEntry, IDataDownloadLocationResolver dataDownloadLocationResolver)
        {
            _logEntry = logEntry;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
        }

        public void LogContextError(ExceptionContext exceptionContext, DataDownload dataDownload, string context)
        {
            LogInternal(exceptionContext, dataDownload, context);
        }

        public void Log(ExceptionContext exceptionContext, DataDownload dataDownload)
        {
            LogInternal(exceptionContext, dataDownload);
        }

        void LogInternal(ExceptionContext exceptionContext, DataDownload dataDownload, string context = null)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var logfile = string.IsNullOrEmpty(context) ? _logEntry.NewLog(string.Empty) : _logEntry.NewContextLog(context, string.Empty);
            var p = _dataDownloadLocationResolver.ResolveForErrorLog(dataDownload, logfile);

            _logEntry.Create(exceptionContext, p);
        }
    }
}
