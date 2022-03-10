using System;
using System.Runtime.Serialization;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public class DmsConfigurationException : Exception
    {
        public DmsConfigurationException()
        {
        }

        public DmsConfigurationException(string message) : base(message)
        {
        }

        public DmsConfigurationException(string message, Exception innerException) : base(message, innerException)
        {
        }

        protected DmsConfigurationException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }

    public class AuthenticationException : DmsConfigurationException
    {
        public AuthenticationException()
        {
        }

        public AuthenticationException(string message, string advice) : base(message + Environment.NewLine + advice)
        {
        }

        public AuthenticationException(string message, Exception innerException) : base(message, innerException)
        {
        }

        protected AuthenticationException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }

    public class CachedTokenExpiredException : DmsConfigurationException
    {
        public CachedTokenExpiredException()
        {
        }

        public CachedTokenExpiredException(string message, Exception innerException) : base(message, innerException)
        {
        }

        protected CachedTokenExpiredException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }

    public class OAuth2TokenException : AuthenticationException
    {
        public OAuth2TokenException()
        {
        }

        public OAuth2TokenException(string message, Exception innerException) : base(message, innerException)
        {
        }

        protected OAuth2TokenException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}