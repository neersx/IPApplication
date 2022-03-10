using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class ChecklistFacts
    {
        public class GetMethod : FactBase
        {
            public GetMethod()
            {
                _defaultCountry = new Country("ZZZ", "Default Country").In(Db);
                _australia = new CountryBuilder {Id = "AU", Name = "Australia"}.Build();
                _patent = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build();
                _properties = new CaseTypeBuilder {Id = "A", Name = "Properties"}.Build().In(Db);
            }

            readonly Country _australia;
            readonly Country _defaultCountry;
            readonly PropertyType _patent;
            readonly CaseType _properties;

            [Theory]
            [InlineData(null)]
            [InlineData("")]
            [InlineData("AU")]
            [InlineData("ZZZ")]
            public void FallsBackToDefaultCountry(string countryCode)
            {
                var c = new CheckList(1, "Base Checklist Decoy").In(Db);

                var vc1 = new ValidChecklistBuilder
                {
                    Country = _defaultCountry,
                    PropertyType = _patent,
                    CaseType = _properties,
                    CheckList = c,
                    ChecklistDesc = "Checklist 1"
                }.Build().In(Db);

                var vc2 = new ValidChecklistBuilder
                {
                    Country = _defaultCountry,
                    PropertyType = _patent,
                    CaseType = _properties,
                    CheckList = new CheckList(2, "Checklist 2").In(Db),
                    ChecklistDesc = "Checklist 2"
                }.Build().In(Db);

                var f = new ChecklistFixture(Db);

                var r = f.Subject.Get(countryCode, _patent.Code, _properties.Code).ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(vc1.ChecklistType, r[0].Id);
                Assert.Equal(vc1.ChecklistDescription, r[0].Description);
                Assert.Equal(vc2.ChecklistType, r[1].Id);
                Assert.Equal(vc2.ChecklistDescription, r[1].Description);
            }

            [Theory]
            [InlineData("AU", "T", "A")]
            [InlineData("AU", "P", "B")]
            [InlineData("AU", "", "")]
            [InlineData("", "P", "")]
            [InlineData("", "", "A")]
            [InlineData("", "", "")]
            public void FallsBackToBaseChecklists(string country, string property, string caseType)
            {
                var c1 = new ChecklistBuilder {Description = "Base Checklist 1"}.Build().In(Db);
                var c2 = new ChecklistBuilder {Description = "Base Checklist 2"}.Build().In(Db);

                new ValidChecklistBuilder
                {
                    Country = _defaultCountry,
                    PropertyType = _patent,
                    CaseType = _properties,
                    CheckList = c1,
                    ChecklistDesc = "Decoy Valid Checklist"
                }.Build().In(Db);

                var f = new ChecklistFixture(Db);

                var r = f.Subject.Get(country, property, caseType).ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(c1.Id, r[0].Id);
                Assert.Equal(c1.Description, r[0].Description);
                Assert.Equal(c2.Id, r[1].Id);
                Assert.Equal(c2.Description, r[1].Description);
            }

            [Fact]
            public void FallsBackToBaseChecklistsIfKeyNotExistsInValidList()
            {
                var c1 = new ChecklistBuilder {Description = "Base Checklist 1"}.Build().In(Db);
                var c2 = new ChecklistBuilder {Description = "Base Checklist 2"}.Build().In(Db);
                var c3 = new ChecklistBuilder {Description = "Base Checklist 3"}.Build().In(Db);

                new ValidChecklistBuilder
                {
                    Country = _australia,
                    PropertyType = _patent,
                    CaseType = _properties,
                    CheckList = c1,
                    ChecklistDesc = "Checklist 1"
                }.Build().In(Db);

                new ValidChecklistBuilder
                {
                    Country = _australia,
                    PropertyType = _patent,
                    CaseType = _properties,
                    CheckList = c2,
                    ChecklistDesc = "Checklist 2"
                }.Build().In(Db);

                var f = new ChecklistFixture(Db);

                var r = f.Subject.Get(_australia.Id, _patent.Code, _properties.Code, c3.Id).ToArray();

                Assert.Equal(3, r.Length);
                Assert.Contains(r, _ => _.Id == c3.Id);
                Assert.Equal(new[] {"Base Checklist 1", "Base Checklist 2", "Base Checklist 3"}, r.Select(_ => _.Description).ToArray());
            }

            [Fact]
            public void GetsAllValidChecklists()
            {
                var c = new CheckList(1, "Base Checklist Decoy").In(Db);
                var vc1 = new ValidChecklistBuilder
                {
                    Country = _australia,
                    PropertyType = _patent,
                    CaseType = _properties,
                    CheckList = c,
                    ChecklistDesc = "Checklist 1"
                }.Build().In(Db);
                var vc2 = new ValidChecklistBuilder
                {
                    Country = _australia,
                    PropertyType = _patent,
                    CaseType = _properties,
                    CheckList = new CheckList(2, "Checklist 2").In(Db),
                    ChecklistDesc = "Checklist 2"
                }.Build().In(Db);

                new ValidChecklistBuilder
                {
                    Country = _defaultCountry,
                    PropertyType = _patent,
                    CaseType = _properties,
                    CheckList = new CheckList(3, "Decoy Checklist").In(Db),
                    ChecklistDesc = "Decoy Checklist"
                }.Build().In(Db);

                var f = new ChecklistFixture(Db);

                var r = f.Subject.Get(_australia.Id, _patent.Code, _properties.Code).ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(vc1.ChecklistType, r[0].Id);
                Assert.Equal(vc1.ChecklistDescription, r[0].Description);
                Assert.Equal(vc2.ChecklistType, r[1].Id);
                Assert.Equal(vc2.ChecklistDescription, r[1].Description);
            }
        }

        public class ChecklistFixture : IFixture<Checklists>
        {
            public ChecklistFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                SecurityContext = Substitute.For<ISecurityContext>();
                Subject = new Checklists(db, PreferredCultureResolver, SecurityContext);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public ISecurityContext SecurityContext { get; set; }

            public Checklists Subject { get; }
        }
    }
}