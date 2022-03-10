using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEventControlServiceDataNormalisationFacts
    {
        public class NormaliseDocumentsMethod : FactBase
        {
            [Fact]
            public void ClearsLetterFeeOptionsWhenNoFee()
            {
                var model = new WorkflowEventControlSaveModel();
                var d = new ReminderRuleSaveModel
                {
                    LetterFeeId = null,
                    PayFeeCode = "1",
                    EstimateFlag = 1,
                    DirectPayFlag = true
                };
                model.DocumentDelta = new Delta<ReminderRuleSaveModel> {Added = new List<ReminderRuleSaveModel> {d}};

                WorkflowEventControlService.NormaliseDocuments(model);

                Assert.Null(d.PayFeeCode);
                Assert.Null(d.EstimateFlag);
                Assert.Null(d.DirectPayFlag);
            }

            [Fact]
            public void ClearsRecurringFieldsWhenNonRecurring()
            {
                var model = new WorkflowEventControlSaveModel();
                var d = new ReminderRuleSaveModel
                {
                    LetterFeeId = Fixture.Short(),
                    LeadTime = 1,
                    StartBeforePeriod = "D",
                    Frequency = 0,
                    FreqPeriodType = "D",
                    StopTime = 1,
                    StopTimePeriod = "D",
                    MaxLetters = 1
                };
                model.DocumentDelta = new Delta<ReminderRuleSaveModel> {Added = new List<ReminderRuleSaveModel> {d}};

                WorkflowEventControlService.NormaliseDocuments(model);

                Assert.Null(d.StopTime);
                Assert.Null(d.StopTimePeriodType);
                Assert.Null(d.MaxLetters);
            }

            [Fact]
            public void ClearsScheduleWhenNotScheduled()
            {
                var model = new WorkflowEventControlSaveModel();
                var d = new ReminderRuleSaveModel
                {
                    LetterFeeId = Fixture.Short(),
                    UpdateEvent = 1,
                    LeadTime = 1,
                    StartBeforePeriod = "D",
                    Frequency = 1,
                    FreqPeriodType = "D",
                    StopTime = 1,
                    StopTimePeriod = "D",
                    MaxLetters = 1
                };
                model.DocumentDelta = new Delta<ReminderRuleSaveModel> {Added = new List<ReminderRuleSaveModel> {d}};

                WorkflowEventControlService.NormaliseDocuments(model);

                Assert.Null(d.LeadTime);
                Assert.Null(d.PeriodType);
                Assert.Null(d.Frequency);
                Assert.Null(d.FreqPeriodType);
                Assert.Null(d.StopTime);
                Assert.Null(d.StopTimePeriodType);
                Assert.Null(d.MaxLetters);
            }
        }

        public class NormaliseCharges : FactBase
        {
            [Theory]
            [InlineData(false, false, false, true)]
            [InlineData(false, false, true, false)]
            [InlineData(false, true, false, false)]
            [InlineData(false, true, true, false)]
            [InlineData(true, false, false, false)]
            [InlineData(true, true, false, false)]
            [InlineData(true, true, true, false)]
            public void DoesNotModifyValidData(bool isPayFee, bool isRaiseCharge, bool isEstimate, bool isDirectPay)
            {
                var formData = new WorkflowEventControlSaveModel
                {
                    ChargeType = Fixture.Integer(),
                    ChargeType2 = Fixture.Integer(),
                    IsPayFee = isPayFee,
                    IsPayFee2 = isPayFee,
                    IsRaiseCharge = isRaiseCharge,
                    IsRaiseCharge2 = isRaiseCharge,
                    IsEstimate = isEstimate,
                    IsEstimate2 = isEstimate,
                    IsDirectPay = isDirectPay,
                    IsDirectPay2 = isDirectPay
                };

                WorkflowEventControlService.NormaliseCharges(formData);

                Assert.Equal(isPayFee, formData.IsPayFee);
                Assert.Equal(isPayFee, formData.IsPayFee2);
                Assert.Equal(isRaiseCharge, formData.IsRaiseCharge);
                Assert.Equal(isRaiseCharge, formData.IsRaiseCharge2);
                Assert.Equal(isEstimate, formData.IsEstimate);
                Assert.Equal(isEstimate, formData.IsEstimate2);
                Assert.Equal(isDirectPay, formData.IsDirectPay);
                Assert.Equal(isDirectPay, formData.IsDirectPay2);
            }

            [Fact]
            public void SetEstimateFalseIfPayFeeAlsoTrueAndNoRaiseCharge()
            {
                var formData = new WorkflowEventControlSaveModel
                {
                    ChargeType = Fixture.Integer(),
                    IsPayFee = true,
                    IsRaiseCharge = false,
                    IsEstimate = true,

                    ChargeType2 = Fixture.Integer(),
                    IsPayFee2 = true,
                    IsRaiseCharge2 = false,
                    IsEstimate2 = true
                };

                WorkflowEventControlService.NormaliseCharges(formData);

                Assert.False(formData.IsRaiseCharge);
                Assert.True(formData.IsPayFee);
                Assert.False(formData.IsEstimate);

                Assert.False(formData.IsRaiseCharge2);
                Assert.True(formData.IsPayFee2);
                Assert.False(formData.IsEstimate2);

                formData = new WorkflowEventControlSaveModel
                {
                    ChargeType = Fixture.Integer(),
                    IsPayFee = true,
                    IsRaiseCharge = true,
                    IsEstimate = true,

                    ChargeType2 = Fixture.Integer(),
                    IsPayFee2 = true,
                    IsRaiseCharge2 = true,
                    IsEstimate2 = true
                };

                WorkflowEventControlService.NormaliseCharges(formData);

                Assert.True(formData.IsRaiseCharge);
                Assert.True(formData.IsPayFee);
                Assert.True(formData.IsEstimate);

                Assert.True(formData.IsRaiseCharge2);
                Assert.True(formData.IsPayFee2);
                Assert.True(formData.IsEstimate2);
            }

            [Fact]
            public void SetFlagsFalseIfNoChargeType()
            {
                var formData = new WorkflowEventControlSaveModel
                {
                    ChargeType = null,
                    IsPayFee = true,
                    IsRaiseCharge = true,
                    IsEstimate = true,
                    IsDirectPay = true,

                    ChargeType2 = null,
                    IsPayFee2 = true,
                    IsRaiseCharge2 = true,
                    IsEstimate2 = true,
                    IsDirectPay2 = true
                };

                WorkflowEventControlService.NormaliseCharges(formData);

                Assert.False(formData.IsPayFee);
                Assert.False(formData.IsRaiseCharge);
                Assert.False(formData.IsEstimate);
                Assert.False(formData.IsDirectPay.GetValueOrDefault());

                Assert.False(formData.IsPayFee2);
                Assert.False(formData.IsRaiseCharge2);
                Assert.False(formData.IsEstimate2);
                Assert.False(formData.IsDirectPay2.GetValueOrDefault());
            }

            [Fact]
            public void SetOtherFlagsFalseIfIsDirectPayment()
            {
                var formData = new WorkflowEventControlSaveModel
                {
                    ChargeType = Fixture.Integer(),
                    IsPayFee = true,
                    IsRaiseCharge = true,
                    IsEstimate = true,
                    IsDirectPay = true,

                    ChargeType2 = Fixture.Integer(),
                    IsPayFee2 = true,
                    IsRaiseCharge2 = true,
                    IsEstimate2 = true,
                    IsDirectPay2 = true
                };

                WorkflowEventControlService.NormaliseCharges(formData);

                Assert.False(formData.IsPayFee);
                Assert.False(formData.IsRaiseCharge);
                Assert.False(formData.IsEstimate);
                Assert.True(formData.IsDirectPay.GetValueOrDefault());

                Assert.False(formData.IsPayFee2);
                Assert.False(formData.IsRaiseCharge2);
                Assert.False(formData.IsEstimate2);
                Assert.True(formData.IsDirectPay2.GetValueOrDefault());
            }
        }

        public class NormaliseRelatedEvents : FactBase
        {
            [Fact]
            public void EventsToUpdateAreFlagged()
            {
                var delta = new Delta<RelatedEventRuleSaveModel>();
                var addModel = new RelatedEventSaveModelBuilder().Build();
                var updateModel = new RelatedEventSaveModelBuilder().Build();
                var deleteModel = new RelatedEventSaveModelBuilder().Build();
                addModel.IsUpdateEvent = false;
                updateModel.IsUpdateEvent = false;
                deleteModel.IsUpdateEvent = false;
                delta.Added.Add(addModel);
                delta.Updated.Add(updateModel);
                delta.Deleted.Add(deleteModel);

                var formData = new WorkflowEventControlSaveModel
                {
                    EventsToUpdateDelta = delta
                };

                WorkflowEventControlService.NormaliseRelatedEvents(formData);

                Assert.True(formData.EventsToUpdateDelta.Added.First().IsUpdateEvent);
                Assert.True(formData.EventsToUpdateDelta.Updated.First().IsUpdateEvent);
                Assert.True(formData.EventsToUpdateDelta.Deleted.First().IsUpdateEvent);
            }

            [Fact]
            public void SatisfyingEventsFromDeltaAreFlagged()
            {
                var delta = new Delta<RelatedEventRuleSaveModel>();
                var addModel = new SatisfyingEventSaveModelBuilder().Build();
                var updateModel = new SatisfyingEventSaveModelBuilder().Build();
                var deleteModel = new SatisfyingEventSaveModelBuilder().Build();
                addModel.IsSatisfyingEvent = false;
                updateModel.IsSatisfyingEvent = false;
                deleteModel.IsSatisfyingEvent = false;
                delta.Added.Add(addModel);
                delta.Updated.Add(updateModel);
                delta.Deleted.Add(deleteModel);

                var formData = new WorkflowEventControlSaveModel
                {
                    SatisfyingEventsDelta = delta
                };

                WorkflowEventControlService.NormaliseRelatedEvents(formData);

                Assert.True(formData.SatisfyingEventsDelta.Added.First().IsSatisfyingEvent);
                Assert.True(formData.SatisfyingEventsDelta.Updated.First().IsSatisfyingEvent);
                Assert.True(formData.SatisfyingEventsDelta.Deleted.First().IsSatisfyingEvent);
            }
        }

        public class NormaliseLoadEvent : FactBase
        {
            [Fact]
            public void NormalisesLoadEventData()
            {
                var formData = new WorkflowEventControlSaveModel
                {
                    CaseOption = SyncedFromCaseOption.NotApplicable,
                    FromEvent = Fixture.Integer(),
                    DateAdjustment = Fixture.String(),
                    FromRelationship = Fixture.String(),
                    LoadNumberType = Fixture.String(),
                    UseCycle = UseCycleOption.CaseRelationship
                };

                WorkflowEventControlService.NormaliseLoadEvent(formData);

                Assert.Null(formData.SyncedEventId);
                Assert.Null(formData.SyncedEventDateAdjustmentId);
                Assert.Null(formData.SyncedCaseRelationshipId);
                Assert.Null(formData.SyncedNumberTypeId);
                Assert.Null(formData.UseReceivingCycle);

                formData = new WorkflowEventControlSaveModel
                {
                    CaseOption = SyncedFromCaseOption.SameCase,
                    FromEvent = Fixture.Integer(),
                    DateAdjustment = Fixture.String(),
                    FromRelationship = Fixture.String(),
                    LoadNumberType = Fixture.String(),
                    UseCycle = UseCycleOption.CaseRelationship
                };

                WorkflowEventControlService.NormaliseLoadEvent(formData);

                Assert.Null(formData.SyncedCaseRelationshipId);
                Assert.Null(formData.SyncedNumberTypeId);
                Assert.Null(formData.UseReceivingCycle);
            }
        }

        public class NormaliseNameChange : FactBase
        {
            [Fact]
            public void NormalisesNameChangeData()
            {
                var formData = new WorkflowEventControlSaveModel
                {
                    ChangeNameTypeCode = Fixture.String(),
                    DeleteCopyFromName = Fixture.Boolean(),
                    MoveOldNameToNameTypeCode = Fixture.String()
                };

                WorkflowEventControlService.NormaliseNameChange(formData);

                Assert.Null(formData.ChangeNameTypeCode);
                Assert.Null(formData.DeleteCopyFromName);
                Assert.Null(formData.MoveOldNameToNameTypeCode);

                formData = new WorkflowEventControlSaveModel
                {
                    CopyFromNameTypeCode = Fixture.String(),
                    DeleteCopyFromName = Fixture.Boolean(),
                    MoveOldNameToNameTypeCode = Fixture.String()
                };

                WorkflowEventControlService.NormaliseNameChange(formData);

                Assert.Null(formData.CopyFromNameTypeCode);
                Assert.Null(formData.DeleteCopyFromName);
                Assert.Null(formData.MoveOldNameToNameTypeCode);
            }
        }
    }
}