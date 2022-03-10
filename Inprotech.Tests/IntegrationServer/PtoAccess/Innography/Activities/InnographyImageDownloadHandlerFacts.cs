using System.IO;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.Activities
{
    public class InnographyImageDownloadHandlerFacts : FactBase
    {
        IInnographyTrademarksImage InnographyTrademarksImage { get; set; }
        IInnographyIdFromCpaXml InnographyIdFromCpaXml { get; set; }
        IFileSystem FileSystem { get; set; }
        ISourceImageDownloadHandler CreateSubject()
        {
            InnographyTrademarksImage = Substitute.For<IInnographyTrademarksImage>();
            InnographyIdFromCpaXml = Substitute.For<IInnographyIdFromCpaXml>();
            FileSystem = Substitute.For<IFileSystem>();

            return new InnographyImageDownloadHandler(InnographyTrademarksImage, InnographyIdFromCpaXml, FileSystem);
        }
        [Fact]
        public async Task ShouldCallDownloadResultWithCorrectParameters()
        {
            var subject = CreateSubject();
            var eligibleCase = new EligibleCase();
            var xmlPath = Fixture.String();
            var ipId = Fixture.String();
            var imagePath = Fixture.String();

            FileSystem.OpenRead(Arg.Any<string>()).ReturnsForAnyArgs(new MemoryStream(new byte[0]));
            InnographyIdFromCpaXml.Resolve(Arg.Any<string>()).Returns(ipId);

            await subject.Download(eligibleCase, xmlPath, imagePath);

            InnographyIdFromCpaXml.Received(1).Resolve(Arg.Any<string>());
            FileSystem.Received(1).OpenRead(xmlPath);
            InnographyTrademarksImage.Received(1).Download(eligibleCase, imagePath, ipId, true).IgnoreAwaitForNSubstituteAssertion();
        }
    }
}