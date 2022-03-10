using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Innography.Activities;
using Inprotech.IntegrationServer.PtoAccess.Innography.CpaXmlConversion;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.Activities
{
    public class DetailsAvailableFacts
    {
        public class ConvertToCpaXmlMethod
        {
            [Fact]
            public async Task CallsAppropriateMethodsForPatentDownLoad()
            {
                var dataDownload = new DataDownload {Case = new EligibleCase {PropertyType = KnownPropertyTypes.Patent}};

                var f = new DetailsAvailableFixture();

                await f.Subject.ConvertToCpaXml(dataDownload);

                f.DataDownloadLocationResolver.Received(1).Resolve(Arg.Is(dataDownload), Arg.Is(PtoAccessFileNames.CpaXml));

                f.CpaXmlConverter.Received(1).Convert(Arg.Any<ValidationResult>());

                f.BufferedStringWriter.Received(1).Write(Arg.Any<string>(), Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task CallsAppropriateMethodsForTradeMarkDownLoad()
            {
                var dataDownload = new DataDownload {Case = new EligibleCase {PropertyType = KnownPropertyTypes.TradeMark}};

                var f = new DetailsAvailableFixture();

                await f.Subject.ConvertToCpaXml(dataDownload);

                f.DataDownloadLocationResolver.Received(1).Resolve(Arg.Is(dataDownload), Arg.Is(PtoAccessFileNames.CpaXml));

                f.CpaXmlConverter.Received(1).Convert(Arg.Any<TrademarkDataValidationResult>(), Arg.Any<string>());

                f.BufferedStringWriter.Received(1).Write(Arg.Any<string>(), Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
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