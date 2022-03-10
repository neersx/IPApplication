using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EventControlMaintenance
{
    public class ReminderAndDocumentFacts
    {
        public class ValidateMethod
        {
            [Theory]
            [InlineData('A', null, true, "S", 1, "D", 1, "D", true)]
            [InlineData('A', "A", true, null, 1, "D", 1, "D", true)]
            [InlineData('A', "A", true, "S", null, "D", 1, "D", true)]
            [InlineData('A', "A", true, "S", 1, null, 1, "D", true)]
            [InlineData('A', "A", true, "S", 1, "D", null, "D", true)]
            [InlineData('A', "A", true, "S", 1, "D", 1, null, true)]
            [InlineData('A', "A", true, "S", 1, "D", 1, "D", false)]
            [InlineData('E', null, true, "S", 1, "D", 1, "D", true)]
            [InlineData('E', "A", true, "S", 1, "D", 1, "D", false)]
            public void ChecksMandatoryFieldsOnReminderRules(char addOrEdit, string message, bool sendEmailFlag, string emailSubject, int? startSending, string periodType, int? freq, string freqPeriodType, bool shouldReturnError)
            {
                var f = new ReminderAndDocumentFixture();

                var eventControl = f.SetupValidEvent();
                var reminderRule = new ReminderRule(eventControl, Fixture.Short()) {Message1 = Fixture.String()};
                eventControl.Reminders.Add(reminderRule);
                var reminderRuleSave = new ReminderRuleSaveModelBuilder().For(eventControl).Build();
                reminderRuleSave.Sequence = reminderRule.Sequence;
                reminderRuleSave.Message1 = message;
                reminderRuleSave.SendElectronically = sendEmailFlag ? 1 : 0;
                reminderRuleSave.EmailSubject = emailSubject;
                reminderRuleSave.LeadTime = (short?) startSending;
                reminderRuleSave.PeriodType = periodType;
                reminderRuleSave.Frequency = (short?) freq;
                reminderRuleSave.FreqPeriodType = freqPeriodType;
                reminderRuleSave.EmployeeFlag = 1;

                var delta = new Delta<ReminderRuleSaveModel>();
                if (addOrEdit == 'A')
                {
                    delta.Added.Add(reminderRuleSave);
                }
                else
                {
                    delta.Updated.Add(reminderRuleSave);
                }

                var errors = f.Subject.Validate(new WorkflowEventControlSaveModel
                {
                    Description = Fixture.String(),
                    ImportanceLevel = Fixture.String(),
                    NumberOfCyclesAllowed = Fixture.Short(),
                    ReminderRuleDelta = delta
                }).ToArray();

                if (shouldReturnError)
                {
                    Assert.NotEmpty(errors);
                    Assert.True(errors.All(_ => _.Topic == "reminders"));
                }
                else
                {
                    Assert.Empty(errors);
                }
            }

            [Theory]
            [InlineData('A', true, false, false, null, null, null, false)]
            [InlineData('A', false, true, false, null, null, null, false)]
            [InlineData('A', false, false, true, null, null, null, false)]
            [InlineData('A', false, false, false, 1, null, null, false)]
            [InlineData('A', false, false, false, null, "I", null, false)]
            [InlineData('A', false, false, false, null, null, "O;I;", false)]
            [InlineData('A', false, false, false, null, null, null, true)]
            [InlineData('E', true, false, false, null, null, null, false)]
            [InlineData('E', false, false, false, null, null, null, true)]
            public void AtLeastOneRecipientIsRequiredInReminderRule(char addOrEdit, bool emp, bool signatory, bool critList, int? empNo, string nameType, string extNameType, bool shouldReturnError)
            {
                var f = new ReminderAndDocumentFixture();

                var eventControl = f.SetupValidEvent();
                var reminderRule = new ReminderRule(eventControl, Fixture.Short()) {Message1 = Fixture.String()};
                eventControl.Reminders.Add(reminderRule);
                var reminderRuleSave = new ReminderRuleSaveModelBuilder().For(eventControl).Build();
                reminderRuleSave.Sequence = reminderRule.Sequence;
                reminderRuleSave.Message1 = Fixture.String();
                reminderRuleSave.LeadTime = Fixture.Short();
                reminderRuleSave.PeriodType = Fixture.String();
                reminderRuleSave.Frequency = Fixture.Short();
                reminderRuleSave.FreqPeriodType = Fixture.String();
                reminderRuleSave.EmployeeFlag = emp ? 1 : 0;
                reminderRuleSave.SignatoryFlag = signatory ? 1 : 0;
                reminderRuleSave.CriticalFlag = critList ? 1 : 0;
                reminderRuleSave.RemindEmployeeId = empNo;
                reminderRuleSave.NameTypeId = nameType;
                reminderRuleSave.ExtendedNameType = extNameType;

                var delta = new Delta<ReminderRuleSaveModel>();
                if (addOrEdit == 'A')
                {
                    delta.Added.Add(reminderRuleSave);
                }
                else
                {
                    delta.Updated.Add(reminderRuleSave);
                }

                var errors = f.Subject.Validate(new WorkflowEventControlSaveModel
                {
                    Description = Fixture.String(),
                    ImportanceLevel = Fixture.String(),
                    NumberOfCyclesAllowed = Fixture.Short(),
                    ReminderRuleDelta = delta
                }).ToArray();

                if (shouldReturnError)
                {
                    Assert.NotEmpty(errors);
                    Assert.True(errors.All(_ => _.Topic == "reminders"));
                }
                else
                {
                    Assert.Empty(errors);
                }
            }

            [Theory]
            [InlineData('A', null, 1, 1, "D", -1, true, true)]
            [InlineData('A', 1, null, null, "D", -1, true, true)]
            [InlineData('A', 1, null, 1, null, -1, true, true)]
            [InlineData('A', 1, null, 1, "D", -1, false, true)]
            [InlineData('A', 1, null, 1, "D", -1, null, true)]
            [InlineData('A', 1, null, 1, "D", -1, true, false)]
            [InlineData('A', 1, 1, null, null, -1, true, false)]
            [InlineData('A', 1, null, 1, "D", null, false, false)]
            [InlineData('E', null, 1, 1, "D", -1, true, true)]
            [InlineData('E', 1, null, 1, "D", -1, true, false)]
            public void ChecksMandatoryFieldsOnDocuments(char addOrEdit, int? docId,
                                                         int? updateEvent, int? leadTime, string periodType,
                                                         int? letterFee, bool? payFee,
                                                         bool shouldReturnError)
            {
                var f = new ReminderAndDocumentFixture();

                var eventControl = f.SetupValidEvent();
                var letterRule = new ReminderRule(eventControl, Fixture.Short()) {LetterNo = Fixture.Short()};
                eventControl.Reminders.Add(letterRule);
                var documentSave = new ReminderRuleSaveModelBuilder().For(eventControl).Build();
                documentSave.LetterNo = (short?) docId;
                documentSave.UpdateEvent = updateEvent;
                documentSave.LeadTime = (short?) leadTime;
                documentSave.PeriodType = periodType;
                documentSave.LetterFeeId = letterFee;
                documentSave.PayFeeCode = payFee == null ? null : payFee.GetValueOrDefault() ? "2" : "0";

                var delta = new Delta<ReminderRuleSaveModel>();
                if (addOrEdit == 'A')
                {
                    delta.Added.Add(documentSave);
                }
                else
                {
                    delta.Updated.Add(documentSave);
                }

                var errors = f.Subject.Validate(new WorkflowEventControlSaveModel
                {
                    Description = Fixture.String(),
                    ImportanceLevel = Fixture.String(),
                    NumberOfCyclesAllowed = Fixture.Short(),
                    DocumentDelta = delta
                }).ToArray();

                if (shouldReturnError)
                {
                    Assert.NotEmpty(errors);
                    Assert.True(errors.All(_ => _.Topic == "documents"));
                }
                else
                {
                    Assert.Empty(errors);
                }
            }
        }

        public class SetChildInheritanceDeltaMethod
        {
            [Fact]
            public void SetsDeltaToInheritFromInheritanceService()
            {
                var f = new ReminderAndDocumentFixture();

                var validEvent = f.SetupValidEvent();
                var saveModel = new WorkflowEventControlSaveModel();
                var rDelta = new Delta<int>();
                var dDelta = new Delta<int>();

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.ReminderRulesDelta = rDelta;
                fieldsToUpdate.DocumentsDelta = dDelta;

                var mockReturnFields = new EventControlFieldsToUpdate();

                f.WorkflowEventInheritanceService.GetInheritDelta(Arg.Any<Func<Delta<int>>>(), validEvent.ReminderRuleHashList).Returns(mockReturnFields.ReminderRulesDelta);
                f.WorkflowEventInheritanceService.GetInheritDelta(Arg.Any<Func<Delta<int>>>(), validEvent.DocumentsHashList).Returns(mockReturnFields.DocumentsDelta);

                f.Subject.SetChildInheritanceDelta(validEvent, saveModel, fieldsToUpdate);

                f.WorkflowEventInheritanceService.Received(1).GetInheritDelta(Arg.Any<Func<Delta<int>>>(), validEvent.ReminderRuleHashList);
                f.WorkflowEventInheritanceService.Received(1).GetInheritDelta(Arg.Any<Func<Delta<int>>>(), validEvent.DocumentsHashList);

                Assert.Equal(fieldsToUpdate.ReminderRulesDelta, mockReturnFields.ReminderRulesDelta);
                Assert.Equal(fieldsToUpdate.DocumentsDelta, mockReturnFields.DocumentsDelta);
            }
        }

        public class ApplyChangesMethod
        {
            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            public void AddsOrInheritsReminderRulesSpecifiedInDelta(bool inherit)
            {
                var f = new ReminderAndDocumentFixture();

                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();
                eventRule.Reminders.Add(new ReminderRuleBuilder {Sequence = sequence}.AsReminderRule().For(eventRule).Build());

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = inherit ? Fixture.Integer() : eventRule.CriteriaId};
                var newReminderRuleSave = new ReminderRuleSaveModelBuilder().AsReminderRule().For(eventRule).Build();
                newReminderRuleSave.LeadTime = Fixture.Short();
                saveModel.ReminderRuleDelta.Added.Add(newReminderRuleSave);

                var reminderDelta = new Delta<ReminderRuleSaveModel>();
                reminderDelta.Added.Add(newReminderRuleSave);

                var newDocument = new ReminderRuleSaveModelBuilder().AsDocumentRule().For(eventRule).Build();
                saveModel.DocumentDelta.Added.Add(newDocument);

                var documentDelta = new Delta<ReminderRuleSaveModel>();
                documentDelta.Added.Add(newDocument);

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.ReminderRulesDelta.Added.Add(newReminderRuleSave.HashKey());

                f.WorkflowEventInheritanceService.GetDelta(saveModel.ReminderRuleDelta, Arg.Any<Delta<int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>()).Returns(reminderDelta);
                f.WorkflowEventInheritanceService.GetDelta(saveModel.DocumentDelta, Arg.Any<Delta<int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>()).Returns(documentDelta);

                f.Subject.ApplyChanges(eventRule, saveModel, fieldsToUpdate);

                Assert.Equal(3, eventRule.Reminders.Count);
                var addedReminderRule = eventRule.Reminders.SingleOrDefault(_ => _.HashKey() == newReminderRuleSave.HashKey());
                Assert.NotNull(addedReminderRule);
                Assert.Equal(inherit, addedReminderRule.IsInherited);

                var addedDocumentRule = eventRule.Reminders.WhereDocument().Single();
                Assert.Equal(addedDocumentRule.HashKey(), newDocument.HashKey());
                Assert.Equal(inherit, addedDocumentRule.IsInherited);
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            public void UpdatesOrInheritsReminderRules(bool inherit)
            {
                var f = new ReminderAndDocumentFixture();

                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();
                var existingReminderRule = new ReminderRuleBuilder().For(eventRule).Build();
                DataFiller.Fill(existingReminderRule);
                existingReminderRule.Inherited = inherit ? 1 : 0;
                existingReminderRule.Sequence = sequence;
                existingReminderRule.LetterNo = null;
                eventRule.Reminders.Add(existingReminderRule);

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = inherit ? Fixture.Integer() : eventRule.CriteriaId};
                var editedReminderRule = new ReminderRuleSaveModelBuilder().For(eventRule).Build();
                DataFiller.Fill(editedReminderRule);
                editedReminderRule.OriginalHashKey = existingReminderRule.HashKey();
                editedReminderRule.Sequence = sequence;
                editedReminderRule.LetterNo = null;
                saveModel.ReminderRuleDelta.Updated.Add(editedReminderRule);

                var delta = new Delta<ReminderRuleSaveModel>();
                delta.Updated.Add(editedReminderRule);

                Assert.NotEqual(eventRule.Reminders.Single().HashKey(), editedReminderRule.HashKey());

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.ReminderRulesDelta.Added.Add(editedReminderRule.HashKey());

                f.WorkflowEventInheritanceService.GetDelta(saveModel.ReminderRuleDelta, Arg.Any<Delta<int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>()).Returns(delta);

                f.Subject.ApplyChanges(eventRule, saveModel, fieldsToUpdate);

                var updatedRule = eventRule.Reminders.Single();
                Assert.Equal(sequence, updatedRule.Sequence);
                Assert.Equal(editedReminderRule.Message1, updatedRule.Message1);
                Assert.Equal(editedReminderRule.Message2, updatedRule.Message2);
                Assert.Equal(editedReminderRule.EmailSubject, updatedRule.EmailSubject);
                Assert.Equal(editedReminderRule.LeadTime, updatedRule.LeadTime);
                Assert.Equal(inherit, updatedRule.IsInherited);
            }

            [Fact]
            public void AppliesReminderRuleReorderingWhenAReminderChanged()
            {
                var f = new ReminderAndDocumentFixture();

                var eventRule = f.SetupValidEvent();

                var existingRule = new ReminderRule();
                var existingRule1 = new ReminderRule();

                DataFiller.Fill(existingRule);
                DataFiller.Fill(existingRule1);

                existingRule.PeriodType = "D";
                existingRule.LeadTime = 1;
                existingRule.Sequence = 1;
                var erHash = existingRule.HashKey();

                existingRule1.PeriodType = "W";
                existingRule1.LeadTime = 1;
                existingRule1.Sequence = 2;
                var er1Hash = existingRule1.HashKey();

                eventRule.Reminders.AddRange(new[] {existingRule, existingRule1});

                var newRule = new ReminderRuleSaveModel();
                DataFiller.Fill(newRule);
                newRule.PeriodType = "D";
                newRule.LeadTime = 3;
                var nrHash = newRule.HashKey();

                var saveModel = new WorkflowEventControlSaveModel();
                saveModel.ReminderRuleDelta.Added.Add(newRule);

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.ReminderRulesDelta.Added.Add(newRule.HashKey());

                f.WorkflowEventInheritanceService.GetDelta(saveModel.ReminderRuleDelta, Arg.Any<Delta<int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>()).Returns(saveModel.ReminderRuleDelta);

                f.Subject.ApplyChanges(eventRule, saveModel, fieldsToUpdate);

                Assert.Equal(3, eventRule.Reminders.Count);
                var rules = eventRule.Reminders.OrderBy(_ => _.Sequence).ToArray();
                Assert.Equal(er1Hash, rules.First().HashKey());
                Assert.Equal(nrHash, rules.ToArray()[1].HashKey());
                Assert.Equal(erHash, rules.Last().HashKey());
            }

            [Fact]
            public void RemovesInheritedChildReminderRules()
            {
                var f = new ReminderAndDocumentFixture();

                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();
                var reminderRuleToBeDeleted = new ReminderRuleBuilder {Sequence = sequence, Inherited = 1}.For(eventRule).Build();
                eventRule.Reminders.Add(reminderRuleToBeDeleted);

                var reminderRuleNotInherited = new ReminderRuleBuilder {Sequence = ++sequence}.For(eventRule).Build();
                eventRule.Reminders.Add(reminderRuleNotInherited);

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = Fixture.Integer(), ReminderRuleDelta = new Delta<ReminderRuleSaveModel> {Deleted = new List<ReminderRuleSaveModel>()}};

                var delete1 = new ReminderRuleSaveModelBuilder().For(eventRule).Build();
                delete1.OriginalHashKey = reminderRuleToBeDeleted.HashKey();

                var delete2 = new ReminderRuleSaveModelBuilder().For(eventRule).Build();
                delete2.OriginalHashKey = reminderRuleNotInherited.HashKey();

                saveModel.ReminderRuleDelta.Deleted.AddRange(new[] {delete1, delete2});

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.ReminderRulesDelta.Added.AddRange(new[] {delete1.HashKey(), delete2.HashKey()});

                f.WorkflowEventInheritanceService.GetDelta(saveModel.ReminderRuleDelta, Arg.Any<Delta<int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>()).Returns(saveModel.ReminderRuleDelta);

                f.Subject.ApplyChanges(eventRule, saveModel, fieldsToUpdate);

                Assert.Null(eventRule.Reminders.SingleOrDefault(_ => _.Sequence == reminderRuleToBeDeleted.Sequence));
                Assert.NotNull(eventRule.Reminders.SingleOrDefault(_ => _.Sequence == reminderRuleNotInherited.Sequence));
            }

            [Fact]
            public void ThrowsErrorForDuplicateReminderRule()
            {
                var f = new ReminderAndDocumentFixture();

                var eventRule = f.SetupValidEvent();
                var sequence = Fixture.Short();

                var reminderRule = new ReminderRuleBuilder {Sequence = sequence}.For(eventRule).Build();
                reminderRule.Message1 = Fixture.String();
                eventRule.Reminders.Add(reminderRule);

                var saveModel = new WorkflowEventControlSaveModel();
                var newReminderRuleSave = new ReminderRuleSaveModelBuilder().For(eventRule).Build();
                newReminderRuleSave.CopyFrom(reminderRule); // make a duplicate
                saveModel.ReminderRuleDelta.Added.Add(newReminderRuleSave);

                var delta = new Delta<ReminderRuleSaveModel>();
                delta.Added.Add(newReminderRuleSave);

                f.WorkflowEventInheritanceService.GetDelta(saveModel.ReminderRuleDelta, Arg.Any<Delta<int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>(), Arg.Any<Func<ReminderRuleSaveModel, int>>()).Returns(delta);

                Assert.Throws<InvalidOperationException>(() => f.Subject.ApplyChanges(eventRule, saveModel, new EventControlFieldsToUpdate()));
            }
        }

        public class RemoveInheritanceMethod
        {
            [Fact]
            public void RemovesInheritanceOnAllUpdatedAndDeleted()
            {
                var f = new ReminderAndDocumentFixture();

                var validEvent = f.SetupValidEvent();

                var reminderUpdate = new ReminderRuleSaveModelBuilder {Inherited = 1}.AsReminderRule().Build();
                var reminderDelete = new ReminderRuleSaveModelBuilder {Inherited = 1}.AsReminderRule().Build();

                var documentUpdate = new ReminderRuleSaveModelBuilder {Inherited = 1}.AsDocumentRule().Build();
                var documentDelete = new ReminderRuleSaveModelBuilder {Inherited = 1}.AsDocumentRule().Build();

                validEvent.Reminders.AddRange(new[] {reminderUpdate, reminderDelete, documentUpdate, documentDelete});

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.ReminderRulesDelta.Updated.Add(reminderUpdate.HashKey());
                fieldsToUpdate.ReminderRulesDelta.Deleted.Add(reminderDelete.HashKey());
                fieldsToUpdate.DocumentsDelta.Updated.Add(documentUpdate.HashKey());
                fieldsToUpdate.DocumentsDelta.Deleted.Add(documentDelete.HashKey());

                f.Subject.RemoveInheritance(validEvent, fieldsToUpdate);
                Assert.True(validEvent.Reminders.All(_ => _.IsInherited == false));
            }
        }

        public class ResetMethod
        {
            [Fact]
            public void AddsIfNotExisting()
            {
                var f = new ReminderAndDocumentFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var reminderRule = new ReminderRuleBuilder().AsReminderRule().Build();
                var documentRule = new ReminderRuleBuilder().AsDocumentRule().Build();
                parent.Reminders.Add(reminderRule);
                parent.Reminders.Add(documentRule);

                f.Subject.Reset(newValues, parent, criteria);

                var addedReminder = newValues.ReminderRuleDelta.Added.First();
                var addedDocument = newValues.DocumentDelta.Added.First();
                Assert.Equal(reminderRule.HashKey(), addedReminder.HashKey());
                Assert.Equal(documentRule.HashKey(), addedDocument.HashKey());
                Assert.Empty(newValues.ReminderRuleDelta.Updated);
                Assert.Empty(newValues.DocumentDelta.Updated);
                Assert.Empty(newValues.ReminderRuleDelta.Deleted);
                Assert.Empty(newValues.DocumentDelta.Deleted);
            }

            [Fact]
            public void DeletesIfNotInParent()
            {
                var f = new ReminderAndDocumentFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var reminderRule = new ReminderRuleBuilder().AsReminderRule().Build();
                var documentRule = new ReminderRuleBuilder().AsDocumentRule().Build();
                criteria.Reminders.Add(reminderRule);
                criteria.Reminders.Add(documentRule);

                f.Subject.Reset(newValues, parent, criteria);

                var deletedReminder = newValues.ReminderRuleDelta.Deleted.First();
                var deletedDocument = newValues.DocumentDelta.Deleted.First();
                Assert.Equal(reminderRule.HashKey(), deletedReminder.HashKey());
                Assert.Equal(documentRule.HashKey(), deletedDocument.HashKey());
                Assert.Empty(newValues.ReminderRuleDelta.Updated);
                Assert.Empty(newValues.DocumentDelta.Updated);
                Assert.Empty(newValues.ReminderRuleDelta.Added);
                Assert.Empty(newValues.DocumentDelta.Added);
            }

            [Fact]
            public void UpdatesIfExisting()
            {
                var f = new ReminderAndDocumentFixture();
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var criteria = new ValidEventBuilder().Build();

                var reminderRule = new ReminderRuleBuilder().AsReminderRule().Build();
                var documentRule = new ReminderRuleBuilder().AsDocumentRule().Build();
                parent.Reminders.Add(reminderRule);
                criteria.Reminders.Add(reminderRule);
                parent.Reminders.Add(documentRule);
                criteria.Reminders.Add(documentRule);

                f.Subject.Reset(newValues, parent, criteria);

                var updatedReminder = newValues.ReminderRuleDelta.Updated.First();
                var updatedDocument = newValues.DocumentDelta.Updated.First();
                Assert.Equal(reminderRule.HashKey(), updatedReminder.OriginalHashKey);
                Assert.Equal(documentRule.HashKey(), updatedDocument.OriginalHashKey);
                Assert.Empty(newValues.ReminderRuleDelta.Added);
                Assert.Empty(newValues.DocumentDelta.Added);
                Assert.Empty(newValues.ReminderRuleDelta.Deleted);
                Assert.Empty(newValues.DocumentDelta.Deleted);
            }
        }
    }

    public class ReminderAndDocumentFixture : IFixture<ReminderAndDocument>
    {
        public ReminderAndDocumentFixture()
        {
            WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();
            Subject = new ReminderAndDocument(WorkflowEventInheritanceService);
        }

        public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; }
        public ReminderAndDocument Subject { get; }

        public ValidEvent SetupValidEvent()
        {
            var baseEvent = new Event(Fixture.Integer());
            var criteria = new CriteriaBuilder().Build();
            var eventRule = new ValidEventBuilder {Inherited = true}.For(criteria, baseEvent).Build();

            return eventRule;
        }
    }
}