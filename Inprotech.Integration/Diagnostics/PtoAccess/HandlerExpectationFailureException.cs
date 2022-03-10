using System;
using System.Diagnostics.CodeAnalysis;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    [SuppressMessage("Microsoft.Usage", "CA2240:ImplementISerializableCorrectly")]
    [SuppressMessage("Microsoft.Usage", "CA2229:Implement serialization constructors")]
    [Serializable]
    public class HandlerExpectationFailureException : Exception
    {
        public string AdditionalData { get; set; }

        public HandlerExpectationFailureException(string message)
            : this(message, null)
        {
        }

        public HandlerExpectationFailureException(string message, string additionalData)
            : base(message)
        {
            AdditionalData = additionalData;
        }
    }

    [Serializable]
    [SuppressMessage("Microsoft.Usage", "CA2229:Implement serialization constructors")]
    public class ExternalCaseNotRetrievableException : HandlerExpectationFailureException
    {
        public ExternalCaseNotRetrievableException(string message) : base(message)
        {
        }

        public ExternalCaseNotRetrievableException(string message, string additionalData)
            : base(message, additionalData)
        {
        }
    }
}