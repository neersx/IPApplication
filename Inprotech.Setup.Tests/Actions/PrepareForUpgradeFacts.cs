using System.Collections.Generic;
using System.IO;
using System.Linq;
using Inprotech.Setup.Actions;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class PrepareForUpgradeFacts
    {
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        readonly IEventStream _eventStream = Substitute.For<IEventStream>();
        readonly IDictionary<string, object> _context = new Dictionary<string, object>
        {
            {"InstanceDirectory", @"Assets\instance-1"},
            {"BackupDirectory", ".backup"}
        };

        ~PrepareForUpgradeFacts()
        {
            const string path = @"Assets\instance-1\.backup";

            if (Directory.Exists(path))
            {
                Directory.Delete(path, true);
            }
        }

        static PrepareForUpgrade CreateSubject(IFileSystem fileSystem = null)
        {
            return new PrepareForUpgrade(fileSystem ?? new FileSystem());
        }

        [Fact]
        public void ShouldBackupFilesToSpecifiedDirectory()
        {
            var action = CreateSubject();
            action.Run(_context, _eventStream);

            string BackedUp(string file)
            {
                return Path.Combine(@"Assets\instance-1\.backup", file);
            }

            Assert.True(File.Exists(BackedUp(@"inprotech.server\client\styles\custom.css")));
            Assert.True(File.Exists(BackedUp(@"inprotech.server\client\batchEventUpdate\custom.css")));
            Assert.True(File.Exists(BackedUp(@"inprotech.server\client\favicon.ico")));
            Assert.True(File.Exists(BackedUp(@"inprotech.server\client\images\branding-logo.png")));
        }

        [Fact]
        public void ShouldNotContinueOnException()
        {
            var action = CreateSubject();

            Assert.False(action.ContinueOnException);
        }

        [Fact]
        public void ShouldDeleteExistingBackupDirectory()
        {
            var backupDirectory = Path.Combine((string) _context["InstanceDirectory"], (string) _context["BackupDirectory"]);

            _fileSystem.DirectoryExists(backupDirectory).Returns(true);

            CreateSubject(_fileSystem).Run(_context, _eventStream);

            _fileSystem.Received(1).DeleteDirectory(backupDirectory);
        }

        [Fact]
        public void ShouldEnsureBackupDirectoryIsCreated()
        {
            var backupDirectory = Path.Combine((string) _context["InstanceDirectory"], (string) _context["BackupDirectory"]);
            
            CreateSubject(_fileSystem).Run(_context, _eventStream);

            _fileSystem.Received(1).EnsureDirectory(backupDirectory);
        }

        [Fact]
        public void ShouldIndicateEachFileCopied()
        {
            var instanceDirectory = (string) _context["InstanceDirectory"];

            bool ShouldCopy(string path)
            {
                if (!Fixture.Boolean()) return false;
                _fileSystem.FileExists(path).Returns(true);
                return true;
            }

            var filesCopied = new[]
            {
                Path.Combine(instanceDirectory, Constants.Branding.CustomStylesheet),
                Path.Combine(instanceDirectory, Constants.Branding.BatchEventCustomStylesheet),
                Path.Combine(instanceDirectory, Constants.Branding.FavIcon),
                Path.Combine(instanceDirectory, Constants.Branding.ImagesFolder, "1.png"),
                Path.Combine(instanceDirectory, Constants.Branding.ImagesFolder, "2.png")
            }.Where(ShouldCopy).ToList();
            
            var images = filesCopied.Where(_ => _.EndsWith("png")).ToArray();

            filesCopied.ForEach(_ => _fileSystem.FileExists(_).Returns(true));

            _fileSystem.GetFiles(Path.Combine(instanceDirectory, Constants.Branding.ImagesFolder))
                       .Returns(images);

            CreateSubject(_fileSystem).Run(_context, _eventStream);

            _eventStream.Received(filesCopied.Count).Publish(Arg.Any<Event>());
        }
    }
}