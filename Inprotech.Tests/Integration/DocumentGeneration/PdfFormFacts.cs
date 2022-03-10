using System.IO;
using Inprotech.Infrastructure;
using Inprotech.Integration.DocumentGeneration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DocumentGeneration
{
    public class PdfFormFacts
    {
        public class EnsureExistsMethod
        {
            [Fact]
            public void ShouldReturnCombinedFileNameInPdfDirectoryIfExists()
            {
                var pdfFormsDirectory = Fixture.String();

                var fixture = new PdfFormFixture(pdfFormsDirectory);
                var fileName = Fixture.String();
                var combined = Path.Combine(pdfFormsDirectory, Path.GetFileName(fileName));

                fixture.FileHelpers.Exists(fileName).Returns(false);
                fixture.FileHelpers.Exists(combined).Returns(true);

                var response = fixture.Subject.EnsureExists(fileName);

                Assert.Equal(combined, response);
            }

            [Fact]
            public void ShouldReturnFileNameIfFileExists()
            {
                var fixture = new PdfFormFixture();
                var fileName = Fixture.String();
                fixture.FileHelpers.Exists(fileName).Returns(true);

                var response = fixture.Subject.EnsureExists(fileName);

                Assert.Equal(fileName, response);
            }

            [Fact]
            public void ShouldThrowExceptionIfFileDoesntExistAndFileIsntInPdfDirectory()
            {
                var pdfFormsDirectory = Fixture.String();

                var fixture = new PdfFormFixture(pdfFormsDirectory);
                var fileName = Fixture.String();
                var combined = Path.Combine(pdfFormsDirectory, Path.GetFileName(fileName));

                fixture.FileHelpers.Exists(fileName).Returns(false);
                fixture.FileHelpers.Exists(combined).Returns(false);

                Assert.Throws<FileNotFoundException>(() => { fixture.Subject.EnsureExists(fileName); });
            }

            [Fact]
            public void ShouldThrowExceptionIfFileDoesntExistAndNoPdfFileName()
            {
                var fixture = new PdfFormFixture();
                var fileName = Fixture.String();
                fixture.FileHelpers.Exists(fileName).Returns(false);
                Assert.Throws<FileNotFoundException>(() => { fixture.Subject.EnsureExists(fileName); });
            }
        }

        public class CacheDocumentMethod
        {
            [Fact]
            public void ShouldReturnEmptyKeyIfFileDoesntExist()
            {
                var fixture = new PdfFormFixture();
                var fileName = Fixture.String();
                var fileRealName = Fixture.String();
                fixture.FileHelpers.Exists(fileName).Returns(false);

                var response = fixture.Subject.CacheDocument(fileName, fileRealName);

                Assert.True(string.IsNullOrWhiteSpace(response));
            }

            [Fact]
            public void ShouldReturnGeneratedKeyFromCacheIfFileExists()
            {
                var fixture = new PdfFormFixture();
                var fileName = Fixture.String();
                var fileRealName = Fixture.String();
                fixture.FileHelpers.Exists(fileName).Returns(true);
                fixture.FileHelpers.ReadAllBytes(fileName).Returns(new byte[0]);
                var key = Fixture.String();
                fixture.PdfDocumentCache.CacheDocument(Arg.Any<CachedDocument>()).Returns(key);

                var response = fixture.Subject.CacheDocument(fileName, fileRealName);

                fixture.PdfDocumentCache.Received(1).CacheDocument(Arg.Any<CachedDocument>());
                Assert.Equal(key, response);
            }
        }

        public class GetCachedDocumentMethod
        {
            [Fact]
            public void ShouldReturnCachedDocument()
            {
                var fixture = new PdfFormFixture();
                var fileKey = Fixture.String();
                var fileName = Fixture.String();
                fixture.PdfDocumentCache.Retrieve(fileKey).Returns(new CachedDocument {FileName = fileName});

                var response = fixture.Subject.GetCachedDocument(fileKey, true);

                fixture.PdfDocumentCache.Received(1).Retrieve(fileKey);
                Assert.NotNull(response);
                Assert.Equal(fileName, response.FileName);
            }
        }
    }

    public class PdfFormFixture : IFixture<PdfForm>
    {
        public PdfFormFixture(string pdfFormsDirectory = null)
        {
            FileHelpers = Substitute.For<IFileHelpers>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            if (!string.IsNullOrWhiteSpace(pdfFormsDirectory))
            {
                SiteControlReader.Read<string>(SiteControls.PDFFormsDirectory).Returns(pdfFormsDirectory);
            }

            PdfDocumentCache = Substitute.For<IPdfDocumentCache>();
            Subject = new PdfForm(FileHelpers, SiteControlReader, PdfDocumentCache);
        }

        public IFileHelpers FileHelpers { get; }
        public ISiteControlReader SiteControlReader { get; }
        public IPdfDocumentCache PdfDocumentCache { get; }

        public PdfForm Subject { get; }
    }
}