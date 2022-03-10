using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Integration.Documents;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Documents
{
    public class ImportDocumentControllerFacts
    {
        public class GetMethod : FactBase
        {
            Case CreateCase(string irn = null, string title = null, bool? withEthicalWallRestriction = false)
            {
                var @case = new Case("123", new Country(), new CaseType(), new PropertyType())
                {
                    Irn = irn,
                    Title = title
                }.In(Db);

                if (!withEthicalWallRestriction.GetValueOrDefault())
                {
                    new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                }

                return @case;
            }

            [Fact]
            public async Task ReturnsProposedValuesForDocumentImport()
            {
                var @case = CreateCase();

                var mailRoomDate = Fixture.PastDate();

                var doc = new Document
                {
                    DocumentDescription = "ABC",
                    MailRoomDate = mailRoomDate
                }.In(Db);

                new TableCode(100, (int) TableTypes.ContactActivityCategory, "Contact Activity Category").In(Db);
                new TableCode(200, (int) TableTypes.ContactActivityType, "Contact Activity Type").In(Db);
                new TableCode(300, (int) TableTypes.AttachmentType, "Attachment Type").In(Db);

                var f = new ImportDocumentControllerFixture(Db);

                f.OccurredEvents.For(@case)
                 .Returns(
                          new[]
                          {
                              new OccurredEvent {EventId = 8888},
                              new OccurredEvent {EventId = 9999}
                          }
                         );

                var result = await f.Subject.Get(@case.Id, doc.Id);

                Assert.Equal(@case.Id, result.CaseId);
                Assert.Equal(@case.Irn, result.CaseRef);
                Assert.Equal(@case.Title, result.Title);
                Assert.Equal(doc.Id, result.DocumentId);
                Assert.Equal(mailRoomDate, result.ActivityDate);
                Assert.Equal("ABC", result.AttachmentName);

                Assert.Equal(
                             "Contact Activity Category",
                             ((IEnumerable<dynamic>) result.Categories).Single().Description);
                Assert.Equal(
                             "Contact Activity Type",
                             ((IEnumerable<dynamic>) result.ActivityTypes).Single().Description);
                Assert.Equal("Attachment Type", ((IEnumerable<dynamic>) result.AttachmentTypes).Single().Description);

                Assert.Contains((OccurredEvent[]) result.OccurredEvents, oe => oe.EventId == 8888);
                Assert.Contains((OccurredEvent[]) result.OccurredEvents, oe => oe.EventId == 9999);
            }

            [Fact]
            public async Task ThrowsErrorWhenDocumentIsInvalid()
            {
                var @case = CreateCase();

                var e = await Assert.ThrowsAsync<HttpException>(async () =>
                {
                    var f = new ImportDocumentControllerFixture(Db);

                    await f.Subject.Get(@case.Id, 98710);
                });

                Assert.Equal("Document Not Found.", e.Message);
            }

            [Fact]
            public async Task ThrowsErrorWhenDocumentIsNotProvided()
            {
                await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    var f = new ImportDocumentControllerFixture(Db);
                    await f.Subject.Get(1, null);
                });
            }
        }

        public class ImportDocumentControllerFixture : IFixture<ImportDocumentController>
        {
            public ImportDocumentControllerFixture(InMemoryDbContext db)
            {
                OccurredEvents = Substitute.For<IOccurredEvents>();

                DocumentImporter = Substitute.For<IDocumentImporter>();

                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User());

                Subject = new ImportDocumentController(
                                                       db,
                                                       db,
                                                       securityContext,
                                                       OccurredEvents,
                                                       DocumentImporter);
            }

            public IOccurredEvents OccurredEvents { get; set; }

            public IDocumentImporter DocumentImporter { get; set; }

            public ImportDocumentController Subject { get; }
        }
    }
}