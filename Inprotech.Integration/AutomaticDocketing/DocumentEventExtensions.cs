using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.Documents;

namespace Inprotech.Integration.AutomaticDocketing
{
    public static class DocumentEventExtensions
    {
        public static IEnumerable<Document> WithStatus(this IEnumerable<Document> documents, params DocumentEventStatus[] statuses)
        {
            if (documents == null) throw new ArgumentNullException("documents");
            return documents.WithDocumentEvents().Where(_ => statuses.Contains(_.DocumentEvent.Status));
        }
        
        public static bool HasPendingEventToProcess(this IEnumerable<Document> documents)
        {
            if (documents == null) throw new ArgumentNullException("documents");
            return documents.WithDocumentEvents().Any(_ => _.DocumentEvent.Status == DocumentEventStatus.Pending);
        }

        public static bool HasPendingEventToProcess(this Document document)
        {
            if (document == null) throw new ArgumentNullException("document");
            
            return document.DocumentEvent != null && document.DocumentEvent.Status == DocumentEventStatus.Pending;
        }

        public static IEnumerable<Document> WithDocumentEvents(this IEnumerable<Document> documents)
        {
            return documents.Where(_ => _.DocumentEvent != null);
        }
    }
}
