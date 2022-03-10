using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.DmsIntegration
{
    [Collection("Dependable")]
    public class PrivatePairDmsIntegrationWorkflowFacts : FactBase
    {
        [Fact]
        public void BuildPrivatePairShouldNoopIfIntegrationDisabled()
        {
            var @case = new Case {CorrelationId = 1, ApplicationNumber = "number", Id = 1}.In(Db);
            var document = new Document
            {
                ApplicationNumber = "number",
                DocumentObjectId = "doc1",
                Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                Id = 100,
                Source = DataSourceType.UsptoPrivatePair
            }.In(Db);

            var f = new DmsIntegrationDependableWireup(Db);
            var applicationDownload = new ApplicationDownload
            {
                Number = "number"
            };

            f.Settings.PrivatePairIntegrationEnabled.Returns(false);

            var activity = f.Subject.BuildPrivatePair(applicationDownload);

            f.Execute(activity);

            f.Sender.DidNotReceive().MoveToDms(@case.Id, document.Id).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void BuildPrivatePairShouldOnlySendDocumentsAtSendingToDmsStatus()
        {
            var f = new DmsIntegrationDependableWireup(Db);
            var @case = new Case {CorrelationId = 1, ApplicationNumber = "number", Id = 1}.In(Db);
            var documents = new[]
            {
                new Document
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc1",
                    Status = DocumentDownloadStatus.SendToDms,
                    Id = 100
                }.In(Db),
                new Document
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc2",
                    Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                    Id = 101
                }.In(Db),
                new Document
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc3",
                    Status = DocumentDownloadStatus.SentToDms,
                    Id = 102
                }.In(Db)
            };

            var applicationDownload = new ApplicationDownload
            {
                Number = "number"
            };

            f.Settings.PrivatePairIntegrationEnabled.Returns(true);
            f.Loader.GetCaseAndDocuments(applicationDownload).Returns(new CaseAndDocuments(@case, documents));

            var activity = f.Subject.BuildPrivatePair(applicationDownload);

            f.Execute(activity);

            f.Sender.Received(1).MoveToDms(@case.Id, documents[1].Id).IgnoreAwaitForNSubstituteAssertion();
            f.Sender.DidNotReceive().MoveToDms(@case.Id, documents[0].Id).IgnoreAwaitForNSubstituteAssertion();
            f.Sender.DidNotReceive().MoveToDms(@case.Id, documents[2].Id).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void BuildPrivatePairShouldSendToDmsIfEnabled()
        {
            var @case = new Case {CorrelationId = 1, ApplicationNumber = "number", Id = 1}.In(Db);
            var document = new Document
            {
                ApplicationNumber = "number",
                DocumentObjectId = "doc1",
                Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                Id = 100,
                Source = DataSourceType.UsptoPrivatePair
            }.In(Db);

            var f = new DmsIntegrationDependableWireup(Db);
            var applicationDownload = new ApplicationDownload
            {
                Number = "number"
            };

            f.Settings.PrivatePairIntegrationEnabled.Returns(true);

            f.Loader.GetCaseAndDocuments(applicationDownload).Returns(new CaseAndDocuments(@case, new[] {document}));

            var activity = f.Subject.BuildPrivatePair(applicationDownload);

            f.Execute(activity);

            f.Sender.Received(1).MoveToDms(@case.Id, document.Id).IgnoreAwaitForNSubstituteAssertion();
        }
    }
}