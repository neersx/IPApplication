using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Documents;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Epo;
using Inprotech.IntegrationServer.PtoAccess.Epo.Activities;
using NSubstitute;
using Xunit;

#pragma warning disable 4014

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.Activities
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
            public async Task CallsPtoDocumentPassingEpRegisterDocumentDownloadMethod()
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

                f.PtoDocument.Received(1).Download(_dataDownload, doc, f.EpRegisterClient.DownloadDocument);
            }
        }

        public class DownloadDocumentFixture : IFixture<DownloadDocument>
        {
            public DownloadDocumentFixture()
            {
                PtoDocument = Substitute.For<IPtoDocument>();
                EpRegisterClient = Substitute.For<IEpRegisterClient>();

                Subject = new DownloadDocument(PtoDocument, EpRegisterClient);
            }

            public IEpRegisterClient EpRegisterClient { get; set; }

            public IPtoDocument PtoDocument { get; set; }
            public DownloadDocument Subject { get; }
        }
    }
}