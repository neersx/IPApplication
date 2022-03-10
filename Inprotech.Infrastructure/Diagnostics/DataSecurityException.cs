using System;
using System.Runtime.Serialization;
using System.Security.Permissions;

namespace Inprotech.Infrastructure.Diagnostics
{
    [Serializable]
    public class DataSecurityException : Exception
    {
        public DataSecurityException(string message) : base(message)
        {
        }

        public DataSecurityException()
        {
        }

        public DataSecurityException(string message, Exception innerException) : base(message, innerException)
        {
        }

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        protected DataSecurityException(SerializationInfo info, StreamingContext context)
            : base(info, context)

        {
        }
    }
}