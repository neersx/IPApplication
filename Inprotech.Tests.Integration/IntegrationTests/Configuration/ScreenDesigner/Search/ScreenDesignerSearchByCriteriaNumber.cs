using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Configuration.ScreenDesigner.Search
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class ScreenDesignerSearchByCriteriaNumber : IntegrationTest
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
                var criteria1 = db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("should-return"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });

                var criteria2 = db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("should-return"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });

                var criteria3 = db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("should-not-return"),
                    PurposeCode = CriteriaPurposeCodes.CaseLinks,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });

                return new
                {
                    CriteriaIDs = new[] { criteria1.Id, criteria2.Id, criteria3.Id }
                };
            });

            AssertCriteriaReturnsCount(data.CriteriaIDs, 2, "Should return not protected records only.");
        }

        [Test]
        public void ShouldReturnRecordsWithIdsInList()
        {
            var data = DbSetup.Do(db =>
            {
                var program = db.InsertWithNewId(new InprotechKaizen.Model.Security.Program { Name = Fixture.AlphaNumericString(10), ProgramGroup = "C" }, x => x.Id, useAlphaNumeric: true);
                var criteria1 = db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("should-return"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });

                var criteria2 = db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("should-return"),
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });
                
                var criteria3 = db.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("should-return"),
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
                    PurposeCode = CriteriaPurposeCodes.WindowControl,
                    ProgramId = program.Id,
                    RuleInUse = 1,
                    IsProtected = false
                });
                return new
                {
                    CriteriaIDs = new[] { criteria1.Id, criteria2.Id, criteria3.Id }
                };
            });

            AssertCriteriaReturnsCount(data.CriteriaIDs, 3, "Should return not protected records only.");
        }

        void AssertCriteriaReturnsCount(int[] ids, int expectedCount, string assertMessage)
        {
            var queryParam = new CommonQueryParameters { Skip = 0, Take = 1000 };

            var queryString = $"configuration/rules/screen-designer/case/searchByIds?q={JsonConvert.SerializeObject(ids)}&params={JsonConvert.SerializeObject(queryParam)}";
            var result = ApiClient.Get<dynamic>(queryString, _user.Username, _user.Id)
                                  .data
                                  .ToObject<List<dynamic>>();

            Assert.AreEqual(expectedCount, result.Count, assertMessage);
        }
    }
}