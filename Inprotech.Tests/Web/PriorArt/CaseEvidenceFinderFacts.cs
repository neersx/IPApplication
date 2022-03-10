using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class CaseEvidenceFinderFacts : FactBase
    {
        CaseEvidenceFinder CreateSubject()
        {
            return new CaseEvidenceFinder(Db);
        }
        
        [Fact]
        public async Task ShouldMatchCountry()
        {
            var @case = new CaseBuilder
            {
                Country = new CountryBuilder().Build().In(Db)
            }.Build().In(Db);

            new CaseIndexes
            {
                CaseId = @case.Id,
                GenericIndex = "12345",
                Source = CaseIndexSource.OfficialNumbers
            }.In(Db);

            var request = new SearchRequest
            {
                Country = Fixture.String(),
                OfficialNumber = "12345"
            };

            var r = await CreateSubject().Find(request, new SearchResultOptions());

            Assert.Empty(r.Matches.Data);
        }

        [Fact]
        public async Task ShouldReturnEmptyIfSourceType()
        {
            var @case = new CaseBuilder
            {
                Country = new CountryBuilder().Build().In(Db)
            }.Build().In(Db);

            new CaseIndexes
            {
                CaseId = @case.Id,
                GenericIndex = "12345",
                Source = CaseIndexSource.OfficialNumbers
            }.In(Db);

            var request = new SearchRequest
            {
                Country = Fixture.String(),
                OfficialNumber = "12345",
                SourceType = PriorArtTypes.Source
            };

            var r = await CreateSubject().Find(request, new SearchResultOptions());

            Assert.Empty(r.Matches.Data);
        }

        [Fact]
        public async Task ShouldMatchNumber()
        {
            var @case = new CaseBuilder
            {
                Country = new CountryBuilder().Build().In(Db)
            }.Build().In(Db);

            new CaseIndexes
            {
                CaseId = @case.Id,
                GenericIndex = Fixture.String(),
                Source = CaseIndexSource.OfficialNumbers
            }.In(Db);

            var request = new SearchRequest
            {
                Country = @case.Country.Id,
                OfficialNumber = Fixture.String(),
                SourceType = PriorArtTypes.Ipo
            };

            var r = await CreateSubject().Find(request, new SearchResultOptions());

            Assert.Empty(r.Matches.Data);
        }

        [Fact]
        public async Task ShouldMatchNumberUsingCaseIndexes()
        {
            var @case = new CaseBuilder
            {
                Country = new CountryBuilder().Build().In(Db)
            }.Build().In(Db);

            new CaseIndexes
            {
                CaseId = @case.Id,
                GenericIndex = "12345",
                Source = CaseIndexSource.OfficialNumbers
            }.In(Db);

            var request = new SearchRequest
            {
                Country = @case.Country.Id,
                OfficialNumber = "12/34/5",
                SourceType = PriorArtTypes.Ipo
            };

            var r = await CreateSubject().Find(request, new SearchResultOptions());

            Assert.Equal(@case.Id.ToString(), r.Matches.Data.Single().Id);
            Assert.Equal(@case.Irn, r.Matches.Data.Single().Reference);
            Assert.Equal(@case.Title, r.Matches.Data.Single().Title);
        }

        [Fact]
        public async Task ShouldThrowWhenCountryNotProvidedInSearchRequest()
        {
            var subject = CreateSubject();

            var request = new SearchRequest
            {
                Country = null,
                OfficialNumber = Fixture.String(),
                SourceType = PriorArtTypes.Ipo
            };

            var exception = await Assert.ThrowsAsync<ArgumentException>(
                                                                        async () => await subject.Find(request, new SearchResultOptions()));

            Assert.Equal("A valid country is required.", exception.Message);
        }

        [Fact]
        public async Task ShouldThrowWhenOfficialNumberNotProvidedInSearchRequest()
        {
            var subject = CreateSubject();

            var request = new SearchRequest
            {
                Country = Fixture.String(),
                OfficialNumber = null,
                SourceType = PriorArtTypes.Ipo
            };

            var exception = await Assert.ThrowsAsync<ArgumentException>(
                                                                        async () => await subject.Find(request, new SearchResultOptions()));

            Assert.Equal("A valid official number is required.", exception.Message);
        }

        [Fact]
        public async Task ShouldReturnMultipleResultsForMultiSearchRequests()
        {
            var caseA = new CaseBuilder { Country = new CountryBuilder().Build().In(Db) }.Build().In(Db);
            new CaseIndexes { CaseId = caseA.Id, GenericIndex = "12345", Source = CaseIndexSource.OfficialNumbers }.In(Db);
            var caseB = new CaseBuilder { Country = new CountryBuilder().Build().In(Db) }.Build().In(Db);
            new CaseIndexes { CaseId = caseB.Id, GenericIndex = "7777778", Source = CaseIndexSource.OfficialNumbers }.In(Db);
            var ipoRequest1 = new IpoSearchRequest { Country = caseA.Country.Id, OfficialNumber = "12345" };
            var ipoRequest2 = new IpoSearchRequest { Country = caseB.Country.Id, OfficialNumber = "7777778" };
            var request = new SearchRequest
            {
                SourceType = PriorArtTypes.Ipo,
                IpoSearchType = IpoSearchType.Multiple,
                MultipleIpoSearch = new[] { ipoRequest1, ipoRequest2 }
            };

            var r = await CreateSubject().Find(request, new SearchResultOptions());

            Assert.True(r.Matches.Data.Any(v => v.Id == caseA.Id.ToString()));
            Assert.True(r.Matches.Data.Any(v => v.Id == caseB.Id.ToString()));
            Assert.True(r.Matches.Data.Any(v => v.Title == caseA.Title));
            Assert.True(r.Matches.Data.Any(v => v.Title == caseB.Title));
        }
    }
}