using System;
using System.Runtime.Serialization;

namespace Inprotech.Integration.Reports
{
    public class ReportingServicesConfigurationException : Exception
    {
        public ReportingServicesConfigurationException()
        {
        }

        public ReportingServicesConfigurationException(string message) : base(message)
        {
        }

        public ReportingServicesConfigurationException(string message, Exception innerException) : base(message, innerException)
        {
        }

        protected ReportingServicesConfigurationException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}