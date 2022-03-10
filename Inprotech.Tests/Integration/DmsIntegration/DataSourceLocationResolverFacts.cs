using Inprotech.Infrastructure;
using Inprotech.Integration;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Settings;
using Inprotech.Integration.Storage;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration
{
    public class DataSourceLocationResolverFacts : FactBase
    {
        [Fact]
        public void ShouldResolveCorrectPath()
        {
            var f = new DataSourceLocationResolverFixture();

            var document = new Document
            {
                DocumentObjectId = "doc1",
                FileStore = new FileStore
                {
                    Id = 1,
                    OriginalFileName = "doc1.pdf",
                    Path = @"relative\path\doc1.pdf"
                },
                Source = DataSourceType.UsptoPrivatePair
            };

            f.Settings.PrivatePairLocation.Returns(@"C:\private\pair");
            f.Formatter.Format(document).Returns("doc1.pdf");
            f.FileHelpers.PathCombine(@"C:\private\pair", "doc1.pdf").Returns(@"C:\private\pair\doc1.pdf");

            Assert.Equal(@"C:\private\pair\doc1.pdf", f.Subject.ResolveDestinationPath(document));
        }
    }

    internal class DataSourceLocationResolverFixture : IFixture<DataSourceLocationResolver>
    {
        public IFileHelpers FileHelpers = Substitute.For<IFileHelpers>();
        public IFormatDmsFilenames Formatter = Substitute.For<IFormatDmsFilenames>();
        public IDmsIntegrationSettings Settings = Substitute.For<IDmsIntegrationSettings>();
        public DataSourceLocationResolver Subject => new DataSourceLocationResolver(Settings, FileHelpers, Formatter);
    }
}