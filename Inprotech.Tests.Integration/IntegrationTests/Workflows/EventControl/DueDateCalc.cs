using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class DueDateCalcTest : IntegrationTest
    {
        [Test]
        public void AddDueDateCalc()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var dueDateFromEvent = setup.InsertWithNewId(new Event());
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 0) { FromEventId = dueDateFromEvent.Id, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Cycle = 1 });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    f.Importance,
                    FromEventId = dueDateFromEvent.Id
                };
            });
            var formData = new WorkflowEventControlSaveModel
                               {
                                   ImportanceLevel = data.Importance,
                                   ChangeRespOnDueDates = false,
                                   DueDateCalcDelta = new Delta<DueDateCalcSaveModel> {Added = new List<DueDateCalcSaveModel>()},
                                   MaxCycles = 2
                               }.WithMandatoryFields();

            formData.DueDateCalcDelta.Added.Add(new DueDateCalcSaveModel { Operator = "A", FromEventId = data.FromEventId, Period = 1, PeriodType = "W", RelCycle = 1, Cycle = 1 }); // existing in child
            formData.DueDateCalcDelta.Added.Add(new DueDateCalcSaveModel { Operator = "A", FromEventId = data.FromEventId, Period = 1, PeriodType = "W", RelCycle = 2, Cycle = 2 });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var criteriaDueDateCalcs = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).DueDateCalcs;
                var childDueDateCalcs = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).DueDateCalcs.Where(_ => _.Inherited == 1);
                var grandchildDueDateCalcs = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).DueDateCalcs.Where(_ => _.Inherited == 1);

                Assert.AreEqual(2, criteriaDueDateCalcs.Count, "Adds new due date calcs.");
                Assert.AreEqual(1, childDueDateCalcs.Count(), "Inherits different due date calc only.");
                Assert.AreEqual(2, childDueDateCalcs.First().RelativeCycle, "Inherits different due date calc only.");
                Assert.AreEqual(1, grandchildDueDateCalcs.Count(), "Inherits different due date calc only.");
                Assert.AreEqual(2, grandchildDueDateCalcs.First().RelativeCycle, "Inherits different due date calc only.");
            }
        }

        [Test]
        public void UpdateDueDateCalc()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var eventBuilder = new EventBuilder(setup.DbContext);
                var countryBuilder = new CountryBuilder(setup.DbContext);
                var documentBuilder = new DocumentBuilder(setup.DbContext);

                setup.Insert(new DueDateCalc(f.CriteriaValidEvent, 0) { FromEventId = f.EventId, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Inherited = 1, Cycle = 1 });
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 0) { FromEventId = f.EventId, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Inherited = 1, Cycle = 1});
                setup.Insert(new DueDateCalc(f.GrandchildValidEvent, 0) { FromEventId = f.EventId, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 0, Inherited = 1, Cycle = 2 });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    NewEvent = eventBuilder.Create("event2"),
                    NewCountry = countryBuilder.Create("country"),
                    NewDocument = documentBuilder.Create("doc")
                };
            });

            var updates = new List<DueDateCalcSaveModel>
            {
                new DueDateCalcSaveModel
                {
                    Period = 1,
                    Operator = "S",
                    Sequence = 0,
                    FromEventId = data.NewEvent.Id,
                    PeriodType = "D",
                    RelCycle = 2,
                    JurisdictionId = data.NewCountry.Id,
                    DocumentId = data.NewDocument.Id,
                    MustExist = true,
                    FromTo = 1,
                    AdjustBy = "1",
                    ReminderOption = "alternate",
                    Cycle = 2
                }
            };

            var formData = new WorkflowEventControlSaveModel
                               {
                                   ChangeRespOnDueDates = false,
                                   ImportanceLevel = data.ImportanceLevel,
                                   DueDateCalcDelta = new Delta<DueDateCalcSaveModel> {Updated = updates},
                                   MaxCycles = 2
                               }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentDueDateCalc = dbContext.Set<DueDateCalc>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childDueDateCalc = dbContext.Set<DueDateCalc>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var grandchildDueDateCalc = dbContext.Set<DueDateCalc>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual("D", parentDueDateCalc.PeriodType, "updates parent due date calc");
                Assert.AreEqual(2, parentDueDateCalc.RelativeCycle, "updates parent due date calc");
                Assert.AreEqual("S", parentDueDateCalc.Operator, "updates parent due date calc");
                Assert.AreEqual(data.NewEvent.Id, parentDueDateCalc.FromEventId, "updates parent due date calc");
                Assert.AreEqual(data.NewCountry.Id, parentDueDateCalc.JurisdictionId, "updates parent due date calc");
                Assert.AreEqual(data.NewDocument.Id, parentDueDateCalc.OverrideLetterId, "updates parent due date calc");
                Assert.AreEqual(1, parentDueDateCalc.MustExist, "updates parent due date calc");
                Assert.AreEqual(1, parentDueDateCalc.EventDateFlag, "updates parent due date calc");
                Assert.AreEqual("1", parentDueDateCalc.Adjustment, "updates parent due date calc");
                Assert.AreEqual(1, parentDueDateCalc.Message2Flag, "updates parent due date calc");
                Assert.AreEqual(0, parentDueDateCalc.SuppressReminders, "updates parent due date calc");
                Assert.AreEqual(2, parentDueDateCalc.Cycle); 

                Assert.AreEqual("D", childDueDateCalc.PeriodType, "updates child due date calc");
                Assert.AreEqual(2, childDueDateCalc.RelativeCycle, "updates child due date calc");
                Assert.AreEqual("S", childDueDateCalc.Operator, "updates child due date calc");
                Assert.AreEqual(data.NewEvent.Id, childDueDateCalc.FromEventId, "updates child due date calc");
                Assert.AreEqual(data.NewCountry.Id, childDueDateCalc.JurisdictionId, "updates child due date calc");
                Assert.AreEqual(data.NewDocument.Id, childDueDateCalc.OverrideLetterId, "updates child due date calc");
                Assert.AreEqual(1, childDueDateCalc.MustExist, "updates child due date calc");
                Assert.AreEqual(1, childDueDateCalc.EventDateFlag, "updates child due date calc");
                Assert.AreEqual("1", childDueDateCalc.Adjustment, "updates child due date calc");
                Assert.AreEqual(1, childDueDateCalc.Message2Flag, "updates child due date calc");
                Assert.AreEqual(0, childDueDateCalc.SuppressReminders, "updates child due date calc");
                Assert.AreEqual(2, childDueDateCalc.Cycle);

                Assert.AreEqual("W", grandchildDueDateCalc.PeriodType, "should not update grandchild due date calc");
                Assert.AreEqual(0, grandchildDueDateCalc.RelativeCycle, "should not update grandchild due date calc");
                Assert.AreEqual(2, grandchildDueDateCalc.Cycle);
            }
        }

        [Test]
        public void DeleteDueDateCalc()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                setup.Insert(new DueDateCalc(f.CriteriaValidEvent, 0) { FromEventId = f.EventId, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Inherited = 1 });
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 0) { FromEventId = f.EventId, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Inherited = 1 });
                setup.Insert(new DueDateCalc(f.GrandchildValidEvent, 0) { FromEventId = f.EventId, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Inherited = 0 });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance
                };
            });

            var deletes = new List<DueDateCalcSaveModel>
            {
                new DueDateCalcSaveModel
                {
                    Sequence = 0
                }
            };

            var formData = new WorkflowEventControlSaveModel
            {
                ChangeRespOnDueDates = false,
                ImportanceLevel = data.ImportanceLevel,
                DueDateCalcDelta = new Delta<DueDateCalcSaveModel> { Deleted = deletes }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentCount = dbContext.Set<DueDateCalc>().Count(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childCount = dbContext.Set<DueDateCalc>().Count(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var grandchildCount = dbContext.Set<DueDateCalc>().Count(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(0, parentCount);
                Assert.AreEqual(0, childCount);
                Assert.AreEqual(1, grandchildCount);
            }
        }

        [Test]
        public void UpdateDueDateCalcSettings()
        {
            var data = DbSetup.Do(setup =>
            {
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importance = setup.Insert(new Importance { Level = "E2", Description = "E2E" });

                var @event = eventBuilder.Create("event");
                var parent = criteriaBuilder.Create("parent");
                var child = criteriaBuilder.Create("child", parent.Id);

                var parentValidEvent = setup.Insert(new ValidEvent(parent, @event, "Apple")
                {
                    Inherited = 1,
                    SaveDueDate = 0,
                    DateToUse = "E",
                    RecalcEventDate = false,
                    ExtendPeriod = 3,
                    ExtendPeriodType = "M",
                    SuppressDueDateCalculation = false
                });

                var childValidEvent = new ValidEvent(child, @event, "Orange");
                childValidEvent.InheritRulesFrom(parentValidEvent);
                setup.Insert(childValidEvent);

                return new
                {
                    EventId = @event.Id,
                    ParentId = parent.Id,
                    ChildId = child.Id,
                    ImportanceLevel = importance.Level
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.ImportanceLevel,
                IsSaveDueDate = true,
                DateToUse = "L",
                RecalcEventDate = true,
                DoNotCalculateDueDate = true,
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.ParentId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ParentId && _.EventId == data.EventId);
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);

                Assert.AreEqual(1, parent.SaveDueDate);
                Assert.AreEqual("L", parent.DateToUse);
                Assert.AreEqual(true, parent.RecalcEventDate);
                Assert.AreEqual(null, parent.ExtendPeriod);
                Assert.AreEqual(null, parent.ExtendPeriodType);
                Assert.AreEqual(true, parent.SuppressDueDateCalculation);

                Assert.AreEqual(1, child.SaveDueDate);
                Assert.AreEqual("L", child.DateToUse);
                Assert.AreEqual(true, child.RecalcEventDate);
                Assert.AreEqual(null, child.ExtendPeriod);
                Assert.AreEqual(null, child.ExtendPeriodType);
                Assert.AreEqual(true, child.SuppressDueDateCalculation);
            }
        }
        
        [Test]
        public void InheritDueDateCalcFromGenericToJurisdictionSpecificCriteria()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var jurisdiction = new CountryBuilder(setup.DbContext).Create("E2E_Country");

                setup.DbContext.Set<Criteria>().Single(_ => _.Id == f.CriteriaId).CountryId = null;
                setup.DbContext.Set<Criteria>().Single(_ => _.Id == f.ChildCriteriaId).CountryId = null;
                setup.DbContext.Set<Criteria>().Single(_ => _.Id == f.GrandchildCriteriaId).CountryId = jurisdiction.Id;
                setup.DbContext.SaveChanges();

                var dueDateFromEvent = setup.InsertWithNewId(new Event());

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    f.Importance,
                    JurisdictionId = jurisdiction.Id,
                    FromEventId = dueDateFromEvent.Id
                };
            });

            var formData = new WorkflowEventControlSaveModel
                               {
                                   ImportanceLevel = data.Importance,
                                   ChangeRespOnDueDates = false,
                                   DueDateCalcDelta = new Delta<DueDateCalcSaveModel> {Added = new List<DueDateCalcSaveModel>()},
                                   MaxCycles = 2
                               }.WithMandatoryFields();

            formData.DueDateCalcDelta.Added.Add(new DueDateCalcSaveModel { Operator = "A", JurisdictionId = null, FromEventId = data.FromEventId, Period = 1, PeriodType = "W", RelCycle = 1, Cycle = 1 });
            formData.DueDateCalcDelta.Added.Add(new DueDateCalcSaveModel { Operator = "A", JurisdictionId = data.JurisdictionId, FromEventId = data.FromEventId, Period = 1, PeriodType = "W", RelCycle = 2, Cycle = 2 });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var criteriaDueDateCalcs = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).DueDateCalcs;
                var childDueDateCalcs = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).DueDateCalcs.Where(_ => _.Inherited == 1);
                var grandchildDueDateCalcs = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).DueDateCalcs.Where(_ => _.Inherited == 1);

                Assert.AreEqual(2, criteriaDueDateCalcs.Count, "Adds new due date calcs.");
                Assert.AreEqual(2, childDueDateCalcs.Count(), "Inherits all due date calcs when child country is null.");
                Assert.AreEqual(1, grandchildDueDateCalcs.Count(), "Only inherits due date calcs with no country when criteria country is not null.");
                Assert.IsNull(grandchildDueDateCalcs.Single().JurisdictionId, "Inherits the due date calc with no jurisdiction specified");
            }
        }
    }
}