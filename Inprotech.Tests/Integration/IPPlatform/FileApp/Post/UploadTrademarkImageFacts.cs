using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Post;
using Inprotech.Tests.Extensions;
using Microsoft.WindowsAzure.Storage.Blob;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp.Post
{
    public class UploadTrademarkImageFacts
    {
        readonly ICloudBlob _blobHandler = Substitute.For<ICloudBlob>();
        readonly IFileApiClient _fileApiClient = Substitute.For<IFileApiClient>();
        readonly IFileImageStorageHandler _fileImageStorageHandler = Substitute.For<IFileImageStorageHandler>();

        readonly FileSettings _fileSettings = new FileSettings
        {
            ApiBase = "http://ipplatform.com/file"
        };

        static string SafeFileName(string fileName)
        {
            return Path.GetInvalidFileNameChars()
                       .Aggregate(fileName, (current, c) => current.Replace(c.ToString(), string.Empty));
        }

        [Fact]
        public async Task ShouldOchestrateImageUploadWithSanitizedFileName()
        {
            var token = new TrademarkImageUploadToken
            {
                BaseUri = "http://azuretorage.com",
                SasToken = Fixture.String(),
                Uid = Guid.NewGuid()
            };

            var trademarkImage = new TrademarkImage
            {
                CaseId = Fixture.Integer(),
                CaseReference = Fixture.String("case-ref//abc"),
                ContentType = Fixture.String(),
                Image = new byte[0],
                ImageDescription = Fixture.String("img%desc")
            };

            var blobProperties = new BlobProperties();

            _blobHandler.Properties.Returns(blobProperties);

            _fileApiClient.Put<TrademarkImageUploadToken>(_fileSettings.CasesBlobApi(trademarkImage.CaseId))
                          .Returns(token);

            _fileImageStorageHandler.Create(Arg.Any<Uri>())
                                    .Returns(_blobHandler);

            var subject = new UploadTrademarkImage(_fileApiClient, _fileImageStorageHandler);

            await subject.Upload(trademarkImage, _fileSettings);

            Assert.Equal(trademarkImage.ContentType, blobProperties.ContentType);

            // File Name needs to be sanitised to file name appropriate, so that it does not spill over to a child folder in Azure.
            // The validation api called below will only grant access to the folder returned with the baseUri + sasToken.
            var expectedSanitizedFileName = Uri.EscapeDataString(SafeFileName(trademarkImage.CaseReference + "-" + trademarkImage.ImageDescription));

            var expectedStorageUri = new Uri(token.BaseUri + "/" + expectedSanitizedFileName + ".png" + token.SasToken).ToString();

            var expectedSasAllocationUri = _fileSettings.CasesBlobApi(trademarkImage.CaseId).ToString();

            var expectedAccessGrantUri = _fileSettings.CasesBlobValidateApi(token.Uid).ToString();

            // First call to FILE API endpoint to return sas token for the case image storage
            _fileApiClient.Received(1)
                          .Put<TrademarkImageUploadToken>(Arg.Is<Uri>(_ => _.ToString() == expectedSasAllocationUri))
                          .IgnoreAwaitForNSubstituteAssertion();

            // Setup CloudBlogBlob Uri for upload of the image
            _fileImageStorageHandler.Received(1)
                                    .Create(Arg.Is<Uri>(_ => _.ToString() == expectedStorageUri));

            // Actually uploading the image
            _blobHandler.Received(1)
                        .UploadFromStreamAsync(Arg.Any<Stream>())
                        .IgnoreAwaitForNSubstituteAssertion();

            // Last call to FILE API to grant access to the image so it is viewable in FILE App
            _fileApiClient.Received(1)
                          .Put<dynamic>(Arg.Is<Uri>(_ => _.ToString() == expectedAccessGrantUri))
                          .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}