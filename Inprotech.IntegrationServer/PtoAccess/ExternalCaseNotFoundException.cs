using System;

namespace Inprotech.IntegrationServer.PtoAccess
{
    [Serializable]
    public class ExternalCaseNotFoundException : Exception
    {
        public ExternalCaseNotFoundException()
            : base(Properties.PtoAccess.ExternalCaseNotFoundExceptionMessage)
        {
            
        }
    }

    [Serializable]
    public class MultiplePossibleInprotechCasesException : Exception
    {
        public MultiplePossibleInprotechCasesException() : base(Properties.PtoAccess.MultiplePossibleInprotechCasesExceptionMessage)
        {}
    }

    [Serializable]
    public class CorrespondingCaseChangedException : Exception
    {
        public CorrespondingCaseChangedException()
            : base(Properties.PtoAccess.CorrespondingCaseChangedException)
        { }
    }

    [Serializable]
    public class ExternalDocumentDownloadFailedException : Exception
    {
        public ExternalDocumentDownloadFailedException(string documentName)
            : base(string.Format(Properties.PtoAccess.ExternalDocumentCouldNotBeDownloadedExceptionMessage, documentName))
        {

        }

        public ExternalDocumentDownloadFailedException(string documentName, Exception innerException)
            : base(string.Format(Properties.PtoAccess.ExternalDocumentCouldNotBeDownloadedExceptionMessage, documentName), innerException)
        {

        }
    }
}
