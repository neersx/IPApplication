using System;
using System.Linq;
using Dependable.Dispatcher;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public interface IFailedSendingDocumentToDms
    {
        void Fail(ExceptionContext ex, int documentId);
    }

    public class DocumentSendToDmsFailure : IFailedSendingDocumentToDms
    {
        readonly IRepository _repository;
        readonly Func<DateTime> _now;
        readonly ILogEntry _logEntry;

        public DocumentSendToDmsFailure(IRepository repository, Func<DateTime> now, ILogEntry logEntry)
        {
            _now = now;
            _repository = repository;
            _logEntry = logEntry;
        }

        public void Fail(ExceptionContext ex, int documentId)
        {
            // update the status to failed and set the document error field
            var document = _repository.Set<Document>().SingleOrDefault(d => d.Id == documentId);
            if (document == null) return;

            document.Status = DocumentDownloadStatus.FailedToSendToDms;
            document.Errors = _logEntry.Create(ex, LogEntryCategory.DmsIntegrationError).ToString(Formatting.None);
            document.UpdatedOn = _now();
            _repository.SaveChanges();
        }
    }
}