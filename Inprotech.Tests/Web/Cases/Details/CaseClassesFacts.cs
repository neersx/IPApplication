using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseClassesFacts
    {
        public class GetMethod : FactBase
        {
            Case CreateCase(string localClasses, bool createLocalClasses = true, decimal allowSubClass = 1m)
            {
                var caseType = new CaseTypeBuilder
                {
                    Id = Fixture.String(),
                    Name = Fixture.String(),
                    ActualCaseTypeId = Fixture.String()
                }.Build().In(Db);

                var propertyType = new PropertyTypeBuilder
                {
                    Name = Fixture.String(),
                    Id = Fixture.String(),
                    AllowSubClass = allowSubClass
                }.Build().In(Db);

                var country = new CountryBuilder
                {
                    Name = Fixture.String(),
                    Id = Fixture.String()
                }.Build().In(Db);

                var @case = new Case("123", country, caseType, propertyType) {LocalClasses = localClasses, PropertyTypeId = propertyType.Code}.In(Db);

                if (createLocalClasses)
                {
                    new TmClass(country.Id, "01", propertyType.Code).In(Db);
                    new TmClass(country.Id, "01", propertyType.Code, 1) {SubClass = "B"}.In(Db);
                    new TmClass(country.Id, "02", propertyType.Code).In(Db);
                    new TmClass(country.Id, "02", propertyType.Code, 1) {SubClass = "B"}.In(Db);
                }

                new TmClass(KnownValues.DefaultCountryCode, "01", propertyType.Code).In(Db);
                new TmClass(KnownValues.DefaultCountryCode, "01", propertyType.Code, 1) {SubClass = "A"}.In(Db);
                new TmClass(KnownValues.DefaultCountryCode, "01", propertyType.Code, 1) {SubClass = "B"}.In(Db);
                new TmClass(KnownValues.DefaultCountryCode, "02", propertyType.Code).In(Db);
                new TmClass(KnownValues.DefaultCountryCode, "02", propertyType.Code, 1) {SubClass = "A"}.In(Db);
                new TmClass(KnownValues.DefaultCountryCode, "02", propertyType.Code, 1) {SubClass = "B"}.In(Db);

                return @case;
            }

            [Fact]
            public void ReturnLocalClassAndSubClassIfAllowSubClassIsTrueAndLocalClassExist()
            {
                var @case = CreateCase("01,01.B,02,02.B");

                var f = new CaseClassesFixture(Db);
                var r = f.Subject.Get(@case).ToArray();

                Assert.Equal(4, r.Length);
                Assert.Equal(4, r.Count(_=>_.CountryCode != KnownValues.DefaultCountryCode));
                Assert.Equal(0, r.Count(_=>_.CountryCode == KnownValues.DefaultCountryCode));
                Assert.Equal(2, r.Count(_=>_.SubClass != null));
                Assert.Equal(2, r.Count(_=>_.SubClass == null));
            }

            [Fact]
            public void ReturnOnlyLocalClassIfAllowSubClassIsFalseAndLocalClassExist()
            {
                var @case = CreateCase( "01,01.A,01.B,02,02.B", allowSubClass: 0);

                var f = new CaseClassesFixture(Db);
                var r = f.Subject.Get(@case).ToArray();

                Assert.Equal(2, r.Count());
                Assert.Equal(2, r.Count(_=>_.CountryCode != KnownValues.DefaultCountryCode));
                Assert.Equal(0, r.Count(_=>_.CountryCode == KnownValues.DefaultCountryCode));
                Assert.Equal(0, r.Count(_=>_.SubClass != null));
                Assert.Equal(2, r.Count(_=>_.SubClass == null));
            }

            [Fact]
            public void ReturnLocalClassAndSubClassIfAllowSubClassIsTrueAndLocalClassDoeNotExist()
            {
                var @case = CreateCase("01,01.A,01.B,02,02.A,02.B", false);

                var f = new CaseClassesFixture(Db);
                var r = f.Subject.Get(@case).ToArray();

                Assert.Equal(6, r.Length);
                Assert.Equal(0, r.Count(_=>_.CountryCode != KnownValues.DefaultCountryCode));
                Assert.Equal(6, r.Count(_=>_.CountryCode == KnownValues.DefaultCountryCode));
                Assert.Equal(4, r.Count(_=>_.SubClass != null));
                Assert.Equal(2, r.Count(_=>_.SubClass == null));
            }

            [Fact]
            public void ReturnOnlyLocalClassIfAllowSubClassIsFalseAndLocalClassDoesNotExist()
            {
                var @case = CreateCase( "01,01.A,01.B,02,02.A,02.B", false, 0);

                var f = new CaseClassesFixture(Db);
                var r = f.Subject.Get(@case).ToArray();

                Assert.Equal(2, r.Count());
                Assert.Equal(0, r.Count(_=>_.CountryCode != KnownValues.DefaultCountryCode));
                Assert.Equal(2, r.Count(_=>_.CountryCode == KnownValues.DefaultCountryCode));
                Assert.Equal(0, r.Count(_=>_.SubClass != null));
                Assert.Equal(2, r.Count(_=>_.SubClass == null));
            }
        }

        public class CaseClassesFixture : IFixture<CaseClasses>
        {
            public CaseClassesFixture(InMemoryDbContext dbContext)
            {
                Subject = new CaseClasses(dbContext);
            }

            public CaseClasses Subject { get; }
        }
    }
}