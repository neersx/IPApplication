using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class DatesLogicTest : IntegrationTest
    {
        [Test]
        public void AddDatesLogic()
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var f = new EventControlDbSetup().SetupCriteriaInheritance();
                var existingEvent = eventBuilder.Create();
                var caseRelationship = new CaseRelationBuilder(setup.DbContext).Create(Fixture.String(3));
                var existingChildDatesLogic = setup.Insert(new DatesLogic(f.ChildValidEvent, 0)
                {
                    CompareEventId = existingEvent.Id,
                    DateTypeId = 1,
                    Operator = "<",
                    MustExist = 1,
                    RelativeCycle = 1,
                    CompareDateTypeId = 1,
                    CaseRelationshipId = caseRelationship.Relationship,
                    DisplayErrorFlag = 0,
                    ErrorMessage = Fixture.String(10)
                });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    f.Importance,
                    ExistingChildDatesLogic = existingChildDatesLogic
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                ChangeRespOnDueDates = false,
                DatesLogicDelta = new Delta<DatesLogicSaveModel>()
            }.WithMandatoryFields();

            var addNewDatesLogic = new DatesLogicSaveModel
            {
                CompareEventId = data.ExistingChildDatesLogic.CompareEventId,
                DateTypeId = 2,
                Operator = ">=",
                MustExist = 0,
                RelativeCycle = 2,
                CompareDateTypeId = 1,
                CaseRelationshipId = data.ExistingChildDatesLogic.CaseRelationshipId,
                DisplayErrorFlag = 1,
                ErrorMessage = Fixture.String(10)
            };
            formData.DatesLogicDelta.Added.Add(addNewDatesLogic);

            var duplicate = new DatesLogicSaveModel();
            duplicate.CopyFrom(data.ExistingChildDatesLogic, false);
            formData.DatesLogicDelta.Added.Add(duplicate);

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentRecords = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).DatesLogic.ToArray();
                var childInheritedRecords = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).DatesLogic.Where(_ => _.Inherited == 1).ToArray();
                var grandchildInheritedRecords = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).DatesLogic.Where(_ => _.Inherited == 1).ToArray();

                Assert.AreEqual(2, parentRecords.Length, "Adds new Dates Logic.");
                Assert.AreEqual(1, childInheritedRecords.Length, "Adds Dates Logic to child");

                var theOnlyAddedChildRecord = childInheritedRecords.Single();
                Assert.AreEqual(addNewDatesLogic.HashKey(), theOnlyAddedChildRecord.HashKey());

                Assert.AreEqual(1, grandchildInheritedRecords.Length, "Adds Dates Logic to grandchild");
                Assert.AreEqual(addNewDatesLogic.HashKey(), grandchildInheritedRecords.Single().HashKey(), "Adds Dates Logic with correct data");
            }
        }

        [Test]
        public void UpdateDatesLogic()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var eventBuilder = new EventBuilder(setup.DbContext);
                var existingEvent = eventBuilder.Create();
                var caseRelationship = new CaseRelationBuilder(setup.DbContext).Create(Fixture.String(3));

                var updateToEvent = eventBuilder.Create();
                var updateToCaseRelation = new CaseRelationBuilder(setup.DbContext).Create(Fixture.String(3));

                var existingDatesLogic = setup.Insert(new DatesLogic(f.CriteriaValidEvent, 0)
                {
                    Inherited = 0,
                    CompareEventId = existingEvent.Id,
                    DateTypeId = 1,
                    Operator = "<",
                    MustExist = 1,
                    RelativeCycle = 1,
                    CompareDateTypeId = 1,
                    CaseRelationshipId = caseRelationship.Relationship,
                    DisplayErrorFlag = 0,
                    ErrorMessage = Fixture.String(10)
                });

                var existingChildDatesLogic = setup.Insert(new DatesLogic(f.ChildValidEvent, 0).CopyFrom(existingDatesLogic, true));
                var existingGrandChildDatesLogic = setup.Insert(new DatesLogic(f.GrandchildValidEvent, 0).CopyFrom(existingDatesLogic, false));

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    f.Importance,
                    ExistingDatesLogic = existingDatesLogic,
                    ExistingChildDatesLogic = existingChildDatesLogic,
                    ExistingGrandChildDatesLogic = existingGrandChildDatesLogic,
                    UpdateToEvent = updateToEvent,
                    UpdateToCaseRelation = updateToCaseRelation
                };
            });

            var saveModel = new DatesLogicSaveModel();
            saveModel.CopyFrom(data.ExistingChildDatesLogic, false);

            saveModel.CompareEventId = data.UpdateToEvent.Id;
            saveModel.DateTypeId = 2;
            saveModel.Operator = ">=";
            saveModel.MustExist = 0;
            saveModel.RelativeCycle = 2;
            saveModel.CompareDateTypeId = 0;
            saveModel.CaseRelationshipId = data.UpdateToCaseRelation.Relationship;
            saveModel.DisplayErrorFlag = 1;
            saveModel.ErrorMessage = Fixture.String(10);

            var updates = new List<DatesLogicSaveModel>
            {
                saveModel
            };

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Apple",
                MaxCycles = 1,
                ApplyToDescendants = true,
                ImportanceLevel = data.Importance,
                DatesLogicDelta = new Delta<DatesLogicSaveModel> { Updated = updates }
            };

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).DatesLogic.Single();
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).DatesLogic.Single(_ => _.Inherited == 1);
                var grandchild = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).DatesLogic.Single();

                Assert.AreEqual(saveModel.HashKey(), parent.HashKey(), "Updates dates logic");
                Assert.False(parent.IsInherited);

                Assert.AreEqual(saveModel.HashKey(), child.HashKey(), "Updates inherited child dates logic");
                Assert.True(child.IsInherited);

                Assert.AreNotEqual(saveModel.HashKey(), grandchild.HashKey(), "Does not Update uninherited grandchild");
                Assert.False(grandchild.IsInherited, "Does not Update grandchild inheritance");
            }
        }

        [Test]
        public void DeleteDatesLogic()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var child1 = new CriteriaBuilder(setup.DbContext).Create("child1", f.CriteriaId);
                var childValidEvent1 = setup.Insert(new ValidEvent(child1.Id, f.EventId, "Pear") { NumberOfCyclesAllowed = 1, Inherited = 1 });

                var existingEvent = new EventBuilder(setup.DbContext).Create();
                var caseRelationship = new CaseRelationBuilder(setup.DbContext).Create(Fixture.String(3));

                var existingDatesLogic = setup.Insert(new DatesLogic(f.CriteriaValidEvent, 0)
                {
                    Inherited = 0,
                    CompareEventId = existingEvent.Id,
                    DateTypeId = 1,
                    Operator = "<",
                    MustExist = 1,
                    RelativeCycle = 1,
                    CompareDateTypeId = 1,
                    CaseRelationshipId = caseRelationship.Relationship,
                    DisplayErrorFlag = 0,
                    ErrorMessage = Fixture.String(10)
                });

                setup.Insert(new DatesLogic(f.ChildValidEvent, 0).CopyFrom(existingDatesLogic, true));
                setup.Insert(new DatesLogic(childValidEvent1, 0).CopyFrom(existingDatesLogic, false));
                setup.Insert(new DatesLogic(f.GrandchildValidEvent, 0).CopyFrom(existingDatesLogic, false));
                
                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    Child1Id = child1.Id,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    DatesLogicToDelete = existingDatesLogic
                };
            });

            var deleteModel = new DatesLogicSaveModel();
            deleteModel.CopyFrom(data.DatesLogicToDelete, false);
            deleteModel.Sequence = data.DatesLogicToDelete.Sequence;

            var deletes = new List<DatesLogicSaveModel>
            {
                deleteModel
            };

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Apple",
                MaxCycles = 1,
                ApplyToDescendants = true,
                ImportanceLevel = data.ImportanceLevel,
                DatesLogicDelta = new Delta<DatesLogicSaveModel> { Deleted = deletes }
            };

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentCount = dbContext.Set<DatesLogic>().Count(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childCount = dbContext.Set<DatesLogic>().Count(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var child1Count = dbContext.Set<DatesLogic>().Count(_ => _.CriteriaId == data.Child1Id && _.EventId == data.EventId);
                var grandchildCount = dbContext.Set<DatesLogic>().Count(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(0, parentCount, "Deletes dates logic.");
                Assert.AreEqual(0, childCount, "Deletes Inherited child dates logic.");
                Assert.AreEqual(1, child1Count, "Does not delete non inherited child dates logic.");
                Assert.AreEqual(1, grandchildCount, "Does not delete not-inherited grandchild dates logic.");
            }
        }

        [Test]
        public void DoNotApplyChangesToDescendants()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var eventBuilder = new EventBuilder(setup.DbContext);
                var existingEvent = eventBuilder.Create();
                var caseRelationship = new CaseRelationBuilder(setup.DbContext).Create(Fixture.String(3));

                var updateToEvent = eventBuilder.Create();
                var updateToCaseRelation = new CaseRelationBuilder(setup.DbContext).Create(Fixture.String(3));

                var existingDatesLogic = setup.Insert(new DatesLogic(f.CriteriaValidEvent, 0)
                {
                    Inherited = 0,
                    CompareEventId = existingEvent.Id,
                    DateTypeId = 1,
                    Operator = "<",
                    MustExist = 1,
                    RelativeCycle = 1,
                    CompareDateTypeId = 1,
                    CaseRelationshipId = caseRelationship.Relationship,
                    DisplayErrorFlag = 0,
                    ErrorMessage = Fixture.String(10)
                });

                var existingChildDatesLogic = setup.Insert(new DatesLogic(f.ChildValidEvent, 0).CopyFrom(existingDatesLogic, true));
                var existingGrandChildDatesLogic = setup.Insert(new DatesLogic(f.GrandchildValidEvent, 0).CopyFrom(existingDatesLogic, true));

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    f.Importance,
                    ExistingDatesLogic = existingDatesLogic,
                    ExistingChildDatesLogic = existingChildDatesLogic,
                    ExistingGrandChildDatesLogic = existingGrandChildDatesLogic,
                    UpdateToEvent = updateToEvent,
                    UpdateToCaseRelation = updateToCaseRelation
                };
            });

            var saveModel = new DatesLogicSaveModel();
            saveModel.CopyFrom(data.ExistingChildDatesLogic, false);

            saveModel.CompareEventId = data.UpdateToEvent.Id;
            saveModel.DateTypeId = 2;

            var updates = new List<DatesLogicSaveModel>
            {
                saveModel
            };

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Apple",
                MaxCycles = 1,
                ApplyToDescendants = false,
                ImportanceLevel = data.Importance,
                DatesLogicDelta = new Delta<DatesLogicSaveModel> { Updated = updates }
            };

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).DatesLogic.Single();
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).DatesLogic.Single();
                var grandchild = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).DatesLogic.Single();

                Assert.AreEqual(saveModel.HashKey(), parent.HashKey(), "Updates dates logic");
                Assert.False(parent.IsInherited);

                Assert.AreEqual(data.ExistingChildDatesLogic.HashKey(), child.HashKey(), "Child is not updated");
                Assert.IsFalse(child.IsInherited, "Child inheritance is broken");

                Assert.AreEqual(data.ExistingGrandChildDatesLogic.HashKey(), grandchild.HashKey(), "Does not Update uninherited grandchild");
                Assert.True(grandchild.IsInherited, "Grandchild inheritance is maintained");
            }
        }
    }
}