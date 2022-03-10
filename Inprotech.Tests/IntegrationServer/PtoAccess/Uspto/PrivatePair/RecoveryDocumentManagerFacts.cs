using System;
using System.Linq;
using System.Threading.Tasks;
using CPAXML.Extensions;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class RecoveryDocumentManagerFacts
    {
        public class ByDocumentIds : FactBase
        {
            [Fact]
            public void ReturnsDocumentsAsRequired()
            {
                var doc = new Document
                {
                    DocumentCategory = Fixture.String(),
                    DocumentDescription = Fixture.String(),
                    FileWrapperDocumentCode = Fixture.String(),
                    MailRoomDate = Fixture.Today(),
                    PageCount = Fixture.Integer()
                }.In(Db);

                var f = new RecoveryDocumentManagerFixture(Db);

                var r = f.Subject.GetDocumentsToRecover(new[] { doc.Id });

                var docData = r.Single();

                Assert.Equal(doc.DocumentCategory, docData.DocumentCategory);
                Assert.Equal(doc.DocumentDescription, docData.DocumentDescription);
                Assert.Equal(doc.FileWrapperDocumentCode, docData.FileWrapperDocumentCode);
                Assert.Equal(doc.MailRoomDate, docData.MailRoomDate);
                Assert.Equal(doc.PageCount, docData.PageCount);
            }

            [Fact]
            public void ReturnsOnlyDocumentsRequested()
            {
                new Document
                {
                    DocumentCategory = Fixture.String(),
                    DocumentDescription = Fixture.String(),
                    FileWrapperDocumentCode = Fixture.String(),
                    MailRoomDate = Fixture.Today(),
                    PageCount = Fixture.Integer()
                }.In(Db);

                var f = new RecoveryDocumentManagerFixture(Db);

                var r = f.Subject.GetDocumentsToRecover(new[] { Fixture.Integer() });

                Assert.Empty(r);
            }
        }

        public class BySessionAndApplication : FactBase
        {
            [Fact]
            public async Task LimitToThoseInScheduleScope()
            {
                var notInScope = new AvailableDocument
                {
                    DocumentCategory = Fixture.String(),
                    DocumentDescription = Fixture.String(),
                    FileWrapperDocumentCode = Fixture.String(),
                    MailRoomDate = Fixture.PastDate().AddDays(-10),
                    /* it is dated beyond schedule document scope */
                    PageCount = Fixture.Integer(),
                    ObjectId = Fixture.String()
                };

                var inScope = new AvailableDocument
                {
                    DocumentCategory = Fixture.String(),
                    DocumentDescription = Fixture.String(),
                    FileWrapperDocumentCode = Fixture.String(),
                    MailRoomDate = Fixture.PastDate(),
                    PageCount = Fixture.Integer(),
                    ObjectId = Fixture.String()
                };

                var f = new RecoveryDocumentManagerFixture(Db)
                        .WithScheduleDocumentScope(Fixture.PastDate())
                        .ImageFileWrapperReturns(notInScope, inScope);

                var r = await f.Subject.GetDocumentsToRecover(new Session(), new ApplicationDownload());

                var doc = r.Single();

                Assert.Equal(inScope.DocumentCategory, doc.DocumentCategory);
                Assert.Equal(inScope.DocumentDescription, doc.DocumentDescription);
                Assert.Equal(inScope.FileWrapperDocumentCode, doc.FileWrapperDocumentCode);
                Assert.Equal(inScope.MailRoomDate, doc.MailRoomDate);
                Assert.Equal(inScope.PageCount, doc.PageCount);
            }

            [Fact]
            public async Task ReturnsDocumentByExtractingFromImageFileWrapper()
            {
                var foundInIfw = new AvailableDocument
                {
                    DocumentCategory = Fixture.String(),
                    DocumentDescription = Fixture.String(),
                    FileWrapperDocumentCode = Fixture.String(),
                    MailRoomDate = Fixture.Today(),
                    PageCount = Fixture.Integer(),
                    ObjectId = Fixture.String()
                };

                var f = new RecoveryDocumentManagerFixture(Db)
                        .WithScheduleDocumentScope(Fixture.PastDate())
                        .ImageFileWrapperReturns(foundInIfw);

                var r = await f.Subject.GetDocumentsToRecover(new Session(), new ApplicationDownload());

                var doc = r.Single();

                Assert.Equal(foundInIfw.DocumentCategory, doc.DocumentCategory);
                Assert.Equal(foundInIfw.DocumentDescription, doc.DocumentDescription);
                Assert.Equal(foundInIfw.FileWrapperDocumentCode, doc.FileWrapperDocumentCode);
                Assert.Equal(foundInIfw.MailRoomDate, doc.MailRoomDate);
                Assert.Equal(foundInIfw.PageCount, doc.PageCount);
            }
        }

        public class RecoveryDocumentManagerFixture : IFixture<IProvideDocumentsToRecover>
        {
            public RecoveryDocumentManagerFixture(InMemoryDbContext db)
            {
                ScheduleDocumentStartDate = Substitute.For<IScheduleDocumentStartDate>();

                BiblioReader = Substitute.For<IBiblioStorage>();

                Subject = new RecoveryDocumentManager(
                                                      db,
                                                      ScheduleDocumentStartDate, BiblioReader);
            }

            public IScheduleDocumentStartDate ScheduleDocumentStartDate { get; set; }

            public IBiblioStorage BiblioReader { get; set; }

            public IProvideDocumentsToRecover Subject { get; set; }

            public RecoveryDocumentManagerFixture WithScheduleDocumentScope(DateTime? date = null)
            {
                ScheduleDocumentStartDate.Resolve(Arg.Any<Session>())
                                         .Returns(date ?? Fixture.Today());

                return this;
            }

            public RecoveryDocumentManagerFixture ImageFileWrapperReturns(params AvailableDocument[] documents)
            {
                BiblioReader.Read(Arg.Any<ApplicationDownload>())
                            .Returns(Task.FromResult(
                                                     new BiblioFile()
                                                     {
                                                         ImageFileWrappers = documents.AsEnumerable().Select(_ => new ImageFileWrapper()
                                                         {
                                                             FileName = _.ObjectId,
                                                             DocCategory = _.DocumentCategory,
                                                             MailDate = _.MailRoomDate.Iso8601OrNull(),
                                                             DocDesc = _.DocumentDescription,
                                                             DocCode = _.FileWrapperDocumentCode,
                                                             PageCount = _.PageCount
                                                         }).ToList()
                                                     }));

                return this;
            }
        }
    }
}