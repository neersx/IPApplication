using System;
using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion;
using Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public class ApplicantConverterFacts
    {
        readonly ApplicantsConverter _subject = new ApplicantsConverter();
        readonly CaseDetails _caseDetails = new CaseDetails("Trademark", "US");
        TsdrSourceFixture _fixture;

        [Fact]
        public void ReturnsAddress()
        {
            var source = new ApplicantBuilder()
                         .AsOrganisation("Brimstone Holding Company")
                         .WithAddress(new StructuredAddressBuilder
                         {
                             AddressLineText1 = "York St",
                             CityName = "Sydney",
                             GeographicRegionName = "NSW",
                             CountryCode = "AU",
                             PostalCode = "2000"
                         }.Build())
                         .Build()
                         .AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            var formattedAddress = _caseDetails.NameDetails.Single().AddressBook
                                               .FormattedNameAddress.Address.FormattedAddress;

            Assert.Equal("York St", formattedAddress.AddressStreet);
            Assert.Equal("Sydney", formattedAddress.AddressCity);
            Assert.Equal("NSW", formattedAddress.AddressState);
            Assert.Equal("AU", formattedAddress.AddressCountryCode);
            Assert.Equal("2000", formattedAddress.AddressPostcode);
        }

        [Fact]
        public void ReturnsAddressLinesConcatenated()
        {
            var source = new ApplicantBuilder()
                         .AsOrganisation("Brimstone Holding Company")
                         .WithAddress(new StructuredAddressBuilder
                         {
                             AddressLineText1 = "Level 4",
                             AddressLineText2 = "York St",
                             CityName = "Sydney",
                             GeographicRegionName = "NSW",
                             CountryCode = "AU",
                             PostalCode = "2000"
                         }.Build())
                         .Build()
                         .AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            var formattedAddress = _caseDetails.NameDetails.Single().AddressBook
                                               .FormattedNameAddress.Address.FormattedAddress;

            Assert.Equal("Level 4" + Environment.NewLine + "York St", formattedAddress.AddressStreet);
            Assert.Equal("Sydney", formattedAddress.AddressCity);
            Assert.Equal("NSW", formattedAddress.AddressState);
            Assert.Equal("AU", formattedAddress.AddressCountryCode);
            Assert.Equal("2000", formattedAddress.AddressPostcode);
        }

        [Fact]
        public void ReturnsCurrentApplicant()
        {
            var builder = new ApplicantBuilder();
            var applicants = new[]
            {
                builder.AsIndividual("George Grey")
                       .WithSequence("10")
                       .Build(),
                builder.AsIndividual("George Greyer")
                       .WithSequence("20")
                       .Build()
            }.AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(applicants);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            var applicant =
                _caseDetails.NameDetails.Single()
                            .AddressBook.FormattedNameAddress.Name.FreeFormatName;

            Assert.Equal("George Greyer", applicant.FreeFormatNameDetails.FreeFormatNameLine.Single());
        }

        [Fact]
        public void ReturnsCurrentApplicants()
        {
            var builder = new ApplicantBuilder();
            var applicants = new[]
            {
                builder.AsIndividual("George Greyer")
                       .WithSequence("100")
                       .Build(),
                builder.AsIndividual("George Grey")
                       .WithSequence("20")
                       .Build(),
                builder.AsIndividual("George Greybeard")
                       .WithSequence("100")
                       .Build()
            }.AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(applicants);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            var returnedApplicants = _caseDetails.NameDetails.Select(_ => _.AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.Single()).ToArray();

            Assert.Equal(2, returnedApplicants.Count());
            Assert.Contains("George Greyer", returnedApplicants);
            Assert.Contains("George Greybeard", returnedApplicants);
        }

        [Fact]
        public void ReturnsEntityName()
        {
            var source = new ApplicantBuilder()
                         .AsEntityName("Brimstone Holding Company")
                         .Build()
                         .AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            var freeFormatName =
                _caseDetails.NameDetails.Single()
                            .AddressBook.FormattedNameAddress.Name.FreeFormatName;

            Assert.Equal("Brimstone Holding Company", freeFormatName.FreeFormatNameDetails.FreeFormatNameLine.Single());
            Assert.Equal(NameKindType.Organisation, freeFormatName.NameKind);
        }

        [Fact]
        public void ReturnsInvidualName()
        {
            var source = new ApplicantBuilder()
                         .AsIndividual("George Grey")
                         .Build()
                         .AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            var freeFormatName =
                _caseDetails.NameDetails.Single()
                            .AddressBook.FormattedNameAddress.Name.FreeFormatName;

            Assert.Equal("George Grey", freeFormatName.FreeFormatNameDetails.FreeFormatNameLine.Single());
            Assert.Equal(NameKindType.Individual, freeFormatName.NameKind);
        }

        [Fact]
        public void ReturnsOrganisationName()
        {
            var source = new ApplicantBuilder()
                         .AsOrganisation("Brimstone Holding Company")
                         .Build()
                         .AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            var freeFormatName =
                _caseDetails.NameDetails.Single()
                            .AddressBook.FormattedNameAddress.Name.FreeFormatName;

            Assert.Equal("Brimstone Holding Company", freeFormatName.FreeFormatNameDetails.FreeFormatNameLine.Single());
            Assert.Equal(NameKindType.Organisation, freeFormatName.NameKind);
        }
    }
}