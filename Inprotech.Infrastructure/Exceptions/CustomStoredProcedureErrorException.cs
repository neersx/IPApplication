using System;

namespace Inprotech.Infrastructure.Exceptions
{
    public class CustomStoredProcedureErrorException : Exception
    {
        public CustomStoredProcedureErrorException(string procedureName, string message, Exception innerException)
            : base(message, innerException)
        {
            ProcedureName = procedureName;
        }

        public string ProcedureName { get; set; }
    }
}