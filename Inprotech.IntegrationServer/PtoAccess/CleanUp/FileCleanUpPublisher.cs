using System;
using Inprotech.Contracts.Messages;
using Inprotech.Contracts.Messages.PtoAccess.CleanUp;
using Inprotech.Infrastructure.Messaging;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public interface IPublishFileCleanUpEvents
    {
        void Publish(Guid sessionGuid, string reason, string path, Exception ex = null);
    }

    public interface IPublishFolderCleanUpEvents
    {
        void Publish(Guid sessionGuid, string reason, string path, Exception ex = null);
    }

    public class FileCleanUpPublisher : IPublishFileCleanUpEvents
    {
        readonly IBus _bus;

        public FileCleanUpPublisher(IBus bus)
        {
            _bus = bus;
        }

        public void Publish(Guid sessionGuid, string reason, string path, Exception ex = null)
        {
            if (sessionGuid == Guid.Empty)
            {
                _bus.Publish(ex == null ? (Message)new LegacyFileCleanedUp(path, reason) : new LegacyFileCleanUpFailed(path, reason, ex));
                return;
            }

            _bus.Publish(ex == null ? (Message)new FileCleanedUp(path, sessionGuid, reason) : new FileCleanUpFailed(path, sessionGuid, reason, ex));
        }
    }

    public class FolderCleanUpPublisher : IPublishFolderCleanUpEvents
    {
        readonly IBus _bus;

        public FolderCleanUpPublisher(IBus bus)
        {
            _bus = bus;
        }

        public void Publish(Guid sessionGuid, string reason, string path, Exception ex = null)
        {
            if (sessionGuid == Guid.Empty)
            {
                _bus.Publish(ex == null ? (Message)new LegacyFolderCleanedUp(path, reason) : new LegacyFolderCleanUpFailed(path, reason, ex));
                return;
            }

            _bus.Publish(ex == null ? (Message)new FolderCleanedUp(path, sessionGuid, reason) : new FolderCleanUpFailed(path, sessionGuid, reason, ex));
        }
    }
}
