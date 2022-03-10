using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model;
using NSubstitute;
using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Xunit;
using CaseText = InprotechKaizen.Model.Cases.CaseText;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class CaseBillNarrativeControllerFacts
    {
        public class CaseBillNarrativeControllerFixture : IFixture<CaseBillNarrativeController>
        {
            public CaseBillNarrativeControllerFixture(InMemoryDbContext db)
            {
                CultureResolver = Substitute.For<IPreferredCultureResolver>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                Now = Substitute.For<Func<DateTime>>();
                Subject = new CaseBillNarrativeController(db, CultureResolver, SiteControlReader, Now);
            } 
            public CaseBillNarrativeController Subject { get; set; }
            public IPreferredCultureResolver CultureResolver { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }
            public Func<DateTime> Now { get; set; }
        }

        public class GetCaseBillNarrativesDefaultsMethod : FactBase
        {
            [Fact]
            public async Task GetCaseBillNarrativeDefaultsShouldThrowExceptionIfCaseNotFound()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetCaseBillNarrativeDefaults(Fixture.Integer()));
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task GetCaseBillNarrativeDefaultsShouldReturnValues()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var textType = new TextTypeBuilder {Id = KnownTextTypes.Billing}.Build().In(Db);
                f.SiteControlReader.Read<bool>(SiteControls.EnableRichTextFormatting).Returns(true);
                var result = await f.Subject.GetCaseBillNarrativeDefaults(@case.Id);
                Assert.Equal(@case.Irn, result.CaseReference);
                Assert.True(result.AllowRichText);
                Assert.Equal(textType.TextDescription, result.TextType);
                Assert.Equal(@case.Irn, result.CaseReference);
            }
        }

        public class GetAllCaseBillNarrativesMethod : FactBase
        {
            [Fact]
            public async Task GetCaseBillNarrativeShouldThrowExceptionIfCaseNotFound()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetAllCaseBillNarratives(Fixture.Integer()));
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task GetCaseBillNarrativeShouldReturnValues()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var lan = new TableCodeBuilder().Build().In(Db);
                var language = lan.Id;
                new TextTypeBuilder {Id = KnownTextTypes.Billing}.Build().In(Db);
                var ct = new CaseTextBuilder {CaseId = @case.Id, TextTypeId = KnownTextTypes.Billing}.Build().In(Db);
                var ct1 = new CaseTextBuilder {CaseId = @case.Id, TextTypeId = KnownTextTypes.Billing, Language = language}.Build().In(Db);
                ct1.LanguageValue = lan; 
                var result = (await f.Subject.GetAllCaseBillNarratives(@case.Id)).ToArray();
                Assert.Equal(2, result.Length);
                Assert.Equal(ct.Text, result[0].Notes);
                Assert.Null(result[0].Language);
                Assert.Equal(ct1.Text, result[1].Notes);
                Assert.Equal(language, result[1].Language.Key);
                Assert.True(result[0].IsDefault);
                Assert.True(result[0].Selected);
                Assert.False(result[1].IsDefault);
                Assert.False(result[1].Selected);
            }
        }

        public class SetCaseBillNarrativeMethod : FactBase
        {
            [Fact]
            public async Task SetCaseNarrativeShouldThrowExceptionIfRequestIsNull()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.SetCaseBillNarrative(null));
            }

            [Fact]
            public async Task SetCaseBillNarrativeShouldThrowExceptionIfCaseNotFound()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.SetCaseBillNarrative(new CaseBillNarrativeRequest {CaseKey = Fixture.Integer(), Notes = Fixture.String()}));
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task SetCaseBillNarrativeShouldThrowExceptionIfNotesEmpty()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.SetCaseBillNarrative(new CaseBillNarrativeRequest {CaseKey = Fixture.Integer()}));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task SaveCaseBillNarrativeShouldAddCaseTextIfNotExist()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                new TextTypeBuilder {Id = KnownTextTypes.Billing}.Build().In(Db);
                var request = new CaseBillNarrativeRequest
                {
                    CaseKey = @case.Id,
                    Notes = Fixture.String()
                };
                await f.Subject.SetCaseBillNarrative(request);
                var caseText = Db.Set<CaseText>().FirstOrDefault(_ => _.CaseId == @case.Id);
                Assert.NotNull(caseText);
                Assert.Equal(KnownTextTypes.Billing, caseText.Type);
                Assert.Equal(request.Notes, caseText.Text);
                Assert.Equal((short) 0, caseText.Number);
                Assert.Equal(0, caseText.IsLongText);
                Assert.Equal(f.Now(), caseText.ModifiedDate);
            }

            [Fact]
            public async Task SaveCaseBillNarrativeShouldSaveTextIfExists()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                new TextTypeBuilder {Id = KnownTextTypes.Billing}.Build().In(Db);
                var ct = new CaseTextBuilder {CaseId = @case.Id, Text = Fixture.String(), TextTypeId = KnownTextTypes.Billing, TextNumber = 0}.Build().In(Db);
                var request = new CaseBillNarrativeRequest
                {
                    CaseKey = @case.Id,
                    Notes = Fixture.String()
                };
                await f.Subject.SetCaseBillNarrative(request);
                Assert.Equal(request.Notes, ct.Text);
                Assert.Equal(f.Now(), ct.ModifiedDate);
            }
        }

        public class DeleteCaseBillNarrativeMethod : FactBase
        {
            [Fact]
            public async Task DeleteCaseNarrativeShouldThrowExceptionIfRequestIsNull()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.DeleteCaseBillNarrative(null));
            }

            [Fact]
            public async Task DeleteCaseBillNarrativeShouldThrowExceptionIfCaseNotFound()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.DeleteCaseBillNarrative(new CaseBillNarrativeRequest {CaseKey = Fixture.Integer()}));
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task DeleteCaseBillNarrativeShouldThrowExceptionIfCaseTextNotFound()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.DeleteCaseBillNarrative(new CaseBillNarrativeRequest {CaseKey = @case.Id}));
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task DeleteCaseBillNarrativeShouldRemoveTextIfExists()
            {
                var f = new CaseBillNarrativeControllerFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                new TextTypeBuilder {Id = KnownTextTypes.Billing}.Build().In(Db);
                var language = Fixture.Integer();
                new CaseTextBuilder {CaseId = @case.Id, Text = Fixture.String(), TextTypeId = KnownTextTypes.Billing, TextNumber = 0, Language = language}.Build().In(Db);
                new CaseTextBuilder {CaseId = @case.Id, Text = Fixture.String(), TextTypeId = KnownTextTypes.Billing, TextNumber = 1}.Build().In(Db);
                var request = new CaseBillNarrativeRequest
                {
                    CaseKey = @case.Id,
                    Notes = null,
                    Language = language
                };
                await f.Subject.DeleteCaseBillNarrative(request);
                Assert.Empty(Db.Set<CaseText>().Where(_ => _.CaseId == @case.Id && _.Language == language));
                Assert.True(Db.Set<CaseText>().Any(_ => _.CaseId == @case.Id && _.Number == 1));
            }
        }
    }
}