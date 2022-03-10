using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Settings;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration
{
    public class DmsFilenameFormatterFacts
    {
        const string ApplicationNumber = "applicationnumber";
        const string RegistrationNumber = "registrationnumber";
        const string PublicationNumber = "publicationnumber";
        const string DocumentCategory = "documentcategory";
        const string DocumentObjectId = "documentobjectid";
        const string DocumentDescription = "documentdescription";

        static readonly DateTime MailRoomDate = Fixture.Today();

        [Theory]
        [MemberData(nameof(FormattingData))]
        public void ShouldFormatEachItemInFilename(Document document, string format, string expectedResult)
        {
            var f = new DmsFilenameFormatterFixture();

            f.Settings.PrivatePairFilename.Returns(format);

            Assert.Equal(expectedResult, f.Subject.Format(document));
        }

        [Theory]
        [InlineData("audio/wav", "a.wav")]
        [InlineData("audio/mp3", "a.mp3")]
        public void ShouldChangeFileExtensionIfRequired(string mediaType, string expected)
        {
            var f = new DmsFilenameFormatterFixture();

            var document = new Document
            {
                ApplicationNumber = ApplicationNumber,
                RegistrationNumber = RegistrationNumber,
                PublicationNumber = PublicationNumber,
                Source = DataSourceType.UsptoPrivatePair,
                MediaType = mediaType
            };

            f.Settings.PrivatePairFilename.Returns("a.pdf");

            Assert.Equal(expected, f.Subject.Format(document));
        }

        public static IEnumerable<object[]> FormattingData => new[]
        {
            new object[]
            {
                new Document
                {
                    ApplicationNumber = ApplicationNumber,
                    Source = DataSourceType.UsptoPrivatePair
                },
                "{AN}.pdf", ApplicationNumber + ".pdf"
            },
            new object[]
            {
                new Document
                {
                    RegistrationNumber = RegistrationNumber,
                    Source = DataSourceType.UsptoPrivatePair
                },
                "{RN}.pdf", RegistrationNumber + ".pdf"
            },
            new object[]
            {
                new Document
                {
                    PublicationNumber = PublicationNumber,
                    Source = DataSourceType.UsptoPrivatePair
                },
                "{PN}.pdf", PublicationNumber + ".pdf"
            },
            new object[]
            {
                new Document
                {
                    MailRoomDate = MailRoomDate,
                    Source = DataSourceType.UsptoPrivatePair
                },
                "{MDT:yyyyMMdd}.pdf", MailRoomDate.ToString("yyyyMMdd") + ".pdf"
            },
            new object[]
            {
                new Document
                {
                    Source = DataSourceType.UsptoPrivatePair
                },
                "{CDT:yyyyMMddHHmmss}.pdf", Fixture.Today().ToString("yyyyMMddHHmmss") + ".pdf"
            },
            new object[]
            {
                new Document
                {
                    DocumentCategory = DocumentCategory,
                    Source = DataSourceType.UsptoPrivatePair
                },
                "{CAT}.pdf", DocumentCategory + ".pdf"
            },
            new object[]
            {
                new Document
                {
                    DocumentObjectId = DocumentObjectId,
                    Source = DataSourceType.UsptoPrivatePair
                },
                "{ID}.pdf", DocumentObjectId + ".pdf"
            },
            new object[]
            {
                new Document
                {
                    DocumentDescription = DocumentDescription,
                    Source = DataSourceType.UsptoPrivatePair
                },
                "{DESC}.pdf", DocumentDescription + ".pdf"
            }
        };

        [Fact]
        public void ShouldFilterOutIllegalPathCharacters()
        {
            var f = new DmsFilenameFormatterFixture();

            var illegalFilenameCharacters = Path.GetInvalidFileNameChars();

            var random = new Random();

            var chars = Enumerable.Range(1, 3)
                                  .Select(i => illegalFilenameCharacters[random.Next(0, illegalFilenameCharacters.Length - 1)])
                                  .ToArray();

            var format = $"{chars[0]} {{AN}} {chars[1]} {{RN}} {chars[2]} {{PN}}.pdf";

            var document = new Document
            {
                ApplicationNumber = ApplicationNumber,
                RegistrationNumber = RegistrationNumber,
                PublicationNumber = PublicationNumber,
                Source = DataSourceType.UsptoPrivatePair
            };

            f.Settings.PrivatePairFilename.Returns(format);

            var expectedResult = $"{ApplicationNumber}  {RegistrationNumber}  {PublicationNumber}.pdf";
            Assert.Equal(expectedResult, f.Subject.Format(document));
        }

        [Fact]
        public void ShouldFormatManyItemsInFilename()
        {
            var f = new DmsFilenameFormatterFixture();

            var document = new Document
            {
                ApplicationNumber = ApplicationNumber,
                DocumentObjectId = DocumentObjectId,
                RegistrationNumber = RegistrationNumber,
                PublicationNumber = PublicationNumber,
                MailRoomDate = MailRoomDate,
                DocumentCategory = DocumentCategory,
                DocumentDescription = DocumentDescription,
                Source = DataSourceType.UsptoPrivatePair
            };

            f.Settings.PrivatePairFilename.Returns("{AN} {RN} {PN} {MDT:yyyyMMdd} {ID} {CAT} {DESC}.pdf");

            var expectedResult = $"{ApplicationNumber} {RegistrationNumber} {PublicationNumber} {MailRoomDate:yyyyMMdd} {DocumentObjectId} {DocumentCategory} {DocumentDescription}.pdf";

            Assert.Equal(expectedResult, f.Subject.Format(document));
        }

        [Fact]
        public void ShouldTrimWhitespace()
        {
            var f = new DmsFilenameFormatterFixture();

            var format = "  {AN} {RN} {PN}.pdf  ";

            var document = new Document
            {
                ApplicationNumber = ApplicationNumber,
                RegistrationNumber = RegistrationNumber,
                PublicationNumber = PublicationNumber,
                Source = DataSourceType.UsptoPrivatePair
            };

            f.Settings.PrivatePairFilename.Returns(format);

            var expectedResult = $"{ApplicationNumber} {RegistrationNumber} {PublicationNumber}.pdf";
            Assert.Equal(expectedResult, f.Subject.Format(document));
        }
    }

    internal class DmsFilenameFormatterFixture : IFixture<DmsFilenameFormatter>
    {
        public IDmsIntegrationSettings Settings = Substitute.For<IDmsIntegrationSettings>();

        public DmsFilenameFormatter Subject => new DmsFilenameFormatter(Settings, Fixture.Today);
    }
}