using System;

namespace Inprotech.Infrastructure.Exceptions
{
    [Serializable]
    public class ReportNotFoundException : Exception
    {
        public ReportNotFoundException(string message = "Report not found.") : base(message)
        {
        }

        public ReportNotFoundException(string message, Exception innerException) :
            base(message, innerException)
        {
        }
    }
}