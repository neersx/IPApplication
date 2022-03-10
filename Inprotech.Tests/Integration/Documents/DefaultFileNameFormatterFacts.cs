using System.IO;
using Inprotech.Integration.Documents;
using Xunit;

namespace Inprotech.Tests.Integration.Documents
{
    public class DefaultFileNameFormatterFacts : FactBase
    {
        [Theory]
        [InlineData("audio/mp3", ".mp3")]
        [InlineData("audio/wav", ".wav")]
        public void SoundFilesExtensionDefaultedFromMediaType(string mediaType, string expectedExtension)
        {
            var d = new Document
            {
                DocumentDescription = "ABC",
                MailRoomDate = Fixture.PastDate(),
                PageCount = 5,
                MediaType = mediaType
            };

            var result = new DefaultFileNameFormatter().Format(d);

            Assert.Equal(expectedExtension, Path.GetExtension(result));
        }

        [Fact]
        public void DefaultAsPdfFile()
        {
            var d = new Document
            {
                DocumentDescription = "ABC",
                MailRoomDate = Fixture.PastDate(),
                PageCount = 5,
                MediaType = null /* application/xml, image/tiff, image/jpeg, application/pdf do not have MediaType set */
            };

            var result = new DefaultFileNameFormatter().Format(d);

            Assert.Equal("19991201 ABC (5 pages).pdf", result);
        }

        [Fact]
        public void FormatsDocumentWithMoreThanOnePage()
        {
            var d = new Document
            {
                DocumentDescription = "ABC",
                MailRoomDate = Fixture.PastDate(),
                PageCount = 5
            };

            var result = new DefaultFileNameFormatter().Format(d);

            Assert.Equal("19991201 ABC (5 pages).pdf", result);
        }

        [Fact]
        public void FormatsDocumentWithNoPageCount()
        {
            var d = new Document
            {
                DocumentDescription = "ABC",
                MailRoomDate = Fixture.PastDate(),
                PageCount = null
            };

            var result = new DefaultFileNameFormatter().Format(d);

            Assert.Equal("19991201 ABC.pdf", result);
        }

        [Fact]
        public void FormatsDocumentWithOnePageOnly()
        {
            var d = new Document
            {
                DocumentDescription = "ABC",
                MailRoomDate = Fixture.PastDate(),
                PageCount = 1
            };

            var result = new DefaultFileNameFormatter().Format(d);

            Assert.Equal("19991201 ABC.pdf", result);
        }
    }
}