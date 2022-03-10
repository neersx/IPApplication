using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;
using RelatedCase = Inprotech.Web.Cases.Details.RelatedCase;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class RelatedCasesControllerFacts : FactBase
    {
        RelatedCasesController _subject;
        readonly int _caseKey = Fixture.Integer();
        IExternalPatentInfoLinkResolver _externalPatentInfoLink;
        readonly IFileInstructInterface _fileInstructInterface = Substitute.For<IFileInstructInterface>();
        readonly IAuthSettings _authSettings = Substitute.For<IAuthSettings>();

        RelatedCasesController CreateSubject(RelatedCase[] returnResults, Dictionary<(string countryCode, string officialNumber), Uri> officialNumbers = null)
        {
            var relatedCases = Substitute.For<IRelatedCases>();
            _externalPatentInfoLink = Substitute.For<IExternalPatentInfoLinkResolver>();

            relatedCases.Retrieve(_caseKey).Returns(returnResults.AsDbAsyncEnumerble().AsQueryable().OfType<RelatedCase>());
            _externalPatentInfoLink.ResolveRelatedCases(Arg.Any<string>(), Arg.Any<(string countryCode, string officialNumber)[]>()).Returns(officialNumbers ?? new Dictionary<(string countryCode, string officialNumber), Uri>());

            return _subject = new RelatedCasesController(Db, relatedCases, _externalPatentInfoLink, _fileInstructInterface, _authSettings);
        }

        const bool IpPlatformSessionActive = true;
        const bool IpPlatformSessionInactive = false;

        [Theory]
        [InlineData(IpPlatformSessionActive)]
        [InlineData(IpPlatformSessionInactive)]
        public async Task ShouldReturnCanViewInFileIfThereIsActiveIpPlatformSession(bool ipPlatformIsActive)
        {
            var r1Ok = Fixture.Integer();
            var r2NotOk = Fixture.Integer();
            var r3FiledButNoAccess = Fixture.Integer();

            _authSettings.SsoEnabled.Returns(true);

            _fileInstructInterface.GetFiledCaseIdsFor(Arg.Any<HttpRequestMessage>(), _caseKey)
                                  .Returns(new FiledCases
                                  {
                                      FiledCaseIds = new[] { r1Ok, r3FiledButNoAccess },
                                      CanView = ipPlatformIsActive
                                  });

            var returnResults = new[]
            {
                new RelatedCase {CaseId = r1Ok, ClientReference = Fixture.String(), IsFiled = false},
                new RelatedCase {CaseId = r2NotOk},
                new RelatedCase {CaseId = r3FiledButNoAccess}
            };

            var subject = CreateSubject(returnResults);
            var result = (await subject.GetRelatedCases(_caseKey, new CommonQueryParameters())).Data.Cast<RelatedCase>().ToArray();

            // first case filed, inprotech case accessible
            Assert.True(result.ElementAt(0).IsFiled);
            Assert.Equal(ipPlatformIsActive, result.ElementAt(0).CanViewInFile);

            // second case not filed, inprotech case accessible
            Assert.False(result.ElementAt(1).IsFiled);
            Assert.False(result.ElementAt(1).CanViewInFile);

            // third case filed, inprotech case not accessible (could be due to Ethical Wall / Row Level Access)
            Assert.True(result.ElementAt(2).IsFiled);
            Assert.False(result.ElementAt(2).CanViewInFile);
        }

        [Fact]
        public async Task ShouldHandleDuplicatesWithOfficalNumberLink()
        {
            var countries = new[] { Fixture.String("US"), Fixture.String("AU") };
            var officialNumbers = new[] { Fixture.String("123"), Fixture.String("456") };
            var urls = new[] { new Uri("http://www.abc.com"), new Uri("http://www.xyz.com") };
            var returnResults = new[]
            {
                new RelatedCase {CountryCode = countries[0], OfficialNumber = officialNumbers[0]},
                new RelatedCase {CountryCode = countries[0], OfficialNumber = officialNumbers[0]},
                new RelatedCase {CountryCode = countries[0], OfficialNumber = officialNumbers[0]},
                new RelatedCase {CountryCode = countries[1], OfficialNumber = officialNumbers[1]}
            };
            var returnOfficialNumbers = new Dictionary<(string countryCode, string officialNumber), Uri>
            {
                {(returnResults[0].CountryCode, returnResults[0].OfficialNumber), urls[0]},
                {(countries[1], officialNumbers[1]), urls[1]}
            };

            CreateSubject(returnResults, returnOfficialNumbers);

            var r = (await _subject.GetRelatedCases(_caseKey, new CommonQueryParameters())).Data.Cast<RelatedCase>().ToArray();

            Assert.Equal(urls[0], r.First().ExternalInfoLink);
            Assert.Equal(urls[1], r.Last().ExternalInfoLink);
            Assert.Equal(3, r.Count(_ => _.CountryCode == countries[0]));
        }

        [Fact]
        public async Task ShouldNotPopulateFiledDetailsIfSsoNotSet()
        {
            var r1Ok = Fixture.Integer();

            _authSettings.SsoEnabled.Returns(false); // not configured.

            _fileInstructInterface.GetFiledCaseIdsFor(Arg.Any<HttpRequestMessage>(), _caseKey)
                                  .Returns(new FiledCases
                                  {
                                      FiledCaseIds = new[] { r1Ok },
                                      CanView = true
                                  });

            var returnResults = new[]
            {
                new RelatedCase {CaseId = r1Ok, InternalReference = Fixture.String()}
            };

            var subject = CreateSubject(returnResults);
            var result = (await subject.GetRelatedCases(_caseKey, new CommonQueryParameters())).Data.Cast<RelatedCase>().ToArray();

            Assert.False(result.Last().IsFiled);
        }

        [Fact]
        public async Task ShouldReturnRelatedCases()
        {
            var returnResults = new[]
            {
                new RelatedCase(),
                new RelatedCase()
            };
            CreateSubject(returnResults);

            var r = (await _subject.GetRelatedCases(_caseKey, new CommonQueryParameters())).Data as IEnumerable<RelatedCase>;

            Assert.Equal(returnResults, r);
        }

        [Fact]
        public async Task ShouldReturnRelatedCasesWithOfficalNumberLink()
        {
            var countries = new[] { Fixture.String("US"), Fixture.String("AU") };
            var officialNumbers = new[] { Fixture.String("123"), Fixture.String("456") };
            var urls = new[] { new Uri("http://www.abc.com"), new Uri("http://www.xyz.com") };
            var returnResults = new[]
            {
                new RelatedCase {CountryCode = countries[0], OfficialNumber = officialNumbers[0]},
                new RelatedCase {CountryCode = countries[1], OfficialNumber = officialNumbers[1]}
            };
            var returnOfficialNumbers = new Dictionary<(string countryCode, string officialNumber), Uri>
            {
                {(returnResults[0].CountryCode, returnResults[0].OfficialNumber), urls[0]},
                {(returnResults[1].CountryCode, returnResults[1].OfficialNumber), urls[1]}
            };

            CreateSubject(returnResults, returnOfficialNumbers);

            var r = (await _subject.GetRelatedCases(_caseKey, new CommonQueryParameters())).Data.Cast<RelatedCase>().ToArray();

            Assert.Equal(urls[0], r.First().ExternalInfoLink);
            Assert.Equal(urls[1], r.Last().ExternalInfoLink);
        }
    }
}