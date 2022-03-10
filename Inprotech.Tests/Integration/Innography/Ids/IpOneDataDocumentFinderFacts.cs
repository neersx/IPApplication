using System;
using System.Linq;
using System.Threading.Tasks;
using CPAXML.Extensions;
using Inprotech.Contracts;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Innography.Ids;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Innography.Ids
{
    public class IpOneDataDocumentFinderFacts : FactBase
    {
        readonly IDocumentApiClient _documentApiClient = Substitute.For<IDocumentApiClient>();
        readonly IPatentScoutUrlFormatter _patentScoutUrlFormatter = Substitute.For<IPatentScoutUrlFormatter>();
        readonly InMemoryDbContext _db = new InMemoryDbContext();
        readonly ILogger<IpOneDataDocumentFinder> _logger = Substitute.For<ILogger<IpOneDataDocumentFinder>>();

        [Theory]
        [InlineData("Publication")]
        [InlineData("PublicationOfApplication")]
        public async Task ShouldSetPublicationDateForPublicationDocumentTypesFromTheStates(string documentType)
        {
            var countryCode = "US";
            var officialNumber = Fixture.String();
            var kindCode = "B1";

            var country = new Country(countryCode, Fixture.String()).In(_db);

            var subject = new IpOneDataDocumentFinder(_documentApiClient, _patentScoutUrlFormatter, _db, _logger);

            _documentApiClient.Documents(countryCode, officialNumber, kindCode)
                              .Returns(new DocumentApiResponse
                              {
                                  Result = new Result
                                  {
                                      DocumentDetails =
                                          new[]
                                          {
                                              new DocumentDetails
                                              {
                                                  CountryCode = countryCode,
                                                  KindCode = kindCode,
                                                  Number = officialNumber,
                                                  DocumentType = documentType,
                                                  Date = "2017-01-01"
                                              }
                                          }
                                  }
                              });

            var r = await subject.Find(new SearchRequest
            {
                Country = countryCode,
                Kind = kindCode,
                OfficialNumber = officialNumber,
                SourceType = PriorArtTypes.Ipo
            }, new SearchResultOptions());

            Assert.Equal(new DateTime(2017, 1, 1), r.Matches.Data.Single().PublishedDate);
            Assert.Null(r.Matches.Data.Single().GrantedDate);
            Assert.Equal(country.Name, r.Matches.Data.Single().CountryName);
        }

        [Theory]
        [InlineData("PublicationOfApplication")]
        [InlineData("Grant")]
        [InlineData("Any Kinds Unknown")]
        public async Task ShouldSetPublicationDateForAnyDocumentTypesFromTheRestOfTheWorld(string documentType)
        {
            var countryCode = Fixture.String();
            var officialNumber = Fixture.String();
            var kindCode = Fixture.String();
            new Country(countryCode, Fixture.String()).In(_db);

            var subject = new IpOneDataDocumentFinder(_documentApiClient, _patentScoutUrlFormatter, _db, _logger);

            _documentApiClient.Documents(countryCode, officialNumber, kindCode)
                              .Returns(new DocumentApiResponse
                              {
                                  Result = new Result
                                  {
                                      DocumentDetails =
                                          new[]
                                          {
                                              new DocumentDetails
                                              {
                                                  CountryCode = countryCode,
                                                  KindCode = kindCode,
                                                  Number = officialNumber,
                                                  DocumentType = documentType,
                                                  Date = "2017-01-01"
                                              }
                                          }
                                  }
                              });

            var r = await subject.Find(new SearchRequest
            {
                Country = countryCode,
                Kind = kindCode,
                OfficialNumber = officialNumber,
                SourceType = PriorArtTypes.Ipo
            }, new SearchResultOptions());

            Assert.Equal(new DateTime(2017, 1, 1), r.Matches.Data.Single().PublishedDate);
            Assert.Null(r.Matches.Data.Single().GrantedDate);
        }

        [Fact]
        public async Task ShouldPassArgumentsCorrectly()
        {
            var countryCode = Fixture.String();
            var officialNumber = Fixture.String();
            var kindCode = Fixture.String();
            new Country(countryCode, Fixture.String()).In(_db);

            var subject = new IpOneDataDocumentFinder(_documentApiClient, _patentScoutUrlFormatter, _db, _logger);

            _documentApiClient.Documents(countryCode, officialNumber, kindCode)
                              .Returns(new DocumentApiResponse());

            await subject.Find(new SearchRequest
            {
                Country = countryCode,
                Kind = kindCode,
                OfficialNumber = officialNumber,
                SourceType = PriorArtTypes.Ipo
            }, new SearchResultOptions());

            _documentApiClient.Received(1).Documents(countryCode, officialNumber, kindCode)
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnNoMatchesIfSourceType()
        {
            var countryCode = Fixture.String();
            var officialNumber = Fixture.String();
            var kindCode = Fixture.String();
            new Country(countryCode, Fixture.String()).In(_db);

            var subject = new IpOneDataDocumentFinder(_documentApiClient, _patentScoutUrlFormatter, _db, _logger);
            var result = await subject.Find(new SearchRequest
            {
                SourceType = PriorArtTypes.Source,
                Country = countryCode,
                Kind = kindCode,
                OfficialNumber = officialNumber
            }, new SearchResultOptions());
            Assert.Empty(result.Matches.Data);
            _documentApiClient.DidNotReceive().Documents(countryCode, officialNumber, kindCode)
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldSetAllOtherDetails()
        {
            var countryCode = Fixture.String();
            var officialNumber = Fixture.String();
            var kindCode = Fixture.String();
            new Country(countryCode, Fixture.String()).In(_db);

            var result = new DocumentDetails
            {
                CountryCode = countryCode,
                KindCode = kindCode,
                Number = officialNumber,
                DocumentType = Fixture.String(),
                Abstract = Fixture.String(),
                ApplicationNumber = Fixture.String(),
                ApplicationDate = Fixture.Date().Iso8601OrNull(),
                IpId = Fixture.String(),
                Title = Fixture.String(),
                Date = "2017-01-01"
            };

            var subject = new IpOneDataDocumentFinder(_documentApiClient, _patentScoutUrlFormatter, _db, _logger);

            _documentApiClient.Documents(countryCode, officialNumber, kindCode)
                              .Returns(new DocumentApiResponse
                              {
                                  Result = new Result {DocumentDetails = new[] {result}}
                              });

            var r = await subject.Find(new SearchRequest
            {
                Country = countryCode,
                Kind = kindCode,
                OfficialNumber = officialNumber,
                SourceType = PriorArtTypes.Ipo
            }, new SearchResultOptions());

            Assert.Equal(result.IpId, r.Matches.Data.Single().Id);
            Assert.Equal(result.Title, r.Matches.Data.Single().Title);
            Assert.Equal(result.KindCode, r.Matches.Data.Single().Kind);
            Assert.Equal(result.Abstract, r.Matches.Data.Single().Abstract);
            Assert.Equal(result.ApplicationDate.ToDateTime(), r.Matches.Data.Single().ApplicationDate);
            Assert.Equal(new DateTime(2017, 1, 1), r.Matches.Data.Single().PublishedDate);
            Assert.Equal($"{result.CountryCode}-{result.Number}-{result.KindCode}", r.Matches.Data.Single().Reference);
            Assert.Equal(result.Number, r.Matches.Data.Single().OfficialNumber);
            Assert.Null(r.Matches.Data.Single().GrantedDate);
        }

        [Theory]
        [InlineData("John; Mike; Albert", "Carl; Craig; Catherine")]
        [InlineData("", "")]
        [InlineData(null, null)]
        public async Task ShouldSetApplicantAsNamesFromRestOfTheWorld(string inventors, string applicants)
        {
            var countryCode = Fixture.String();
            var officialNumber = Fixture.String();
            var kindCode = "B1";
            new Country(countryCode, Fixture.String()).In(_db);

            var subject = new IpOneDataDocumentFinder(_documentApiClient, _patentScoutUrlFormatter, _db, _logger);

            _documentApiClient.Documents(countryCode, officialNumber, kindCode)
                              .Returns(new DocumentApiResponse
                              {
                                  Result = new Result
                                  {
                                      DocumentDetails =
                                          new[]
                                          {
                                              new DocumentDetails
                                              {
                                                  CountryCode = countryCode,
                                                  KindCode = kindCode,
                                                  Number = officialNumber,
                                                  DocumentType = "Grant",
                                                  Date = "2017-01-01",
                                                  Inventor = inventors?.Split(';').Select(v => v.Trim()).ToArray(),
                                                  Applicant = applicants?.Split(';').Select(v => v.Trim()).ToArray()
                                              }
                                          }
                                  }
                              });

            var r = await subject.Find(new SearchRequest
            {
                Country = countryCode,
                Kind = kindCode,
                OfficialNumber = officialNumber,
                SourceType = PriorArtTypes.Ipo
            }, new SearchResultOptions());

            Assert.Equal(applicants ?? string.Empty, r.Matches.Data.Single().Name);
        }

        [Fact]
        public async Task ShouldSetGrantDateForGrantDocumentTypesFromTheStates()
        {
            var countryCode = "US";
            var officialNumber = Fixture.String();
            var kindCode = "B1";
            new Country(countryCode, Fixture.String()).In(_db);

            var subject = new IpOneDataDocumentFinder(_documentApiClient, _patentScoutUrlFormatter, _db, _logger);

            _documentApiClient.Documents(countryCode, officialNumber, kindCode)
                              .Returns(new DocumentApiResponse
                              {
                                  Result = new Result
                                  {
                                      DocumentDetails =
                                          new[]
                                          {
                                              new DocumentDetails
                                              {
                                                  CountryCode = countryCode,
                                                  KindCode = kindCode,
                                                  Number = officialNumber,
                                                  DocumentType = "Grant",
                                                  Date = "2017-01-01"
                                              }
                                          }
                                  }
                              });

            var r = await subject.Find(new SearchRequest
            {
                Country = countryCode,
                Kind = kindCode,
                OfficialNumber = officialNumber,
                SourceType = PriorArtTypes.Ipo
            }, new SearchResultOptions());

            Assert.Equal(new DateTime(2017, 1, 1), r.Matches.Data.Single().GrantedDate);
            Assert.Null(r.Matches.Data.Single().PublishedDate);
        }

        [Theory]
        [InlineData("John; Mike; Albert", "Carl; Craig; Catherine")]
        [InlineData("", "")]
        [InlineData(null, null)]
        public async Task ShouldSetInventorAsNamesFromTheStates(string inventors, string applicants)
        {
            var countryCode = "US";
            var officialNumber = Fixture.String();
            var kindCode = "B1";
            new Country(countryCode, Fixture.String()).In(_db);

            var subject = new IpOneDataDocumentFinder(_documentApiClient, _patentScoutUrlFormatter, _db, _logger);

            _documentApiClient.Documents(countryCode, officialNumber, kindCode)
                              .Returns(new DocumentApiResponse
                              {
                                  Result = new Result
                                  {
                                      DocumentDetails =
                                          new[]
                                          {
                                              new DocumentDetails
                                              {
                                                  CountryCode = countryCode,
                                                  KindCode = kindCode,
                                                  Number = officialNumber,
                                                  DocumentType = "Grant",
                                                  Date = "2017-01-01",
                                                  Inventor = inventors?.Split(';').Select(v => v.Trim()).ToArray(),
                                                  Applicant = applicants?.Split(';').Select(v => v.Trim()).ToArray()
                                              }
                                          }
                                  }
                              });

            var r = await subject.Find(new SearchRequest
            {
                Country = countryCode,
                Kind = kindCode,
                OfficialNumber = officialNumber,
                SourceType = PriorArtTypes.Ipo
            }, new SearchResultOptions());

            Assert.Equal(inventors ?? string.Empty, r.Matches.Data.Single().Name);
        }

        [Fact]
        public async Task ShouldReturnMultipleResultsForMultiSearch()
        {
            var ipoRequest1 = new IpoSearchRequest { Country = Fixture.String(), OfficialNumber = Fixture.String(), Kind = Fixture.String() };
            var ipoRequest2 = new IpoSearchRequest { Country = Fixture.String(), OfficialNumber = Fixture.String(), Kind = Fixture.String() };
            new Country(ipoRequest1.Country, Fixture.String()).In(_db);
            new Country(ipoRequest2.Country, Fixture.String()).In(_db);
            var result1 = new DocumentDetails
            {
                CountryCode = ipoRequest1.Country,
                KindCode = ipoRequest1.Kind,
                Number = ipoRequest1.OfficialNumber,
                DocumentType = Fixture.String(),
                Abstract = Fixture.String(),
                ApplicationNumber = Fixture.String(),
                ApplicationDate = Fixture.Date().Iso8601OrNull(),
                IpId = Fixture.String(),
                Title = Fixture.String(),
                Date = "2017-01-01"
            };
            var result2 = new DocumentDetails
            {
                CountryCode = ipoRequest2.Country,
                KindCode = ipoRequest2.Kind,
                Number = ipoRequest2.OfficialNumber,
                DocumentType = Fixture.String(),
                Abstract = Fixture.String(),
                ApplicationNumber = Fixture.String(),
                ApplicationDate = Fixture.Date().Iso8601OrNull(),
                IpId = Fixture.String(),
                Title = Fixture.String(),
                Date = "2017-01-01"
            };
            _documentApiClient.Documents(ipoRequest1.Country, ipoRequest1.OfficialNumber, ipoRequest1.Kind)
                              .Returns(new DocumentApiResponse
                              {
                                  Result = new Result {DocumentDetails = new[] {result1}}
                              });
            _documentApiClient.Documents(ipoRequest2.Country, ipoRequest2.OfficialNumber, ipoRequest2.Kind)
                              .Returns(new DocumentApiResponse
                              {
                                  Result = new Result {DocumentDetails = new[] {result2}}
                              });
            var subject = new IpOneDataDocumentFinder(_documentApiClient, _patentScoutUrlFormatter, _db, _logger);
            var r = await subject.Find(new SearchRequest
            {
                SourceType = PriorArtTypes.Ipo,
                IpoSearchType = IpoSearchType.Multiple,
                MultipleIpoSearch = new[] { ipoRequest1, ipoRequest2 }
            }, new SearchResultOptions());

            Assert.Equal(2, r.Matches.Data.Count());
            Assert.NotNull(r.Matches.Data.Single(v => v.Id == result1.IpId));
            Assert.NotNull(r.Matches.Data.Single(v => v.Id == result2.IpId));
            Assert.NotNull(r.Matches.Data.Single(v => v.Title == result1.Title));
            Assert.NotNull(r.Matches.Data.Single(v => v.Title == result2.Title));
            Assert.NotNull(r.Matches.Data.Single(v => v.Abstract == result1.Abstract));
            Assert.NotNull(r.Matches.Data.Single(v => v.Abstract == result2.Abstract));
            Assert.NotNull(r.Matches.Data.Single(v => v.OfficialNumber == result1.Number));
            Assert.NotNull(r.Matches.Data.Single(v => v.OfficialNumber == result2.Number));
        }
    }
}