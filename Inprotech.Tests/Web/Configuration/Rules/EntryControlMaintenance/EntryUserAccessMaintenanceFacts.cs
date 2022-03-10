using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance
{
    public class EntryUserAccessMaintenanceFacts
    {
        public class SetDeltaForUpdateMethod
        {
            public SetDeltaForUpdateMethod()
            {
                _entry = new DataEntryTask(2, 3)
                {
                    RolesAllowed = new List<RolesControl>
                    {
                        new RolesControl(ExistingRoleId, 2, 3) {Inherited = false},
                        new RolesControl(ExistingRoleId1, 2, 3) {Inherited = true}
                    }
                };

                _initial = new DataEntryTask(2, 3)
                {
                    RolesAllowed = new List<RolesControl>
                    {
                        new RolesControl(ExistingRoleId, 2, 3) {Inherited = false},
                        new RolesControl(ExistingRoleId1, 2, 3) {Inherited = true}
                    }
                };
            }

            const int ExistingRoleId = 1;
            const int ExistingRoleId1 = 2;

            readonly DataEntryTask _entry;
            readonly DataEntryTask _initial;

            [Fact]
            public void OnlyIncludesExistingInheritedRolesInDelete()
            {
                var deletes = new WorkflowEntryControlSaveModel
                {
                    UserAccessDelta = new Delta<int>
                    {
                        Deleted = new[] {1, 2, 3}
                    }
                };

                var f = new EntryUserAccessMaintenanceFixture();
                var fieldsToUpdate = new EntryControlFieldsToUpdate(_initial, deletes);
                f.Subject.SetDeltaForUpdate(_entry, deletes, fieldsToUpdate);

                // of the 3 requested, only deletes the one that exists and is inherited
                Assert.Equal(1, fieldsToUpdate.UserAccessDelta.Deleted.Count);
                Assert.Equal(2, fieldsToUpdate.UserAccessDelta.Deleted.Single());
            }

            [Fact]
            public void OnlyIncludesNewRolesInAddDelta()
            {
                var updates = new WorkflowEntryControlSaveModel
                {
                    UserAccessDelta = new Delta<int>
                    {
                        Added = new[] {1, 2, 99}
                    }
                };

                var f = new EntryUserAccessMaintenanceFixture();
                var fieldsToUpdate = new EntryControlFieldsToUpdate(_initial, updates);
                f.Subject.SetDeltaForUpdate(_entry, updates, fieldsToUpdate);

                // of the 3 requested, only adds the one that does not already exist
                Assert.Equal(1, fieldsToUpdate.UserAccessDelta.Added.Count);
                Assert.Equal(99, fieldsToUpdate.UserAccessDelta.Added.Single());
            }
        }

        public class ResetMethod
        {
            [Fact]
            public void AddsRolesFromParentAndDeletesRolesNotInParent()
            {
                var f = new EntryUserAccessMaintenanceFixture();
                var parent = new DataEntryTask(1, 1)
                {
                    RolesAllowed = new[]
                    {
                        new RolesControl(1, 1, 1), // add this one
                        new RolesControl(2, 1, 1) // ignore this common one
                    }
                };

                var child = new DataEntryTask(99, 88)
                {
                    RolesAllowed = new List<RolesControl>
                    {
                        new RolesControl(2, 99, 88),
                        new RolesControl(4, 99, 88) // delete this one
                    }
                };

                var saveModel = new WorkflowEntryControlSaveModel();
                f.Subject.Reset(child, parent, saveModel);

                // Reset should add 1 role in the parent that wasn't in the child
                Assert.Equal(1, saveModel.UserAccessDelta.Added.Count);
                Assert.Contains(saveModel.UserAccessDelta.Added, u => u == 1);

                // Reset should delete 2 role in child not matching in the parent
                Assert.Equal(1, saveModel.UserAccessDelta.Deleted.Count);
                Assert.Contains(saveModel.UserAccessDelta.Deleted, u => u == 4);
            }
        }

        public class RemoveInheritanceMethod
        {
            [Fact]
            public void RemovesInheritanceForItemsDeletedInTheParent()
            {
                var f = new EntryUserAccessMaintenanceFixture();

                var entry = new DataEntryTask(99, 88)
                {
                    RolesAllowed = new List<RolesControl>
                    {
                        new RolesControl(1, 99, 88) {Inherited = true},
                        new RolesControl(2, 99, 88) {Inherited = true},
                        new RolesControl(3, 99, 88) {Inherited = true}
                    }
                };

                var userAccessDelta = new Delta<int>
                {
                    Deleted = new[] {1, 3}
                };

                var fieldsToUpdate = new EntryControlFieldsToUpdate(new DataEntryTaskBuilder().Build(), new WorkflowEntryControlSaveModel {UserAccessDelta = userAccessDelta});

                f.Subject.RemoveInheritance(entry, fieldsToUpdate);

                Assert.False(entry.RolesAllowed.Single(r => r.RoleId == 1).Inherited.GetValueOrDefault());
                Assert.False(entry.RolesAllowed.Single(r => r.RoleId == 3).Inherited.GetValueOrDefault());
                Assert.True(entry.RolesAllowed.Single(r => r.RoleId == 2).Inherited.GetValueOrDefault());
            }
        }

        public class ApplyChangesMethod
        {
            [Fact]
            public void AddsNewInheritedItemsToChildEntry()
            {
                var f = new EntryUserAccessMaintenanceFixture();
                var entry = new DataEntryTaskBuilder().Build();

                entry.RolesAllowed = new List<RolesControl>();

                var saveModel = new WorkflowEntryControlSaveModel
                {
                    CriteriaId = entry.CriteriaId + 1,
                    Id = (short) (entry.Id + 1),
                    UserAccessDelta = new Delta<int>
                    {
                        Added = new[] {1, 3}
                    }
                };

                var fieldsToUpdate = new EntryControlFieldsToUpdate(entry, saveModel);

                f.Subject.ApplyChanges(entry, saveModel, fieldsToUpdate);

                var first = entry.RolesAllowed.SingleOrDefault(r => r.RoleId == 1);
                Assert.NotNull(first);
                Assert.Equal(first.CriteriaId, entry.CriteriaId);
                Assert.Equal(first.DataEntryTaskId, entry.Id);
                Assert.True(first.Inherited.GetValueOrDefault());

                var second = entry.RolesAllowed.SingleOrDefault(r => r.RoleId == 3);
                Assert.NotNull(second);
                Assert.Equal(second.CriteriaId, entry.CriteriaId);
                Assert.Equal(second.DataEntryTaskId, entry.Id);
                Assert.True(second.Inherited.GetValueOrDefault());
            }

            [Fact]
            public void AddsNewItemsToEntry()
            {
                var f = new EntryUserAccessMaintenanceFixture();
                var entry = new DataEntryTaskBuilder().Build();

                entry.RolesAllowed = new List<RolesControl>();

                var saveModel = new WorkflowEntryControlSaveModel
                {
                    CriteriaId = entry.CriteriaId,
                    Id = entry.Id,
                    UserAccessDelta = new Delta<int>
                    {
                        Added = new[] {1, 3}
                    }
                };

                var fieldsToUpdate = new EntryControlFieldsToUpdate(entry, saveModel);

                f.Subject.ApplyChanges(entry, saveModel, fieldsToUpdate);

                var first = entry.RolesAllowed.SingleOrDefault(r => r.RoleId == 1);
                Assert.NotNull(first);
                Assert.Equal(first.CriteriaId, entry.CriteriaId);
                Assert.Equal(first.DataEntryTaskId, entry.Id);
                Assert.False(first.Inherited.GetValueOrDefault());

                var second = entry.RolesAllowed.SingleOrDefault(r => r.RoleId == 3);
                Assert.NotNull(second);
                Assert.Equal(second.CriteriaId, entry.CriteriaId);
                Assert.Equal(second.DataEntryTaskId, entry.Id);
                Assert.False(second.Inherited.GetValueOrDefault());
            }

            [Fact]
            public void RemovesItems()
            {
                var f = new EntryUserAccessMaintenanceFixture();
                var entry = new DataEntryTaskBuilder().Build();

                entry.RolesAllowed = new List<RolesControl>
                {
                    new RolesControl(1, entry.CriteriaId, entry.Id),
                    new RolesControl(2, entry.CriteriaId, entry.Id),
                    new RolesControl(3, entry.CriteriaId, entry.Id)
                };

                var saveModel = new WorkflowEntryControlSaveModel
                {
                    UserAccessDelta = new Delta<int>
                    {
                        Deleted = new[] {1, 3}
                    }
                };

                var fieldsToUpdate = new EntryControlFieldsToUpdate(entry, saveModel);

                f.Subject.ApplyChanges(entry, saveModel, fieldsToUpdate);

                Assert.Null(entry.RolesAllowed.SingleOrDefault(r => r.RoleId == 1));
                Assert.NotNull(entry.RolesAllowed.SingleOrDefault(r => r.RoleId == 2));
                Assert.Null(entry.RolesAllowed.SingleOrDefault(r => r.RoleId == 3));
            }

            [Fact]
            public void TurnsOnInheritanceFlagWhenResetting()
            {
                var f = new EntryUserAccessMaintenanceFixture();
                var entry = new DataEntryTaskBuilder().Build();

                entry.RolesAllowed = new List<RolesControl>();

                var saveModel = new WorkflowEntryControlSaveModel
                {
                    CriteriaId = entry.CriteriaId,
                    Id = entry.Id,
                    ResetInheritance = true,
                    UserAccessDelta = new Delta<int>
                    {
                        Added = new[] {1, 3}
                    }
                };

                var fieldsToUpdate = new EntryControlFieldsToUpdate(entry, saveModel);
                f.Subject.ApplyChanges(entry, saveModel, fieldsToUpdate);
                Assert.True(entry.RolesAllowed.All(r => r.Inherited == true));
            }
        }
    }

    public class EntryUserAccessMaintenanceFixture : IFixture<EntryUserAccessMaintenance>
    {
        public EntryUserAccessMaintenanceFixture()
        {
            Subject = new EntryUserAccessMaintenance();
        }

        public EntryUserAccessMaintenance Subject { get; }
    }
}