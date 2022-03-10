using System;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using Xunit;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Cases
{
    public class CaseDataExtensionFacts
    {
        static CaseDataExtension CreateSubject(IDbContext db)
        {

            return new CaseDataExtension(db);
        }

        static Case CreateCaseWith(string country, string propertyType)
        {
            return new()
            {
                Irn = Fixture.String(),
                Title = Fixture.String(),
                CountryId = country,
                PropertyTypeId = propertyType
            };
        }

        public class RetrieveMethodWithCaseIds : FactBase
        {
            [Fact]
            public async Task ShouldReturnCountryAndPropertyTypeDescription()
            {
                var country = new Country(Fixture.String(), Fixture.String()).In(Db);
                var propertyType = new PropertyType(Fixture.String(), Fixture.String()).In(Db);
                var propertyType2 = new PropertyType(Fixture.String(), Fixture.String()).In(Db);
                var vp = new ValidProperty { Country = country, CountryId = country.Id, PropertyType = propertyType, PropertyTypeId = propertyType.Code, PropertyName = Fixture.String() }.In(Db);
                var vp2 = new ValidProperty { CountryId = KnownValues.DefaultCountryCode, PropertyType = propertyType2, PropertyTypeId = propertyType2.Code, PropertyName = Fixture.String() }.In(Db);
                var case1 = CreateCaseWith(country.Id, propertyType.Code).In(Db);
                var case2 = CreateCaseWith(country.Id, propertyType2.Code).In(Db);

                var subject = CreateSubject(Db);

                var r = await subject.GetPropertyTypeAndCountry(new[]
                {
                    case1.Id,
                    case2.Id
                }, String.Empty);

                Assert.Equal(2, r.Count);

                Assert.Equal(case1.Id, r[case1.Id].CaseId);
                Assert.Equal(country.Name, r[case1.Id].Country);
                Assert.Equal(vp.PropertyName, r[case1.Id].PropertyTypeDescription);

                Assert.Equal(case2.Id, r[case2.Id].CaseId);
                Assert.Equal(country.Name, r[case1.Id].Country);
                Assert.Equal(vp2.PropertyName, r[case2.Id].PropertyTypeDescription);
            }
        }

        public class GetActionMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnNullWhenNoActionIsProvided()
            {
                var subject = CreateSubject(Db);
                var r = await subject.GetValidAction(new ValidActionIdentifier(), Fixture.String());
                Assert.Null(r);
            }

            [Fact]
            public async Task ShouldReturnActionDataWhenNoActionIsProvided()
            {
                var country = new Country(Fixture.String(), Fixture.String()).In(Db);
                var propertyType = new PropertyType(Fixture.String(), Fixture.String()).In(Db);
                var caseType = new CaseType(Fixture.String(), Fixture.String()).In(Db);
                var action = new Action(Fixture.String()) {Code = Fixture.String()};
                var validAction = new ValidAction(Fixture.String(), action, country, caseType, propertyType).In(Db);
                var subject = CreateSubject(Db);
                var r = await subject.GetValidAction(new ValidActionIdentifier {ActionCode = action.Code, CaseTypeCode = caseType.Code, CountryCode = country.Id, PropertyTypeCode = propertyType.Code}, Fixture.String());
                Assert.Equal(action.Code, r.Code);
                Assert.Equal(validAction.ActionName, r.Value);
            }
        }
    }
}
