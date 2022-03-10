using System;
using System.Linq;
using Dependable.Dispatcher;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web;
using Inprotech.Tests.Web.Builders;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.DmsIntegration
{
    public class BackgroundJobDmsIntegrationWorkflowFacts
    {
        [Collection("Dependable")]
        public class BuildWorkflowToSendAllDownloadedDocumentsToDmsFacts : FactBase
        {
            [Fact]
            public void ShouldContinueSendingRemainingDocumentsFollowingExceptions()
            {
                var docs = new[]
                {
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms),
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms),
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms)
                };

                var f = new DmsIntegrationDependableWireup(Db)
                    .WithDownloadedDocuments(docs);

                f.LoaderAndSender
                 .When(x => x.SendToDms(docs[0].Id))
                 .Do(c => throw new Exception("Bummer !!!"));

                var activity = f.Subject.BuildWorkflowToSendAllDownloadedDocumentsToDms(
                                                                                        DataSourceType.UsptoPrivatePair, Fixture.DefaultJobId);

                f.Execute(activity);

                f.LoaderAndSender.Received(1).SendToDms(docs[1].Id);
                f.LoaderAndSender.Received(1).SendToDms(docs[2].Id);
            }

            [Fact]
            public void ShouldDispatchSendToDmsActivityForEachDocument()
            {
                var docs = new[]
                {
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms),
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SentToDms)
                };

                var f = new DmsIntegrationDependableWireup(Db)
                    .WithDownloadedDocuments(docs);

                var activity = f.Subject.BuildWorkflowToSendAllDownloadedDocumentsToDms(
                                                                                        DataSourceType.UsptoPrivatePair, Fixture.DefaultJobId);

                f.Execute(activity);

                f.LoaderAndSender.Received(1).SendToDms(docs.First().Id);
                f.LoaderAndSender.Received(1).SendToDms(docs.Last().Id);
            }

            [Fact]
            public void ShouldFailDocumentsThatThrowExceptions()
            {
                const string exMessage = "sending failure";

                var docs = new[]
                {
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms),
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms)
                };

                var f = new DmsIntegrationDependableWireup(Db)
                    .WithDownloadedDocuments(docs);

                f.LoaderAndSender
                 .When(x => x.SendToDms(docs.First().Id))
                 .Do(c => throw new Exception(exMessage));

                var activity = f.Subject.BuildWorkflowToSendAllDownloadedDocumentsToDms(
                                                                                        DataSourceType.UsptoPrivatePair, Fixture.DefaultJobId);

                f.Execute(activity);

                // first call fails and the retry fails
                f.FailingSender
                 .Received(2)
                 .Fail(Arg.Is<ExceptionContext>(x => DependableActivity.TestException(x, exMessage)), docs.First().Id);

                f.FailingSender
                 .DidNotReceive()
                 .Fail(Arg.Any<ExceptionContext>(), docs.Last().Id);
            }

            [Fact]
            public void ShouldNotFailAnyJobsThatDontThrowExceptions()
            {
                var docs = new[]
                {
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms),
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms)
                };

                var f = new DmsIntegrationDependableWireup(Db)
                    .WithDownloadedDocuments(docs);

                var activity = f.Subject.BuildWorkflowToSendAllDownloadedDocumentsToDms(
                                                                                        DataSourceType.UsptoPrivatePair, Fixture.DefaultJobId);

                f.Execute(activity);

                f.FailingSender.DidNotReceiveWithAnyArgs().Fail(Arg.Any<ExceptionContext>(), Arg.Any<int>());
            }

            [Fact]
            public void ShouldUpdateJobStateForEachDocumentSent()
            {
                var docs = new[]
                {
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms),
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms)
                };

                var f = new DmsIntegrationDependableWireup(Db)
                    .WithDownloadedDocuments(docs);

                var activity = f.Subject.BuildWorkflowToSendAllDownloadedDocumentsToDms(
                                                                                        DataSourceType.UsptoPrivatePair, Fixture.DefaultJobId);

                f.Execute(activity);

                f.DmsIntegrationJobStateUpdater.Received(2).DocumentSent(Fixture.DefaultJobId);
            }
        }

        [Collection("Dependable")]
        public class BuildWorkflowToSendAnyDocumentsAtSendToDmsFacts : FactBase
        {
            [Theory]
            [InlineData(DocumentDownloadStatus.SendToDms)]
            [InlineData(DocumentDownloadStatus.ScheduledForSendingToDms)]
            [InlineData(DocumentDownloadStatus.Downloaded)]
            [InlineData(DocumentDownloadStatus.Failed)]
            [InlineData(DocumentDownloadStatus.FailedToSendToDms)]
            public void ShouldSetAllDocumentsStatusToSendingToDms(DocumentDownloadStatus status)
            {
                var docs = new[]
                {
                    Fixture.PrivatePairDoc(Db, status),
                    Fixture.TsdrDoc(Db, status)
                };

                var f = new DmsIntegrationDependableWireup(Db)
                    .WithDocumentsAtSendToDms(docs);

                var activity = f.Subject.BuildWorkflowToSendAnyDocumentsAtSendToDms(Fixture.DefaultJobId);

                f.Execute(activity);

                f.LoaderAndSender.Received(1).SendToDms(docs.First().Id);
                f.LoaderAndSender.Received(1).SendToDms(docs.Last().Id);
            }

            [Theory]
            [InlineData(DocumentDownloadStatus.SendToDms)]
            [InlineData(DocumentDownloadStatus.ScheduledForSendingToDms)]
            [InlineData(DocumentDownloadStatus.Downloaded)]
            [InlineData(DocumentDownloadStatus.Failed)]
            [InlineData(DocumentDownloadStatus.FailedToSendToDms)]
            public void ShouldUpdateJobStateForEachDocumentSent(DocumentDownloadStatus status)
            {
                var docs = new[]
                {
                    Fixture.PrivatePairDoc(Db, status),
                    Fixture.TsdrDoc(Db, status)
                };

                var f = new DmsIntegrationDependableWireup(Db)
                    .WithDocumentsAtSendToDms(docs);

                var activity = f.Subject.BuildWorkflowToSendAnyDocumentsAtSendToDms(Fixture.DefaultJobId);

                f.Execute(activity);

                f.DmsIntegrationJobStateUpdater.Received(2).DocumentSent(Fixture.DefaultJobId);
            }

            [Fact]
            public void ShouldContinueSendingRemainingDocumentsFollowingExceptions()
            {
                var docs = new[]
                {
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms),
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms),
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms)
                };

                var f = new DmsIntegrationDependableWireup(Db)
                    .WithDocumentsAtSendToDms(docs);

                f.LoaderAndSender
                 .When(x => x.SendToDms(docs[0].Id))
                 .Do(c => throw new Exception("Bummer !!!"));

                var activity = f.Subject.BuildWorkflowToSendAnyDocumentsAtSendToDms(Fixture.DefaultJobId);

                f.Execute(activity);

                f.LoaderAndSender.Received(1).SendToDms(docs[1].Id);
                f.LoaderAndSender.Received(1).SendToDms(docs[2].Id);
            }

            [Fact]
            public void ShouldFailDocumentsThatThrowExceptions()
            {
                const string exMessage = "sending failure";

                var docs = new[]
                {
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms),
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms)
                };

                var f = new DmsIntegrationDependableWireup(Db)
                    .WithDocumentsAtSendToDms(docs);

                f.LoaderAndSender
                 .When(x => x.SendToDms(docs.First().Id))
                 .Do(c => throw new Exception(exMessage));

                var activity = f.Subject.BuildWorkflowToSendAnyDocumentsAtSendToDms(Fixture.DefaultJobId);

                f.Execute(activity);

                // first call fails and the retry fails
                f.FailingSender
                 .Received(2)
                 .Fail(Arg.Is<ExceptionContext>(x => DependableActivity.TestException(x, exMessage)), docs.First().Id);

                f.FailingSender
                 .DidNotReceive()
                 .Fail(Arg.Any<ExceptionContext>(), docs.Last().Id);
            }

            [Fact]
            public void ShouldNotFailAnyJobsThatDontThrowExceptions()
            {
                var docs = new[]
                {
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms),
                    Fixture.PrivatePairDoc(Db, DocumentDownloadStatus.SendToDms)
                };

                var f = new DmsIntegrationDependableWireup(Db)
                    .WithDownloadedDocuments(docs);

                var activity = f.Subject.BuildWorkflowToSendAllDownloadedDocumentsToDms(
                                                                                        DataSourceType.UsptoPrivatePair, Fixture.DefaultJobId);

                f.Execute(activity);

                f.FailingSender.DidNotReceiveWithAnyArgs().Fail(Arg.Any<ExceptionContext>(), Arg.Any<int>());
            }
        }

        public static class Fixture
        {
            public const long DefaultJobId = 1;

            public static Document PrivatePairDoc(InMemoryDbContext db, DocumentDownloadStatus status)
            {
                return new DocumentBuilder(db)
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    Status = status
                }.Build();
            }

            public static Document TsdrDoc(InMemoryDbContext db, DocumentDownloadStatus status)
            {
                return new DocumentBuilder(db)
                {
                    Source = DataSourceType.UsptoTsdr,
                    Status = status
                }.Build();
            }
        }
    }

    public static class DmsIntegrationDependableWireupExt
    {
        public static DmsIntegrationDependableWireup WithDownloadedDocuments(this DmsIntegrationDependableWireup wireup,
                                                                             params Document[] docs)
        {
            wireup
                .Loader.GetDownloadedDocumentsToSendToDms(Arg.Any<DataSourceType>())
                .Returns(docs);
            return wireup;
        }

        public static DmsIntegrationDependableWireup WithDocumentsAtSendToDms(this DmsIntegrationDependableWireup wireup,
                                                                              params Document[] docs)
        {
            wireup
                .Loader.GetAnyDocumentsAtSendToDms()
                .Returns(docs);
            return wireup;
        }
    }

    public class DocumentBuilder : IBuilder<Document>
    {
        readonly InMemoryDbContext _db;

        public DocumentBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public string ObjectId { get; set; }

        public DocumentDownloadStatus? Status { get; set; }

        public DataSourceType? Source { get; set; }

        public int? Id { get; set; }

        public Document Build()
        {
            var document = new Document
                {
                    DocumentObjectId = ObjectId ?? Fixture.String(),
                    Status = Status ?? DocumentDownloadStatus.Pending,
                    Source = Source ?? DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = Fixture.String()
                }
                .In(_db);

            if (Id.HasValue)
            {
                document.WithKnownId(Id.Value);
            }

            return document;
        }
    }
}