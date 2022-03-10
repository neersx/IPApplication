using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.Storage;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;
using FileMetadata = Inprotech.Contracts.Storage.FileMetadata;

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class FileSystemStorageFacts : FactBase
    {
        bool MetadatasAreEqual(FileMetadata x, FileMetadata y)
        {
            if (x == null || y == null) return false;
            return x.Filename.Equals(y.Filename) && x.FileId == y.FileId && x.ContentHash.Equals(y.ContentHash) &&
                   x.Group.Equals(y.Group) && x.SavedOn == y.SavedOn && x.Size == y.Size;
        }

        string GetFileSystemPath(string group, Guid fileId)
        {
            return string.Format(@"{0}\{1}.dat", group, fileId.ToString("N"));
        }

        public class FileSystemStorageFixture : IFixture<FileSystemStorage>
        {
            readonly InMemoryDbContext _db;

            public FileSystemStorageFixture(InMemoryDbContext db)
            {
                _db = db;
                FileSystem = Substitute.For<IFileSystem>();
                Repository = Substitute.For<IFileMetadataRepository>();
                PathBuilder = Substitute.For<IBuildFileSystemPaths>();
                HashingStorer = Substitute.For<IStoreAndHashFiles>();
            }

            public IFileSystem FileSystem { get; set; }
            public IFileMetadataRepository Repository { get; set; }
            public IBuildFileSystemPaths PathBuilder { get; set; }
            public DateTime SavedOn { get; set; }
            public IStoreAndHashFiles HashingStorer { get; set; }

            public FileSystemStorage Subject
            {
                get { return new FileSystemStorage(FileSystem, Repository, _db, PathBuilder, () => SavedOn, HashingStorer); }
            }

            public FileSystemStorageFixture WithPathBuilder(string group, Guid fileId, string path)
            {
                PathBuilder.GetPath(group, fileId).Returns(path);

                return this;
            }

            public FileSystemStorageFixture WithAbsolutePath(string path, string result)
            {
                FileSystem.AbsolutePath(path).Returns(result);
                return this;
            }

            public FileSystemStorageFixture WithContentHash(string hash)
            {
                HashingStorer.StoreAndHash(Arg.Any<string>(), Arg.Any<Stream>()).Returns(Task.FromResult(hash));
                return this;
            }
        }

        [Fact]
        public async Task Given2FileMetadatasExistForFilenameAndGroupGetFileMetadataReturnsBoth()
        {
            var fileId1 = Guid.NewGuid();
            var fileId2 = Guid.NewGuid();
            const string group = "group";
            const string filename = "filename";

            const int size1 = 100;
            const int size2 = 200;
            const string contentHash1 = "contenthash1";
            const string contentHash2 = "contenthash2";
            var savedOn1 = DateTime.UtcNow;
            var savedOn2 = savedOn1.AddHours(-2);

            var metadatas = new List<FileMetadata>
            {
                new FileMetadata(fileId1, filename, group, contentHash1, size1, savedOn1),
                new FileMetadata(fileId2, filename, group, contentHash2, size2, savedOn2)
            };

            var fixture = new FileSystemStorageFixture(Db);
            fixture.Repository.Get(filename, group).Returns(metadatas);

            var result = (await fixture.Subject.GetFileMetadata(filename, group)).ToArray();

            Assert.True(result.Join(metadatas, m => m.FileId, m => m.FileId, MetadatasAreEqual).DefaultIfEmpty().All(x => x));
        }

        [Fact]
        public async Task GivenFileMetadataExistsDeleteShouldRemoveFileFromFileSystem()
        {
            var fileId = Guid.NewGuid();
            const string group = "group";
            const string filename = "filename";
            const string contentHash = "contentHash";
            const long length = 100;

            var path = GetFileSystemPath(group, fileId);
            var dateSavedOn = DateTime.UtcNow;

            var fixture = new FileSystemStorageFixture(Db) {SavedOn = dateSavedOn}
                          .WithAbsolutePath(path, path)
                          .WithPathBuilder(group, fileId, path);

            fixture.Repository.Get(fileId)
                   .Returns(new FileMetadata(fileId, filename, group, contentHash, length, dateSavedOn));

            await fixture.Subject.Delete(fileId);

            fixture.FileSystem.Received(1).DeleteFile(path);
        }

        [Fact]
        public async Task GivenFileMetadataExistsDeleteShouldRemoveFileMetadataFromRepository()
        {
            var fileId = Guid.NewGuid();
            const string group = "group";
            const string filename = "filename";
            const string contentHash = "contentHash";
            const long length = 100;

            var path = GetFileSystemPath(group, fileId);
            var dateSavedOn = DateTime.UtcNow;

            var fixture = new FileSystemStorageFixture(Db) {SavedOn = dateSavedOn}
                          .WithAbsolutePath(path, path)
                          .WithPathBuilder(group, fileId, path);

            fixture.Repository.Get(fileId)
                   .Returns(new FileMetadata(fileId, filename, group, contentHash, length, dateSavedOn));

            await fixture.Subject.Delete(fileId);

            fixture.Repository.Received(1).Delete(fileId);
        }

        [Fact]
        public async Task GivenFileSaveShouldCreateCorrectFolder()
        {
            var fileId = Guid.NewGuid();
            const string filename = "filename";
            const string group = "group";

            const string textContent = "test content";

            var path = GetFileSystemPath(group, fileId);
            var content = Encoding.UTF8.GetBytes(textContent);

            var fixture = new FileSystemStorageFixture(Db)
                          .WithPathBuilder(group, fileId, path)
                          .WithAbsolutePath(path, path)
                          .WithContentHash("hash");

            using (var ms = new MemoryStream(content))
            {
                fixture.FileSystem.GetLength(path).Returns(content.LongLength);

                await fixture.Subject.Save(filename, group, fileId, ms);
            }

            fixture.FileSystem.Received(1).EnsureFolderExists(path);
        }

        [Fact]
        public async Task GivenValidFileSaveShouldAddFileMetadataToRepository()
        {
            var fileId = Guid.NewGuid();
            const string group = "group";
            const string textContent = "test content";
            const string filename = "filename";
            const string hash = "hash";

            var content = Encoding.UTF8.GetBytes(textContent);
            var path = GetFileSystemPath(group, fileId);
            var dateSavedOn = DateTime.UtcNow;

            var fixture = new FileSystemStorageFixture(Db) {SavedOn = dateSavedOn}
                          .WithPathBuilder(group, fileId, path)
                          .WithAbsolutePath(path, path)
                          .WithContentHash(hash);

            using (var contentStream = new MemoryStream(content))
            {
                fixture.PathBuilder.GetPath(group, fileId).Returns(path);
                fixture.FileSystem.GetLength(path).Returns(content.LongLength);

                await fixture.Subject.Save(filename, group, fileId, contentStream);

                fixture.Repository.Received(1).Add(Arg.Is<FileMetadata>(fm =>
                                                                            fm.FileId == fileId && fm.ContentHash.Equals(hash) && fm.Filename.Equals(filename) &&
                                                                            fm.Group == group && fm.SavedOn == dateSavedOn && fm.Size == content.LongLength));
            }
        }

        [Fact]
        public async Task GivenValidFileSaveShouldStoreFileToFileSystem()
        {
            var fileId = Guid.NewGuid();
            const string group = "group";
            const string textContent = "test content";
            var content = Encoding.UTF8.GetBytes(textContent);
            var path = GetFileSystemPath(group, fileId);

            var fixture = new FileSystemStorageFixture(Db)
                          .WithPathBuilder(group, fileId, path)
                          .WithAbsolutePath(path, path)
                          .WithContentHash("hash");

            using (var contentStream = new MemoryStream(content))
            {
                fixture.FileSystem.GetLength(path).Returns(content.LongLength);

                await fixture.Subject.Save("filename", group, fileId, contentStream);

#pragma warning disable 4014
                fixture.HashingStorer.Received(1).StoreAndHash(path, contentStream);
#pragma warning restore 4014
            }
        }
    }
}