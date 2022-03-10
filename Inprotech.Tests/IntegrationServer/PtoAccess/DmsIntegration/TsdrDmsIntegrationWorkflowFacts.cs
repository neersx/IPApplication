using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Documents;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.DmsIntegration
{
    [Collection("Dependable")]
    public class TsdrDmsIntegrationWorkflowFacts : FactBase
    {
        [Fact]
        public async Task BuildTsdrShouldNoopIfIntegrationDisabled()
        {
            var @case = new Case {CorrelationId = 1, ApplicationNumber = "number", Id = 1}.In(Db);
            var document = new Document
            {
                ApplicationNumber = "number",
                DocumentObjectId = "doc1",
                Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                Id = 100,
                Source = DataSourceType.UsptoTsdr
            }.In(Db);

            var f = new DmsIntegrationDependableWireup(Db);
            var dataDownload = new DataDownload
            {
                DataSourceType = DataSourceType.UsptoTsdr,
                Case = new EligibleCase {CaseKey = 1, ApplicationNumber = "number"}
            };

            f.Settings.TsdrIntegrationEnabled.Returns(false);

            var activity = await f.Subject.BuildTsdr(dataDownload);

            f.Execute(activity);

            f.Sender.DidNotReceive().MoveToDms(@case.Id, document.Id).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task BuildTsdrShouldOnlySendDocumentsAtSendingToDmsStatus()
        {
            var f = new DmsIntegrationDependableWireup(Db);
            var @case = new Case {CorrelationId = 1, ApplicationNumber = "number", Id = 1}.In(Db);
            var documents = new[]
            {
                new Document
                {
                    Source = DataSourceType.UsptoTsdr,
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc1",
                    Status = DocumentDownloadStatus.SendToDms,
                    Id = 100
                }.In(Db),
                new Document
                {
                    Source = DataSourceType.UsptoTsdr,
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc2",
                    Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                    Id = 101
                }.In(Db),
                new Document
                {
                    Source = DataSourceType.UsptoTsdr,
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc3",
                    Status = DocumentDownloadStatus.SentToDms,
                    Id = 102
                }.In(Db)
            };

            var dataDownload = new DataDownload
            {
                DataSourceType = DataSourceType.UsptoTsdr,
                Case = new EligibleCase {CaseKey = 1, ApplicationNumber = "number"}
            };

            f.Settings.TsdrIntegrationEnabled.Returns(true);
            f.Loader.GetCaseAndDocuments(dataDownload).Returns(new CaseAndDocuments(@case, documents));

            var activity = await f.Subject.BuildTsdr(dataDownload);

            f.Execute(activity);

            f.Sender.Received(1).MoveToDms(@case.Id, documents[1].Id).IgnoreAwaitForNSubstituteAssertion();
            f.Sender.DidNotReceive().MoveToDms(@case.Id, documents[0].Id).IgnoreAwaitForNSubstituteAssertion();
            f.Sender.DidNotReceive().MoveToDms(@case.Id, documents[2].Id).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task BuildTsdrShouldSendToDmsIfEnabled()
        {
            var @case = new Case {CorrelationId = 1, ApplicationNumber = "number", Id = 1}.In(Db);
            var document = new Document
            {
                ApplicationNumber = "number",
                DocumentObjectId = "doc1",
                Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                Id = 100,
                Source = DataSourceType.UsptoTsdr
            }.In(Db);

            var f = new DmsIntegrationDependableWireup(Db);
            var dataDownload = new DataDownload
            {
                DataSourceType = DataSourceType.UsptoTsdr,
                Case = new EligibleCase {CaseKey = 1, ApplicationNumber = "number"}
            };

            f.Settings.TsdrIntegrationEnabled.Returns(true);
            f.Loader.GetCaseAndDocuments(dataDownload).Returns(new CaseAndDocuments(@case, new[] {document}));

            var activity = await f.Subject.BuildTsdr(dataDownload);

            f.Execute(activity);

            f.Sender.Received(1).MoveToDms(@case.Id, document.Id).IgnoreAwaitForNSubstituteAssertion();
        }
    }
}