using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NUnit.Framework;
using SearchCriteria = InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner.SearchCriteria;

namespace Inprotech.Tests.Integration.IntegrationTests.Configuration.Checklists.Search
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class ChecklistConfigurationSearch : IntegrationTest
    {
        TestUser _user;
        [SetUp]
        public void Setup()
        {
            _user = new Users()
                    .WithPermission(ApplicationTask.MaintainCpassRules, Deny.Create | Deny.Delete | Deny.Modify)
                    .WithPermission(ApplicationTask.MaintainRules, Deny.Create | Deny.Delete | Deny.Modify)
                    .WithPermission(ApplicationTask.MaintainQuestion)
                    .WithLicense(LicensedModule.IpMatterManagementModule)
                    .Create();
        }

        [Test]
        public void ShouldAllowUsersWithOnlyMaintainQuestionAccess()
        {
            var result = ApiClient.Get<JObject>("configuration/rules/checklist-configuration/view", _user.Username, _user.Id);
            Assert.False(bool.Parse(result["canMaintainProtectedRules"].ToString()));
            Assert.False(bool.Parse(result["canMaintainRules"].ToString()));

            var criteria = JsonConvert.SerializeObject(new WorkflowCharacteristics());
            result = ApiClient.Get<dynamic>($"configuration/rules/characteristics/validateCharacteristics?purposeCode=C&criteria={criteria}", _user.Username, _user.Id)
                              .ToObject<dynamic>();
            Assert.IsNotNull(result);
        }
    }

    [Category(Categories.Integration)]
    [TestFixture]
    public class ChecklistConfigurationSearchBase : IntegrationTest
    {
        internal TestUser User;
        internal dynamic Data;

        [SetUp]
        public void Setup()
        {
            User = new Users()
                    .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create)
                    .WithPermission(ApplicationTask.MaintainRules, Allow.Create)
                    .WithLicense(LicensedModule.IpMatterManagementModule)
                    .Create();

            Data = DbSetup.Do(db =>
            {
                var checklist = db.InsertWithNewId(new CheckList { Description = Fixture.AlphaNumericString(10) }, x => x.Id);
                var anotherChecklist= db.InsertWithNewId(new CheckList { Description = Fixture.AlphaNumericString(10) }, x => x.Id);
                var office = db.InsertWithNewId(new Office { Name = Fixture.UriSafeString(10) });
                var unusedOffice = db.InsertWithNewId(new Office { Name = Fixture.UriSafeString(10) });
                var caseType = db.InsertWithNewId(new CaseType(Fixture.UriSafeString(1), Fixture.UriSafeString(10)));
                var unusedCaseType = db.InsertWithNewId(new CaseType(Fixture.UriSafeString(1), Fixture.UriSafeString(10)));
                var jurisdiction = db.InsertWithNewId(new Country(Fixture.UriSafeString(2), Fixture.UriSafeString(10), Fixture.String(1)));
                var unusedJurisdiction = db.InsertWithNewId(new Country(Fixture.UriSafeString(2), Fixture.UriSafeString(10), Fixture.String(1)));
                var propertyType = db.InsertWithNewId(new PropertyType(Fixture.UriSafeString(2), Fixture.UriSafeString(10)));
                var unusedPropertyType = db.InsertWithNewId(new PropertyType(Fixture.UriSafeString(2), Fixture.UriSafeString(10)));
                var caseCategory = db.Insert(new CaseCategory(caseType.Code, "T", Fixture.UriSafeString(10)));
                var unusedCaseCategory = db.Insert(new CaseCategory(caseType.Code, "X", Fixture.UriSafeString(10)));
                var subType = db.InsertWithNewId(new SubType("T", Fixture.UriSafeString(10)));
                var unusedSubType = db.InsertWithNewId(new SubType("X", Fixture.UriSafeString(10)));
                var basis = db.InsertWithNewId(new ApplicationBasis("BS", Fixture.UriSafeString(10)));
                var unusedBasis = db.InsertWithNewId(new ApplicationBasis("BX", Fixture.UriSafeString(10)));

                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("not-protected"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("protected"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    RuleInUse = 1,
                    IsProtected = true
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("non-checklist"),
                    PurposeCode = CriteriaPurposeCodes.CaseLinks,
                    ChecklistType = checklist.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("not-in-use"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    RuleInUse = 0,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("best-criteria"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    RuleInUse = 1,
                    CaseTypeId = caseType.Code,
                    PropertyTypeId = propertyType.Code,
                    CaseCategoryId = caseCategory.CaseCategoryId,
                    SubTypeId = subType.Code,
                    BasisId = basis.Code,
                    LocalClientFlag = 1m,
                    CountryId = jurisdiction.Id,
                    OfficeId = office.Id,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("with-office"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    OfficeId = office.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("with-caseType"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    CaseTypeId = caseType.Code,
                    RuleInUse = 1,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("with-jurisdiction"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    CountryId = jurisdiction.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("with-property-type"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    PropertyTypeId = propertyType.Code,
                    RuleInUse = 1,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("with-case-category"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    CaseCategoryId = caseCategory.CaseCategoryId,
                    RuleInUse = 1,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("with-sub-type"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    SubTypeId = subType.Code,
                    RuleInUse = 1,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("with-basis"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    BasisId = basis.Code,
                    RuleInUse = 1,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("apply-to-local"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = checklist.Id,
                    LocalClientFlag = 1m,
                    RuleInUse = 1,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("alternative checklist"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = anotherChecklist.Id,
                    LocalClientFlag = 1m,
                    RuleInUse = 1,
                    IsProtected = false
                });
                db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("alternative checklist"),
                    PurposeCode = CriteriaPurposeCodes.CheckList,
                    ChecklistType = anotherChecklist.Id,
                    LocalClientFlag = 1m,
                    RuleInUse = 1,
                    IsProtected = false
                });
                return new
                {
                    Checklist = checklist,
                    AnotherChecklist = anotherChecklist,
                    Office = office.Id,
                    UnusedOffice = unusedOffice.Id,
                    CaseType = caseType.Code,
                    UnusedCaseType = unusedCaseType.Code,
                    Jurisdiction = jurisdiction.Id,
                    UnusedJurisdiction = unusedJurisdiction.Id,
                    PropertyType = propertyType.Code,
                    UnusedPropertyType = unusedPropertyType.Code,
                    CaseCategory = caseCategory.CaseCategoryId,
                    UnusedCaseCategory = unusedCaseCategory.CaseCategoryId,
                    SubType = subType.Code,
                    UnusedSubType = unusedSubType.Code,
                    Basis = basis.Code,
                    UnusedBasis = unusedBasis.Code
                };
            });
        }
    }

    public static class ChecklistSearchTestHelper
    {
        internal static void AssertCriteriaReturnsCount(TestUser user, SearchCriteria searchCriteria, int expectedCount, string assertMessage)
        {
            var queryParam = new CommonQueryParameters { Skip = 0, Take = 20 };

            var queryString = $"configuration/rules/checklist-configuration/search?criteria={JsonConvert.SerializeObject(searchCriteria)}&params={JsonConvert.SerializeObject(queryParam)}";
            var result = ApiClient.Get<dynamic>(queryString, user.Username, user.Id)
                                  .data
                                  .ToObject<List<dynamic>>();

            Assert.AreEqual(expectedCount, result.Count, assertMessage);
        }
    }
}
