using System.IO;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.PtoAccess;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess.Diagnostics.PtoAccess
{
    public class UsptoFileIssuesFacts
    {
        public class PrepareMethod
        {
            [Fact]
            public void ShouldCreateDirectoryIfFolderHasFiles()
            {
                var fixture = new UsptoFileIssuesFixture();
                var messagePath = Fixture.String();
                fixture.UsptoMessageFileLocationResolver.ResolveMessagePath().Returns(messagePath);
                var messageRootDirectory = Fixture.String();
                fixture.UsptoMessageFileLocationResolver.ResolveRootDirectory().Returns(messageRootDirectory);
                fixture.FileSystem.AbsolutePath(messageRootDirectory).Returns(messageRootDirectory);
                fixture.FileSystem.AbsolutePath(messagePath).Returns(messagePath);
                fixture.FileSystem.FolderExists(messagePath).Returns(true);
                var files = new[] {Fixture.String(), Fixture.String(), Fixture.String()};

                fixture.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(files);

                var basePath = Fixture.String();
                fixture.Subject.Prepare(basePath);

                fixture.CompressionHelper.Received(1).CreateFromDirectory(messageRootDirectory, Path.Combine(basePath, "IPOne.zip"));
            }

            [Fact]
            public void ShouldNotCreateDirectoryIfFolderDoesNotExist()
            {
                var fixture = new UsptoFileIssuesFixture();
                var messagePath = Fixture.String();
                fixture.UsptoMessageFileLocationResolver.ResolveMessagePath().Returns(messagePath);
                fixture.FileSystem.FolderExists(messagePath).Returns(false);

                fixture.Subject.Prepare(Fixture.String());

                fixture.CompressionHelper.Received(0).CreateFromDirectory(Arg.Any<string>(), Arg.Any<string>());
            }

            [Fact]
            public void ShouldNotCreateDirectoryIfFolderEmpty()
            {
                var fixture = new UsptoFileIssuesFixture();
                var messagePath = Fixture.String();
                fixture.UsptoMessageFileLocationResolver.ResolveMessagePath().Returns(messagePath);
                fixture.FileSystem.FolderExists(messagePath).Returns(true);
                fixture.FileSystem.Files(Arg.Any<string>()).Returns(Enumerable.Empty<string>());

                fixture.Subject.Prepare(Fixture.String());

                fixture.CompressionHelper.Received(0).CreateFromDirectory(Arg.Any<string>(), Arg.Any<string>());
            }
        }

        public class UsptoFileIssuesFixture : IFixture<UsptoFileIssues>
        {
            public UsptoFileIssuesFixture()
            {
                CompressionHelper = Substitute.For<ICompressionHelper>();
                FileSystem = Substitute.For<IFileSystem>();
                UsptoMessageFileLocationResolver = Substitute.For<IUsptoMessageFileLocationResolver>();
                Subject = new UsptoFileIssues(CompressionHelper, UsptoMessageFileLocationResolver, FileSystem);
            }

            public ICompressionHelper CompressionHelper { get; }
            public IFileSystem FileSystem { get; }
            public IUsptoMessageFileLocationResolver UsptoMessageFileLocationResolver { get; }
            public UsptoFileIssues Subject { get; }
        }
    }
}