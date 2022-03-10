using System;
using System.Runtime.Serialization;
using System.Security.Permissions;

namespace Inprotech.Integration.DmsIntegration
{
    [Serializable]
    public abstract class DmsIntegrationException : Exception
    {
        protected DmsIntegrationException(string message) : base(message)
        {
        }

        protected DmsIntegrationException(string message, Exception innerException) :
            base(message, innerException)
        {
        }

        protected DmsIntegrationException()
        {
        }

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        protected DmsIntegrationException(SerializationInfo info, StreamingContext context)
            : base(info, context)
        {
        }
    }

    [Serializable]
    public class FileAlreadyExistsException : DmsIntegrationException
    {
        public FileAlreadyExistsException(string filepath)
            : base(GetExceptionMessage(filepath))
        {
            Filepath = filepath;
        }

        public FileAlreadyExistsException(string filepath, Exception innerException)
            : base(GetExceptionMessage(filepath), innerException)
        {
            Filepath = filepath;
        }

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        protected FileAlreadyExistsException(SerializationInfo info, StreamingContext context)
            : base(info, context)
        {
            Filepath = (string) info.GetValue("Filepath", typeof(string));
        }

        public string Filepath { get; }

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        public override void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            info.AddValue("Filepath", Filepath, typeof(string));
            base.GetObjectData(info, context);
        }

        static string GetExceptionMessage(string filepath)
        {
            return $"File '{filepath}' already exists.";
        }
    }

    [Serializable]
    public class FilenameFormatException : DmsIntegrationException
    {
        public FilenameFormatException(string formatString, Exception innerException)
            : base($"Failed to format filename for document using format string: '{formatString}'.", innerException)
        {
            FormatString = formatString;
        }

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        protected FilenameFormatException(SerializationInfo info, StreamingContext context)
            : base(info, context)
        {
            FormatString = (string) info.GetValue("FormatString", typeof(string));
        }

        public string FormatString { get; }

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        public override void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            info.AddValue("FormatString", FormatString, typeof(string));
            base.GetObjectData(info, context);
        }
    }
}