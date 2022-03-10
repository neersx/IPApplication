using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class DateComparisonTest : IntegrationTest
    {
        [Test]
        public void AddDateComparison()
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var compareEvent = eventBuilder.Create();
                var fromEvent = eventBuilder.Create();
                var fixture = new EventControlDbSetup().SetupCriteriaInheritance();

                return new
                {
                    fixture.EventId,
                    fixture.CriteriaId,
                    fixture.ChildCriteriaId,
                    fixture.Importance,
                    FromEventId = fromEvent.Id,
                    RelativeCycle = (short)1,
                    EventDateFlag = (short)1,
                    Comparison = "=",
                    CompareEventId = compareEvent.Id,
                    CompareCycle = (short)2,
                    CompareEventFlag = (short)2
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                DateComparisonDelta = new Delta<DateComparisonSaveModel>()
                {
                    Added = new[]
                    {
                        new DateComparisonSaveModel
                        {
                            FromEventId = data.FromEventId,
                            RelativeCycle = data.RelativeCycle,
                            EventDateFlag = data.EventDateFlag,
                            Comparison = data.Comparison,
                            CompareEventId = data.CompareEventId,
                            CompareCycle = data.CompareCycle,
                            CompareEventFlag = data.CompareEventFlag
                        }
                    }
                }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).DueDateCalcs.Single();
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildCriteriaId && _.EventId == data.EventId).DueDateCalcs.Single();

                Assert.AreEqual(data.FromEventId, parent.FromEventId);
                Assert.AreEqual(data.RelativeCycle, parent.RelativeCycle);
                Assert.AreEqual(data.EventDateFlag, parent.EventDateFlag);
                Assert.AreEqual(data.Comparison, parent.Comparison);
                Assert.AreEqual(data.CompareEventId, parent.CompareEventId);
                Assert.AreEqual(data.CompareCycle, parent.CompareCycle);
                Assert.AreEqual(data.CompareEventFlag, parent.CompareEventFlag);

                Assert.AreEqual(data.FromEventId, child.FromEventId);
                Assert.AreEqual(data.RelativeCycle, child.RelativeCycle);
                Assert.AreEqual(data.EventDateFlag, child.EventDateFlag);
                Assert.AreEqual(data.Comparison, child.Comparison);
                Assert.AreEqual(data.CompareEventId, child.CompareEventId);
                Assert.AreEqual(data.CompareCycle, child.CompareCycle);
                Assert.AreEqual(data.CompareEventFlag, child.CompareEventFlag);
            }
        }

        [Test]
        public void DeleteDateComparison()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var child1 = new CriteriaBuilder(setup.DbContext).Create("child1", f.CriteriaId);
                var childValidEvent1 = setup.Insert(new ValidEvent(child1.Id, f.EventId, "Pear") { NumberOfCyclesAllowed = 1, Inherited = 1 });

                setup.Insert(new DueDateCalc(f.CriteriaValidEvent, 0) { FromEventId = f.EventId, Comparison = "<", Inherited = 1 });
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 0) { FromEventId = f.EventId, Comparison = "<", Inherited = 1 });
                setup.Insert(new DueDateCalc(childValidEvent1, 0) { FromEventId = f.EventId, Comparison = ">", Inherited = 1 });
                setup.Insert(new DueDateCalc(f.GrandchildValidEvent, 0) { FromEventId = f.EventId, Comparison = "<", Inherited = 0 });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    Child1Id = child1.Id,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance
                };
            });

            var deletes = new List<DateComparisonSaveModel>
            {
                new DateComparisonSaveModel
                {
                    Sequence = 0
                }
            };

            var formData = new WorkflowEventControlSaveModel
            {
                ChangeRespOnDueDates = false,
                ImportanceLevel = data.ImportanceLevel,
                DateComparisonDelta = new Delta<DateComparisonSaveModel> { Deleted = deletes }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentCount = dbContext.Set<DueDateCalc>().Count(_ => _.Comparison != null && _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childCount = dbContext.Set<DueDateCalc>().Count(_ => _.Comparison != null && _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var child1Count = dbContext.Set<DueDateCalc>().Count(_ => _.Comparison != null && _.CriteriaId == data.Child1Id && _.EventId == data.EventId);
                var grandchildCount = dbContext.Set<DueDateCalc>().Count(_ => _.Comparison != null && _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(0, parentCount, "Deletes date comparison.");
                Assert.AreEqual(0, childCount, "Deletes Inherited child date comparison when rules are the same.");
                Assert.AreEqual(1, child1Count, "Does not delete child date comparison when rules are different.");
                Assert.AreEqual(1, grandchildCount, "Does not delete not-inherited grandchild.");
            }
        }

        [Test]
        public void UpdateDateComparison()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var eventBuilder = new EventBuilder(setup.DbContext);
                var compareEventId = eventBuilder.Create();

                setup.Insert(new DueDateCalc(f.CriteriaValidEvent, 0) { FromEventId = f.EventId, RelativeCycle = 1, EventDateFlag = 1, Comparison = "=", CompareEventId = compareEventId.Id, CompareCycle = 1, CompareEventFlag = 1 });
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 0) { Inherited = 1, FromEventId = f.EventId, RelativeCycle = 1, EventDateFlag = 1, Comparison = "=", CompareEventId = compareEventId.Id, CompareCycle = 1, CompareEventFlag = 1 });
                setup.Insert(new DueDateCalc(f.GrandchildValidEvent, 0) { Inherited = 1, FromEventId = f.EventId, RelativeCycle = 1, EventDateFlag = 1, Comparison = "<>", CompareEventId = compareEventId.Id, CompareCycle = 1, CompareEventFlag = 1 });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    NewFromEvent = eventBuilder.Create(),
                    NewRelativeCycle = (short)2,
                    NewEventDateFlag = (short)2,
                    NewComparison = ">",
                    NewCompareEvent = eventBuilder.Create(),
                    NewCompareCycle = (short)2,
                    NewCompareFlag = (short)2
                };
            });

            var updates = new List<DateComparisonSaveModel>
            {
                new DateComparisonSaveModel
                {
                    FromEventId = data.NewFromEvent.Id,
                    RelativeCycle = data.NewRelativeCycle,
                    EventDateFlag = data.NewEventDateFlag,
                    Comparison = data.NewComparison,
                    CompareEventId = data.NewCompareEvent.Id,
                    CompareCycle = data.NewCompareCycle,
                    CompareEventFlag = data.NewCompareFlag
                }
            };

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.ImportanceLevel,
                DateComparisonDelta = new Delta<DateComparisonSaveModel> { Updated = updates }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<DueDateCalc>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var child = dbContext.Set<DueDateCalc>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var grandchild = dbContext.Set<DueDateCalc>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(data.NewFromEvent.Id, parent.FromEventId);
                Assert.AreEqual(data.NewRelativeCycle, parent.RelativeCycle);
                Assert.AreEqual(data.NewEventDateFlag, parent.EventDateFlag);
                Assert.AreEqual(data.NewCompareEvent.Id, parent.CompareEventId);
                Assert.AreEqual(data.NewCompareCycle, parent.CompareCycle);
                Assert.AreEqual(data.NewCompareFlag, parent.CompareEventFlag);

                Assert.AreEqual(data.NewFromEvent.Id, child.FromEventId);
                Assert.AreEqual(data.NewRelativeCycle, child.RelativeCycle);
                Assert.AreEqual(data.NewEventDateFlag, child.EventDateFlag);
                Assert.AreEqual(data.NewCompareEvent.Id, child.CompareEventId);
                Assert.AreEqual(data.NewCompareCycle, child.CompareCycle);
                Assert.AreEqual(data.NewCompareFlag, child.CompareEventFlag);

                Assert.AreNotEqual(data.NewFromEvent.Id, grandchild.FromEventId);
                Assert.AreNotEqual(data.NewRelativeCycle, grandchild.RelativeCycle);
                Assert.AreNotEqual(data.NewEventDateFlag, grandchild.EventDateFlag);
                Assert.AreNotEqual(data.NewCompareEvent.Id, grandchild.CompareEventId);
                Assert.AreNotEqual(data.NewCompareCycle, grandchild.CompareCycle);
                Assert.AreNotEqual(data.NewCompareFlag, grandchild.CompareEventFlag);
            }
        }

        [Test]
        public void SaveDatesLogicComparison()
        {
            var data = DbSetup.Do(setup =>
            {
                var eventControlSetup = new EventControlDbSetup();
                var f = eventControlSetup.SetupCriteriaInheritance(new ValidEvent { DatesLogicComparison = 0 });

                var eventBuilder = new EventBuilder(setup.DbContext);
                var fromEvent = eventBuilder.Create();
                var compareEvent = eventBuilder.Create();
                setup.Insert(new DueDateCalc(f.CriteriaValidEvent, 0) { FromEventId = fromEvent.Id, Comparison = "=" });
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 0) { FromEventId = fromEvent.Id, Comparison = "=", IsInherited = true });
                setup.Insert(new DueDateCalc(f.GrandchildValidEvent, 0) { FromEventId = fromEvent.Id, Comparison = "=", IsInherited = false });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    f.ChildCriteriaId,
                    f.GrandchildCriteriaId,
                    f.Importance,
                    FromEventId = fromEvent.Id,
                    RelativeCycle = (short)1,
                    EventDateFlag = (short)1,
                    Comparison = "=",
                    CompareEventId = compareEvent.Id,
                    CompareCycle = (short)2,
                    CompareEventFlag = (short)2
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                DatesLogicComparison = 1
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildCriteriaId && _.EventId == data.EventId);
                var grandchild = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildCriteriaId && _.EventId == data.EventId);

                Assert.AreEqual(1, parent.DatesLogicComparison, "Criteria Dates Logic Comparison changed");
                Assert.AreEqual(1, child.DatesLogicComparison, "Child Dates Logic Comparison changed");
                Assert.AreEqual(0, grandchild.DatesLogicComparison, "GrandChild Dates Logic Comparison not changed because due date calc didn't match");
            }
        }
    }
}