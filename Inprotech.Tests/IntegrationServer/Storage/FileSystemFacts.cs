using System;
using System.IO;
using CpaGlobal.Utilities.Contracts;
using CpaGlobal.Utilities.IO;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Storage
{
    public class FileSystemFacts
    {
        public class AbsolutePath
        {
            [Fact]
            public void ShouldReturnAbsolutePath()
            {
                var f = new FileSystemFixture();

                const string path = @"sample\item.txt";
                Assert.Equal(Path.Combine(f.Root, path), f.Subject.AbsolutePath(path));
            }

            [Fact]
            public void ShouldThrowIfPathIsRooted()
            {
                Assert.Throws<InvalidOperationException>(
                                                         () =>
                                                         {
                                                             new FileSystemFixture().Subject.AbsolutePath(
                                                                                                          @"c:\root\a.txt");
                                                         });
            }
        }

        public class UniqueDirectoryMethod
        {
            [Fact]
            public void ShouldGenerateUniquePath()
            {
                var f = new FileSystemFixture();
                var first = f.Subject.UniqueDirectory();
                var second = f.Subject.UniqueDirectory();

                Assert.NotEqual(first, second);
            }
        }
    }

    public class FileSystemFixture : IFixture<FileSystem>
    {
        public FileSystemFixture()
        {
            Root = @"c:\root";

            StorageLocation = Substitute.For<IStorageLocation>();
            StorageLocation.Resolve().Returns(Root);
        }

        public IStorageLocation StorageLocation { get; set; }

        public string Root { get; set; }

        public FileSystem Subject
        {
            get { return new FileSystem(StorageLocation, Substitute.For<Func<Guid>>()); }
        }
    }
}