using System;

namespace Inprotech.Contracts.Messages.PtoAccess.DmsIntegration
{
    public class DmsIntegrationMessage : Message
    {
        public DmsIntegrationMessage(Guid guid, string message, int documentId)
        {
            MessageId = guid;
            Message = message;
            DocumentId = documentId;
        }

        public DmsIntegrationMessage(Guid guid, string message, int caseId, int documentId)
        {
            MessageId = guid;
            Message = message;
            CaseId = caseId;
            DocumentId = documentId;
        }

        public DmsIntegrationMessage(Guid guid, string message, string documentSource, string destination)
        {
            MessageId = guid;
            Message = message;
            DocumentSource = documentSource;
            Destination = destination;
        }

        public Guid MessageId { get; }

        public string Message { get; }

        public int? CaseId { get; }

        public int? DocumentId { get; }

        public string DocumentSource { get; }

        public string Destination { get; }
    }

    public class DmsIntegrationFailedMessage : DmsIntegrationMessage
    {
        public DmsIntegrationFailedMessage(Exception exception, string message, int documentId)
            : base(Guid.Empty, message ?? exception.Message, documentId)
        {
            Exception = exception;
        }

        public DmsIntegrationFailedMessage(Exception exception, string message, string documentSource, string destination)
            : base(Guid.Empty, message ?? exception.Message, documentSource, destination)
        {
            Exception = exception;
        }

        public Exception Exception { get; }
    }
}