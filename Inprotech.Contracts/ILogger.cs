using System;

namespace Inprotech.Contracts
{
    public interface ILogger
    {
        void SetContext(Guid contextId);

        void Trace(string message, object data = null);
        
        void Debug(string message, object data = null);
        
        void Information(string message, object data = null);

        void Warning(string message, object data = null);

        void Exception(Exception exception, string message = null);
    }

    public interface IContextualLogger
    {
        void SetLogContext(Guid context);
    }

    public interface ILogger<T> : ILogger
    {
    }
}