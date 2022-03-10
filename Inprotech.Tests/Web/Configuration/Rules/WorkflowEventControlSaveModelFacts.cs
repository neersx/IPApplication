using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEventControlSaveModelFacts
    {
        public class CloneMethod
        {
            [Fact]
            public void MakesACopyOfTheModel()
            {
                var fieldsToUpdate = new EventControlFieldsToUpdate();
                var list = new[] {1, 2, 3, 4};
                fieldsToUpdate.DueDateCalcsDelta.Added = list;
                var childFieldsToUpdate = fieldsToUpdate.Clone();

                Assert.NotSame(fieldsToUpdate.DueDateCalcsDelta.Added, childFieldsToUpdate.DueDateCalcsDelta.Added);
                Assert.Equal(list, childFieldsToUpdate.DueDateCalcsDelta.Added);

                childFieldsToUpdate.DueDateCalcsDelta.Added = new int[0];
                Assert.Equal(list, fieldsToUpdate.DueDateCalcsDelta.Added);
            }
        }

        public class ReminderOptionsMethod
        {
            [Fact]
            public void ReturnsCorrectOption()
            {
                Assert.Equal(ReminderOptions.Alternate, ReminderOptions.DeriveOption(1, 0));
                Assert.Equal(ReminderOptions.SuppressAll, ReminderOptions.DeriveOption(0, 1));
                Assert.Equal(ReminderOptions.Standard, ReminderOptions.DeriveOption(0, 0));
            }
        }

        public class AllOrNoneOptions
        {
            [Theory]
            [InlineData(false, true, true, true, true, true, false)]
            [InlineData(true, false, true, true, true, true, false)]
            [InlineData(true, true, false, true, true, true, false)]
            [InlineData(true, true, true, false, true, true, false)]
            [InlineData(true, true, true, true, false, true, false)]
            [InlineData(true, true, true, true, true, false, false)]
            [InlineData(true, true, true, true, true, true, true)]
            public void DueDateCalcSettingsRequiresAllToBeTrue(bool saveDueDate, bool dateToUse, bool extendPeriod, bool extendPeriodType, bool recalcEventDate, bool suppressDueDateCalculation, bool expectedResult)
            {
                var r = new EventControlFieldsToUpdate
                {
                    IsSaveDueDate = saveDueDate,
                    DateToUse = dateToUse,
                    ExtendPeriod = extendPeriod,
                    ExtendPeriodType = extendPeriodType,
                    RecalcEventDate = recalcEventDate,
                    SuppressDueDateCalculation = suppressDueDateCalculation
                };
                Assert.Equal(expectedResult, r.IsSaveDueDate);
                Assert.Equal(expectedResult, r.DateToUse);
                Assert.Equal(expectedResult, r.ExtendPeriod);
                Assert.Equal(expectedResult, r.ExtendPeriodType);
                Assert.Equal(expectedResult, r.RecalcEventDate);
                Assert.Equal(expectedResult, r.SuppressDueDateCalculation);
            }

            [Theory]
            [InlineData(false, true, true, true, true, true, false)]
            [InlineData(true, false, true, true, true, true, false)]
            [InlineData(true, true, false, true, true, true, false)]
            [InlineData(true, true, true, false, true, true, false)]
            [InlineData(true, true, true, true, false, true, false)]
            [InlineData(true, true, true, true, true, false, false)]
            [InlineData(true, true, true, true, true, true, true)]
            public void LoadEventRequiresAllToBeTrue(bool syncFromCase, bool useReceivingCycle, bool syncEventId, bool syncCaseRelationship, bool syncNumberType, bool syncEventDateAdjustment, bool expectedResult)
            {
                var r = new EventControlFieldsToUpdate
                {
                    SyncedFromCase = syncFromCase,
                    UseReceivingCycle = useReceivingCycle,
                    SyncedEventId = syncEventId,
                    SyncedCaseRelationshipId = syncCaseRelationship,
                    SyncedNumberTypeId = syncNumberType,
                    SyncedEventDateAdjustmentId = syncEventDateAdjustment
                };
                Assert.Equal(expectedResult, r.SyncedFromCase);
                Assert.Equal(expectedResult, r.UseReceivingCycle);
                Assert.Equal(expectedResult, r.SyncedEventId);
                Assert.Equal(expectedResult, r.SyncedCaseRelationshipId);
                Assert.Equal(expectedResult, r.SyncedNumberTypeId);
                Assert.Equal(expectedResult, r.SyncedEventDateAdjustmentId);
            }

            [Theory]
            [InlineData(false, true, true, true, false)]
            [InlineData(true, false, true, true, false)]
            [InlineData(true, true, false, true, false)]
            [InlineData(true, true, true, false, false)]
            [InlineData(true, true, true, true, true)]
            public void NameChangeRequiresAllToBeTrue(bool changeName, bool fromName, bool deleteName, bool moveNameTo, bool expectedResult)
            {
                var r = new EventControlFieldsToUpdate {ChangeNameTypeCode = changeName, CopyFromNameTypeCode = fromName, DeleteCopyFromName = deleteName, MoveOldNameToNameTypeCode = moveNameTo};
                Assert.Equal(expectedResult, r.ChangeNameTypeCode);
                Assert.Equal(expectedResult, r.CopyFromNameTypeCode);
                Assert.Equal(expectedResult, r.DeleteCopyFromName);
                Assert.Equal(expectedResult, r.MoveOldNameToNameTypeCode);
            }

            [Theory]
            [InlineData(false, true, true, true, true, false)]
            [InlineData(true, false, true, true, true, false)]
            [InlineData(true, true, false, true, true, false)]
            [InlineData(true, true, true, false, true, false)]
            [InlineData(true, true, true, true, false, false)]
            [InlineData(true, true, true, true, true, true)]
            public void ChargesRequireAllToBeTrue(bool initialFee, bool isPayFee, bool isRaiseCharge, bool isEstimate, bool isDirectPay, bool expectedResult)
            {
                var r = new EventControlFieldsToUpdate {InitialFeeId = initialFee, IsPayFee = isPayFee, IsRaiseCharge = isRaiseCharge, IsEstimate = isEstimate, IsDirectPayBool = isDirectPay};
                Assert.Equal(expectedResult, r.InitialFeeId);
                Assert.Equal(expectedResult, r.IsPayFee);
                Assert.Equal(expectedResult, r.IsEstimate);
                Assert.Equal(expectedResult, r.IsDirectPayBool);

                r = new EventControlFieldsToUpdate {InitialFee2Id = initialFee, IsPayFee2 = isPayFee, IsRaiseCharge2 = isRaiseCharge, IsEstimate2 = isEstimate, IsDirectPayBool2 = isDirectPay};
                Assert.Equal(expectedResult, r.InitialFee2Id);
                Assert.Equal(expectedResult, r.IsPayFee2);
                Assert.Equal(expectedResult, r.IsEstimate2);
                Assert.Equal(expectedResult, r.IsDirectPayBool2);
            }
        }

        public class DocumentSaveModelFacts
        {
            [Fact]
            public void ConvertsProduceWhenOptions()
            {
                var s = new ReminderRuleSaveModel();
                s.ProduceWhen = ProduceWhenOptions.EventOccurs;
                Assert.Equal(2, s.UpdateEvent);
                s.ProduceWhen = ProduceWhenOptions.OnDueDate;
                Assert.Equal(1, s.UpdateEvent);
                s.ProduceWhen = "The Sun and the Moon meet in the third quarter of the Equinox";
                Assert.Null(s.UpdateEvent);
            }

            [Fact]
            public void ConvertsRaiseChargeOptions()
            {
                var s = new ReminderRuleSaveModel();
                s.IsPayFee = true;
                Assert.Equal("2", s.PayFeeCode);
                s.IsRaiseCharge = true;
                Assert.Equal("3", s.PayFeeCode);
                s.IsPayFee = false;
                Assert.Equal("1", s.PayFeeCode);
                s.IsRaiseCharge = false;
                Assert.Equal("0", s.PayFeeCode);
            }
        }

        [Fact]
        public void WrappedFieldsUpdateBaseValues()
        {
            var model = new WorkflowEventControlSaveModel
            {
                MaxCycles = 1,
                DateToUse = "E",
                RecalcEventDate = true,
                ExtendPeriod = 3,
                ExtendPeriodType = "M",
                DoNotCalculateDueDate = true,
                CaseOption = SyncedFromCaseOption.OriginatingCase,
                UseCycle = UseCycleOption.CaseRelationship,
                FromEvent = 123,
                FromRelationship = "ABC",
                LoadNumberType = "DEF",
                DateAdjustment = "HIJ",
                Report = ReportMode.On,
                ChargeType = 69,
                ChargeType2 = 101,
                PtaDelaySelection = PtaDelayMode.ApplicantDelay
            };

            Assert.Equal((short) 1, model.NumberOfCyclesAllowed);
            Assert.Equal("E", model.DateToUse);
            Assert.Equal(true, model.RecalcEventDate);
            Assert.Equal((short) 3, model.ExtendPeriod);
            Assert.Equal("M", model.ExtendPeriodType);
            Assert.Equal(true, model.SuppressDueDateCalculation);
            Assert.Equal(1, model.SyncedFromCase);
            Assert.Equal(true, model.UseReceivingCycle);
            Assert.Equal(123, model.SyncedEventId);
            Assert.Equal("ABC", model.SyncedCaseRelationshipId);
            Assert.Equal("DEF", model.SyncedNumberTypeId);
            Assert.Equal("HIJ", model.SyncedEventDateAdjustmentId);
            Assert.Equal(1, model.SetThirdPartyOn);
            Assert.Equal(false, model.IsThirdPartyOff);
            Assert.Equal(69, model.InitialFeeId);
            Assert.Equal(101, model.InitialFee2Id);
            Assert.Equal((short)PtaDelayMode.ApplicantDelay, model.PtaDelay);
        }
    }
}