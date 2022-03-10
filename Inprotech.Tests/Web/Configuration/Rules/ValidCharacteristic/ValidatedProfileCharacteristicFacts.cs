using System;
using System.Globalization;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using Inprotech.Web.Search.Case;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ValidCharacteristic
{
    public class ValidatedProfileCharacteristicFacts : FactBase
    {
        public class GetProfileMethod : FactBase
        {
            [Theory]
            [InlineData(null)]
            [InlineData("")]
            [InlineData(" ")]
            public async Task ReturnsEmptyValidatedCharacteristicWhenNoProfileName(string profileId)
            {
                var f = new ValidatedProfileCharacteristicFixture(Db);
                var result = f.Subject.GetProfile(profileId);

                Assert.Null(result);
            }
            
            [Fact]
            public async Task ReturnsEmptyValidatedCharacteristicWhenNoProfileMatchingName()
            {
                var profileId = Fixture.String();
                var f = new ValidatedProfileCharacteristicFixture(Db);
                var result = f.Subject.GetProfile(profileId);

                Assert.Null(result);
            }
            
            [Fact]
            public async Task ReturnsValidatedCharacteristicWithMatchingProfileIfMatchFound()
            {
                var profileId = Fixture.Integer();
                var profileName = Fixture.String();
                new Profile(profileId, profileName).In(Db);
                var f = new ValidatedProfileCharacteristicFixture(Db);
                var result = f.Subject.GetProfile(profileName);

                Assert.True(result.IsValid);
                Assert.Equal(profileId.ToString(), result.Code);
                Assert.Equal(profileId.ToString(), result.Key);
                Assert.Equal(profileName, result.Value);
            }
        }

        public class ValidatedProfileCharacteristicFixture : IFixture<ValidatedProfileCharacteristic>
        {
            public ValidatedProfileCharacteristicFixture(IDbContext db)
            {
                Subject = new ValidatedProfileCharacteristic(db);
            }

            public ValidatedProfileCharacteristic Subject { get; set; }
        }
    }
}
