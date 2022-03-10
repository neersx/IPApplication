using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.ValidCombinations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidJurisdictionsControllerFacts
    {
        public class ValidJurisdictionsControllerFixture : IFixture<ValidJurisdictionsController>
        {
            readonly InMemoryDbContext _db;

            public ValidJurisdictionsControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                Exporter = Substitute.For<ISimpleExcelExporter>();
                ValidJurisdictionsDetails = new ValidJurisdictionDetails(_db);
                Subject = new ValidJurisdictionsController(_db, Exporter, ValidJurisdictionsDetails);
            }

            public ISimpleExcelExporter Exporter { get; }
            public IValidJurisdictionsDetails ValidJurisdictionsDetails { get; set; }
            public ValidJurisdictionsController Subject { get; }

            public void SetValidJurisdictions()
            {
                var country = new CountryBuilder { Id = "NZ", Name = "New Zealand" }.Build();
                var propertyType = new PropertyTypeBuilder { Id = "T", Name = "TradeMark" }.Build();
                var caseType = new CaseTypeBuilder { Id = "P", Name = "Properties" }.Build();
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
                    Action = new ActionBuilder { Id = Fixture.String(), Name = Fixture.String() }.Build(),
                    ActionName = "Valid Action"
                }.Build().In(_db);
                var category = new ValidCategoryBuilder
                {
                    Country = country,
                    PropertyType = propertyType,
                    CaseType = caseType,
                    CaseCategory = new CaseCategoryBuilder { CaseTypeId = "P", Name = ".COM", CaseCategoryId = "P" }.Build(),
                    CaseCategoryDesc = "Valid .COM"
                }.Build().In(_db);
                new ValidSubTypeBuilder
                {
                    Country = country,
                    PropertyType = propertyType,
                    CaseType = caseType,
                    SubType = new SubTypeBuilder { Id = "5", Name = "5 yearly" }.Build(),
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
                    Status = new StatusBuilder { Id = Fixture.Short(), Name = "Status 1" }.Build()
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

                var countryAU = new CountryBuilder { Id = "AU", Name = "Australia" }.Build();
                var propertyTypeAU = new PropertyTypeBuilder { Id = "T", Name = "TradeMark" }.Build();
                var caseTypeAU = new CaseTypeBuilder { Id = "P", Name = "Properties" }.Build();
                new ValidCategoryBuilder
                {
                    Country = countryAU,
                    PropertyType = propertyTypeAU,
                    CaseType = caseTypeAU,
                    CaseCategory = new CaseCategoryBuilder { CaseTypeId = caseTypeAU.Code, Name = ".COM", CaseCategoryId = "P" }.Build()
                }.Build().In(_db);

                var countryUS = new CountryBuilder { Id = "US", Name = "United States Of America" }.Build();
                var propertyTypeUS = new PropertyTypeBuilder { Id = "P", Name = "Patent" }.Build();
                new ValidPropertyBuilder
                {
                    CountryCode = countryUS.Id,
                    CountryName = countryUS.Name,
                    PropertyTypeId = propertyTypeUS.Code,
                    PropertyTypeName = propertyTypeUS.Name
                }.Build().In(_db);
            }
        }

        public class GetPagedResultsMethod : FactBase
        {
            [Fact]
            public void OrdersByDescription()
            {
                var f = new ValidJurisdictionsControllerFixture(Db);
                f.SetValidJurisdictions();

                var jurisdictionData = f.ValidJurisdictionsDetails.SearchValidJurisdiction(new ValidCombinationSearchCriteria());

                var result = f.Subject.GetPagedResults(jurisdictionData,
                                                       new CommonQueryParameters { SortBy = "PropertyType", SortDir = "asc", Skip = 0, Take = 10 });

                var results = ((IEnumerable<dynamic>)result.Data).ToArray();

                Assert.Equal(10, results.Length);
                Assert.Equal(Db.Set<ValidProperty>().OrderBy(c => c.PropertyName).First().PropertyName, results[0].PropertyType);
            }

            [Fact]
            public void SkipsAndTakes()
            {
                var f = new ValidJurisdictionsControllerFixture(Db);
                f.SetValidJurisdictions();

                var jurisdictionData = f.ValidJurisdictionsDetails.SearchValidJurisdiction(new ValidCombinationSearchCriteria());
                var result = f.Subject.GetPagedResults(jurisdictionData,
                                                       new CommonQueryParameters { SortBy = "Country", SortDir = "asc", Skip = 3, Take = 5 });
                var results = ((IEnumerable<dynamic>)result.Data).ToArray();

                Assert.Equal(5, results.Length);
                Assert.Equal(Db.Set<ValidSubType>().First(vc => vc.CountryId == "NZ").SubTypeDescription, results[3].SubType);
            }
        }

        public class ExportToExcelMethod : FactBase
        {
            [Fact]
            public void ShouldExportSearchResults()
            {
                var fixture = new ValidJurisdictionsControllerFixture(Db);
                fixture.SetValidJurisdictions();

                fixture
                    .Subject
                    .ExportToExcel(new ValidCombinationSearchCriteria());

                var totalInDb = Db.Set<ValidProperty>().Select(_ => _.PropertyTypeId)
                                  .Concat(Db.Set<ValidAction>().Select(_ => _.ActionId))
                                  .Concat(Db.Set<ValidCategory>().Select(_ => _.CaseCategoryId))
                                  .Concat(Db.Set<ValidSubType>().Select(_ => _.CaseCategoryId))
                                  .Concat(Db.Set<ValidChecklist>().Select(_ => _.ChecklistDescription))
                                  .Concat(Db.Set<ValidRelationship>().Select(_ => _.ReciprocalRelationshipCode))
                                  .Concat(Db.Set<ValidBasis>().Select(_ => _.BasisId))
                                  .Concat(Db.Set<ValidStatus>().Select(_ => _.CaseTypeId));

                fixture.Exporter.Received(1).Export(Arg.Is<PagedResults>(x => x.Data.Count() == totalInDb.Count()), "Search Result.xlsx");
            }
        }
    }
}