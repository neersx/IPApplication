using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class DocumentsTest : IntegrationTest
    {
        ReminderRule SetupExistingDocument(DbSetup setup, ValidEvent e)
        {
            var document = new DocumentBuilder(setup.DbContext).Create("doc");
            var fee = new ChargeTypeBuilder(setup.DbContext).Create("charge");

            return new ReminderRule(e, 0)
            {
                LetterNo = document.Id,
                UpdateEvent = null,
                LeadTime = 1,
                PeriodType = "D",
                Frequency = 2,
                FreqPeriodType = "W",
                MaxLetters = Fixture.Short(),
                LetterFeeId = fee.Id,
                PayFeeCode = "1"
            };
        }

        [Test]
        public void AddDocument()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var existingRule = SetupExistingDocument(setup, f.ChildValidEvent);
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
                DocumentDelta = new Delta<ReminderRuleSaveModel> { Added = new List<ReminderRuleSaveModel>() }
            }.WithMandatoryFields();

            var sameAsExisting = new ReminderRuleSaveModel();
            sameAsExisting.CopyFrom(data.existingRule);
            var newRule = new ReminderRuleSaveModel();
            newRule.CopyFrom(data.existingRule);
            newRule.LeadTime = 5;
            formData.DocumentDelta.Added.Add(sameAsExisting); // existing in child
            formData.DocumentDelta.Added.Add(newRule);

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var criteriaDocuments = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).Reminders;
                var childDocuments = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).Reminders.Where(_ => _.Inherited == 1).ToArray();
                var grandchildDocuments = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).Reminders.Where(_ => _.Inherited == 1).ToArray();

                Assert.AreEqual(2, criteriaDocuments.Count, "Adds new reminder rules.");
                Assert.AreEqual(1, childDocuments.Length, "Inherits different reminder rule only.");
                Assert.AreEqual(5, childDocuments.First().LeadTime, "Inherits different reminder rule only.");
                Assert.AreEqual(1, grandchildDocuments.Length, "Inherits different reminder rule only.");
                Assert.AreEqual(5, grandchildDocuments.First().LeadTime, "Inherits different reminder rule only.");
            }
        }

        [Test]
        public void UpdateDocument()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var existingRule = SetupExistingDocument(setup, f.CriteriaValidEvent);
                setup.Insert(existingRule);

                var childRule = new ReminderRule(f.ChildValidEvent, 0);
                childRule.CopyFrom(existingRule, true);
                setup.Insert(childRule);

                var grandChildRule = new ReminderRule(f.GrandchildValidEvent, 0);
                grandChildRule.CopyFrom(existingRule, false);
                setup.Insert(grandChildRule);

                var document = setup.InsertWithNewId(new Document { Name = Fixture.String(5) });
                var fee = setup.InsertWithNewId(new ChargeType { Description = Fixture.String(5) });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    NewDocumentId = document.Id,
                    NewFeeId = fee.Id,
                    ExistingRule = existingRule
                };
            });

            var saveData = new ReminderRuleSaveModel
            {
                Sequence = data.ExistingRule.Sequence,
                DocumentId = data.NewDocumentId,
                ProduceWhen = "eventOccurs",
                LetterFeeId = data.NewFeeId,
                IsRaiseCharge = true,
                IsCheckCycleForSubstitute = true
            };

            var formData = new WorkflowEventControlSaveModel
            {
                ChangeRespOnDueDates = false,
                ImportanceLevel = data.ImportanceLevel,
                DocumentDelta = new Delta<ReminderRuleSaveModel> { Updated = new List<ReminderRuleSaveModel> { saveData } }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var p = dbContext.Set<ReminderRule>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var c = dbContext.Set<ReminderRule>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var g = dbContext.Set<ReminderRule>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(saveData.HashKey(), p.HashKey(), "Should update parent Document");
                Assert.AreEqual(saveData.HashKey(), c.HashKey(), "Should update child Document");
                Assert.AreEqual(data.ExistingRule.HashKey(), g.HashKey(), "should not update grandchild Document");
            }
        }

        [Test]
        public void DeleteDocument()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var existingRule = SetupExistingDocument(setup, f.CriteriaValidEvent);
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
                DocumentDelta = new Delta<ReminderRuleSaveModel> { Deleted = deletes }
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
    }
}