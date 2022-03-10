using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion;
using Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public class PriorityClaimsConverterFacts
    {
        readonly PriorityClaimsConverter _subject = new PriorityClaimsConverter();
        readonly CaseDetails _caseDetails = new CaseDetails("Patent", "EP");
        WorldPatentFixture _fixture;

        [Fact]
        public void ReturnsPriorityClaim()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithClaims(new[] {new PriorityClaimsBuilder().WithClaimDetails("EP", "1111", "20141112", "national", "1").Build()})
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var associatedCase = _caseDetails.AssociatedCaseDetails.Single();
            var officialNumberCreated = associatedCase.AssociatedCaseIdentifierNumberDetails.Single();
            var officialNumberDate = associatedCase.AssociatedCaseEventDetails.Single();

            Assert.Equal("EP", associatedCase.AssociatedCaseCountryCode);
            Assert.Equal("1111", officialNumberCreated.IdentifierNumberText);
            Assert.Equal("Priority", officialNumberCreated.IdentifierNumberCode);
            Assert.Equal("2014-11-12", officialNumberDate.EventDate);
        }

        [Fact]
        public void ReturnsPriorityClaims()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithClaims(new[]
                             {
                                 new PriorityClaimsBuilder().WithClaimDetails("EP", "1111", "20141112", "national", "1").Build(),
                                 new PriorityClaimsBuilder().WithClaimDetails("EP", "2222", "20140102", "national", "2").Build()
                             })
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var associatedCase = _caseDetails.AssociatedCaseDetails.ToArray();
            Assert.Equal(2, associatedCase.Count());

            Assert.Equal("EP", associatedCase[0].AssociatedCaseCountryCode);
            var officialNumberCreated = associatedCase[0].AssociatedCaseIdentifierNumberDetails.Single();
            var officialNumberDate = associatedCase[0].AssociatedCaseEventDetails.Single();
            Assert.Equal("1111", officialNumberCreated.IdentifierNumberText);
            Assert.Equal("Priority", officialNumberCreated.IdentifierNumberCode);
            Assert.Equal("2014-11-12", officialNumberDate.EventDate);

            Assert.Equal("EP", associatedCase[1].AssociatedCaseCountryCode);
            officialNumberCreated = associatedCase[1].AssociatedCaseIdentifierNumberDetails.Single();
            officialNumberDate = associatedCase[1].AssociatedCaseEventDetails.Single();
            Assert.Equal("2222", officialNumberCreated.IdentifierNumberText);
            Assert.Equal("Priority", officialNumberCreated.IdentifierNumberCode);
            Assert.Equal("2014-01-02", officialNumberDate.EventDate);
        }

        [Fact]
        public void ReturnsPriorityClaimWithLatestGazetteNum()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithClaims(new[] {new PriorityClaimsBuilder().WithClaimDetails("EP", "2222", "20140102", "national", "1").Build()}, "2010/42")
                             .WithClaims(new[] {new PriorityClaimsBuilder().WithClaimDetails("EP", "1111", "20141112", "national", "1").Build()}, "2014/40")
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var associatedCase = _caseDetails.AssociatedCaseDetails.Single();
            var officialNumberCreated = associatedCase.AssociatedCaseIdentifierNumberDetails.Single();
            var officialNumberDate = associatedCase.AssociatedCaseEventDetails.Single();

            Assert.Equal("EP", associatedCase.AssociatedCaseCountryCode);
            Assert.Equal("1111", officialNumberCreated.IdentifierNumberText);
            Assert.Equal("Priority", officialNumberCreated.IdentifierNumberCode);
            Assert.Equal("2014-11-12", officialNumberDate.EventDate);
        }

        [Fact]
        public void WithNoPriorityClaims()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            Assert.Empty(_caseDetails.AssociatedCaseDetails);
        }
    }
}