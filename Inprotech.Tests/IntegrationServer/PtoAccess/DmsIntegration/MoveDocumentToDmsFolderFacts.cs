using System.Threading.Tasks;
using Inprotech.Contracts.Messages.PtoAccess.DmsIntegration;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.DmsIntegration
{
    public class MoveDocumentToDmsFolderFacts
    {
        public class MoveToDmsMethod : FactBase
        {
            readonly Case _case = new Case
            {
                Id = 1,
                CorrelationId = 1,
                Source = DataSourceType.UsptoPrivatePair
            };

            readonly Document _document = new Document
            {
                Source = DataSourceType.UsptoPrivatePair,
                FileStore = new FileStore {Path = "blah"},
                Id = 1,
                Status = DocumentDownloadStatus.SendToDms
            };

            [Fact]
            public async Task MoveFileAsRequired()
            {
                var fixture = new MoveDocumentToDmsFolderFixture()
                    .LoaderReturns(_case, _document);

                fixture.UpdateDocumentStatus.UpdateTo(_document.Id, Arg.Any<DocumentDownloadStatus>())
                       .Returns(Task.FromResult(true));

                await fixture.Subject.MoveToDms(_case.Id, _document.Id);

                fixture.DocumentForDms.Received(1)
                       .MoveDocumentWithItsMetadata(_document, Arg.Any<int>())
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.DmsIntegrationPublisher.Received(1)
                       .Publish(Arg.Is<DmsIntegrationMessage>(x => x.Message.StartsWith("Item sent to DMS")));
            }

            [Fact]
            public async Task PreventDmsIntegrationWithoutCorrectStatus()
            {
                var fixture = new MoveDocumentToDmsFolderFixture()
                    .LoaderReturns(_case, _document);

                fixture.UpdateDocumentStatus.UpdateTo(_document.Id, Arg.Any<DocumentDownloadStatus>())
                       .Returns(Task.FromResult(false));

                await fixture.Subject.MoveToDms(_case.Id, _document.Id);

                fixture.DocumentForDms.DidNotReceive()
                       .MoveDocumentWithItsMetadata(_document, Arg.Any<int>())
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.DmsIntegrationPublisher.Received(1)
                       .Publish(
                                Arg.Is<DmsIntegrationMessage>(
                                                              x =>
                                                                  x.Message.StartsWith(
                                                                                       "Transition to 'SendingToDms' state is not allowed, current state: ")));
            }

            [Fact]
            public async Task PreventDmsIntegrationWithoutCorrelationId()
            {
                var fixture = new MoveDocumentToDmsFolderFixture()
                    .LoaderReturns(_case, _document);

                _case.CorrelationId = null;

                await fixture.Subject.MoveToDms(_case.Id, _document.Id);

                fixture.DocumentForDms.DidNotReceive()
                       .MoveDocumentWithItsMetadata(_document, Arg.Any<int>())
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.DmsIntegrationPublisher.Received(1)
                       .Publish(Arg.Is<DmsIntegrationMessage>(x => x.Message == "Case has no correlationId"));
            }

            [Fact]
            public async Task UpdateToSentToDmsStatus()
            {
                var fixture = new MoveDocumentToDmsFolderFixture()
                    .LoaderReturns(_case, _document);

                fixture.UpdateDocumentStatus.UpdateTo(_document.Id, Arg.Any<DocumentDownloadStatus>())
                       .Returns(Task.FromResult(true));

                await fixture.Subject.MoveToDms(_case.Id, _document.Id);

                fixture.UpdateDocumentStatus.Received(1)
                       .UpdateTo(_document.Id, DocumentDownloadStatus.SentToDms)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class MoveDocumentToDmsFolderFixture : IFixture<MoveDocumentToDmsFolder>
        {
            public MoveDocumentToDmsFolderFixture()
            {
                Loader = Substitute.For<ILoadCaseAndDocuments>();

                UpdateDocumentStatus = Substitute.For<IUpdateDocumentStatus>();

                DocumentForDms = Substitute.For<IDocumentForDms>();

                DmsIntegrationPublisher = Substitute.For<IDmsIntegrationPublisher>();

                CorrelationIdUpdator = Substitute.For<ICorrelationIdUpdator>();

                Subject = new MoveDocumentToDmsFolder(Loader, UpdateDocumentStatus, DocumentForDms, DmsIntegrationPublisher, CorrelationIdUpdator);
            }

            public ILoadCaseAndDocuments Loader { get; set; }

            public IUpdateDocumentStatus UpdateDocumentStatus { get; set; }

            public IDmsIntegrationPublisher DmsIntegrationPublisher { get; set; }

            public IDocumentForDms DocumentForDms { get; set; }

            public ICorrelationIdUpdator CorrelationIdUpdator { get; set; }

            public MoveDocumentToDmsFolder Subject { get; set; }

            public MoveDocumentToDmsFolderFixture LoaderReturns(Case @case, Document doc)
            {
                Loader.GetCaseAndDocumentsFor(@case.Id, doc.Id)
                      .Returns(new CaseAndDocuments(@case, new[] {doc}));

                return this;
            }
        }
    }
}