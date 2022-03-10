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
    public class ValidatedOfficeCharacteristicFacts : FactBase
    {
        [Fact]
        public async Task ReturnsDefaultCharacteristicForEmptyOfficeId()
        {
            var f = new ValidatedOfficeCharacteristicFixture(Db);

            var result = f.Subject.GetOffice(null);

            Assert.True(result.IsValid);
            Assert.Null(result.Code);
            Assert.Null(result.Key);
            Assert.Null(result.Value);
        }

        [Fact]
        public async Task ReturnsValidOfficeIfFound()
        {

            var f = new ValidatedOfficeCharacteristicFixture(Db);
            var officeId = Fixture.Integer();
            var name = Fixture.String();

            new Office(officeId, name).In(Db);

            var result = f.Subject.GetOffice(officeId);

            Assert.True(result.IsValid);
            Assert.Equal(officeId.ToString(), result.Code);
            Assert.Equal(officeId.ToString(), result.Key);
            Assert.Equal(name, result.Value);
        }

        [Fact]
        public async Task ReturnsNullIfNoOffice()
        {
            var f = new ValidatedOfficeCharacteristicFixture(Db);
            var officeId = Fixture.Integer();
            
            var result = f.Subject.GetOffice(officeId);

            Assert.Null(result);
        }

        public class ValidatedOfficeCharacteristicFixture : IFixture<ValidatedOfficeCharacteristic>
        {
            public ValidatedOfficeCharacteristicFixture(IDbContext db)
            {
                PreferredCulture = Substitute.For<IPreferredCultureResolver>();
                Subject = new ValidatedOfficeCharacteristic(PreferredCulture, db);
            }
            public IPreferredCultureResolver PreferredCulture { get; set; }
            public ValidatedOfficeCharacteristic Subject { get; set; }
        }
    }
}
