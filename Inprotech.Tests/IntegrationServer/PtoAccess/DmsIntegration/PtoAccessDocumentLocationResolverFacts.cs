using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.DmsIntegration
{
    public class PtoAccessDocumentLocationResolverFacts
    {
        [Fact]
        public void ShouldResolveAbsolutePath()
        {
            const string absolutePath = @"c:\relative\path\name.txt";

            var f = new PtoAccessDocumentLocationResolverFixture();

            var document = new Document
            {
                FileStore = new FileStore
                {
                    Path = absolutePath
                }
            };

            f.FileHelpers.IsPathRooted(absolutePath).Returns(true);

            Assert.Equal(absolutePath, f.Subject.Resolve(document));
        }

        [Fact]
        public void ShouldResolveRelativePathToAbsolutePath()
        {
            const string relativePath = @"relative\path\name.txt";
            const string absolutePath = @"absolute\" + relativePath;

            var f = new PtoAccessDocumentLocationResolverFixture();

            var document = new Document
            {
                FileStore = new FileStore
                {
                    Path = relativePath
                }
            };

            f.FileSystem.AbsolutePath(relativePath).Returns(absolutePath);
            f.FileHelpers.IsPathRooted(relativePath).Returns(false);

            Assert.Equal(absolutePath, f.Subject.Resolve(document));
        }
    }

    internal class PtoAccessDocumentLocationResolverFixture : IFixture<PtoAccessDocumentLocationResolver>
    {
        public IFileHelpers FileHelpers = Substitute.For<IFileHelpers>();
        public IFileSystem FileSystem = Substitute.For<IFileSystem>();

        public PtoAccessDocumentLocationResolver Subject => new PtoAccessDocumentLocationResolver(FileSystem, FileHelpers);
    }
}