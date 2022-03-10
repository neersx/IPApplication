using System.Collections.Generic;
using Inprotech.Setup.Actions;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class RestoreBackupFacts
    {
        public RestoreBackupFacts()
        {
            _eventStream = Substitute.For<IEventStream>();
            _context = new Dictionary<string, object>
            {
                {"InstanceDirectory", @"instance-1"},
                {"BackupDirectory", ".backup"}
            };
        }

        readonly IEventStream _eventStream;
        readonly IDictionary<string, object> _context;
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();

        [Fact]
        public void ShouldNotContinueOnException()
        {
            Assert.False(new RestoreBackup().ContinueOnException);
        }

        [Fact]
        public void ShouldNotDeleteBackupFilesAfterRestoring()
        {
            new RestoreBackup(_fileSystem).Run(_context, _eventStream);

            _fileSystem.DidNotReceiveWithAnyArgs().DeleteDirectory(null);
        }

        [Fact]
        public void ShouldPublishToEventStream()
        {
            new RestoreBackup(_fileSystem).Run(_context, _eventStream);

            _eventStream.ReceivedWithAnyArgs(1).PublishInformation(null);
        }

        [Fact]
        public void ShouldRestoreBackupFiles()
        {
            new RestoreBackup(_fileSystem).Run(_context, _eventStream);

            _fileSystem.Received(1).CopyDirectory(@"instance-1\.backup", @"instance-1");
        }
    }
}