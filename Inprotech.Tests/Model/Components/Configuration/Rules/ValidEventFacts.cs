using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.Rules
{
    public class ValidEventFacts
    {
        public class SaveDueDateFlags
        {
            [Fact]
            public void CombinesBitwiseFlags()
            {
                var subject = new ValidEventBuilder().Build();
                subject.SaveDueDate = 0;
                subject.IsSaveDueDate = true;
                subject.ExtendDueDate = true;
                subject.UpdateEventImmediate = true;
                subject.UpdateEventWhenDue = true;
                Assert.Equal((short) 15, subject.SaveDueDate);

                subject.UpdateEventWhenDue = false;
                subject.UpdateEventImmediate = false;
                subject.ExtendDueDate = false;
                subject.IsSaveDueDate = false;
                Assert.Equal((short) 0, subject.SaveDueDate);
            }

            [Fact]
            public void ReturnsExtendDueDateBitwiseFlag()
            {
                var subject = new ValidEventBuilder().Build();
                subject.SaveDueDate = 0;
                subject.ExtendDueDate = true;
                Assert.Equal((short) 8, subject.SaveDueDate);
                Assert.True(subject.ExtendDueDate);
            }

            [Fact]
            public void ReturnsIsSaveDueDateBitwiseFlag()
            {
                var subject = new ValidEventBuilder().Build();
                subject.SaveDueDate = 0;
                subject.IsSaveDueDate = true;
                Assert.Equal((short) 1, subject.SaveDueDate);
            }

            [Fact]
            public void ReturnsUpdateEventImmediateBitwiseFlag()
            {
                var subject = new ValidEventBuilder().Build();
                subject.SaveDueDate = 0;
                subject.UpdateEventImmediate = true;
                Assert.Equal((short) 2, subject.SaveDueDate);
                Assert.True(subject.UpdateEventImmediate);
            }

            [Fact]
            public void ReturnsUpdateEventWhenDueBitwiseFlag()
            {
                var subject = new ValidEventBuilder().Build();
                subject.SaveDueDate = 0;
                subject.UpdateEventWhenDue = true;
                Assert.Equal((short) 4, subject.SaveDueDate);
                Assert.True(subject.UpdateEventWhenDue);
            }
        }

        public class DatesLogicComparisonTypeProperty
        {
            [Theory]
            [InlineData(null)]
            [InlineData(0)]
            public void ReturnsAnyByDefault(int? anyComparsionType)
            {
                var subject = new ValidEvent(new CriteriaBuilder().Build().Id, new EventBuilder().Build().Id, Fixture.String("Description")) {DatesLogicComparison = anyComparsionType};

                Assert.Equal(DatesLogicComparisonType.Any, subject.DatesLogicComparisonType);
            }

            [Fact]
            public void ReturnsAllWhenComparisonFlagIsOn()
            {
                var subject = new ValidEvent(new CriteriaBuilder().Build().Id, new EventBuilder().Build().Id, Fixture.String("Description")) {DatesLogicComparison = 1};

                Assert.Equal(DatesLogicComparisonType.All, subject.DatesLogicComparisonType);
            }
        }

        public class LoadEventFromAnotherEventFacts
        {
            [Fact]
            public void ReturnsSyncedFromCaseEnumOption()
            {
                var subject = new ValidEvent(new CriteriaBuilder().Build().Id, new EventBuilder().Build().Id, Fixture.String("Description")) {SyncedFromCase = null};

                Assert.Equal(SyncedFromCaseOption.NotApplicable, subject.SyncedFromCaseOption);

                subject.SyncedEventId = 1;
                Assert.Equal(SyncedFromCaseOption.RelatedCase, subject.SyncedFromCaseOption);

                subject.SyncedFromCase = 1;
                Assert.Equal(SyncedFromCaseOption.OriginatingCase, subject.SyncedFromCaseOption);

                subject.SyncedFromCase = 0;
                Assert.Equal(SyncedFromCaseOption.SameCase, subject.SyncedFromCaseOption);

                subject.SyncedCaseRelationshipId = "BAR";
                Assert.Equal(SyncedFromCaseOption.RelatedCase, subject.SyncedFromCaseOption);
            }
        }

        public class IsRaisedChargeProperty
        {
            [Theory]
            [InlineData(null, false)]
            [InlineData("2", false)]
            [InlineData("1", true)]
            public void ReturnBasedOnPayFeeCode(string payFeeCode, bool result)
            {
                var subject = new ValidEvent(new CriteriaBuilder().Build().Id, new EventBuilder().Build().Id, Fixture.String("Description")) {PayFeeCode = payFeeCode};
                Assert.Equal(subject.IsRaiseCharge, result);
            }
        }

        public class IsPayFeeProperty
        {
            [Theory]
            [InlineData(null, false)]
            [InlineData("2", true)]
            [InlineData("1", false)]
            public void ReturnBasedOnPayFeeCode(string payFeeCode, bool result)
            {
                var subject = new ValidEvent(new CriteriaBuilder().Build().Id, new EventBuilder().Build().Id, Fixture.String("Description")) {PayFeeCode = payFeeCode};
                Assert.Equal(subject.IsPayFee, result);
            }
        }

        public class IsEstimateProperty
        {
            [Theory]
            [InlineData(null, false)]
            [InlineData(1, true)]
            [InlineData(0, false)]
            public void ReturnBasedOnEstimateFlag(int? estimateFlag, bool result)
            {
                var subject = new ValidEvent(new CriteriaBuilder().Build().Id, new EventBuilder().Build().Id, Fixture.String("Description")) {EstimateFlag = estimateFlag};
                Assert.Equal(subject.IsEstimate, result);
            }
        }

        public class IsRaisedCharge2Property
        {
            [Theory]
            [InlineData(null, false)]
            [InlineData("2", false)]
            [InlineData("1", true)]
            public void ReturnBasedOnPayFeeCode(string payFeeCode, bool result)
            {
                var subject = new ValidEvent(new CriteriaBuilder().Build().Id, new EventBuilder().Build().Id, Fixture.String("Description")) {PayFeeCode2 = payFeeCode};
                Assert.Equal(subject.IsRaiseCharge2, result);
            }
        }

        public class IsPayFee2Property
        {
            [Theory]
            [InlineData(null, false)]
            [InlineData("2", true)]
            [InlineData("1", false)]
            public void ReturnBasedOnPayFeeCode(string payFeeCode, bool result)
            {
                var subject = new ValidEvent(new CriteriaBuilder().Build().Id, new EventBuilder().Build().Id, Fixture.String("Description")) {PayFeeCode2 = payFeeCode};
                Assert.Equal(subject.IsPayFee2, result);
            }
        }

        public class IsEstimate2Property
        {
            [Theory]
            [InlineData(null, false)]
            [InlineData(1, true)]
            [InlineData(0, false)]
            public void ReturnBasedOnEstimateFlag(int? estimateFlag, bool result)
            {
                var subject = new ValidEvent(new CriteriaBuilder().Build().Id, new EventBuilder().Build().Id, Fixture.String("Description")) {EstimateFlag2 = estimateFlag};
                Assert.Equal(subject.IsEstimate2, result);
            }
        }

        public class InheritFromMethod
        {
            [Fact]
            public void CopiesPropertiesAndSetsInheritedFlag()
            {
                var subject = new ValidEvent(new CriteriaBuilder().Build(), new EventBuilder().Build());
                var fromEvent = new ValidEvent(new CriteriaBuilder().Build(), new EventBuilder().Build());

                DataFiller.Fill(fromEvent);
                fromEvent.IsInherited = false;

                subject.InheritRulesFrom(fromEvent);

                Assert.NotEqual(fromEvent.CriteriaId, subject.CriteriaId);
                Assert.NotEqual(fromEvent.DescriptionTId, subject.DescriptionTId);
                Assert.NotEqual(fromEvent.DisplaySequence, subject.DisplaySequence);
                Assert.NotEqual(fromEvent.ParentCriteriaNo, subject.ParentCriteriaNo);
                Assert.NotEqual(fromEvent.EventId, subject.EventId);
                Assert.NotEqual(fromEvent.ParentEventNo, subject.ParentEventNo);
                Assert.NotEqual(fromEvent.Inherited, subject.Inherited);

                Assert.True(subject.IsInherited);
                Assert.Equal(fromEvent.CriteriaId, subject.ParentCriteriaNo);
                Assert.Equal(fromEvent.EventId, subject.ParentEventNo);
                Assert.Equal(fromEvent.Description, subject.Description);
                Assert.Equal(fromEvent.NumberOfCyclesAllowed, subject.NumberOfCyclesAllowed);
                Assert.Equal(fromEvent.ChangeStatusId, subject.ChangeStatusId);
                Assert.Equal(fromEvent.ChangeRenewalStatusId, subject.ChangeRenewalStatusId);
                Assert.Equal(fromEvent.FlagNumber, subject.FlagNumber);
                Assert.Equal(fromEvent.CheckCountryFlag, subject.CheckCountryFlag);
                Assert.Equal(fromEvent.InstructionType, subject.InstructionType);
                Assert.Equal(fromEvent.ImportanceLevel, subject.ImportanceLevel);
                Assert.Equal(fromEvent.Notes, subject.Notes);
                Assert.Equal(fromEvent.DateToUse, subject.DateToUse);
                Assert.Equal(fromEvent.ExtendPeriod, subject.ExtendPeriod);
                Assert.Equal(fromEvent.ExtendPeriodType, subject.ExtendPeriodType);
                Assert.Equal(fromEvent.RecalcEventDate, subject.RecalcEventDate);
                Assert.Equal(fromEvent.SuppressDueDateCalculation, subject.SuppressDueDateCalculation);
                Assert.Equal(fromEvent.SaveDueDate, subject.SaveDueDate);
                Assert.Equal(fromEvent.DueDateRespNameTypeCode, subject.DueDateRespNameTypeCode);
                Assert.Equal(fromEvent.DueDateRespNameId, subject.DueDateRespNameId);
                Assert.Equal(fromEvent.DatesLogicComparison, subject.DatesLogicComparison);
                Assert.Equal(fromEvent.OpenActionId, subject.OpenActionId);
                Assert.Equal(fromEvent.CloseActionId, subject.CloseActionId);
                Assert.Equal(fromEvent.SyncedEventId, subject.SyncedEventId);
                Assert.Equal(fromEvent.SyncedCaseRelationshipId, subject.SyncedCaseRelationshipId);
                Assert.Equal(fromEvent.SyncedFromCase, subject.SyncedFromCase);
                Assert.Equal(fromEvent.UseReceivingCycle, subject.UseReceivingCycle);
                Assert.Equal(fromEvent.SyncedEventDateAdjustmentId, subject.SyncedEventDateAdjustmentId);
                Assert.Equal(fromEvent.SyncedNumberTypeId, subject.SyncedNumberTypeId);
                Assert.Equal(fromEvent.RelativeCycle, subject.RelativeCycle);
                Assert.Equal(fromEvent.SpecialFunction, subject.SpecialFunction);
                Assert.Equal(fromEvent.UserDefinedStatus, subject.UserDefinedStatus);
                Assert.Equal(fromEvent.UpdateManually, subject.UpdateManually);
                Assert.Equal(fromEvent.DocumentId, subject.DocumentId);
                Assert.Equal(fromEvent.NumberOfDocuments, subject.NumberOfDocuments);
                Assert.Equal(fromEvent.MandatoryDocs, subject.MandatoryDocs);
                Assert.Equal(fromEvent.CreateCycle, subject.CreateCycle);
                Assert.Equal(fromEvent.PtaDelay, subject.PtaDelay);
                Assert.Equal(fromEvent.CaseTypeId, subject.CaseTypeId);
                Assert.Equal(fromEvent.CountryCode, subject.CountryCode);
                Assert.Equal(fromEvent.CountryCodeIsThisCase, subject.CountryCodeIsThisCase);
                Assert.Equal(fromEvent.PropertyTypeId, subject.PropertyTypeId);
                Assert.Equal(fromEvent.PropertyTypeIsThisCase, subject.PropertyTypeIsThisCase);
                Assert.Equal(fromEvent.CaseCategoryId, subject.CaseCategoryId);
                Assert.Equal(fromEvent.CaseCategoryIsThisCase, subject.CaseCategoryIsThisCase);
                Assert.Equal(fromEvent.SubTypeId, subject.SubTypeId);
                Assert.Equal(fromEvent.SubTypeIsThisCase, subject.SubTypeIsThisCase);
                Assert.Equal(fromEvent.BasisId, subject.BasisId);
                Assert.Equal(fromEvent.BasisIsThisCase, subject.BasisIsThisCase);
                Assert.Equal(fromEvent.OfficeId, subject.OfficeId);
                Assert.Equal(fromEvent.OfficeIsThisCase, subject.OfficeIsThisCase);
                Assert.Equal(fromEvent.InitialFeeId, subject.InitialFeeId);
                Assert.Equal(fromEvent.PayFeeCode, subject.PayFeeCode);
                Assert.Equal(fromEvent.EstimateFlag, subject.EstimateFlag);
                Assert.Equal(fromEvent.IsDirectPay, subject.IsDirectPay);
                Assert.Equal(fromEvent.InitialFee2Id, subject.InitialFee2Id);
                Assert.Equal(fromEvent.PayFeeCode2, subject.PayFeeCode2);
                Assert.Equal(fromEvent.EstimateFlag2, subject.EstimateFlag2);
                Assert.Equal(fromEvent.IsDirectPay2, subject.IsDirectPay2);
                Assert.Equal(fromEvent.IsThirdPartyOff, subject.IsThirdPartyOff);
                Assert.Equal(fromEvent.SetThirdPartyOn, subject.SetThirdPartyOn);
                Assert.Equal(fromEvent.ChangeNameTypeCode, subject.ChangeNameTypeCode);
                Assert.Equal(fromEvent.CopyFromNameTypeCode, subject.CopyFromNameTypeCode);
                Assert.Equal(fromEvent.MoveOldNameToNameTypeCode, subject.MoveOldNameToNameTypeCode);
                Assert.Equal(fromEvent.DeleteCopyFromName, subject.DeleteCopyFromName);
            }
        }
    }
}