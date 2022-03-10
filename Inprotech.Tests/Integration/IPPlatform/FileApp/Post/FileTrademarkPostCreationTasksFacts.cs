using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.Integration.IPPlatform.FileApp.Post;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp.Post
{
    public class FileTrademarkPostCreationTasksFacts
    {
        readonly ILogger<FileTrademarkPostCreationTasks> _logger = Substitute.For<ILogger<FileTrademarkPostCreationTasks>>();
        readonly ITrademarkImageResolver _trademarkImageResolver = Substitute.For<ITrademarkImageResolver>();
        readonly IUploadTrademarkImage _uploadTrademarkImage = Substitute.For<IUploadTrademarkImage>();
        readonly FileSettings _fileSettings = new FileSettings();

        readonly FileCase _fileCase = new FileCase
        {
            Id = Fixture.Integer().ToString()
        };

        FileTrademarkPostCreationTasks CreateSubject()
        {
            return new FileTrademarkPostCreationTasks(_trademarkImageResolver, _uploadTrademarkImage, _logger);
        }

        [Fact]
        public async Task ShouldLogTheError()
        {
            var trademarkImage = new TrademarkImage();

            _trademarkImageResolver.Resolve(int.Parse(_fileCase.Id))
                                   .Returns(trademarkImage);

            _uploadTrademarkImage
                .When(_ => _.Upload(trademarkImage, _fileSettings))
                .Do(x => throw new Exception("bummer"));

            await CreateSubject().Perform(_fileSettings, _fileCase);

            _logger.Received(1).Exception(Arg.Is<Exception>(_ => _.Message == "bummer"));
        }

        [Fact]
        public async Task ShouldReturnWithoutUploadingIfNoSuitableTrademarkImageIsResolved()
        {
            await CreateSubject().Perform(_fileSettings, _fileCase);

            _uploadTrademarkImage
                .DidNotReceive()
                .Upload(Arg.Any<TrademarkImage>(), Arg.Any<FileSettings>())
                .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldUploadResolvedTrademarkImage()
        {
            var trademarkImage = new TrademarkImage();

            _trademarkImageResolver.Resolve(int.Parse(_fileCase.Id))
                                   .Returns(trademarkImage);

            await CreateSubject().Perform(_fileSettings, _fileCase);

            _uploadTrademarkImage
                .Received(1)
                .Upload(Arg.Any<TrademarkImage>(), Arg.Any<FileSettings>())
                .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}