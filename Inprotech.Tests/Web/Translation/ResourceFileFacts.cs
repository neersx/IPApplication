using System.IO;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Web.Translation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Translation
{
    public class ResourceFileFacts
    {
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();

        IResourceFile CreateSubject()
        {
            return new ResourceFile(_fileSystem);
        }

        [Fact]
        public void AlwaysCheckExistsWithFullPath()
        {
            var thePath = Path.Combine(Path.GetFullPath("."), "aaaa");

            var subject = CreateSubject();

            subject.Exists("aaaa");

            _fileSystem.Received(1).Exists(thePath);

            _fileSystem.ClearReceivedCalls();

            subject.Exists(thePath);

            _fileSystem.Received(1).Exists(thePath);
        }

        [Fact]
        public void BasePathReturnsCurrentDirectory()
        {
            Assert.Equal(Path.GetFullPath("."), CreateSubject().BasePath);
        }

        [Fact]
        public void FetchReturnsFilesRecursvively()
        {
            const bool allDirectories = true;

            CreateSubject().Fetch("aaaa", "bbbb").ToArray();

            _fileSystem.Received().Files("aaaa", "bbbb", allDirectories);
        }
    }
}