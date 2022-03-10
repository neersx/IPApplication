using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
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
    public class ScreenDesignerSearchExactMatch : IntegrationTest
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
                    NotProtectedRecordCount = db.DbContext.Set<Criteria>().Count(x => x.PurposeCode == CriteriaPurposeCodes.WindowControl && x.UserDefinedRule != 0)
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "exact-match"
            };

            AssertCriteriaReturnsCount(searchCriteria, data.NotProtectedRecordCount, "Should return not protected records only.");
        }

        [Test]
        public void ShouldReturnAllNonProtectedCriteriaIfNoFilter()
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
                    IsProtected = false
                });

                return new
                {
                    NotProtectedRecordCount = db.DbContext.Set<Criteria>().Count(x => x.PurposeCode == CriteriaPurposeCodes.WindowControl && x.UserDefinedRule != 0)
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "exact-match"
            };

            AssertCriteriaReturnsCount(searchCriteria, data.NotProtectedRecordCount, "Should return non protected records if filter default");
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
                    Office = office,
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
                MatchType = "exact-match",
                Office = data.Office.Id,
                CaseProgram = data.Program.Id
            };

            AssertCriteriaReturnsCount(searchCriteria, 1, "Returns only records with correct purpose code");
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
                MatchType = "exact-match",
                Office = data.Office.Id,
                CaseProgram = data.Program.Id
            };

            var queryParam = new CommonQueryParameters { Skip = 0, Take = 20 };

            var queryString = $"configuration/rules/screen-designer/case/search?criteria={JsonConvert.SerializeObject(searchCriteria)}&params={JsonConvert.SerializeObject(queryParam)}";
            var result = ApiClient.Get<dynamic>(queryString, _user.Username, _user.Id)
                                  .data
                                  .ToObject<List<dynamic>>();

            Assert.AreEqual(1, result.Count);
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
                MatchType = "exact-match",
                SubType = data.Subtype.Code,
                CaseCategory = data.CaseCategory.CaseCategoryId,
                CaseProgram = data.Program.Id,
                Office = data.Office.Id,
                CaseType = data.CaseType.Code,
                Jurisdiction = data.Jurisdiction.Id,
                PropertyType = data.PropertyType.Code
            };

            AssertCriteriaReturnsCount(allCriteriaChecked, 2, "Should return 2 records when all criteria checked");

            var justOfficeFilter = new SearchCriteria
            {
                MatchType = "exact-match",
                Office = data.Office.Id,
            };
            AssertCriteriaReturnsCount(justOfficeFilter, 2, "Should Return 2 records when just office checked");

            var justProgramFilter = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseProgram = data.Program.Id
            };
            AssertCriteriaReturnsCount(justProgramFilter, 2, "Should Return 2 records when just program checked");

            var justCaseTypeFilter = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseType = data.CaseType.Code
            };
            AssertCriteriaReturnsCount(justCaseTypeFilter, 2, "Should Return 2 records when just case type checked");

            var justJurisdictionFilter = new SearchCriteria
            {
                MatchType = "exact-match",
                Jurisdiction = data.Jurisdiction.Id
            };
            AssertCriteriaReturnsCount(justJurisdictionFilter, 2, "Should Return 2 records when just jurisdiction checked");

            var justPropertyTypeFilter = new SearchCriteria
            {
                MatchType = "exact-match",
                PropertyType = data.PropertyType.Code
            };
            AssertCriteriaReturnsCount(justPropertyTypeFilter, 2, "Should Return 2 records when just property Type checked");

            var justCaseCategoryFilter = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseCategory = data.CaseCategory.CaseCategoryId
            };
            AssertCriteriaReturnsCount(justCaseCategoryFilter, 2, "Should Return 2 records when just case category checked");

            var justSubtypeFilter = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseProgram = data.Program.Id
            };
            AssertCriteriaReturnsCount(justSubtypeFilter, 2, "Should Return 2 records when just subtype checked");
        }

        [Test]
        public void ShouldReturnDataWithPageProgramFilterApplied()
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
                MatchType = "exact-match",
                SubType = data.Subtype.Code,
                CaseCategory = data.CaseCategory.CaseCategoryId,
                Office = data.Office.Id,
                CaseType = data.CaseType.Code,
                Jurisdiction = data.Jurisdiction.Id,
                PropertyType = data.PropertyType.Code
            };

            AssertCriteriaReturnsCount(allCriteriaChecked, 2, "Should return 2 records when all criteria checked", new[]
            {
                new CommonQueryParameters.FilterValue
                {
                    Field = "program",
                    Operator = CollectionExtensions.FilterOperator.Eq.ToString(),
                    Value = data.Program.Id
                }
            });
        }

        [Test]
        public void ShouldReturnDataWithPageJurisdictionFilterApplied()
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
                MatchType = "exact-match",
                SubType = data.Subtype.Code,
                CaseCategory = data.CaseCategory.CaseCategoryId,
                Office = data.Office.Id,
                CaseType = data.CaseType.Code,
                PropertyType = data.PropertyType.Code
            };

            AssertCriteriaReturnsCount(allCriteriaChecked, 2, "Should return 2 records when all criteria checked", new[]
            {
                new CommonQueryParameters.FilterValue
                {
                    Field = "jurisdiction",
                    Operator = CollectionExtensions.FilterOperator.Eq.ToString(),
                    Value = data.Jurisdiction.Id
                }
            });
        }

        [Test]
        public void ShouldReturnDataWithPageJurisdictionAndProgramFiltersApplied()
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
                MatchType = "exact-match",
                SubType = data.Subtype.Code,
                CaseCategory = data.CaseCategory.CaseCategoryId,
                Office = data.Office.Id,
                CaseType = data.CaseType.Code,
                PropertyType = data.PropertyType.Code
            };

            AssertCriteriaReturnsCount(allCriteriaChecked, 2, "Should return 2 records when all criteria checked", new[]
            {
                new CommonQueryParameters.FilterValue
                {
                    Field = "jurisdiction",
                    Operator = CollectionExtensions.FilterOperator.Eq.ToString(),
                    Value = data.Jurisdiction.Id
                },
                new CommonQueryParameters.FilterValue
                {
                    Field = "program",
                    Operator = CollectionExtensions.FilterOperator.Eq.ToString(),
                    Value = data.Program.Id
                }
            });
        }

        [Test]
        public void OrderByCriteriaNoReturnsRecordsInTheExpectedOrder()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var criterias = new[]
                {
                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("With-office-and-program"),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                    Description = Fixture.Prefix("with-office-and-program"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("with-office-and-program"),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    })
                };

                return new
                {
                    Program = program,
                    Criteria = criterias
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseProgram = data.Program.Id
            };

            var sortByCriteriaNumberAsc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "id", sortDirection: "asc");
            Assert.AreEqual(sortByCriteriaNumberAsc[0].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[2].id.Value, data.Criteria[2].Id);

            var sortByCriteriaNumberDesc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "id", sortDirection: "desc");
            Assert.AreEqual(sortByCriteriaNumberDesc[2].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[0].id.Value, data.Criteria[2].Id);
        }
        
        [Test]
        public void OrderByCriteriaNameReturnsRecordsInTheExpectedOrder()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var criterias = new[]
                {
                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("ABC"),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                    Description = Fixture.Prefix("CDE"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("EFG"),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    })
                };

                return new
                {
                    Program = program,
                    Criteria = criterias
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseProgram = data.Program.Id
            };

            var sortByCriteriaNumberAsc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "criteriaName", sortDirection: "asc");
            Assert.AreEqual(sortByCriteriaNumberAsc[0].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[2].id.Value, data.Criteria[2].Id);

            var sortByCriteriaNumberDesc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "criteriaName", sortDirection: "desc");
            Assert.AreEqual(sortByCriteriaNumberDesc[2].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[0].id.Value, data.Criteria[2].Id);
        }

        [Test]
        public void OrderByCriteriaNameReturnsRecordsInTheExpectedOrderAlternativeOrder()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var criterias = new[]
                {
                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("EFG"),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                    Description = Fixture.Prefix("CDE"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("ABC"),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    })
                };

                return new
                {
                    Program = program,
                    Criteria = criterias
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseProgram = data.Program.Id
            };

            var sortByCriteriaNumberAsc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "criteriaName", sortDirection: "asc");
            Assert.AreEqual(sortByCriteriaNumberAsc[2].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[0].id.Value, data.Criteria[2].Id);

            var sortByCriteriaNumberDesc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "criteriaName", sortDirection: "desc");
            Assert.AreEqual(sortByCriteriaNumberDesc[0].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[2].id.Value, data.Criteria[2].Id);
        }

        [Test]
        public void OrderByOfficeReturnsRecordsInTheExpectedOrder()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var programAlternativeOrder = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var criterias = new[]
                {
                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("ABC"),
                        Office = db.InsertWithNewId(new Office(Fixture.Integer(), Fixture.Prefix("1"))),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("CDE"),
                        Office = db.InsertWithNewId(new Office(Fixture.Integer(), Fixture.Prefix("2"))),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("EFG"),
                        Office = db.InsertWithNewId(new Office(Fixture.Integer(), Fixture.Prefix("3"))),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    })
                };

                return new
                {
                    Program = program,
                    Criteria = criterias,
                    ProgramAlternativeOrder = programAlternativeOrder
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseProgram = data.Program.Id
            };

            var sortByCriteriaNumberAsc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "office", sortDirection: "asc");
            Assert.AreEqual(sortByCriteriaNumberAsc[0].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[2].id.Value, data.Criteria[2].Id);

            var sortByCriteriaNumberDesc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "office", sortDirection: "desc");
            Assert.AreEqual(sortByCriteriaNumberDesc[2].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[0].id.Value, data.Criteria[2].Id);
        }

        [Test]
        public void OrderByOfficeReturnsRecordsInTheExpectedOrderAlternativeOrder()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var programAlternativeOrder = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var criterias = new[]
                {
                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("ABC"),
                        Office = db.InsertWithNewId(new Office(Fixture.Integer(), Fixture.Prefix("3"))),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("CDE"),
                        Office = db.InsertWithNewId(new Office(Fixture.Integer(), Fixture.Prefix("2"))),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("EFG"),
                        Office = db.InsertWithNewId(new Office(Fixture.Integer(), Fixture.Prefix("1"))),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    })
                };

                return new
                {
                    Program = program,
                    Criteria = criterias,
                    ProgramAlternativeOrder = programAlternativeOrder
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseProgram = data.Program.Id
            };

            var sortByCriteriaNumberAsc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "office", sortDirection: "asc");
            Assert.AreEqual(sortByCriteriaNumberAsc[2].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[0].id.Value, data.Criteria[2].Id);

            var sortByCriteriaNumberDesc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "office", sortDirection: "desc");
            Assert.AreEqual(sortByCriteriaNumberDesc[0].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[2].id.Value, data.Criteria[2].Id);
        }

        [Test]
        public void OrderByJurisdictionReturnsRecordsInTheExpectedOrderAlternativeOrder()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var programAlternativeOrder = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var criterias = new[]
                {
                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("ABC"),
                        Country = db.InsertWithNewId(new Country(Fixture.String(2), Fixture.Prefix("3"), "1")),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("CDE"),
                        Country = db.InsertWithNewId(new Country(Fixture.String(2), Fixture.Prefix("2"), "1")),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("EFG"),
                        Country = db.InsertWithNewId(new Country(Fixture.String(2), Fixture.Prefix("1"), "1")),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    })
                };

                return new
                {
                    Program = program,
                    Criteria = criterias,
                    ProgramAlternativeOrder = programAlternativeOrder
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseProgram = data.Program.Id
            };

            var sortByCriteriaNumberAsc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "jurisdiction", sortDirection: "asc");
            Assert.AreEqual(sortByCriteriaNumberAsc[2].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[0].id.Value, data.Criteria[2].Id);

            var sortByCriteriaNumberDesc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "jurisdiction", sortDirection: "desc");
            Assert.AreEqual(sortByCriteriaNumberDesc[0].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[2].id.Value, data.Criteria[2].Id);
        }

        [Test]
        public void OrderByJurisdictionReturnsRecordsInTheExpectedOrder()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var programAlternativeOrder = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var criterias = new[]
                {
                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("ABC"),
                        Country = db.InsertWithNewId(new Country(Fixture.String(2), Fixture.Prefix("1"), "1")),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("CDE"),
                        Country = db.InsertWithNewId(new Country(Fixture.String(2), Fixture.Prefix("2"), "1")),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("EFG"),
                        Country = db.InsertWithNewId(new Country(Fixture.String(2), Fixture.Prefix("3"), "1")),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    })
                };

                return new
                {
                    Program = program,
                    Criteria = criterias,
                    ProgramAlternativeOrder = programAlternativeOrder
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseProgram = data.Program.Id
            };

            var sortByCriteriaNumberAsc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "jurisdiction", sortDirection: "asc");
            Assert.AreEqual(sortByCriteriaNumberAsc[0].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[2].id.Value, data.Criteria[2].Id);

            var sortByCriteriaNumberDesc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "jurisdiction", sortDirection: "desc");
            Assert.AreEqual(sortByCriteriaNumberDesc[2].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[0].id.Value, data.Criteria[2].Id);
        }
        
        [Test]
        public void OrderByCaseTypeReturnsRecordsInTheExpectedOrderAlternativeOrder()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var programAlternativeOrder = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var criterias = new[]
                {
                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("ABC"),
                        CaseType = db.InsertWithNewId(new CaseType {Name = "3"}, x => x.Code, useAlphaNumeric: true),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("CDE"),
                        CaseType = db.InsertWithNewId(new CaseType {Name = "2"}, x => x.Code, useAlphaNumeric: true),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("EFG"),
                        CaseType = db.InsertWithNewId(new CaseType {Name = "1"}, x => x.Code, useAlphaNumeric: true),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    })
                };

                return new
                {
                    Program = program,
                    Criteria = criterias,
                    ProgramAlternativeOrder = programAlternativeOrder
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseProgram = data.Program.Id
            };

            var sortByCriteriaNumberAsc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "caseType", sortDirection: "asc");
            Assert.AreEqual(sortByCriteriaNumberAsc[2].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[0].id.Value, data.Criteria[2].Id);

            var sortByCriteriaNumberDesc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "caseType", sortDirection: "desc");
            Assert.AreEqual(sortByCriteriaNumberDesc[0].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[2].id.Value, data.Criteria[2].Id);
        }

        [Test]
        public void OrderByCaseTypeReturnsRecordsInTheExpectedOrder()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var programAlternativeOrder = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var criterias = new[]
                {
                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("ABC"),
                        CaseType = db.InsertWithNewId(new CaseType {Name = "1"}, x => x.Code, useAlphaNumeric: true),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("CDE"),
                        CaseType = db.InsertWithNewId(new CaseType {Name = "2"}, x => x.Code, useAlphaNumeric: true),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    }),

                    db.InsertWithNewId(new Criteria
                    {
                        Description = Fixture.Prefix("EFG"),
                        CaseType = db.InsertWithNewId(new CaseType {Name = "3"}, x => x.Code, useAlphaNumeric: true),
                        PurposeCode = CriteriaPurposeCodes.WindowControl,
                        ProgramId = program.Id,
                        RuleInUse = 1,
                        IsProtected = false
                    })
                };

                return new
                {
                    Program = program,
                    Criteria = criterias,
                    ProgramAlternativeOrder = programAlternativeOrder
                };
            });

            var searchCriteria = new SearchCriteria
            {
                MatchType = "exact-match",
                CaseProgram = data.Program.Id
            };

            var sortByCriteriaNumberAsc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "caseType", sortDirection: "asc");
            Assert.AreEqual(sortByCriteriaNumberAsc[0].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberAsc[2].id.Value, data.Criteria[2].Id);

            var sortByCriteriaNumberDesc = AssertCriteriaReturnsCount(searchCriteria, 3, "Should return not protected records only.", sortBy: "caseType", sortDirection: "desc");
            Assert.AreEqual(sortByCriteriaNumberDesc[2].id.Value, data.Criteria[0].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[1].id.Value, data.Criteria[1].Id);
            Assert.AreEqual(sortByCriteriaNumberDesc[0].id.Value, data.Criteria[2].Id);
        }

        dynamic AssertCriteriaReturnsCount(SearchCriteria searchCriteria, int expectedCount, string assertMessage, IEnumerable<CommonQueryParameters.FilterValue> columnFilters = null, string sortBy = null, string sortDirection = null)
        {
            var queryParam = new CommonQueryParameters { Skip = 0, Take = 1000, Filters = columnFilters, SortBy = sortBy, SortDir = sortDirection};

            var queryString = $"configuration/rules/screen-designer/case/search?criteria={JsonConvert.SerializeObject(searchCriteria)}&params={JsonConvert.SerializeObject(queryParam)}";
            var result = ApiClient.Get<dynamic>(queryString, _user.Username, _user.Id)
                                  .data
                                  .ToObject<List<dynamic>>();

            Assert.AreEqual(expectedCount, result.Count, assertMessage);

            return result;
        }
    }
}