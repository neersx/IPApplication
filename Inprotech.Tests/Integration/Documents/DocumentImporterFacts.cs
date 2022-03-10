using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Storage;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Components.ContactActivities;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.ContactActivities;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Documents
{
    public class DocumentImporterFacts
    {
        public class ImportMethod : FactBase
        {
            Case CreateCase(bool? withEthicalWallRestriction = false)
            {
                var @case = new Case("123", new Country(), new CaseType(), new PropertyType()).In(Db);

                if (!withEthicalWallRestriction.GetValueOrDefault())
                {
                    new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                }

                return @case;
            }

            [Theory]
            [InlineData("audio/wav", "audio/wav")]
            [InlineData("audio/mp3", "audio/mp3")]
            [InlineData(null, "application/pdf")]
            public async Task DefaultAsPdfIfMediaTypeNotProvided(string mediaType, string expectedContentType)
            {
                var f = new DocumentImporterFixture(Db);
                var userIdentityId = Fixture.Integer();
                var @case = CreateCase();
                var doc = new Document
                {
                    Reference = Guid.NewGuid(),
                    FileStore = new FileStore(),
                    MediaType = mediaType
                }.In(Db);

                f.OccurredEvents.For(@case).Returns(new[] {new OccurredEvent {CaseId = @case.Id, EventId = 1, Cycle = 1}});
                f.CreateActivityAttachment.Exec(
                                                userIdentityId,
                                                null,
                                                null,
                                                0,
                                                0,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                false,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null).ReturnsForAnyArgs(
                                                                        x =>
                                                                        {
                                                                            var a = new Activity().In(Db);
                                                                            a.Attachments.Add(new ActivityAttachment().In(Db));
                                                                            return a;
                                                                        });

                await f.Subject.Import(userIdentityId, new DocumentImport
                {
                    CaseId = @case.Id,
                    DocumentId = doc.Id,
                    EventId = 1,
                    Cycle = 1,
                    AttachmentName = "attachment_name"
                });

                var attachment = Db.Set<Activity>().Single().Attachments.Single();

                Assert.Equal(expectedContentType, attachment.AttachmentContent.ContentType);
            }

            [Fact]
            public async Task ReturnsInvalidCycleResponseIfCycleExceededCurrentlyHighestCycle()
            {
                var f = new DocumentImporterFixture(Db);

                var @case = CreateCase();
                var doc = new Document().In(Db);

                f.OccurredEvents.For(@case)
                 .Returns(new[] {new OccurredEvent {CaseId = @case.Id, EventId = 1, Cycle = 1}});

                var response =
                    await f.Subject.Import(Fixture.Integer(),
                                           new DocumentImport {CaseId = @case.Id, DocumentId = doc.Id, EventId = 1, Cycle = 5});

                Assert.Equal("invalid-cycle", response.Result);
            }

            [Fact]
            public async Task ReturnsInvalidCycleResponseIfCycleNotProvided()
            {
                var f = new DocumentImporterFixture(Db);

                var @case = CreateCase();
                var doc = new Document().In(Db);

                f.OccurredEvents.For(@case)
                 .Returns(new[] {new OccurredEvent {CaseId = @case.Id, EventId = 1, Cycle = 1}});

                var response =
                    await f.Subject.Import(Fixture.Integer(),
                                           new DocumentImport
                                           {
                                               CaseId = @case.Id,
                                               DocumentId = doc.Id,
                                               EventId = 1,
                                               Cycle = null
                                           });

                Assert.Equal("invalid-cycle", response.Result);
            }

            [Fact]
            public async Task SavesTheAttachment()
            {
                var f = new DocumentImporterFixture(Db);
                var userIdentityId = Fixture.Integer();
                var @case = CreateCase();
                var doc = new Document().In(Db);

                doc.Reference = Guid.NewGuid();
                doc.FileStore = new FileStore();

                f.OccurredEvents.For(@case)
                 .Returns(new[] {new OccurredEvent {CaseId = @case.Id, EventId = 1, Cycle = 1}});
                f.DefaultFileNameFormatter.Format(doc).Returns("formatted_file_name");
                f.CreateActivityAttachment.Exec(userIdentityId,
                                                null,
                                                null,
                                                0,
                                                0,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                false,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null).ReturnsForAnyArgs(
                                                                        x =>
                                                                        {
                                                                            var a = new Activity().In(Db);
                                                                            a.Attachments.Add(new ActivityAttachment().In(Db));
                                                                            return a;
                                                                        });

                var input = new DocumentImport
                {
                    CaseId = @case.Id,
                    DocumentId = doc.Id,
                    EventId = 1,
                    Cycle = 1,
                    AttachmentName = "attachment_name"
                };

                var response = await f.Subject.Import(userIdentityId, input);

                var activity = Db.Set<Activity>().Single();
                var attachment = activity.Attachments.Single();

                Assert.Equal(doc.Reference, attachment.Reference);

                Assert.Equal("application/pdf", attachment.AttachmentContent.ContentType);
                Assert.Equal("formatted_file_name", attachment.AttachmentContent.FileName);

                Assert.Equal("success", response.Result);

                f.TransactionRecordal.Received(1)
                 .RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase);
            }

            [Fact]
            public async Task ThrowsErrorWhenDocumentIsInvalid()
            {
                var @case = CreateCase();

                var e = await Assert.ThrowsAsync<HttpException>(
                                                                async () =>
                                                                {
                                                                    var f = new DocumentImporterFixture(Db);

                                                                    await f.Subject.Import(Fixture.Integer(), new DocumentImport {CaseId = @case.Id});
                                                                });

                Assert.Equal("Document Not Found.", e.Message);
            }

            [Fact]
            public async Task ThrowsErrorWhenEventProvidedNotPermittedForTheCase()
            {
                var @case = CreateCase();
                var doc = new Document().In(Db);

                var e = await Assert.ThrowsAsync<ArgumentException>(
                                                                    async () =>
                                                                    {
                                                                        var f = new DocumentImporterFixture(Db);

                                                                        f.OccurredEvents.For(@case).Returns(new OccurredEvent[0]);

                                                                        await f.Subject.Import(Fixture.Integer(),
                                                                                               new DocumentImport
                                                                                               {
                                                                                                   CaseId = @case.Id,
                                                                                                   DocumentId = doc.Id,
                                                                                                   EventId = 1
                                                                                               });
                                                                    });

                Assert.Equal("Provided event does not exist in the case.", e.Message);
            }
        }

        public class DocumentImporterFixture : IFixture<DocumentImporter>
        {
            public DocumentImporterFixture(InMemoryDbContext db)
            {
                OccurredEvents = Substitute.For<IOccurredEvents>();

                CreateActivityAttachment = Substitute.For<ICreateActivityAttachment>();

                DefaultFileNameFormatter = Substitute.For<IDefaultFileNameFormatter>();

                IntegrationServerClient = Substitute.For<IIntegrationServerClient>();
                IntegrationServerClient.DownloadContent(Arg.Any<string>())
                                       .Returns(new MemoryStream(new byte[0]));

                TransactionRecordal = Substitute.For<ITransactionRecordal>();

                Subject = new DocumentImporter(
                                               db,
                                               db, OccurredEvents,
                                               IntegrationServerClient,
                                               CreateActivityAttachment,
                                               DefaultFileNameFormatter,
                                               TransactionRecordal);
            }

            public IOccurredEvents OccurredEvents { get; set; }

            public IIntegrationServerClient IntegrationServerClient { get; set; }

            public ICreateActivityAttachment CreateActivityAttachment { get; set; }

            public IDefaultFileNameFormatter DefaultFileNameFormatter { get; set; }

            public ITransactionRecordal TransactionRecordal { get; set; }

            public DocumentImporter Subject { get; }
        }
    }
}