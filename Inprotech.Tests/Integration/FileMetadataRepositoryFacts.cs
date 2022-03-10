using System;
using System.Linq;
using Inprotech.Integration.Storage;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.Integration
{
    public class FileMetadataRepositoryFacts : FactBase
    {
        FileMetadata BuildDbFileMetadata(string filename = "filename", string group = "group",
                                         string contentHash = "contentHash", long size = 100, DateTime? savedOn = null)
        {
            return new FileMetadata(new Contracts.Storage.FileMetadata(Guid.NewGuid(), filename, group, contentHash, size,
                                                                       savedOn ?? DateTime.UtcNow));
        }

        bool MetadatasAreEqual(Contracts.Storage.FileMetadata x, FileMetadata y)
        {
            if (x == null || y == null) return false;
            return x.FileId == y.FileId && x.ContentHash.Equals(y.ContentHash) && x.Filename.Equals(y.Filename) &&
                   x.Group.Equals(y.FileGroup) && x.SavedOn == y.SavedOn && x.Size == y.FileSize;
        }

        [Fact]
        public void GivenExistingMetadataDeleteShouldRemoveMetadata()
        {
            var metadata = BuildDbFileMetadata();
            metadata.In(Db);

            new FileMetadataRepository(Db).Delete(metadata.FileId);

            var result = Db.Set<FileMetadata>().SingleOrDefault(m => m.FileId == metadata.FileId);
            Assert.Null(result);
        }

        [Fact]
        public void GivenMetadataDoesNotExistAddShouldStoreItInTheDatabase()
        {
            var fileId = Guid.NewGuid();
            const string filename = "filename";
            const string group = "group";
            const string contentHash = "contentHash";
            const long size = 100;
            var savedOn = DateTime.UtcNow;

            var metadata = new Contracts.Storage.FileMetadata(fileId, filename, group, contentHash, size, savedOn);

            new FileMetadataRepository(Db).Add(metadata);

            var result = Db.Set<FileMetadata>().Single(m => m.FileId == fileId);

            Assert.True(MetadatasAreEqual(metadata, result));
        }

        [Fact]
        public void GivenMetadataExistsWithFilenameAndGroupGetShouldReturnMetadata()
        {
            var metadata = BuildDbFileMetadata();
            metadata.In(Db);

            var result = new FileMetadataRepository(Db).Get(metadata.Filename, metadata.FileGroup).Single();
            Assert.True(MetadatasAreEqual(result, metadata));
        }

        [Fact]
        public void GivenMultipleMetadataExistsWithFilenameAndGroupGetShouldReturnAllMetadata()
        {
            const string filename = "filename";
            const string group = "group";

            var metadatas = Enumerable.Range(1, 10).Select(i => BuildDbFileMetadata(contentHash: string.Format("contentHash{0}", i),
                                                                                    size: i * 100, filename: filename, @group: group)).ToArray();

            foreach (var metadata in metadatas) metadata.In(Db);

            var result = new FileMetadataRepository(Db).Get(filename, group).ToArray();

            Assert.True(result.Join(metadatas, k1 => k1.FileId, k2 => k2.FileId, MetadatasAreEqual).DefaultIfEmpty().All(x => x));
        }
    }
}