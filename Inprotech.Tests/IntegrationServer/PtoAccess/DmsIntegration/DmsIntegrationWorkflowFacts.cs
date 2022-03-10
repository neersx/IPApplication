using System;
using System.Linq;
using Dependable.Dispatcher;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.DmsIntegration
{
    [Collection("Dependable")]
    public class DmsIntegrationWorkflowFacts : FactBase
    {
        [Fact]
        public void BuildShouldContinueAndSendRestOfDocumentsIfOneFailsToSend()
        {
            const string exMessage = "sending failed";
            var @case = new Case {CorrelationId = 1, ApplicationNumber = "number", Id = 1}.In(Db);
            var document = new Document
            {
                ApplicationNumber = "number",
                DocumentObjectId = "doc1",
                Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                Id = 100
            }.In(Db);

            var document2 = new Document
            {
                ApplicationNumber = "number",
                DocumentObjectId = "doc2",
                Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                Id = 101
            }.In(Db);

            var f = new DmsIntegrationDependableWireup(Db);
            var activity = f.Subject.Build(@case, new[] {document, document2});

            f.Sender.When(x => x.MoveToDms(@case.Id, document.Id)).Do(x => throw new Exception(exMessage));

            f.Execute(activity);

            f.Sender.Received(1).MoveToDms(@case.Id, document2.Id);
        }

        [Fact]
        public void BuildShouldSendDocumentsAtAnyState()
        {
            var f = new DmsIntegrationDependableWireup(Db);
            var @case = new Case {CorrelationId = 1, ApplicationNumber = "number", Id = 1}.In(Db);
            var documents = new[]
            {
                new Document
                {
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc1",
                    Status = DocumentDownloadStatus.SendToDms,
                    Id = 100
                }.In(Db),
                new Document
                {
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc2",
                    Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                    Id = 101
                }.In(Db),
                new Document
                {
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc3",
                    Status = DocumentDownloadStatus.FailedToSendToDms,
                    Id = 102
                }.In(Db),
                new Document
                {
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc4",
                    Status = DocumentDownloadStatus.Downloaded,
                    Id = 103
                },
                new Document
                {
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc5",
                    Status = DocumentDownloadStatus.Failed,
                    Id = 104
                }.In(Db),
                new Document
                {
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc6",
                    Status = DocumentDownloadStatus.Pending,
                    Id = 105
                }.In(Db),
                new Document
                {
                    ApplicationNumber = "number",
                    DocumentObjectId = "doc7",
                    Status = DocumentDownloadStatus.SentToDms,
                    Id = 106
                }.In(Db)
            };

            var activity = f.Subject.Build(@case, documents);

            f.Execute(activity);

            documents.ToList().ForEach(doc => { f.Sender.Received(1).MoveToDms(@case.Id, doc.Id); });
        }

        [Fact]
        public void BuildShouldSendDocumentToDms()
        {
            var f = new DmsIntegrationDependableWireup(Db);
            var @case = new Case {CorrelationId = 1, ApplicationNumber = "number", Id = 1}.In(Db);
            var document = new Document
            {
                ApplicationNumber = "number",
                DocumentObjectId = "doc1",
                Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                Id = 100
            }.In(Db);

            var activity = f.Subject.Build(@case, new[] {document});

            f.Execute(activity);

            f.Sender.Received(1).MoveToDms(@case.Id, document.Id);
        }

        [Fact]
        public void BuildShouldSetDocumentsToDownloadedIfCaseHasNoCorrelationId()
        {
            var @case = new Case {ApplicationNumber = "number", Id = 1}.In(Db);
            var document1 = new Document
            {
                ApplicationNumber = "number",
                DocumentObjectId = "doc1",
                Status = DocumentDownloadStatus.SendToDms,
                Id = 100
            }.In(Db);

            var document2 = new Document
            {
                ApplicationNumber = "number",
                DocumentObjectId = "doc2",
                Status = DocumentDownloadStatus.SendToDms,
                Id = 101
            }.In(Db);

            var f = new DmsIntegrationDependableWireup(Db);
            var activity = f.Subject.Build(@case, new[] {document1, document2});

            f.Execute(activity);

            f.Sender.DidNotReceive().MoveToDms(@case.Id, document1.Id);
            f.Sender.DidNotReceive().MoveToDms(@case.Id, document2.Id);
        }

        [Fact]
        public void BuildShouldSetDocumentToFailedToSendToDmsWhenSendDocumentToDmsThrows()
        {
            const string exMessage = "sending failed";
            var @case = new Case {CorrelationId = 1, ApplicationNumber = "number", Id = 1}.In(Db);
            var document = new Document
            {
                ApplicationNumber = "number",
                DocumentObjectId = "doc1",
                Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                Id = 100
            }.In(Db);

            var document2 = new Document
            {
                ApplicationNumber = "number",
                DocumentObjectId = "doc2",
                Status = DocumentDownloadStatus.ScheduledForSendingToDms,
                Id = 101
            }.In(Db);

            var f = new DmsIntegrationDependableWireup(Db);
            var activity = f.Subject.Build(@case, new[] {document, document2});

            f.Sender.When(x => x.MoveToDms(@case.Id, document.Id)).Do(x => throw new Exception(exMessage));

            f.Execute(activity);

            f.FailingSender.Received(2)
             .Fail(Arg.Is<ExceptionContext>(x => DependableActivity.TestException(x, exMessage)), document.Id);
            f.FailingSender.DidNotReceive().Fail(Arg.Any<ExceptionContext>(), document2.Id);
        }
    }
}