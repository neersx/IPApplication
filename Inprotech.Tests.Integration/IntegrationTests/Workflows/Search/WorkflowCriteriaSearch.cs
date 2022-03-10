using System.Linq;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.Search
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class WorkflowCriteriaSearch : IntegrationTest
    {
        [Test]
        public void UserDefinedComesFirst()
        {
            // this test makes sure that out of two identical criteria
            // best fit is given to user-defined one

            using (var dbContext = new SqlDbContext())
            {
                // select known rule that is not user-defined

                var criteria = dbContext.Set<Criteria>()
                                        .Single(x => x.Id == -2000014 &&
                                                     (x.UserDefinedRule == null || x.UserDefinedRule == 0));

                var response1 = ApiClient.Get<JObject>("configuration/rules/workflows/search?criteria={" +
                                       "caseType:'" + criteria.CaseTypeId + "'" +
                                       ",jurisdiction:'" + criteria.CountryId + "'" +
                                       ",propertyType:'" + criteria.PropertyType + "'" +
                                       ",action:'" + criteria.ActionId + "'" +
                                       ",dateOfLaw:'1/01/1996 12:00:00 AM'" +
                                       ",caseCategory:null" +
                                       ",subType:'" + criteria.SubTypeId + "'" +
                                       ",basis:'" + criteria.BasisId + "'" +
                                       ",office:null" +
                                       ",applyTo:'local-clients'" +
                                       ",matchType:'best-criteria-only'" +
                                       ",includeProtectedCriteria:true" +
                                       "}&params={skip:0,take:20}");

                Assert.AreEqual(criteria.Id, response1["data"][0]["id"].Value<int>(), "the right criteria should be returned");

                #region insert a user-defined copy

                var copy = new Criteria
                               {
                                   Id = dbContext.Set<Criteria>().Max(x => x.Id) + 1,
                                   PurposeCode = criteria.PurposeCode,
                                   ChecklistType = criteria.ChecklistType,
                                   ParentCriteriaId = criteria.ParentCriteriaId,
                                   CaseTypeId = criteria.CaseTypeId,
                                   Description = criteria.Description,
                                   DescriptionTId = criteria.DescriptionTId,
                                   CaseCategoryId = criteria.CaseCategoryId,
                                   IsPublic = criteria.IsPublic,
                                   DateOfLaw = criteria.DateOfLaw,
                                   LocalClientFlag = criteria.LocalClientFlag,
                                   RuleInUse = criteria.RuleInUse,
                                   UserDefinedRule = 1, // unlike the original, this rule is user-defined
                                   CountryId = criteria.CountryId,
                                   PropertyTypeId = criteria.PropertyTypeId,
                                   SubTypeId = criteria.SubTypeId,
                                   BasisId = criteria.BasisId,
                                   ActionId = criteria.ActionId,
                                   OfficeId = criteria.OfficeId,
                               };

                dbContext.Set<Criteria>().Add(copy);
                dbContext.SaveChanges();

                #endregion

                #region execute the same search again

                var response2 = ApiClient.Get<JObject>("configuration/rules/workflows/search?criteria={" +
                                       "caseType:'" + criteria.CaseTypeId + "'" +
                                       ",jurisdiction:'" + criteria.CountryId + "'" +
                                       ",propertyType:'" + criteria.PropertyType + "'" +
                                       ",action:'" + criteria.ActionId + "'" +
                                       ",dateOfLaw:'1/01/1996 12:00:00 AM'" +
                                       ",caseCategory:null" +
                                       ",subType:'" + criteria.SubTypeId + "'" +
                                       ",basis:'" + criteria.BasisId + "'" +
                                       ",office:null" +
                                       ",applyTo:'local-clients'" +
                                       ",matchType:'best-criteria-only'" +
                                       ",includeProtectedCriteria:true" +
                                       "}&params={skip:0,take:20}");

                #endregion

                Assert.AreEqual(copy.Id, response2["data"][0]["id"].Value<int>(), "user-defined copy should be better match than the original");
            }
        }
    }
}
