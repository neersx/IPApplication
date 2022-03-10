using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class WorkflowCriteria : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            DatabaseRestore.CreateNegativeWorkflowSecurityTask();
        }

        [Test]
        public void CreateNegativeCriteria()
        {
            var data = DbSetup.Do(setup =>
            {
                var criteriaMaxim = setup.DbContext.Set<LastInternalCode>().FirstOrDefault(_ => _.TableName == KnownInternalCodeTable.CriteriaMaxim)?.InternalSequence;
                return new
                {
                    nextCriteriaId = criteriaMaxim - 1
                };
            });

            var user = new Users()
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .WithPermission(ApplicationTask.CreateNegativeWorkflowRules)
                       .WithPermission(ApplicationTask.MaintainWorkflowRules)
                       .WithPermission(ApplicationTask.MaintainWorkflowRulesProtected)
                       .Create();

            var request = new WorkflowSaveModel
            {
                Action = "AL",
                CriteriaName = Fixture.Prefix("NegativeIdCriteria"),
                IsProtected = true
            };

            var result = ApiClient.Post<dynamic>("configuration/rules/workflows", JsonConvert.SerializeObject(request), user.Username, user.Id);

            Assert.NotNull(result);
            Assert.IsTrue((bool) result.status);
            Assert.AreEqual(data.nextCriteriaId, (int) result.criteriaId);
        }
    }
}