using Dependable.Dispatcher;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Innography.PrivatePair;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface IPtoFailureLogger
    {
        void LogSessionError(ExceptionContext context, Session session);

        void LogApplicationDownloadError(ExceptionContext context, ApplicationDownload application);

        void LogDocumentDownloadError(ExceptionContext context, ApplicationDownload application, LinkInfo info);

    }
    public class PtoFailureLogger : IPtoFailureLogger
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly ILogEntry _logEntry;
        readonly IFileNameExtractor _fileNameExtractor;

        public PtoFailureLogger(IArtifactsLocationResolver artifactsLocationResolver, ILogEntry logEntry,IFileNameExtractor fileNameExtractor)
        {
            _artifactsLocationResolver = artifactsLocationResolver;
            _logEntry = logEntry;
            _fileNameExtractor = fileNameExtractor;
        }

        public void LogSessionError(ExceptionContext context, Session session)
        {
            var p = _artifactsLocationResolver.Resolve(session, _logEntry.NewLog());
            _logEntry.Create(context, p, LogEntryCategory.PtoAccessError);
        }

        public void LogApplicationDownloadError(ExceptionContext context, ApplicationDownload application)
        {
            var p = _artifactsLocationResolver.Resolve(application, _logEntry.NewLog());
            _logEntry.Create(context, p, LogEntryCategory.PtoAccessError);
        }

        public void LogDocumentDownloadError(ExceptionContext context, ApplicationDownload application,LinkInfo info)
        {
            var p = _artifactsLocationResolver.Resolve(application, _logEntry.NewContextLog(_fileNameExtractor.AbsoluteUriName(info.Link)));
            _logEntry.Create(context, p, LogEntryCategory.PtoAccessError);
        }
    }
}