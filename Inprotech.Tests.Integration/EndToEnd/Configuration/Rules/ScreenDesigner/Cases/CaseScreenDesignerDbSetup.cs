using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.ScreenDesigner.Cases
{
    public class CaseScreenDesignerDbSetup : DbSetup
    {
        internal const string Irn = "e2eScreenDesignerCase";
        internal const string ValidPropertyTypeDescription = "e2e - valid property type";
        internal const string ValidCaseCategoryDescription = "e2e - valid case category";
        internal const string ValidSubTypeDescription = "e2e - valid sub type";
        internal const string ValidBasisDescription = "e2e - valid basis";

        public ClassScreenDesignerData SetUp()
        {

            var office = InsertWithNewId(new Office { Name = "e2e-" + Fixture.AlphaNumericString(10) });
            var officeNavigation = InsertWithNewId(new Office { Name = "e2e-" + Fixture.AlphaNumericString(10) });
            var program = InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = "e2e-case-" + Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
            var profile = InsertWithNewId(new Profile { Name = "e2e-case-" + Fixture.AlphaNumericString(10) });
            var profileNavigation = InsertWithNewId(new Profile { Name = "e2e-case-" + Fixture.AlphaNumericString(10) });
            var caseType = InsertWithNewId(new CaseType { Name = "e2e-caseType" }, x => x.Code, useAlphaNumeric: true);
            var caseTypeNavigation = InsertWithNewId(new CaseType { Name = "e2e-caseType" }, x => x.Code, useAlphaNumeric: true);
            var propertyType = InsertWithNewId(new PropertyType { Name = "e2e-propertyType" }, x => x.Code, useAlphaNumeric: true);
            var propertyTypeNavigation = InsertWithNewId(new PropertyType { Name = "e2e-propertyType" }, x => x.Code, useAlphaNumeric: true);
            var jurisdiction = InsertWithNewId(new Country { Name = "e2e-country", Type = "1" }, x => x.Id, useAlphaNumeric: true);
            var jurisdictionNavigation = InsertWithNewId(new Country { Name = "e2e-country", Type = "1" }, x => x.Id, useAlphaNumeric: true);
            var caseCategory = InsertWithNewId(new CaseCategory { Name = "e2e-caseCategory", CaseType = caseType }, x => x.CaseCategoryId, useAlphaNumeric: true, maxLength: 2);
            var caseCategoryNavigation = InsertWithNewId(new CaseCategory { Name = "e2e-caseCategory", CaseType = caseType }, x => x.CaseCategoryId, useAlphaNumeric: true, maxLength: 2);
            var subType = InsertWithNewId(new SubType { Name = "e2e-subType" }, x => x.Code, useAlphaNumeric: true);
            var subTypeNavigation = InsertWithNewId(new SubType { Name = "e2e-subType" }, x => x.Code, useAlphaNumeric: true);
            var basis = InsertWithNewId(new ApplicationBasis { Name = "e2e-basis" }, x => x.Code, useAlphaNumeric: true);
            var basisNavigation = InsertWithNewId(new ApplicationBasis { Name = "e2e-basis" }, x => x.Code, useAlphaNumeric: true);

            var criteria = new[]
            {
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("With-office"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    Office = office,
                    RuleInUse = 1
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("With-office-and-program"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    Office = office,
                    RuleInUse = 1,
                    IsProtected = true,
                    CountryId = jurisdiction.Id
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-office"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    Office = office
                })
            };
            var newCaseId = DbContext.Set<Case>().Max(_ => _.Id) + 1;
            var @case = new Case(newCaseId, Irn, jurisdiction, caseType, propertyType)
            {
                Office = office,
                SubType = subType,
                CategoryId = caseCategory.CaseCategoryId,
                Title = Fixture.String(10),
                LocalClientFlag = 1
            };

            if (!DbContext.Set<ValidProperty>().Any(_ => _.PropertyName == ValidPropertyTypeDescription))
            {
                DbContext.Set<ValidProperty>().Add(new ValidProperty
                {
                    CountryId = jurisdiction.Id,
                    PropertyTypeId = propertyType.Code,
                    PropertyName = ValidPropertyTypeDescription
                });
            }

            if (!DbContext.Set<ValidCategory>().Any(_ => _.CaseCategoryDesc == ValidCaseCategoryDescription))
            {
                DbContext.Set<ValidCategory>().Add(new ValidCategory
                {
                    CountryId = jurisdiction.Id,
                    PropertyTypeId = propertyType.Code,
                    CaseTypeId = caseType.Code,
                    CaseCategoryId = caseCategory.CaseCategoryId,
                    CaseCategoryDesc = ValidCaseCategoryDescription
                });
            }

            if (!DbContext.Set<ValidSubType>().Any(_ => _.SubTypeDescription == ValidSubTypeDescription))
            {
                DbContext.Set<ValidSubType>().Add(new ValidSubType
                {
                    CountryId = jurisdiction.Id,
                    PropertyTypeId = propertyType.Code,
                    CaseTypeId = caseType.Code,
                    CaseCategoryId = caseCategory.CaseCategoryId,
                    SubtypeId = subType.Code,
                    SubTypeDescription = ValidSubTypeDescription
                });
            }

            if (!DbContext.Set<ValidBasis>().Any(_ => _.BasisDescription == ValidBasisDescription))
            {
                DbContext.Set<ValidBasis>().Add(new ValidBasis(jurisdiction, propertyType, basis)
                {
                    BasisDescription = ValidBasisDescription
                });
            }
            DbContext.SaveChanges();

            if (!DbContext.Set<ValidBasisEx>().Any(_ => _.BasisId == basis.Code))
            {
                DbContext.Set<ValidBasisEx>().Add(new ValidBasisEx(caseType, caseCategory)
                {
                    CountryId = jurisdiction.Id,
                    PropertyTypeId = propertyType.Code,
                    BasisId = basis.Code
                });
                DbContext.SaveChanges();
            }
            DbContext.Set<Case>().Add(@case);

            var newNameId = DbContext.Set<Name>().Max(_ => _.Id) + 1;
            var name = new Name(newNameId) { NameCode = Fixture.String(2), LastName = Fixture.String(10) };
            var nameType = DbContext.Set<InprotechKaizen.Model.Cases.NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Instructor);
            var caseName = new CaseName(@case, nameType, name, 0);
            DbContext.Set<CaseName>().Add(caseName);
            var statusId = DbContext.Set<Status>().Max(_ => _.Id) + 1;
            var status = new Status((short)statusId, Fixture.String(10));

            var caseProperty = new CaseProperty(@case, basis, status);

            DbContext.Set<Status>().Add(status);
            DbContext.Set<CaseProperty>().Add(caseProperty);
            var programNavigation = InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = "e2e-case-" + Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
            var criteriaNavigation = new[]
            {
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-office"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id,
                    Office = officeNavigation
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-profile"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-Case-Type"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id,
                    CaseType = caseTypeNavigation
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-jurisdiction"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id,
                    Country = jurisdictionNavigation
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-property-type"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id,
                    PropertyType = propertyTypeNavigation
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-case-category"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id,
                    CaseCategory = caseCategoryNavigation
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-subtype"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id,
                    SubType = subTypeNavigation
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-basis"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id,
                    Basis = basisNavigation
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-office"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-office"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-office"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-office"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id
                }),
                InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("Unused-With-office"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = programNavigation.Id
                })
            };
            Insert(new Inherits(criteriaNavigation[1].Id, criteriaNavigation[0].Id));
            Insert(new Inherits(criteriaNavigation[2].Id, criteriaNavigation[1].Id));
            Insert(new Inherits(criteriaNavigation[3].Id, criteriaNavigation[2].Id));
            Insert(new Inherits(criteriaNavigation[4].Id, criteriaNavigation[0].Id));
            DbContext.SaveChanges();

            new ScreenCriteriaBuilder(DbContext).Create(@case, out var criteria1Id, KnownCasePrograms.CaseEnquiry)
                                                .WithTopicControl(KnownCaseScreenTopics.Actions)
                                                .WithTopicControl(KnownCaseScreenTopics.Classes)
                                                .WithTopicControl(KnownCaseScreenTopics.Names);
            new ScreenCriteriaBuilder(DbContext).Create(@case, out var criteria2Id, KnownCasePrograms.CaseEnquiry)
                                                .WithTopicControl(KnownCaseScreenTopics.CriticalDates)
                                                .WithTopicControl(KnownCaseScreenTopics.Actions)
                                                .WithTopicControl(KnownCaseScreenTopics.CaseTexts)
                                                .WithTopicControl(KnownCaseScreenTopics.CaseRenewals);
            return new ClassScreenDesignerData
            {
                Office = office,
                Program = program,
                ProgramNavigation = programNavigation,
                CaseType = caseType,
                Jurisdiction = jurisdiction,
                PropertyType = propertyType,
                CaseCategory = caseCategory,
                SubType = subType,
                Profile = profile,
                Basis = basis,
                Criteria = criteria,
                CriteriaNavigation = criteriaNavigation,
                Case = @case,
                CriteriaSectionsScenario1 = criteria1Id,
                CriteriaSectionsScenario2 = criteria2Id
            };
        }

        public class ClassScreenDesignerData
        {
            public Office Office { get; set; }
            public InprotechKaizen.Model.Security.Program Program { get; set; }
            public InprotechKaizen.Model.Security.Program ProgramNavigation { get; set; }
            public CaseType CaseType { get; set; }
            public Country Jurisdiction { get; set; }
            public PropertyType PropertyType { get; set; }
            public CaseCategory CaseCategory { get; set; }
            public SubType SubType { get; set; }
            public ApplicationBasis Basis { get; set; }
            public Profile Profile { get; set; }
            public Criteria[] Criteria { get; set; }
            public Criteria[] CriteriaNavigation { get; set; }
            public Case Case { get; set; }
            public int CriteriaSectionsScenario1 { get; set; }
            public int CriteriaSectionsScenario2 { get; set; }
        }
    }
}