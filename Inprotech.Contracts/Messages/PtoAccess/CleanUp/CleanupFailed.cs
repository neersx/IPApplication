using System;

namespace Inprotech.Contracts.Messages.PtoAccess.CleanUp
{
    public abstract class FileCleanUpFailedBase : CleanUpMessage
    {
        public Exception Exception;
        public string Path;
        public string Reason;
        public Guid SessionGuid;

        protected FileCleanUpFailedBase(string path, Guid sessionGuid, string reason, Exception exception)
        {
            if (string.IsNullOrEmpty(path)) throw new ArgumentNullException("path");
            if (string.IsNullOrEmpty(reason)) throw new ArgumentNullException("reason");
            if (exception == null) throw new ArgumentNullException("exception");

            Path = path;
            SessionGuid = sessionGuid;
            Reason = reason;
            Exception = exception;
        }
    }

    public sealed class FileCleanUpFailed : FileCleanUpFailedBase
    {
        public FileCleanUpFailed(string path, Guid sessionGuid, string reason, Exception exception)
            : base(path, sessionGuid, reason, exception)
        {
        }
    }

    public sealed class FolderCleanUpFailed : FileCleanUpFailedBase
    {
        public FolderCleanUpFailed(string path, Guid sessionGuid, string reason, Exception exception)
            : base(path, sessionGuid, reason, exception)
        {
        }
    }

    public sealed class LegacyFileCleanUpFailed : FileCleanUpFailedBase
    {
        public LegacyFileCleanUpFailed(string path, string reason, Exception exception)
            : base(path, Guid.Empty, reason, exception)
        {
        }
    }

    public sealed class LegacyFolderCleanUpFailed : FileCleanUpFailedBase
    {
        public LegacyFolderCleanUpFailed(string path, string reason, Exception exception)
            : base(path, Guid.Empty, reason, exception)
        {
        }
    }
}