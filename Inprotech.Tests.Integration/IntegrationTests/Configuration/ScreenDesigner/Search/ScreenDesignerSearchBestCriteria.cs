using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Configuration.ScreenDesigner.Search
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class ScreenDesignerSearchBestCriteria : IntegrationTest
    {

        TestUser _user;
        [SetUp]
        public void Setup()
        {
            _user = new Users()
                    .WithPermission(ApplicationTask.MaintainCpassRules, Deny.Create | Deny.Delete | Deny.Modify)
                    .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                    .WithLicense(LicensedModule.IpMatterManagementModule)
                    .Create();
        }

        [Test]
        public void ShouldReturnOnlyCorrectPurposeCodeRecords()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("With-office-and-program"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });

                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("should-not-return"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });

                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("should-not-return"),
                    PurposeCode = CriteriaPurposeCodes.CaseLinks,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });

                return new
                {
                    Program = program,
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "best-criteria-only",
                CaseProgram = data.Program.Id
            };

            AssertCriteriaReturnsCount(searchCriteria, 1, "should only return the top record with purpose code");
        }

        [Test]
        public void ShouldReturnAllNonProtectedCriteriaIfNoFilter()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("With-office-and-program"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });

                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("should-not-return"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = true
                });

                return new
                {
                    Program = program
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "best-criteria-only",
                CaseProgram = data.Program.Id
            };

            AssertCriteriaReturnsCount(searchCriteria, 1, "Assert top criteria not protected if no filter");
        }

        [Test]
        public void ShouldReturnOnlyCriteriaWithPurposeCodeWindowControl()
        {
            var data = DbSetup.Do(db =>
            {
                var office = db.InsertWithNewId(new Office { Name = Fixture.UriSafeString(10) });
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("With-office-and-program"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = true
                });

                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("should-not-return"),
                    PurposeCode = CriteriaPurposeCodes.CaseLinks,
                    ProgramId = program.Id,
                    Office = office,
                    RuleInUse = 1,
                    IsProtected = true
                });

                return new
                {
                    Office = office,
                    Program = program
                };
            });

            var searchCriteria = new SearchCriteria
            {
                IncludeProtectedCriteria = true,
                MatchType = "best-criteria-only",
                Office = data.Office.Id,
                CaseProgram = data.Program.Id
            };

            AssertCriteriaReturnsCount(searchCriteria, 1, "Should only return criteria with purpose code window control");
        }

        [Test]
        public void ShouldExcludeProtectedCriteriaFilterDictatesIt()
        {
            var data = DbSetup.Do(db =>
            {
                var office = db.InsertWithNewId(new Office { Name = Fixture.UriSafeString(10) });
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var criteria = db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("With-office-and-program"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    Office = office,
                    RuleInUse = 1,
                    IsProtected = false
                });

                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("should-not-return"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    Office = office,
                    RuleInUse = 1,
                    IsProtected = true
                });

                return new
                {
                    Office = office,
                    Program = program,
                    Criteria = criteria
                };
            });

            var searchCriteria = new SearchCriteria
            {
                IncludeProtectedCriteria = false,
                MatchType = "best-criteria-only",
                Office = data.Office.Id,
                CaseProgram = data.Program.Id
            };
            AssertCriteriaReturnsCount(searchCriteria, 1, "Should return top match where not protected");
        }

        [Test]
        public void ShouldReturnMultipleMatchesForAllFilters()
        {
            var data = DbSetup.Do(db =>
            {
                var office = db.InsertWithNewId(new Office { Name = Fixture.UriSafeString(10) });
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var caseType = db.InsertWithNewId(new CaseType(Fixture.UriSafeString(1), Fixture.UriSafeString(10)));
                var jurisdiction = db.InsertWithNewId(new Country(Fixture.UriSafeString(2), Fixture.UriSafeString(10), Fixture.String(1)));
                var propertyType = db.InsertWithNewId(new PropertyType(Fixture.UriSafeString(2), Fixture.UriSafeString(10)));
                var caseCategory = db.Insert(new CaseCategory(caseType.Code, "Ť", Fixture.UriSafeString(10)));
                var subType = db.InsertWithNewId(new SubType("Ť", Fixture.UriSafeString(10)));

                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("With-office-and-program"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    Office = office,
                    RuleInUse = 1,
                    IsProtected = false,
                    CaseCategory = caseCategory,
                    SubType = subType,
                    Country = jurisdiction,
                    PropertyType = propertyType
                });

                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("With-office-and-program"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    Office = office,
                    RuleInUse = 1,
                    IsProtected = false,
                    CaseCategory = caseCategory,
                    SubType = subType,
                    Country = jurisdiction,
                    PropertyType = propertyType
                });

                return new
                {
                    Subtype = subType,
                    CaseCategory = caseCategory,
                    Program = program,
                    Office = office,
                    CaseType = caseType,
                    Jurisdiction = jurisdiction,
                    PropertyType = propertyType
                };
            });

            var allCriteriaChecked = new SearchCriteria
            {
                MatchType = "best-criteria-only",
                SubType = data.Subtype.Code,
                CaseCategory = data.CaseCategory.CaseCategoryId,
                CaseProgram = data.Program.Id,
                Office = data.Office.Id,
                CaseType = data.CaseType.Code,
                Jurisdiction = data.Jurisdiction.Id,
                PropertyType = data.PropertyType.Code
            };

            AssertCriteriaReturnsCount(allCriteriaChecked, 1, "Should return 1 records when all criteria checked");

            var justOfficeFilter = new SearchCriteria
            {
                MatchType = "best-criteria-only",
                Office = data.Office.Id,
            };
            AssertCriteriaReturnsCount(justOfficeFilter, 0, "Should Return 0 records when just office checked");

            var justProgramFilter = new SearchCriteria
            {
                MatchType = "best-criteria-only",
                CaseProgram = data.Program.Id
            };
            AssertCriteriaReturnsCount(justProgramFilter, 0, "Should Return 0 records when just program checked");

            var justCaseTypeFilter = new SearchCriteria
            {
                MatchType = "best-criteria-only",
                CaseType = data.CaseType.Code
            };
            AssertCriteriaReturnsCount(justCaseTypeFilter, 0, "Should Return 0 records when just case type checked");

            var justJurisdictionFilter = new SearchCriteria
            {
                MatchType = "best-criteria-only",
                Jurisdiction = data.Jurisdiction.Id
            };
            AssertCriteriaReturnsCount(justJurisdictionFilter, 0, "Should Return 0 records when just jurisdiction checked");

            var justPropertyTypeFilter = new SearchCriteria
            {
                MatchType = "best-criteria-only",
                PropertyType = data.PropertyType.Code
            };
            AssertCriteriaReturnsCount(justPropertyTypeFilter, 0, "Should Return 0 records when just property Type checked");

            var justCaseCategoryFilter = new SearchCriteria
            {
                MatchType = "best-criteria-only",
                CaseCategory = data.CaseCategory.CaseCategoryId
            };
            AssertCriteriaReturnsCount(justCaseCategoryFilter, 0, "Should Return 0 records when just case category checked");

            var justSubtypeFilter = new SearchCriteria
            {
                MatchType = "best-criteria-only",
                CaseProgram = data.Program.Id
            };
            AssertCriteriaReturnsCount(justSubtypeFilter, 0, "Should Return 0 records when just subtype checked");
        }

        void AssertCriteriaReturnsCount(SearchCriteria searchCriteria, int expectedCount, string assertMessage)
        {
            var queryParam = new CommonQueryParameters { Skip = 0, Take = 1000 };

            var queryString = $"configuration/rules/screen-designer/case/search?criteria={JsonConvert.SerializeObject(searchCriteria)}&params={JsonConvert.SerializeObject(queryParam)}";
            var result = ApiClient.Get<dynamic>(queryString, _user.Username, _user.Id)
                                  .data
                                  .ToObject<List<dynamic>>();

            Assert.AreEqual(expectedCount, result.Count, assertMessage);
        }
    }
}