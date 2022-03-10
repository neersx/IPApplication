using System;

namespace Inprotech.Contracts.Messages.PtoAccess.CleanUp
{
    public abstract class CleanedUp : CleanUpMessage
    {
        public string Path;
        public string Reason;
        public Guid SessionGuid;

        protected CleanedUp(string path, Guid sessionGuid, string reason)
        {
            if (string.IsNullOrEmpty(path)) throw new ArgumentNullException("path");
            if (string.IsNullOrEmpty(reason)) throw new ArgumentNullException("reason");

            Path = path;
            SessionGuid = sessionGuid;
            Reason = reason;
        }
    }

    public sealed class FileCleanedUp : CleanedUp
    {
        public FileCleanedUp(string path, Guid sessionGuid, string reason) : base(path, sessionGuid, reason)
        {
        }
    }

    public sealed class LegacyFileCleanedUp : CleanedUp
    {
        public LegacyFileCleanedUp(string path, string reason)
            : base(path, Guid.Empty, reason)
        {
        }
    }

    public sealed class FolderCleanedUp : CleanedUp
    {
        public FolderCleanedUp(string path, Guid sessionGuid, string reason)
            : base(path, sessionGuid, reason)
        {
        }
    }

    public sealed class LegacyFolderCleanedUp : CleanedUp
    {
        public LegacyFolderCleanedUp(string path, string reason)
            : base(path, Guid.Empty, reason)
        {
        }
    }
}