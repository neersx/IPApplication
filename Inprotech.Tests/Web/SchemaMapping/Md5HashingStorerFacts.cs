using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.Storage;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class Md5HashingStorerFacts : FactBase
    {
        string GetContentHash(byte[] content)
        {
            using (var hasher = MD5.Create())
            {
                return Convert.ToBase64String(hasher.ComputeHash(content));
            }
        }

        [Fact]
        public async Task GivenKnownStreamContentStoreAndHashCreatesCorrectHash()
        {
            const string contentText = "known stream content";
            const string path = "path";

            var content = Encoding.UTF8.GetBytes(contentText);
            var hash = GetContentHash(content);
            using (var outputStream = new MemoryStream())
            using (var inputStream = new MemoryStream(content))
            {
                var fixture = new Md5HashingStorerFixture()
                    .WithStandardFileSystemSetup(path, outputStream);

                var result = await fixture.Subject.StoreAndHash(path, inputStream);

                Assert.Equal(hash, result);
            }
        }

        [Fact]
        public async Task GivenKnownStreamContentStoreAndHashWritesContentToStream()
        {
            const string contentText = "known stream content";
            const string path = "path";

            var content = Encoding.UTF8.GetBytes(contentText);
            var hash = GetContentHash(content);
            using (var outputStream = new MemoryStream())
            using (var inputStream = new MemoryStream(content))
            {
                var fixture = new Md5HashingStorerFixture()
                    .WithStandardFileSystemSetup(path, outputStream);

                await fixture.Subject.StoreAndHash(path, inputStream);

                Assert.Equal(content, outputStream.ToArray());
            }
        }
    }

    internal class Md5HashingStorerFixture : IFixture<Md5HashingStorer>
    {
        public Md5HashingStorerFixture()
        {
            FileSystem = Substitute.For<IFileSystem>();
        }

        public IFileSystem FileSystem { get; set; }

        public Md5HashingStorer Subject => new Md5HashingStorer(FileSystem);

        public Md5HashingStorerFixture WithStandardFileSystemSetup(string path, Stream outputStream)
        {
            FileSystem.OpenWrite(path).Returns(outputStream);
            return this;
        }
    }
}