using Inprotech.Integration.DocumentGeneration;
using Xunit;

namespace Inprotech.Tests.Integration.DocumentGeneration
{
    public class PdfDocumentCacheFacts : FactBase
    {
        [Fact]
        public void ShouldBehaveAppropriately()
        {
            var fixture = new PdfDocumentCacheFixture();
            var document1 = new CachedDocument() { FileName = Fixture.String() };
            var document2 = new CachedDocument() { FileName = Fixture.String() };

            var key = fixture.Subject.CacheDocument(document1);
            fixture.Subject.CacheDocument(document2);

            var cachedDocument = fixture.Subject.Retrieve(key);

            //Should Return Correct Document
            Assert.Equal(document1.FileName, cachedDocument.FileName);

            cachedDocument = fixture.Subject.RetrieveAndDelete(key);
            Assert.Equal(document1.FileName, cachedDocument.FileName);

            //Should have removed it from cache
            cachedDocument = fixture.Subject.RetrieveAndDelete(key);
            Assert.Null(cachedDocument);
        }
    }

    public class PdfDocumentCacheFixture : IFixture<PdfDocumentCache>
    {
        public PdfDocumentCacheFixture()
        {
            Subject = new PdfDocumentCache();
        }

        public PdfDocumentCache Subject { get; }
    }
}
