using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class ReminderRuleTest : IntegrationTest
    {
        ReminderRule SetupExistingReminderRule(DbSetup setup, ValidEvent e)
        {
            var name = setup.InsertWithNewId(new Name { LastName = Fixture.String(10) });
            var nameTypeA = setup.InsertWithNewId(new NameType());
            var nameTypeB = setup.InsertWithNewId(new NameType());
            var relationship = setup.Insert(new NameRelation { RelationshipCode = Fixture.String(2) });
            return new ReminderRule(e, 0)
            {
                Message1 = Fixture.String(10),
                Message2 = Fixture.String(10),
                LeadTime = 1,
                PeriodType = "D",
                Frequency = 2,
                FreqPeriodType = "W",
                EmployeeFlag = 1,
                RemindEmployeeId = name.Id,
                RemindEmployee = name,
                NameTypes = new[] { nameTypeA.NameTypeCode, nameTypeB.NameTypeCode },
                RelationshipId = relationship.RelationshipCode,
                NameRelation = relationship
            };
        }

        [Test]
        public void AddReminderRule()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var existingRule = SetupExistingReminderRule(setup, f.ChildValidEvent);
                setup.Insert(existingRule);

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    f.Importance,
                    existingRule
                };
            });
            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                ChangeRespOnDueDates = false,
                ReminderRuleDelta = new Delta<ReminderRuleSaveModel> { Added = new List<ReminderRuleSaveModel>() }
            }.WithMandatoryFields();

            var sameAsExisting = new ReminderRuleSaveModel();
            sameAsExisting.CopyFrom(data.existingRule);
            var newRule = new ReminderRuleSaveModel();
            newRule.CopyFrom(data.existingRule);
            newRule.Message1 = "Remind me to take out the rubbish.";
            formData.ReminderRuleDelta.Added.Add(sameAsExisting); // existing in child
            formData.ReminderRuleDelta.Added.Add(newRule);

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var criteriaReminderRules = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).Reminders;
                var childReminderRules = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).Reminders.Where(_ => _.Inherited == 1).ToArray();
                var grandchildReminderRules = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).Reminders.Where(_ => _.Inherited == 1).ToArray();

                Assert.AreEqual(2, criteriaReminderRules.Count, "Adds new reminder rules.");
                Assert.AreEqual(1, childReminderRules.Length, "Inherits different reminder rule only.");
                Assert.AreEqual("Remind me to take out the rubbish.", childReminderRules.First().Message1, "Inherits different reminder rule only.");
                Assert.AreEqual(1, grandchildReminderRules.Length, "Inherits different reminder rule only.");
                Assert.AreEqual("Remind me to take out the rubbish.", grandchildReminderRules.First().Message1, "Inherits different reminder rule only.");
            }
        }

        [Test]
        public void UpdateReminderRule()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var existingRule = SetupExistingReminderRule(setup, f.CriteriaValidEvent);
                setup.Insert(existingRule);

                var childRule = new ReminderRule(f.ChildValidEvent, 0);
                childRule.CopyFrom(existingRule, true);
                setup.Insert(childRule);

                var grandChildRule = new ReminderRule(f.GrandchildValidEvent, 0);
                grandChildRule.CopyFrom(existingRule, false);
                setup.Insert(grandChildRule);

                var newName = setup.InsertWithNewId(new Name { LastName = Fixture.String(10) });
                var newNameType1 = setup.InsertWithNewId(new NameType());
                var newNameType2 = setup.InsertWithNewId(new NameType());
                var newRelationship = setup.Insert(new NameRelation { RelationshipCode = Fixture.String(2) });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    NewNameNo = newName.Id,
                    NewNameType1 = newNameType1.NameTypeCode,
                    NewNameType2 = newNameType2.NameTypeCode,
                    NewRelationship = newRelationship.RelationshipCode,
                    ExistingRule = existingRule
                };
            });

            var saveData = new ReminderRuleSaveModel
                {
                    Sequence = data.ExistingRule.Sequence,
                    Message1 = Fixture.String(10),
                    Message2 = Fixture.String(10),
                    UseMessage1 = 1,
                    SendElectronically = 1,
                    EmailSubject = Fixture.String(10),
                    LeadTime = 2,
                    PeriodType = "Y",
                    Frequency = 1,
                    FreqPeriodType = "Y",
                    StopTime = 1,
                    StopTimePeriodType = "Y",
                    EmployeeFlag = 0,
                    SignatoryFlag = 1,
                    CriticalFlag = 1,
                    RemindEmployeeId = data.NewNameNo,
                    ExtendedNameType = data.NewNameType1 + ";" + data.NewNameType2,
                    RelationshipId = data.NewRelationship
                };

            var formData = new WorkflowEventControlSaveModel
            {
                ChangeRespOnDueDates = false,
                ImportanceLevel = data.ImportanceLevel,
                ReminderRuleDelta = new Delta<ReminderRuleSaveModel> { Updated = new List<ReminderRuleSaveModel> { saveData } }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var p = dbContext.Set<ReminderRule>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var c = dbContext.Set<ReminderRule>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var g = dbContext.Set<ReminderRule>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(saveData.HashKey(), p.HashKey(), "Should update parent Reminder");
                Assert.AreEqual(saveData.HashKey(), c.HashKey(), "Should update child Reminder");
                Assert.AreEqual(data.ExistingRule.HashKey(), g.HashKey(), "should not update grandchild Reminder");
            }
        }

        [Test]
        public void DeleteReminderRule()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var existingRule = SetupExistingReminderRule(setup, f.CriteriaValidEvent);
                setup.Insert(existingRule);

                var childRule = new ReminderRule(f.ChildValidEvent, 0);
                childRule.CopyFrom(existingRule, true);
                setup.Insert(childRule);

                var grandChildRule = new ReminderRule(f.GrandchildValidEvent, 0);
                grandChildRule.CopyFrom(existingRule, false);
                setup.Insert(grandChildRule);

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance
                };
            });

            var deletes = new List<ReminderRuleSaveModel>
            {
                new ReminderRuleSaveModel
                {
                    Sequence = 0
                }
            };

            var formData = new WorkflowEventControlSaveModel
            {
                ChangeRespOnDueDates = false,
                ImportanceLevel = data.ImportanceLevel,
                ReminderRuleDelta = new Delta<ReminderRuleSaveModel> { Deleted = deletes }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentCount = dbContext.Set<ReminderRule>().Count(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childCount = dbContext.Set<ReminderRule>().Count(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var grandchildCount = dbContext.Set<ReminderRule>().Count(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(0, parentCount);
                Assert.AreEqual(0, childCount);
                Assert.AreEqual(1, grandchildCount);
            }
        }

        [Test]
        public void AutomaticReorderingOfReminderRules()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var baseRule = SetupExistingReminderRule(setup, f.CriteriaValidEvent);
                var existingRule = new ReminderRule(f.CriteriaValidEvent, 0).CopyFrom(baseRule);
                existingRule.LeadTime = 2;
                existingRule.PeriodType = "W";
                setup.Insert(existingRule);

                var existingChildRule = new ReminderRule(f.ChildValidEvent, 0).CopyFrom(baseRule);
                existingChildRule.LeadTime = 2;
                existingChildRule.PeriodType = "M";
                setup.Insert(existingChildRule);

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    BaseRule = baseRule,
                    ParentHash = existingRule.HashKey(),
                    ChildHash = existingChildRule.HashKey()
                };
            });
            
            var r1 = new ReminderRuleSaveModel();
            r1.CopyFrom(data.BaseRule);
            var r2 = new ReminderRuleSaveModel();
            r2.CopyFrom(data.BaseRule);
            r2.PeriodType = "M";
            var r3 = new ReminderRuleSaveModel();
            r3.CopyFrom(data.BaseRule);
            r3.PeriodType = "W";
            var r4 = new ReminderRuleSaveModel();
            r4.CopyFrom(data.BaseRule);
            r4.PeriodType = "Y";
            var r5 = new ReminderRuleSaveModel();
            r5.CopyFrom(data.BaseRule);
            r5.LeadTime = 8;

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.ImportanceLevel,
                ChangeRespOnDueDates = false,
                ReminderRuleDelta = new Delta<ReminderRuleSaveModel> { Added = new List<ReminderRuleSaveModel> {r1,r2,r3,r4,r5} }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var p = dbContext.Set<ReminderRule>().Where(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).ToArray();
                var c = dbContext.Set<ReminderRule>().Where(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).ToArray();
                var g = dbContext.Set<ReminderRule>().Where(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).ToArray();

                Assert.AreEqual(r4.HashKey(), p[0].HashKey(), "Order by lead time descending");
                Assert.AreEqual(r2.HashKey(), p[1].HashKey(), "1M");
                Assert.AreEqual(data.ParentHash, p[2].HashKey(), "2W");
                Assert.AreEqual(r5.HashKey(), p[3].HashKey(), "8D");
                Assert.AreEqual(r3.HashKey(), p[4].HashKey(), "1W");
                Assert.AreEqual(r1.HashKey(), p[5].HashKey(), "1D");

                Assert.AreEqual(r4.HashKey(), c[0].HashKey(), "Child orders by lead time descending");
                Assert.AreEqual(data.ChildHash, c[1].HashKey(), "2M");
                Assert.AreEqual(r2.HashKey(), c[2].HashKey(), "1M");
                Assert.AreEqual(r5.HashKey(), c[3].HashKey(), "8D");
                Assert.AreEqual(r3.HashKey(), c[4].HashKey(), "1W");
                Assert.AreEqual(r1.HashKey(), c[5].HashKey(), "1D");

                Assert.AreEqual(r4.HashKey(), g[0].HashKey(), "Grandchild orders by lead time descending");
                Assert.AreEqual(r2.HashKey(), g[1].HashKey(), "1M");
                Assert.AreEqual(r5.HashKey(), g[2].HashKey(), "8D");
                Assert.AreEqual(r3.HashKey(), g[3].HashKey(), "1W");
                Assert.AreEqual(r1.HashKey(), g[4].HashKey(), "1D");
            }
        }
    }
}