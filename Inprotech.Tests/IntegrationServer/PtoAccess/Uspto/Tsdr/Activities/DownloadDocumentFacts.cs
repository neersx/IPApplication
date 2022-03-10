using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Documents;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities;
using NSubstitute;
using Xunit;

#pragma warning disable 4014

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class DownloadDocumentFacts
    {
        public class DownloadMethod : FactBase
        {
            readonly DataDownload _dataDownload = new DataDownload
            {
                Case = new EligibleCase {ApplicationNumber = "app", RegistrationNumber = "reg", CaseKey = 999},
                DataSourceType = DataSourceType.UsptoTsdr
            };

            [Fact]
            public async Task CallsPtoDocumentPassingTsdrDocumentDownloadMethod()
            {
                var f = new DownloadDocumentFixture();

                var doc = new Document
                {
                    ApplicationNumber = "app",
                    Source = DataSourceType.UsptoTsdr,
                    DocumentObjectId = "ObjId",
                    DocumentDescription = "b"
                };
                await f.Subject.Download(_dataDownload, doc);

                f.PtoDocument.Received(1).Download(_dataDownload, doc, f.TsdrDocumentClient.Download);
            }
        }

        public class DownloadDocumentFixture : IFixture<DownloadDocument>
        {
            public DownloadDocumentFixture()
            {
                PtoDocument = Substitute.For<IPtoDocument>();
                TsdrDocumentClient = Substitute.For<ITsdrDocumentClient>();

                Subject = new DownloadDocument(PtoDocument, TsdrDocumentClient);
            }

            public ITsdrDocumentClient TsdrDocumentClient { get; set; }

            public IPtoDocument PtoDocument { get; set; }
            public DownloadDocument Subject { get; }
        }
    }
}