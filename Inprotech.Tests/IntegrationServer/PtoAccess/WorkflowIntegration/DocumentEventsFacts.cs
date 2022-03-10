using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;
using Workflow = Inprotech.IntegrationServer.PtoAccess.WorkflowIntegration;
using Components = Inprotech.Integration.AutomaticDocketing;

#pragma warning disable 1998

namespace Inprotech.Tests.IntegrationServer.PtoAccess.WorkflowIntegration
{
    public class DocumentEventsFacts
    {
        public class UpdateFromPtoMethod : FactBase
        {
            [Theory]
            [InlineData(DataSourceType.UsptoTsdr, "USPTO.TSDR")]
            [InlineData(DataSourceType.Epo, "EPO")]
            public async Task SendsDocumentsForUpdate(DataSourceType dataSourceType, string systemCode)
            {
                var f = new DocumentEventsFixture(Db)
                        .HasDocumentWith(Components.DocumentEventStatus.Pending)
                        .HasDocumentWith(Components.DocumentEventStatus.Processing)
                        .HasDocumentWith(Components.DocumentEventStatus.Pending);

                f.Subject.UpdateFromPto(new DataDownload
                {
                    DataSourceType = dataSourceType,
                    Case = new EligibleCase
                    {
                        CaseKey = 999
                    }
                }).IgnoreAwaitForNSubstituteAssertion();

                f.DocumentEvents.Received(1)
                 .UpdateAutomatically(systemCode, 999, Arg.Is<IEnumerable<Document>>(_ => _.Count() == 3));
            }

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr, "USPTO.TSDR")]
            [InlineData(DataSourceType.Epo, "EPO")]
            public async Task DropsOutIfThereAreNoPendingDocuments(DataSourceType dataSourceType, string systemCode)
            {
                var f = new DocumentEventsFixture(Db)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed);

                f.Subject.UpdateFromPto(new DataDownload
                {
                    DataSourceType = dataSourceType,
                    Case = new EligibleCase
                    {
                        CaseKey = 999
                    }
                }).IgnoreAwaitForNSubstituteAssertion();

                f.DocumentEvents.DidNotReceive()
                 .UpdateAutomatically(systemCode, 999, Arg.Is<IEnumerable<Document>>(_ => _.Count() == 3));
            }
        }

        public class UpdateFromPrivatePairMethod : FactBase
        {
            [Fact]
            public async Task CallsToUpdateCorrelationId()
            {
                var f = new DocumentEventsFixture(Db)
                    .WithIntegrationcase("12345");

                await f.Subject.UpdateFromPrivatePair(new ApplicationDownload { Number = "12345" });

                f.CorrelationIdUpdator.Received(1).UpdateIfRequired(Arg.Any<Case>());
            }

            [Fact]
            public async Task DropsOutIfInprotechCaseNotFound()
            {
                var f = new DocumentEventsFixture(Db)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed)
                        .HasDocumentsFromWayBefore();

                await f.Subject.UpdateFromPrivatePair(
                                                      new ApplicationDownload
                                                      {
                                                          Number = "12345"
                                                      });

                f.DocumentEvents.DidNotReceiveWithAnyArgs()
                 .UpdateAutomatically(null, 0, null);
            }

            [Fact]
            public async Task DropsOutIfNotCorrelatedWithInprotechCase()
            {
                var f = new DocumentEventsFixture(Db)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed);

                new Case
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = "12345",
                    CorrelationId = null
                }.In(Db);

                await f.Subject.UpdateFromPrivatePair(
                                                      new ApplicationDownload
                                                      {
                                                          Number = "12345"
                                                      });

                f.DocumentEvents.DidNotReceiveWithAnyArgs()
                 .UpdateAutomatically(null, 0, null);
            }

            [Fact]
            public async Task DropsOutIfThereAreNoPendingDocuments()
            {
                var f = new DocumentEventsFixture(Db)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed)
                        .HasDocumentWith(Components.DocumentEventStatus.Processed);

                new Case
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = "12345",
                    CorrelationId = 999
                }.In(Db);

                await f.Subject.UpdateFromPrivatePair(
                                                      new ApplicationDownload
                                                      {
                                                          Number = "12345"
                                                      });

                f.DocumentEvents.DidNotReceive()
                 .UpdateAutomatically("USPTO.PrivatePAIR", 999, Arg.Is<IEnumerable<Document>>(_ => _.Count() == 3));
            }

            [Fact]
            public async Task SendsDocumentsNotDownloadedForComparison()
            {
                var f = new DocumentEventsFixture(Db)
                        .HasDocumentWith(Components.DocumentEventStatus.Pending)
                        .HasDocumentWith(Components.DocumentEventStatus.Processing)
                        .HasDocumentWith(Components.DocumentEventStatus.Pending)
                        /* image file wrapper document that was never downloaded, but critical for resolving cycle in comparison */
                        .HasDocumentsFromWayBefore()
                        .HasDocumentsFromWayBefore();

                new Case
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = "12345",
                    CorrelationId = 999
                }.In(Db);

                await f.Subject.UpdateFromPrivatePair(
                                                      new ApplicationDownload
                                                      {
                                                          Number = "12345"
                                                      });

                f.DocumentEvents.Received(1)
                 .UpdateAutomatically("USPTO.PrivatePAIR", 999, Arg.Is<IEnumerable<Document>>(_ => _.Count() == 5));
            }

            [Fact]
            public async Task SendsOnlyDownloadedDocumentsForUpdate()
            {
                var f = new DocumentEventsFixture(Db)
                        .HasDocumentWith(Components.DocumentEventStatus.Pending)
                        .HasDocumentWith(Components.DocumentEventStatus.Processing)
                        .HasDocumentWith(Components.DocumentEventStatus.Pending);

                new Case
                {
                    Source = DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = "12345",
                    CorrelationId = 999
                }.In(Db);

                await f.Subject.UpdateFromPrivatePair(
                                                      new ApplicationDownload
                                                      {
                                                          Number = "12345"
                                                      });

                f.DocumentEvents.Received(1)
                 .UpdateAutomatically("USPTO.PrivatePAIR", 999, Arg.Is<IEnumerable<Document>>(_ => _.Count() == 3));
            }

            [Fact]
            public async Task ThrowsExceptionIfCorrelationIdUpdatorThrowsException()
            {
                await Assert.ThrowsAsync<Exception>(
                                                    async () =>
                                                    {
                                                        var f = new DocumentEventsFixture(Db)
                                                                .WithIntegrationcase("12345")
                                                                .WithMultipleInprotechCases();

                                                        await f.Subject.UpdateFromPrivatePair(new ApplicationDownload { Number = "12345" });
                                                    }
                                                   );
            }
        }

        public class DocumentEventsFixture : IFixture<Workflow.DocumentEvents>
        {
            readonly List<ComparisonDocument> _comparisonDocument = new List<ComparisonDocument>();
            readonly InMemoryDbContext _db;

            public DocumentEventsFixture(InMemoryDbContext db)
            {
                _db = db;
                DocumentLoader = Substitute.For<IDocumentLoader>();

                DocumentEvents = Substitute.For<Components.IDocumentEvents>();

                CorrelationIdUpdator = Substitute.For<ICorrelationIdUpdator>();

                ComparisonDocumentsProvider = Substitute.For<IComparisonDocumentsProvider>();
                ComparisonDocumentProviderReturnsBothIfwAndConfiguredDocs();

                Subject = new Workflow.DocumentEvents(db, DocumentLoader, DocumentEvents,
                                                      CorrelationIdUpdator,
                                                      ComparisonDocumentsProvider);
            }

            public IDocumentLoader DocumentLoader { get; set; }

            public IComparisonDocumentsProvider ComparisonDocumentsProvider { get; set; }

            public Components.IDocumentEvents DocumentEvents { get; set; }

            public ICorrelationIdUpdator CorrelationIdUpdator { get; set; }

            public Workflow.DocumentEvents Subject { get; set; }

            public DocumentEventsFixture WithIntegrationcase(string applicationNumber)
            {
                _db.Set<Case>().Add(new Case { ApplicationNumber = applicationNumber });

                return this;
            }

            public DocumentEventsFixture HasDocumentWith(Components.DocumentEventStatus status,
                                                         DateTime? mailRoomDate = null)
            {
                var doc = new Document
                {
                    MailRoomDate = mailRoomDate ?? Fixture.Today()
                }.In(_db);

                doc.DocumentEvent = new Components.DocumentEvent(doc)
                {
                    Status = status
                }.In(_db);

                LoaderReturningAllDocuments();

                return this;
            }

            public DocumentEventsFixture HasDocumentsFromWayBefore(DateTime? mailRoomDate = null)
            {
                _comparisonDocument.Add(new ComparisonDocument
                {
                    MailRoomDate = mailRoomDate ?? Fixture.Today()
                });

                ComparisonDocumentProviderReturnsBothIfwAndConfiguredDocs();

                return this;
            }

            void ComparisonDocumentProviderReturnsBothIfwAndConfiguredDocs()
            {
                ComparisonDocumentsProvider
                    .For(Arg.Any<ApplicationDownload>(), Arg.Any<Document[]>())
                    .ReturnsForAnyArgs(
                                       x =>
                                       {
                                           var persistedDocs = (Document[])x[1] ?? new Document[0];
                                           return _comparisonDocument.Concat(persistedDocs).OrderByDescending(_ => _.MailRoomDate);
                                       });
            }

            void LoaderReturningAllDocuments()
            {
                DocumentLoader.GetDocumentsFrom(Arg.Any<DataSourceType>(), Arg.Any<int?>())
                              .Returns(_db.Set<Document>());
            }

            public DocumentEventsFixture WithMultipleInprotechCases()
            {
                CorrelationIdUpdator
                    .When(_ => _.UpdateIfRequired(Arg.Any<Case>()))
                    .Do(_ => throw new Exception("Multiple cases"));

                return this;
            }
        }
    }
}