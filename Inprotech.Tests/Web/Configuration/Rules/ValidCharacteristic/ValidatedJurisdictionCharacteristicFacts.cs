using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ValidCharacteristic
{
    public class ValidatedJurisdictionCharacteristicFacts : FactBase
    {
        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData(" ")]
        public async Task ReturnsDefaultCharacteristicForEmptyJurisdictionId(string jurisdictionId)
        {
            var f = new ValidatedJurisdictionCharacteristicFixture(Db);

            var result = f.Subject.GetJurisdiction(jurisdictionId);

            Assert.True(result.IsValid);
            Assert.Null(result.Code);
            Assert.Null(result.Key);
            Assert.Null(result.Value);
        }

        [Fact]
        public async Task ReturnsValidJurisdictionIfFound()
        {
            var f = new ValidatedJurisdictionCharacteristicFixture(Db);
            var jurisdictionId = Fixture.String();
            var name = Fixture.String();

            new Country(jurisdictionId, name).In(Db);

            var result = f.Subject.GetJurisdiction(jurisdictionId);

            Assert.True(result.IsValid);
            Assert.Equal(jurisdictionId, result.Code);
            Assert.Equal(jurisdictionId, result.Key);
            Assert.Equal(name, result.Value);
        }

        [Fact]
        public async Task ReturnsNullIfNoJurisdiction()
        {
            var f = new ValidatedJurisdictionCharacteristicFixture(Db);
            var jurisdictionId = Fixture.String();
            
            var result = f.Subject.GetJurisdiction(jurisdictionId);

            Assert.Null(result);
        }

        public class ValidatedJurisdictionCharacteristicFixture : IFixture<ValidatedJurisdictionCharacteristic>
        {
            public ValidatedJurisdictionCharacteristicFixture(IDbContext db)
            {
                PreferredCulture = Substitute.For<IPreferredCultureResolver>();
                Subject = new ValidatedJurisdictionCharacteristic(PreferredCulture, db);
            }
            public IPreferredCultureResolver PreferredCulture { get; set; }
            public ValidatedJurisdictionCharacteristic Subject { get; set; }
        }
    }
}
