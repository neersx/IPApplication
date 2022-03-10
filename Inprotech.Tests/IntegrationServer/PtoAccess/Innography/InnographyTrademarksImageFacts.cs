using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Persistence;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography
{
    public class InnographyTrademarksImageFacts
    {
        IPtoAccessCase PtoAccessCase { get; set; }
        IInnographyTradeMarksImageClient TradeMarksImageClient { get; set; }
        IChunkedStreamWriter StreamWriter { get; set; }
        IRepository Repository { get; set; }

        public InnographyTrademarksImage CreateSubject()
        {
            TradeMarksImageClient = Substitute.For<IInnographyTradeMarksImageClient>();
            PtoAccessCase = Substitute.For<IPtoAccessCase>();
            StreamWriter = Substitute.For<IChunkedStreamWriter>();
            Repository = Substitute.For<IRepository>();

            return new InnographyTrademarksImage(TradeMarksImageClient, PtoAccessCase, StreamWriter, Repository);
        }

        [Fact]
        public async Task ShouldThrowExceptionIfIpIdIsNull()
        {
            var subject = CreateSubject();
            var exception = await Assert.ThrowsAsync<ArgumentNullException>(
                                                                            async () => await subject.Download(new EligibleCase(), Fixture.String(), string.Empty));

            Assert.IsType<ArgumentNullException>(exception);
            Assert.Contains("ipid", exception.Message);
        }

        [Fact]
        public async Task ShouldNotCallImageApiIfCaseFileDoesNotExist()
        {
            var subject = CreateSubject();

            PtoAccessCase.CaseFileExists(Arg.Any<int>(), Arg.Any<DataSourceType>(), Arg.Any<CaseFileType>()).Returns(true);

            await subject.Download(new EligibleCase(), Fixture.String(), Fixture.String());

            PtoAccessCase.Received(1).CaseFileExists(Arg.Any<int>(), Arg.Any<DataSourceType>(), Arg.Any<CaseFileType>());
            TradeMarksImageClient.Received(0).ImageApi(Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldNotWriteToStreamWriterIfNoImagesAreReturned()
        {
            var subject = CreateSubject();
            var ipId = Fixture.String();
            PtoAccessCase.CaseFileExists(Arg.Any<int>(), Arg.Any<DataSourceType>(), Arg.Any<CaseFileType>()).Returns(false);
            TradeMarksImageClient.ImageApi(ipId).Returns(new InnographyApiResponse<TrademarkImage>());

            await subject.Download(new EligibleCase(), Fixture.String(), ipId);

            PtoAccessCase.Received(1).CaseFileExists(Arg.Any<int>(), Arg.Any<DataSourceType>(), Arg.Any<CaseFileType>());
            TradeMarksImageClient.Received(1).ImageApi(ipId).IgnoreAwaitForNSubstituteAssertion();
            StreamWriter.Received(0).Write(Arg.Any<string>(), Arg.Any<Stream>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldCallSaveChanges()
        {
            var subject = CreateSubject();
            var ipId = Fixture.String();
            PtoAccessCase.CaseFileExists(Arg.Any<int>(), Arg.Any<DataSourceType>(), Arg.Any<CaseFileType>()).Returns(false);
            TradeMarksImageClient.ImageApi(ipId).Returns(new InnographyApiResponse<TrademarkImage>
            {
                Result = new[]
                {
                    new TrademarkImage
                        {Content = Convert.ToBase64String(Encoding.ASCII.GetBytes(Fixture.String())), Type = Fixture.String()}
                }
            });

            await subject.Download(new EligibleCase(), Fixture.String(), ipId);

            PtoAccessCase.Received(1).CaseFileExists(Arg.Any<int>(), Arg.Any<DataSourceType>(), Arg.Any<CaseFileType>());
            TradeMarksImageClient.Received(1).ImageApi(ipId).IgnoreAwaitForNSubstituteAssertion();
            StreamWriter.Received(1).Write(Arg.Any<string>(), Arg.Any<Stream>()).IgnoreAwaitForNSubstituteAssertion();
            Repository.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
        }
    }
}