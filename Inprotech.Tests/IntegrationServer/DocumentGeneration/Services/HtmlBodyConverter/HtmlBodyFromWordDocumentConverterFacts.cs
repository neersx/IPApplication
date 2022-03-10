using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.IntegrationServer.DocumentGeneration;
using Inprotech.IntegrationServer.DocumentGeneration.Services.HtmlBodyConverter;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.DocumentGeneration.Services.HtmlBodyConverter
{
    public class HtmlBodyFromWordDocumentConverterFacts
    {
        readonly IConvertWordDocToHtml _convertWordDocToHtml = Substitute.For<IConvertWordDocToHtml>();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        readonly IBackgroundProcessLogger<HtmlBodyFromWordDocumentConverter> _logger = Substitute.For<IBackgroundProcessLogger<HtmlBodyFromWordDocumentConverter>>();
        readonly IStorageLocationResolver _storageLocationResolver = Substitute.For<IStorageLocationResolver>();
        readonly ISettingsResolver _settingsResolver = Substitute.For<ISettingsResolver>();
        HtmlBodyFromWordDocumentConverter CreateSubject()
        {
            return new HtmlBodyFromWordDocumentConverter(_logger, _settingsResolver, _convertWordDocToHtml, _storageLocationResolver, _fileSystem, () => Guid.Empty);
        }

        [Theory]
        [InlineData("abc.png", "image/png")]
        [InlineData("abc.jpg", "image/jpeg")]
        [InlineData("abc.jpeg", "image/jpeg")]
        [InlineData("abc.gif", "image/gif")]
        [InlineData("abc.tiff", "image/tiff")]
        public async Task ShouldConvertWordDocumentToHtmlBodyWithDataStreamAsSource(string image, string expectedResolvedMimeType)
        {
            _settingsResolver.Resolve().Returns(new DocumentGenerationSettings
            {
                EmbedImagesUsing = EmbedImagesUsing.DataStream
            });

            var sourceDocumentPath = Fixture.String();
            var imageFolderPath = Fixture.String();
            var imageFilePath = Path.Combine(imageFolderPath, image);

            _storageLocationResolver.UniqueDirectory(fileNameOrPath: "img").Returns(imageFolderPath);

            _convertWordDocToHtml.Convert(sourceDocumentPath, imageFolderPath)
                                 .Returns($"<html><img src=\"{imageFilePath}\"></html>");

            _fileSystem.Files(imageFolderPath, "*.*").Returns(new[] {imageFilePath});

            _fileSystem.ReadAllBytes(imageFilePath).Returns(new byte[500]);

            var subject = CreateSubject();

            var result = await subject.Convert(sourceDocumentPath);

            Assert.StartsWith("<html><img src=\"data:" + expectedResolvedMimeType + ";base64, ", result.Body);
            Assert.EndsWith("=\"></html>", result.Body);  // equal is the delimiter in the base64 encoded value
            Assert.Empty(result.Attachments);
        }

        [Fact]
        public async Task ShouldWarnIfImageMimeTypeUnresolved()
        {
            _settingsResolver.Resolve().Returns(new DocumentGenerationSettings
            {
                EmbedImagesUsing = EmbedImagesUsing.DataStream
            });

            var sourceDocumentPath = Fixture.String();
            var imageFolderPath = Fixture.String();
            var imageFilePath = Path.Combine(imageFolderPath, "abc.xxx");

            _storageLocationResolver.UniqueDirectory(fileNameOrPath: "img").Returns(imageFolderPath);

            _convertWordDocToHtml.Convert(sourceDocumentPath, imageFolderPath)
                                 .Returns($"<html><img src=\"{imageFilePath}\"></html>");

            _fileSystem.Files(imageFolderPath, "*.*").Returns(new[] {imageFilePath});

            _fileSystem.ReadAllBytes(imageFilePath).Returns(new byte[500]);

            var subject = CreateSubject();

            var result = await subject.Convert(sourceDocumentPath);

            Assert.StartsWith("<html><img src=\"data:image/xxx;base64, ", result.Body);
            Assert.EndsWith("=\"></html>", result.Body);  // equal is the delimiter in the base64 encoded value

            _logger.Received(1).Warning($"Conversion to HTML from {sourceDocumentPath} - encountered unknown xxx for MIMETYPE conversion");
        }

        [Fact]
        public async Task ShouldConvertWordDocumentToHtmlBodyWithContentId()
        {
            _settingsResolver.Resolve().Returns(new DocumentGenerationSettings
            {
                EmbedImagesUsing = EmbedImagesUsing.ContentId
            });
            
            var sourceDocumentPath = Fixture.String();
            var imageFolderPath = Fixture.String();
            var imageFilePath = Path.Combine(imageFolderPath, "abc.png");
            var fakeImageBytes = new byte[500];

            _storageLocationResolver.UniqueDirectory(fileNameOrPath: "img").Returns(imageFolderPath);

            _convertWordDocToHtml.Convert(sourceDocumentPath, imageFolderPath)
                                 .Returns($"<html><img src=\"{imageFilePath}\"></html>");

            _fileSystem.Files(imageFolderPath, "*.*").Returns(new[] {imageFilePath});

            _fileSystem.ReadAllBytes(imageFilePath).Returns(fakeImageBytes);

            var subject = CreateSubject();

            var result = await subject.Convert(sourceDocumentPath);

            Assert.Single(result.Attachments);
            Assert.True(result.Attachments.Single().IsInline);
            Assert.Equal(Convert.ToBase64String(fakeImageBytes), result.Attachments.Single().Content);
            Assert.Equal($"<html><img src=\"cid:{result.Attachments.Single().ContentId}\"></html>", result.Body);  
        }
    }
}