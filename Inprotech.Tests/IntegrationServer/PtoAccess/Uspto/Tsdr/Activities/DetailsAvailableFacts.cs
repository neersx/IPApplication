using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class DetailsAvailableFacts
    {
        public class ConvertToCpaXmlMethod
        {
            [Fact]
            public async Task CallsAppropriateMethods()
            {
                var dataDownload = new DataDownload();

                var f = new DetailsAvailableFixture();

                await f.Subject.ConvertToCpaXml(dataDownload);

                f.DataDownloadLocationResolver.Received(1).Resolve(Arg.Is(dataDownload), Arg.Is(PtoAccessFileNames.ApplicationDetails));

                f.DataDownloadLocationResolver.Received(1).Resolve(Arg.Is(dataDownload), Arg.Is(PtoAccessFileNames.CpaXml));

                f.BufferedStringReader.Received(1).Read(Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();

                f.CpaXmlConverter.Received(1).Convert(Arg.Any<EligibleCase>(), Arg.Any<string>());

                f.BufferedStringWriter.Received(1).Write(Arg.Any<string>(), Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class DetailsAvailableFixture : IFixture<DetailsAvailable>
        {
            public DetailsAvailableFixture()
            {
                CpaXmlConverter = Substitute.For<ICpaXmlConverter>();

                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();

                BufferedStringReader = Substitute.For<IBufferedStringReader>();

                BufferedStringWriter = Substitute.For<IBufferedStringWriter>();

                FileSystem = Substitute.For<IFileSystem>();

                Subject = new DetailsAvailable(CpaXmlConverter, DataDownloadLocationResolver, BufferedStringReader, BufferedStringWriter, FileSystem);
            }

            public ICpaXmlConverter CpaXmlConverter { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public IBufferedStringReader BufferedStringReader { get; set; }

            public IBufferedStringWriter BufferedStringWriter { get; set; }

            public IFileSystem FileSystem { get; set; }
            public DetailsAvailable Subject { get; }
        }
    }
}