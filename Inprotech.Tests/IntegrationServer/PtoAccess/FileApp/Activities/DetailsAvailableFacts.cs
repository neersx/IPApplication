using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.FileApp.Activities;
using Inprotech.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class DetailsAvailableFacts
    {
        public class ConvertToCpaXmlMethod
        {
            [Fact]
            public async Task CallsAppropriateMethods()
            {
                var dataDownload = new DataDownload();

                var instruction = new Instruction();

                var f = new DetailsAvailableFixture();

                await f.Subject.ConvertToCpaXml(dataDownload, instruction);

                f.DataDownloadLocationResolver.Received(1).Resolve(Arg.Is(dataDownload), Arg.Is(PtoAccessFileNames.CpaXml));

                f.DataDownloadLocationResolver.Received(1).Resolve(Arg.Is(dataDownload), Arg.Is(PtoAccessFileNames.ApplicationDetails));

                f.CpaXmlConverter.Received(1).Convert(dataDownload, Arg.Any<FileCase>(), instruction)
                 .IgnoreAwaitForNSubstituteAssertion();

                f.BufferedStringWriter.Received(2).Write(Arg.Any<string>(), Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class DetailsAvailableFixture : IFixture<DetailsAvailable>
        {
            public DetailsAvailableFixture()
            {
                CpaXmlConverter = Substitute.For<ICpaXmlConverter>();

                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();

                BufferedStringWriter = Substitute.For<IBufferedStringWriter>();

                Subject = new DetailsAvailable(CpaXmlConverter, DataDownloadLocationResolver, BufferedStringWriter);
            }

            public ICpaXmlConverter CpaXmlConverter { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public IBufferedStringWriter BufferedStringWriter { get; set; }

            public DetailsAvailable Subject { get; }
        }
    }
}