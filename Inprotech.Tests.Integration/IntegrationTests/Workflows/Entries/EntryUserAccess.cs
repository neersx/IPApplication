using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.Entries
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class EntryUserAccess : IntegrationTest
    {
        [Test]
        public void ShouldAddAndDeleteAndPropagateChangesToDescendants()
        {
            var data = CriteriaTreeBuilder.Build();

            var arg = DbSetup.Do(x =>
            {
                var role1 = x.InsertWithNewId(new Role
                {
                    RoleName = Fixture.Prefix("role1")
                });
                var role2 = x.InsertWithNewId(new Role
                {
                    RoleName = Fixture.Prefix("role2")
                });

                return new
                {
                    RoleId1 = role1.Id,
                    RoleId2 = role2.Id
                };
            });

            var entryToUpdate = data.Parent.FirstEntry();

            // add
            ApiClient.Put($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{entryToUpdate.Id}",
                          JsonConvert.SerializeObject(new WorkflowEntryControlSaveModel
                          {
                              CriteriaId = data.Parent.Id,
                              Id = entryToUpdate.Id,
                              Description = entryToUpdate.Description,
                              ApplyToDescendants = true,
                              UserAccessDelta = new Delta<int>
                              {
                                  Added = new[]
                                  {
                                      arg.RoleId1,
                                      arg.RoleId2
                                  }
                              }
                          }));

            using (var ctx = new SqlDbContext())
            {
                var result = ctx.Set<DataEntryTask>()
                                .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                .ToDictionary(k => k.CriteriaId, v => v);

                var parent = result[data.Parent.Id];
                var child1 = result[data.Child1.Id];
                var child2 = result[data.Child2.Id];
                var grandChild21 = result[data.GrandChild21.Id];
                var grandChild22 = result[data.GrandChild22.Id];
                var greatGrandChild211 = result[data.GreatGrandChild211.Id];
                var rolesCount = 2;

                Assert.AreEqual(rolesCount, parent.RolesAllowed.Count, $"Should add the {rolesCount} roles to parent.");
                Assert.AreEqual(rolesCount, child1.RolesAllowed.Count, $"Should add the {rolesCount} roles to child.");
                Assert.AreEqual(rolesCount, child2.RolesAllowed.Count, $"Should add the {rolesCount} roles to child.");
                Assert.AreEqual(rolesCount, grandChild21.RolesAllowed.Count, $"Should add the {rolesCount} roles to grandchild.");
                Assert.AreEqual(rolesCount, grandChild22.RolesAllowed.Count, $"Should add the {rolesCount} roles to grandchild.");
                Assert.AreEqual(rolesCount, greatGrandChild211.RolesAllowed.Count, $"Should add the {rolesCount} roles to greatgrandchild.");

                Assert.Contains(arg.RoleId1, parent.RolesAllowed.Select(r => r.RoleId).ToArray());
                Assert.Contains(arg.RoleId2, parent.RolesAllowed.Select(r => r.RoleId).ToArray());
                Assert.False(parent.RolesAllowed.All(r => r.Inherited.GetValueOrDefault()));

                Assert.Contains(arg.RoleId1, greatGrandChild211.RolesAllowed.Select(r => r.RoleId).ToArray());
                Assert.Contains(arg.RoleId2, greatGrandChild211.RolesAllowed.Select(r => r.RoleId).ToArray());
                Assert.True(greatGrandChild211.RolesAllowed.All(r => r.Inherited.GetValueOrDefault()));
            }

            // delete with propogation
            ApiClient.Put($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{entryToUpdate.Id}",
                          JsonConvert.SerializeObject(new WorkflowEntryControlSaveModel
                          {
                              CriteriaId = data.Parent.Id,
                              Id = entryToUpdate.Id,
                              Description = entryToUpdate.Description,
                              ApplyToDescendants = true,
                              UserAccessDelta = new Delta<int>
                              {
                                  Deleted = new[]
                                  {
                                      arg.RoleId1
                                  }
                              }
                          }));

            using (var ctx = new SqlDbContext())
            {
                var result = ctx.Set<DataEntryTask>()
                                .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                .ToDictionary(k => k.CriteriaId, v => v);

                var parent = result[data.Parent.Id];
                var child1 = result[data.Child1.Id];
                var child2 = result[data.Child2.Id];
                var grandChild21 = result[data.GrandChild21.Id];
                var grandChild22 = result[data.GrandChild22.Id];
                var greatGrandChild211 = result[data.GreatGrandChild211.Id];
                const int rolesCount = 1;

                Assert.AreEqual(rolesCount, parent.RolesAllowed.Count, "Should have deleted the role in the parent.");
                Assert.AreEqual(rolesCount, child1.RolesAllowed.Count, "Should have deleted the role to child.");
                Assert.AreEqual(rolesCount, child2.RolesAllowed.Count, "Should have deleted the role to child.");
                Assert.AreEqual(rolesCount, grandChild21.RolesAllowed.Count, "Should have deleted the role to grandchild.");
                Assert.AreEqual(rolesCount, grandChild22.RolesAllowed.Count, "Should have deleted the role to grandchild.");
                Assert.AreEqual(rolesCount, greatGrandChild211.RolesAllowed.Count, "Should have deleted the role to greatgrandchild.");

                Assert.AreEqual(arg.RoleId2, parent.RolesAllowed.Single().RoleId);
                Assert.AreEqual(arg.RoleId2, greatGrandChild211.RolesAllowed.Single().RoleId);
            }
            
            // delete without propogation
            ApiClient.Put($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{entryToUpdate.Id}",
                          JsonConvert.SerializeObject(new WorkflowEntryControlSaveModel
                          {
                              CriteriaId = data.Parent.Id,
                              Id = entryToUpdate.Id,
                              Description = entryToUpdate.Description,
                              ApplyToDescendants = false,
                              UserAccessDelta = new Delta<int>
                              {
                                  Deleted = new[]
                                  {
                                      arg.RoleId2
                                  }
                              }
                          }));

            using (var ctx = new SqlDbContext())
            {
                var result = ctx.Set<DataEntryTask>()
                                .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                .ToDictionary(k => k.CriteriaId, v => v);

                var parent = result[data.Parent.Id];
                var child1 = result[data.Child1.Id];
                var grandChild21 = result[data.GrandChild21.Id];
                var greatGrandChild211 = result[data.GreatGrandChild211.Id];

                Assert.AreEqual(0, parent.RolesAllowed.Count, "Should have deleted the role in the parent.");

                Assert.False(child1.RolesAllowed.Single().Inherited);
                Assert.True(grandChild21.RolesAllowed.Single().Inherited);
                Assert.True(greatGrandChild211.RolesAllowed.Single().Inherited);
            }
        }
    }
}