using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseHeaderControllerFacts : FactBase
    {
        [Fact]
        public void ShouldDefaultValuesCorrectly()
        {
            var fixture = new CaseHeaderControllerFixture(Db);

            var @case = new CaseBuilder().Build().In(Db);

            var result = fixture.Subject.GetCaseHeader(@case.Id);

            Assert.Null(result.CaseResults.CaseStatusDescription);
            Assert.Null(result.CaseResults.PropertyTypeDescription);
            Assert.Equal(@case.Id, result.CaseResults.Id);
            Assert.Empty(result.OfficialNumbers);
        }

        [Fact]
        public void ShouldReturnTheExpectedCountry()
        {
            var fixture = new CaseHeaderControllerFixture(Db);
            var country = new Country(Fixture.String(), Fixture.String()).In(Db);

            var @case = new CaseBuilder().Build().In(Db);
            @case.CountryId = country.Id;

            var result = fixture.Subject.GetCaseHeader(@case.Id);

            Assert.Equal(country.CountryAdjective, result.CaseResults.CountryAdjective);
        }

        [Fact]
        public void ShouldReturnTheExpectedCaseType()
        {
            var fixture = new CaseHeaderControllerFixture(Db);
            var caseType = new CaseType(Fixture.String(), Fixture.String()).In(Db);
            var @case = new CaseBuilder().Build().In(Db);
            @case.TypeId = caseType.Code;

            var result = fixture.Subject.GetCaseHeader(@case.Id);

            Assert.Equal(caseType.Name, result.CaseResults.CaseTypeDescription);
        }

        [Fact]
        public void ShouldReturnTheExpectedStatus()
        {
            var fixture = new CaseHeaderControllerFixture(Db);

            var status = new Status(Fixture.Short(), Fixture.String()).In(Db);
            var @case = new CaseBuilder().Build().In(Db);
            @case.StatusCode = status.Id;

            var result = fixture.Subject.GetCaseHeader(@case.Id);

            Assert.Equal(status.Name, result.CaseResults.CaseStatusDescription);
        }

        [Fact]
        public void ShouldReturnTheExpectedValidProperty()
        {
            var fixture = new CaseHeaderControllerFixture(Db);
            var country = new Country(Fixture.String(), Fixture.String()).In(Db);
            var validProperty = new ValidProperty() { CountryId = country.Id, PropertyName = Fixture.String(), PropertyTypeId = Fixture.String() }.In(Db);
            var @case = new CaseBuilder().Build().In(Db);
            @case.CountryId = country.Id;
            @case.PropertyTypeId = validProperty.PropertyTypeId;
            var result = fixture.Subject.GetCaseHeader(@case.Id);

            Assert.Equal(validProperty.PropertyName, result.CaseResults.PropertyTypeDescription);
        }

        public class CaseHeaderControllerFixture : IFixture<CaseHeaderController>
        {
            public CaseHeaderControllerFixture(IDbContext db)
            {
                PreferredCulture = Substitute.For<IPreferredCultureResolver>();
                PreferredCulture.Resolve().Returns(Fixture.String());
                Subject = new CaseHeaderController(db, PreferredCulture);
            }
            public IPreferredCultureResolver PreferredCulture { get; set; }
            public CaseHeaderController Subject { get; }
        }
    }
}
