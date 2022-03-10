using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class OfficesPicklistControllerFacts : FactBase
    {
        public class OfficesMethod : FactBase
        {
            [Fact]
            public void MarksExactMatchOnDescription()
            {
                var f = new OfficesPicklistControllerFixture(Db);

                var office = new OfficeBuilder {Name = "ABC"}.Build().In(Db);
                new OfficeBuilder {Name = "abcdef"}.Build().In(Db);

                var r = f.Subject.Offices(null, "abc").Data.OfType<Office>().ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(office.Id, r[0].Key);
            }

            [Fact]
            public void ReturnsOfficesContainingSearchStringOrderedByDescription()
            {
                var f = new OfficesPicklistControllerFixture(Db);

                var first = new OfficeBuilder {Name = "ABXXX"}.Build().In(Db);
                var second = new OfficeBuilder {Name = "AAXAB"}.Build().In(Db);
                var decoy = new OfficeBuilder {Name = "GXXXX"}.Build().In(Db);
                var third = new OfficeBuilder {Name = "XXABX"}.Build().In(Db);

                new CountryBuilder().Build().In(Db);

                var j = f.Subject.Offices(null, "AB").Data.OfType<Office>().ToArray();

                Assert.Equal(first.Id, j[0].Key);
                Assert.Contains(j, x => x.Key == second.Id);
                Assert.Contains(j, x => x.Key == third.Id);
                Assert.DoesNotContain(j, x => x.Key == decoy.Id);
            }

            [Fact]
            public void ReturnsOfficesSortedByDescription()
            {
                var f = new OfficesPicklistControllerFixture(Db);

                var b = new OfficeBuilder {Name = "B"}.Build().In(Db);
                var a = new OfficeBuilder {Name = "A"}.Build().In(Db);
                var c = new OfficeBuilder {Name = "C"}.Build().In(Db);

                var r = f.Subject.Offices();

                var o = r.Data.OfType<Office>().ToArray();

                Assert.Equal(a.Id, o[0].Key);
                Assert.Equal(a.Name, o[0].Value);
                Assert.Equal(b.Id, o[1].Key);
                Assert.Equal(b.Name, o[1].Value);
                Assert.Equal(c.Id, o[2].Key);
                Assert.Equal(c.Name, o[2].Value);
            }

            [Fact]
            public void ReturnsOrganisationCountryAndDefaultLanguage()
            {
                var f = new OfficesPicklistControllerFixture(Db);

                var office = new OfficeBuilder {Name = "B"}.Build().In(Db);
                office.Country = new CountryBuilder().Build();
                office.Organisation = new NameBuilder(Db).Build();
                office.DefaultLanguage = new TableCodeBuilder().Build();

                var r = f.Subject.Offices();

                var o = r.Data.OfType<Office>().Single();

                Assert.Equal(office.Id, o.Key);
                Assert.Equal(office.Name, o.Value);
                Assert.Equal(office.Country.Name, o.Country);
                Assert.Equal(office.Organisation.Formatted(), o.Organisation);
                Assert.Equal(office.DefaultLanguage.Name, o.DefaultLanguage);
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new OfficesPicklistControllerFixture(Db);

                new OfficeBuilder {Name = "AAA"}.Build().In(Db);
                new OfficeBuilder {Name = "CCC"}.Build().In(Db);
                var o = new OfficeBuilder {Name = "BBB"}.Build().In(Db);

                var qParams = new CommonQueryParameters {SortBy = "Value", SortDir = "asc", Skip = 1, Take = 1};
                var r = f.Subject.Offices(qParams);
                var offices = r.Data.OfType<Office>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(offices);
                Assert.Equal(o.Id, offices.Single().Key);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new OfficesPicklistControllerFixture(Db).Subject.GetType();
                var picklistAttribute = subjectType.GetMethod("Offices").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("Office", picklistAttribute.Name);
            }
        }
    }

    public class OfficesPicklistControllerFixture : IFixture<OfficesPicklistController>
    {
        public OfficesPicklistControllerFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            Subject = new OfficesPicklistController(db, PreferredCultureResolver);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public OfficesPicklistController Subject { get; }
    }
}