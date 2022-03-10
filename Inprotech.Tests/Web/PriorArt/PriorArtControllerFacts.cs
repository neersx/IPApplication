using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.PriorArt;
using Inprotech.Web.PriorArt;
using Inprotech.Web.PriorArt.Maintenance;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class PriorArtControllerFacts : FactBase
    {
        public class IncludeInSourceDocumentMethod : FactBase
        {
            [Fact]
            public async Task LinksArtToCase()
            {
                var art = new PriorArtBuilder().Build().In(Db);
                var @case = new CaseBuilder().Build().In(Db);

                var match = new ExistingPriorArtMatch
                {
                    SourceDocumentId = null,
                    Id = art.Id.ToString()
                };

                var fixture = new PriorArtControllerFixture(Db);
                await fixture.Subject.IncludeInSourceDocument(match, @case.Id);
                fixture.EvidenceImporter.Received(1).AssociatePriorArtWithCase(art, @case.Id);
            }

            [Fact]
            public async Task LinksArtToSource()
            {
                var art = new PriorArtBuilder().Build().In(Db);

                var source = new PriorArtBuilder().BuildSourceDocument().In(Db);

                var match = new ExistingPriorArtMatch
                {
                    SourceDocumentId = source.Id,
                    Id = art.Id.ToString()
                };

                var subject = new PriorArtControllerFixture(Db).Subject;

                await subject.IncludeInSourceDocument(match, null);

                Assert.Contains(art, source.CitedPriorArt);
            }

            [Fact]
            public async Task LinksArtToSourceAndCase()
            {
                var art = new PriorArtBuilder().Build().In(Db);
                var @case = new CaseBuilder().Build().In(Db);

                var source = new PriorArtBuilder().BuildSourceDocument().In(Db);

                var match = new ExistingPriorArtMatch
                {
                    SourceDocumentId = source.Id,
                    Id = art.Id.ToString()
                };

                var fixture = new PriorArtControllerFixture(Db);
                await fixture.Subject.IncludeInSourceDocument(match, @case.Id);
                fixture.EvidenceImporter.Received(1).AssociatePriorArtWithCase(art, @case.Id);
            }

            [Fact]
            public void RequiresMaintainPriorArtCreatePermission()
            {
                var r = TaskSecurity.Secures<PriorArtController>(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create);
                Assert.True(r);
            }

            [Fact]
            public async Task ThrowsBadRequestIfArtProvidedAlreadyIncludedInSource()
            {
                var art = new PriorArtBuilder().Build().In(Db);

                var source = new PriorArtBuilder().BuildSourceDocument().In(Db);

                source.CitedPriorArt.Add(art);

                var match = new ExistingPriorArtMatch
                {
                    SourceDocumentId = source.Id,
                    Id = art.Id.ToString()
                };

                var subject = new PriorArtControllerFixture(Db).Subject;

                var exception = await Assert.ThrowsAsync<HttpException>(async () => await subject.IncludeInSourceDocument(match, null));

                Assert.Equal((int)HttpStatusCode.BadRequest, exception.GetHttpCode());
                Assert.Equal("Prior art already cited in the source document.", exception.Message);
            }

            [Fact]
            public async Task ThrowsBadRequestIfArtProvidedNotExist()
            {
                var art = new PriorArtBuilder().Build().In(Db);

                var match = new ExistingPriorArtMatch
                {
                    SourceDocumentId = art.Id,
                    Id = Fixture.Integer().ToString()
                };

                var subject = new PriorArtControllerFixture(Db).Subject;

                var exception = await Assert.ThrowsAsync<HttpException>(async () => await subject.IncludeInSourceDocument(match, null));

                Assert.Equal((int)HttpStatusCode.BadRequest, exception.GetHttpCode());
                Assert.Equal("Either source document or prior art provided is invalid", exception.Message);
            }

            [Fact]
            public async Task ThrowsBadRequestIfInvalidArtProvided()
            {
                var source1 = new PriorArtBuilder().BuildSourceDocument().In(Db);

                var source2 = new PriorArtBuilder().BuildSourceDocument().In(Db);

                var match = new ExistingPriorArtMatch
                {
                    SourceDocumentId = source1.Id,
                    Id = source2.Id.ToString()
                };

                var subject = new PriorArtControllerFixture(Db).Subject;

                var exception = await Assert.ThrowsAsync<HttpException>(async () => await subject.IncludeInSourceDocument(match, null));

                Assert.Equal((int)HttpStatusCode.BadRequest, exception.GetHttpCode());
                Assert.Equal("Not a prior art.", exception.Message);
            }

            [Fact]
            public async Task ThrowsBadRequestIfInvalidSourceDocumentProvided()
            {
                var art1 = new PriorArtBuilder().Build().In(Db);

                var art2 = new PriorArtBuilder().Build().In(Db);

                var match = new ExistingPriorArtMatch
                {
                    SourceDocumentId = art1.Id,
                    Id = art2.Id.ToString()
                };

                var subject = new PriorArtControllerFixture(Db).Subject;

                var exception = await Assert.ThrowsAsync<HttpException>(async () => await subject.IncludeInSourceDocument(match, null));

                Assert.Equal((int)HttpStatusCode.BadRequest, exception.GetHttpCode());
                Assert.Equal("Not a source document.", exception.Message);
            }

            [Fact]
            public async Task ThrowsBadRequestIfSourceDocumentProvidedNotExist()
            {
                var art = new PriorArtBuilder().Build().In(Db);

                var match = new ExistingPriorArtMatch
                {
                    SourceDocumentId = Fixture.Integer(),
                    Id = art.Id.ToString()
                };

                var subject = new PriorArtControllerFixture(Db).Subject;

                var exception = await Assert.ThrowsAsync<HttpException>(async () => await subject.IncludeInSourceDocument(match, null));

                Assert.Equal((int)HttpStatusCode.BadRequest, exception.GetHttpCode());
                Assert.Equal("Either source document or prior art provided is invalid", exception.Message);
            }

            [Fact]
            public async Task ThrowsBadRequestWhenAttemptingToLinkArtToSelf()
            {
                var id = Fixture.Integer();

                var match = new ExistingPriorArtMatch
                {
                    SourceDocumentId = id,
                    Id = id.ToString()
                };

                var subject = new PriorArtControllerFixture(Db).Subject;

                var exception = await Assert.ThrowsAsync<HttpException>(async () => await subject.IncludeInSourceDocument(match, null));

                Assert.Equal((int)HttpStatusCode.BadRequest, exception.GetHttpCode());
                Assert.Equal("Cannot link a source document to self.", exception.Message);
            }
        }

        public class EditExistingMethod : FactBase
        {
            [Fact]
            public async Task EditExistingPriorArt()
            {
                var country = new CountryBuilder().Build().In(Db);

                var art = new PriorArtModel
                {
                    Abstract = Fixture.String(),
                    ApplicationFiledDate = Fixture.Today(),
                    CountryCode = country.Id,
                    Citation = Fixture.String(),
                    CorrelationId = Fixture.String(),
                    GrantedDate = Fixture.Today(),
                    ImportedFrom = Fixture.String(),
                    Kind = Fixture.String(),
                    Name = Fixture.String(),
                    OfficialNumber = Fixture.String(),
                    PriorityDate = Fixture.Today(),
                    PtoCitedDate = Fixture.Today(),
                    PublishedDate = Fixture.Today(),
                    RefDocumentParts = Fixture.String(),
                    Title = Fixture.String(),
                    Translation = Fixture.Integer()
                };

                var subject = new PriorArtControllerFixture(Db).Subject;

                await subject.Create(art);

                var saved = Db.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Single();
                var matchData = new ExistingPriorArtMatch
                {
                    Abstract = Fixture.String(),
                    ApplicationDate = Fixture.Today(),
                    CountryCode = country.Id,
                    Citation = Fixture.String(),
                    GrantedDate = Fixture.Today(),
                    Kind = Fixture.String(),
                    Name = Fixture.String(),
                    OfficialNumber = Fixture.String(),
                    PriorityDate = Fixture.Today(),
                    PtoCitedDate = Fixture.Today(),
                    PublishedDate = Fixture.Today(),
                    RefDocumentParts = Fixture.String(),
                    Title = Fixture.String(),
                    Translation = Fixture.Integer(),
                    Id = saved.Id.ToString()
                };
                await subject.EditExisting(matchData);

                var edited = Db.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Single();

                Assert.Equal(matchData.Title, edited.Title);
                Assert.Equal(matchData.Abstract, edited.Abstract);
                Assert.Equal(matchData.Citation, edited.Citation);
                Assert.Equal(matchData.Name, edited.Name);
                Assert.Equal(matchData.RefDocumentParts, edited.RefDocumentParts);
                Assert.Equal(matchData.Translation, edited.Translation);
                Assert.Equal(matchData.PublishedDate, edited.PublishedDate);
                Assert.Equal(matchData.PriorityDate, edited.PriorityDate);
                Assert.Equal(matchData.GrantedDate, edited.GrantedDate);
                Assert.Equal(matchData.PtoCitedDate, edited.PtoCitedDate);
                Assert.Equal(matchData.ApplicationDate, edited.ApplicationFiledDate);
                Assert.True(edited.IsIpDocument.GetValueOrDefault());
            }
        }

        public class CreateMethod : FactBase
        {
            [Fact]
            public async Task CreatesPriorArt()
            {
                var country = new CountryBuilder().Build().In(Db);

                var art = new PriorArtModel
                {
                    Abstract = Fixture.String(),
                    ApplicationFiledDate = Fixture.Today(),
                    CountryCode = country.Id,
                    Citation = Fixture.String(),
                    CorrelationId = Fixture.String(),
                    GrantedDate = Fixture.Today(),
                    ImportedFrom = Fixture.String(),
                    Kind = Fixture.String(),
                    Name = Fixture.String(),
                    OfficialNumber = Fixture.String(),
                    PriorityDate = Fixture.Today(),
                    PtoCitedDate = Fixture.Today(),
                    PublishedDate = Fixture.Today(),
                    RefDocumentParts = Fixture.String(),
                    Title = Fixture.String(),
                    Translation = Fixture.Integer()
                };

                var subject = new PriorArtControllerFixture(Db).Subject;

                await subject.Create(art);

                var saved = Db.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Single();

                Assert.Equal(art.Title, saved.Title);
                Assert.Equal(art.Abstract, saved.Abstract);
                Assert.Equal(art.Citation, saved.Citation);
                Assert.Equal(art.Name, saved.Name);
                Assert.Equal(art.RefDocumentParts, saved.RefDocumentParts);
                Assert.Equal(art.Translation, saved.Translation);
                Assert.Equal(art.PublishedDate, saved.PublishedDate);
                Assert.Equal(art.PriorityDate, saved.PriorityDate);
                Assert.Equal(art.GrantedDate, saved.GrantedDate);
                Assert.Equal(art.PtoCitedDate, saved.PtoCitedDate);
                Assert.Equal(art.ApplicationFiledDate, saved.ApplicationFiledDate);
                Assert.Equal(art.CorrelationId, saved.CorrelationId);
                Assert.Equal(art.ImportedFrom, saved.ImportedFrom);
                Assert.True(saved.IsIpDocument.GetValueOrDefault());
            }

            [Fact]
            public async Task CreatesPriorArtLinksToCase()
            {
                var caseToLink = Fixture.Integer();

                var country = new CountryBuilder().Build().In(Db);

                var art = new PriorArtModel
                {
                    Abstract = Fixture.String(),
                    ApplicationFiledDate = Fixture.Today(),
                    CountryCode = country.Id,
                    Citation = Fixture.String(),
                    CorrelationId = Fixture.String(),
                    CaseKey = caseToLink,
                    GrantedDate = Fixture.Today(),
                    ImportedFrom = Fixture.String(),
                    Kind = Fixture.String(),
                    Name = Fixture.String(),
                    OfficialNumber = Fixture.String(),
                    PriorityDate = Fixture.Today(),
                    PtoCitedDate = Fixture.Today(),
                    PublishedDate = Fixture.Today(),
                    RefDocumentParts = Fixture.String(),
                    Title = Fixture.String(),
                    Translation = Fixture.Integer()
                };

                var fixture = new PriorArtControllerFixture(Db);

                await fixture.Subject.Create(art);

                var saved = Db.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Single();

                Assert.Equal(art.Title, saved.Title);
                Assert.Equal(art.Abstract, saved.Abstract);
                Assert.Equal(art.Citation, saved.Citation);
                Assert.Equal(art.Name, saved.Name);
                Assert.Equal(art.RefDocumentParts, saved.RefDocumentParts);
                Assert.Equal(art.Translation, saved.Translation);
                Assert.Equal(art.PublishedDate, saved.PublishedDate);
                Assert.Equal(art.PriorityDate, saved.PriorityDate);
                Assert.Equal(art.GrantedDate, saved.GrantedDate);
                Assert.Equal(art.PtoCitedDate, saved.PtoCitedDate);
                Assert.Equal(art.ApplicationFiledDate, saved.ApplicationFiledDate);
                Assert.Equal(art.CorrelationId, saved.CorrelationId);
                Assert.Equal(art.ImportedFrom, saved.ImportedFrom);
                Assert.True(saved.IsIpDocument.GetValueOrDefault());

                fixture.EvidenceImporter.AssociatePriorArtWithCase(saved, caseToLink);
            }

            [Fact]
            public async Task CreatesPriorArtLinksToSource()
            {
                var source = new PriorArtBuilder().BuildSourceDocument().In(Db);

                var country = new CountryBuilder().Build().In(Db);

                var art = new PriorArtModel
                {
                    Abstract = Fixture.String(),
                    ApplicationFiledDate = Fixture.Today(),
                    CountryCode = country.Id,
                    Citation = Fixture.String(),
                    CorrelationId = Fixture.String(),
                    SourceId = source.Id,
                    GrantedDate = Fixture.Today(),
                    ImportedFrom = Fixture.String(),
                    Kind = Fixture.String(),
                    Name = Fixture.String(),
                    OfficialNumber = Fixture.String(),
                    PriorityDate = Fixture.Today(),
                    PtoCitedDate = Fixture.Today(),
                    PublishedDate = Fixture.Today(),
                    RefDocumentParts = Fixture.String(),
                    Title = Fixture.String(),
                    Translation = Fixture.Integer()
                };

                var subject = new PriorArtControllerFixture(Db).Subject;

                await subject.Create(art);

                var saved = Db.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Last();

                Assert.Equal(art.Title, saved.Title);
                Assert.Equal(art.Abstract, saved.Abstract);
                Assert.Equal(art.Citation, saved.Citation);
                Assert.Equal(art.Name, saved.Name);
                Assert.Equal(art.RefDocumentParts, saved.RefDocumentParts);
                Assert.Equal(art.Translation, saved.Translation);
                Assert.Equal(art.PublishedDate, saved.PublishedDate);
                Assert.Equal(art.PriorityDate, saved.PriorityDate);
                Assert.Equal(art.GrantedDate, saved.GrantedDate);
                Assert.Equal(art.PtoCitedDate, saved.PtoCitedDate);
                Assert.Equal(art.ApplicationFiledDate, saved.ApplicationFiledDate);
                Assert.Equal(art.CorrelationId, saved.CorrelationId);
                Assert.Equal(art.ImportedFrom, saved.ImportedFrom);
                Assert.True(saved.IsIpDocument.GetValueOrDefault());

                Assert.Contains(saved, source.CitedPriorArt);
            }

            [Fact]
            public void RequiresMaintainPriorArtCreatePermission()
            {
                var r = TaskSecurity.Secures<PriorArtController>(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create);
                Assert.True(r);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void RequiresMaintainPriorArtPermission()
            {
                var r = TaskSecurity.Secures<PriorArtSearchViewController>(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create);
                Assert.True(r);
            }

            [Fact]
            public void ReturnsEmptyPriorArtSearchModelWithoutParameters()
            {
                var subject = new PriorArtControllerFixture(Db).Subject;

                var r = (PriorArtSearchViewModel)subject.Get();

                Assert.Null(r.CaseKey);

                Assert.Null(r.SourceDocumentData);
            }

            [Fact]
            public void ReturnsModelWithCase()
            {
                var @case = new CaseBuilder().Build().In(Db);

                var subject = new PriorArtControllerFixture(Db).Subject;

                var r = (PriorArtSearchViewModel)subject.Get(caseKey: @case.Id);

                Assert.Equal(@case.Id, r.CaseKey);
                Assert.Equal(@case.Irn, r.CaseIrn);
            }

            [Fact]
            public void ReturnsModelWithSourceDocumentData()
            {
                var source = new PriorArtBuilder().BuildSourceDocument().In(Db);

                var subject = new PriorArtControllerFixture(Db).Subject;

                var r = (PriorArtSearchViewModel)subject.Get(source.Id);

                Assert.NotNull(r.SourceDocumentData);

                Assert.Equal(source.Id, r.SourceDocumentData.SourceId);
                Assert.Equal(source.SourceType.Name, r.SourceDocumentData.SourceType.Name);
            }

            [Fact]
            public void ShouldReturnCorrectTableCodes()
            {
                var source = new PriorArtBuilder().BuildSourceDocument().In(Db);
                new[]
                {
                    new TableCode(1, (short) TableTypes.PriorArtSource, "abc"),
                    new TableCode(2, (short) TableTypes.Office, Fixture.String()),
                    new TableCode(3, (short) TableTypes.PriorArtSource, "def")
                }.In(Db);
                var subject = new PriorArtControllerFixture(Db).Subject;

                var r = (PriorArtSearchViewModel)subject.Get(source.Id);

                Assert.Equal(2, r.PriorArtSourceTableCodes.Count());
                Assert.Equal(1, r.PriorArtSourceTableCodes.First().Id);
                Assert.Equal("abc", r.PriorArtSourceTableCodes.First().Name);
                Assert.Equal(3, r.PriorArtSourceTableCodes.Last().Id);
                Assert.Equal("def", r.PriorArtSourceTableCodes.Last().Name);
                Assert.Equal(source.Id, r.SourceDocumentData.SourceId);
                Assert.Equal(source.SourceType.Name, r.SourceDocumentData.SourceType.Name);
            }
            
            [Fact]
            public void ThrowsNotFoundIfCaseDoNotExist()
            {
                var subject = new PriorArtControllerFixture(Db).Subject;

                var exception = Assert.Throws<HttpException>(() => subject.Get(null, Fixture.Integer()));

                Assert.Equal((int)HttpStatusCode.NotFound, exception.GetHttpCode());
                Assert.Equal("Case not found.", exception.Message);
            }

            [Fact]
            public void ThrowsNotFoundIfSourceProvidedDoNotExist()
            {
                var subject = new PriorArtControllerFixture(Db).Subject;

                var exception = Assert.Throws<HttpException>(() => subject.Get(Fixture.Integer()));

                Assert.Equal((int)HttpStatusCode.NotFound, exception.GetHttpCode());
                Assert.Equal("Source not found.", exception.Message);
            }
        }
        
        public class CiteSourceDocument : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionIfSourceNotFound()
            {
                new PriorArtBuilder().BuildSourceDocument().In(Db);
                var f = new PriorArtControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpException>(async () => await f.Subject.CiteSourceDocument(new PriorArtController.SourceCitationRequest
                {
                    SourceId = Fixture.Integer()
                }));
                Assert.Equal("Source Document does not exist.", exception.Message);
            }

            [Theory]
            [InlineData(true, true)]
            [InlineData(true, false)]
            [InlineData(false, true)]
            [InlineData(false, false)]
            public async Task AddsReportCitation(bool withPriorArtId, bool withCaseId)
            {
                var source = new PriorArtBuilder().BuildSourceDocument().In(Db);
                var f = new PriorArtControllerFixture(Db);
                var request = new PriorArtController.SourceCitationRequest
                {
                    SourceId = source.Id,
                    PriorArtId = withPriorArtId ? Fixture.Integer() : (int?) null,
                    CaseId = withCaseId ? Fixture.Integer() : (int?) null
                };
                await f.Subject.CiteSourceDocument(request);
                if (withPriorArtId)
                {
                    Assert.True(Db.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Single(_ => _.Id == request.SourceId).CitedPriorArt.Any());
                }
                if (withCaseId && !withPriorArtId)
                {
                    Assert.NotNull(Db.Set<CaseSearchResult>().Single(_ => _.PriorArtId == request.SourceId && _.CaseId == request.CaseId));
                }
            }

        }

        public class PriorArtControllerFixture : IFixture<PriorArtController>
        {
            public PriorArtControllerFixture(InMemoryDbContext db)
            {
                EvidenceImporter = Substitute.For<IEvidenceImporter>();
                MatchBuilder = Substitute.For<IExistingPriorArtMatchBuilder>();
                PriorArtMaintenanceValidator = Substitute.For<IPriorArtMaintenanceValidator>();
                SubjectSecurityProvider = Substitute.For<ISubjectSecurityProvider>();

                Subject = new PriorArtController(db, MatchBuilder, EvidenceImporter, Substitute.For<ITaskSecurityProvider>(), PriorArtMaintenanceValidator, SubjectSecurityProvider);
            }

            public IExistingPriorArtMatchBuilder MatchBuilder { get; set; }
            public IEvidenceImporter EvidenceImporter { get; set; }
            public IPriorArtMaintenanceValidator PriorArtMaintenanceValidator { get; set; }
            public ISubjectSecurityProvider SubjectSecurityProvider { get; set; }
            public PriorArtController Subject { get; }
        }
    }
}