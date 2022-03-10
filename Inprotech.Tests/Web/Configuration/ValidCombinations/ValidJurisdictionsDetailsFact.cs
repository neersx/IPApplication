using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.ValidCombinations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidJurisdictionsDetailsFacts
    {
        public class ValidJurisdictionsDetailsFixture : IFixture<ValidJurisdictionDetails>
        {
            readonly InMemoryDbContext _db;

            public ValidJurisdictionsDetailsFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new ValidJurisdictionDetails(_db);
            }

            public ValidJurisdictionDetails Subject { get; set; }

            public void SetValidJurisdictions()
            {
                var country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build();
                var propertyType = new PropertyTypeBuilder {Id = "T", Name = "TradeMark"}.Build();
                var caseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build();
                new ValidPropertyBuilder
                {
                    CountryCode = country.Id,
                    CountryName = country.Name,
                    PropertyTypeId = propertyType.Code,
                    PropertyTypeName = "NZ Trademark"
                }.Build().In(_db);
                new ValidActionBuilder
                {
                    Country = country,
                    PropertyType = propertyType,
                    CaseType = caseType,
                    Action = new ActionBuilder {Id = Fixture.String(), Name = Fixture.String()}.Build(),
                    ActionName = "Valid Action"
                }.Build().In(_db);
                var category = new ValidCategoryBuilder
                {
                    Country = country,
                    PropertyType = propertyType,
                    CaseType = caseType,
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = "P", Name = ".COM", CaseCategoryId = "P"}.Build(),
                    CaseCategoryDesc = "Valid .COM"
                }.Build().In(_db);
                new ValidSubTypeBuilder
                {
                    Country = country,
                    PropertyType = propertyType,
                    CaseType = caseType,
                    SubType = new SubTypeBuilder {Id = "5", Name = "5 yearly"}.Build(),
                    ValidCategory = category,
                    SubTypeDescription = "5 yearly renewals"
                }.Build().In(_db);
                new ValidBasisBuilder
                {
                    Country = country,
                    PropertyType = propertyType,
                    BasisDesc = "Valid Basis"
                }.Build().In(_db);
                new ValidStatusBuilder
                {
                    Country = country,
                    PropertyType = propertyType,
                    CaseType = caseType,
                    Status = new StatusBuilder {Id = Fixture.Short(), Name = "Status 1"}.Build()
                }.Build().In(_db);
                new ValidChecklistBuilder
                {
                    Country = country,
                    PropertyType = propertyType,
                    CaseType = caseType,
                    ChecklistType = Fixture.Short(),
                    ChecklistDesc = "Checklist 1"
                }.Build().In(_db);
                new ValidRelationshipBuilder
                {
                    Country = country,
                    PropertyType = propertyType,
                    Relation = new CaseRelation("EMP", null)
                }.Build().In(_db);

                var countryAU = new CountryBuilder {Id = "AU", Name = "Australia"}.Build();
                var propertyTypeAU = new PropertyTypeBuilder {Id = "T", Name = "TradeMark"}.Build();
                var caseTypeAU = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build();
                new ValidCategoryBuilder
                {
                    Country = countryAU,
                    PropertyType = propertyTypeAU,
                    CaseType = caseTypeAU,
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = caseTypeAU.Code, Name = ".COM", CaseCategoryId = "P"}.Build()
                }.Build().In(_db);

                var countryUS = new CountryBuilder {Id = "US", Name = "United States Of America"}.Build();
                var propertyTypeUS = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build();
                new ValidPropertyBuilder
                {
                    CountryCode = countryUS.Id,
                    CountryName = countryUS.Name,
                    PropertyTypeId = propertyTypeUS.Code,
                    PropertyTypeName = propertyTypeUS.Name
                }.Build().In(_db);
            }
        }

        public class SearchValidJurisdictions : FactBase
        {
            [Fact]
            public void SearchAllJurisdictions()
            {
                var searchCriteria = new ValidCombinationSearchCriteria();
                var f = new ValidJurisdictionsDetailsFixture(Db);
                f.SetValidJurisdictions();
                var results = f.Subject.SearchValidJurisdiction(searchCriteria);
                Assert.Equal(10, results.Count());
            }

            [Fact]
            public void SearchBasedOnCountries()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {Jurisdictions = new[] {"AU", "US"}};
                var f = new ValidJurisdictionsDetailsFixture(Db);
                f.SetValidJurisdictions();

                var results = f.Subject.SearchValidJurisdiction(searchCriteria);

                Assert.Equal(2, results.Count());
            }

            [Fact]
            public void ShouldReturnJurisdictionsInCorrectOrder()
            {
                var countryCode = "NZ";
                var searchCriteria = new ValidCombinationSearchCriteria();
                var f = new ValidJurisdictionsDetailsFixture(Db);
                f.SetValidJurisdictions();

                var result = f.Subject.SearchValidJurisdiction(searchCriteria);
                var results = ((IEnumerable<dynamic>) result).ToArray();

                Assert.Equal("Australia", results.First().Country);
                Assert.Equal(Db.Set<ValidProperty>().First(vp => vp.CountryId == countryCode).PropertyName, results[1].PropertyType);
                Assert.Equal(Db.Set<ValidBasis>().First(vc => vc.CountryId == countryCode).BasisDescription, results[3].Basis);
                Assert.Equal(Db.Set<ValidSubType>().First(vc => vc.CountryId == countryCode).SubTypeDescription, results[6].SubType);
            }

            [Fact]
            public void ShouldReturnValidDescriptions()
            {
                var countryCode = "NZ";
                var searchCriteria = new ValidCombinationSearchCriteria {Jurisdictions = new[] {countryCode}};
                var f = new ValidJurisdictionsDetailsFixture(Db);
                f.SetValidJurisdictions();

                var results = f.Subject.SearchValidJurisdiction(searchCriteria);

                Assert.Equal(8, results.Count());
                Assert.Contains(Db.Set<ValidProperty>().First(vp => vp.CountryId == countryCode).PropertyName, results.Select(r => r.PropertyType));
                Assert.Contains(Db.Set<ValidAction>().First(vc => vc.CountryId == countryCode).ActionName, results.Select(r => r.Action));
                Assert.Contains(Db.Set<ValidCategory>().First(vc => vc.CountryId == countryCode).CaseCategoryDesc, results.Select(r => r.Category));
                Assert.Contains(Db.Set<ValidSubType>().First(vc => vc.CountryId == countryCode).SubTypeDescription, results.Select(r => r.SubType));
                Assert.Contains(Db.Set<ValidBasis>().First(vc => vc.CountryId == countryCode).BasisDescription, results.Select(r => r.Basis));
                Assert.Contains(Db.Set<ValidStatus>().First(vc => vc.CountryId == countryCode).Status.Name, results.Select(r => r.Status));
                Assert.Contains(Db.Set<ValidChecklist>().First(vc => vc.CountryId == countryCode).ChecklistDescription, results.Select(r => r.Checklist));
                Assert.Contains(Db.Set<ValidRelationship>().First(vc => vc.CountryId == countryCode).Relationship.Description, results.Select(r => r.Relationship));
            }
        }
    }
}