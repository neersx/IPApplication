using System;

namespace Inprotech.Integration.ExchangeIntegration
{
    [Serializable]
    public abstract class GraphIntegrationException : Exception
    {
        protected GraphIntegrationException(string message) : base(message)
        {
        }

        protected GraphIntegrationException(string message, Exception innerException) :
            base(message, innerException)
        {
        }
    }

    [Serializable]
    public class GraphAccessTokenNotAvailableException : GraphIntegrationException
    {

        public GraphAccessTokenNotAvailableException(string message) : base(message)
        {
        }

        public GraphAccessTokenNotAvailableException(string message, Exception innerException) :
            base(message, innerException)
        {
        }
    }

    [Serializable]
    public class GraphAccessTokenExpiredException : GraphIntegrationException
    {

        public GraphAccessTokenExpiredException(string message) : base(message)
        {
        }

        public GraphAccessTokenExpiredException(string message, Exception innerException) :
            base(message, innerException)
        {

        }
    }
}
