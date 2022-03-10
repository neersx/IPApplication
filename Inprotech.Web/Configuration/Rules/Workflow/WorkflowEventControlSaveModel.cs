using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
#pragma warning disable 618
    public class WorkflowEventControlSaveModel : ValidEvent
#pragma warning restore 618
    {
        SyncedFromCaseOption _syncedFromCaseOption;

        public int OriginatingCriteriaId { get; set; }
        public bool ResetInheritance { get; set; }

        public bool ApplyToDescendants { get; set; }
        public bool ChangeRespOnDueDates { get; set; }

        public string DatesLogicCompare
        {
            set => DatesLogicComparison = value == DatesLogicComparisonType.All.ToString() ? 1 : 0;
        }

        public short? MaxCycles
        {
            set => NumberOfCyclesAllowed = value;
        }

        public bool? DoNotCalculateDueDate
        {
            set => SuppressDueDateCalculation = value;
        }

        public SyncedFromCaseOption CaseOption
        {
            get => _syncedFromCaseOption;
            set
            {
                _syncedFromCaseOption = value;
                SyncedFromCaseOption = value;
            }
        }

        public int? FromEvent
        {
            set => SyncedEventId = value;
        }

        public string FromRelationship
        {
            set => SyncedCaseRelationshipId = value;
        }

        public string LoadNumberType
        {
            set => SyncedNumberTypeId = value;
        }

        public string DateAdjustment
        {
            set => SyncedEventDateAdjustmentId = value;
        }

        public short? Characteristic
        {
            set => FlagNumber = value;
        }

        public ReportMode Report
        {
            set
            {
                IsThirdPartyOn = value == ReportMode.On;
                IsThirdPartyOff = value == ReportMode.Off;
            }
        }

        public int? ChargeType
        {
            set => InitialFeeId = value;
        }

        public int? ChargeType2
        {
            set => InitialFee2Id = value;
        }

        public int? CountryFlagForStopReminders
        {
            set => CheckCountryFlag = value;
        }

        public PtaDelayMode PtaDelaySelection
        {
            set => PtaDelay = value == PtaDelayMode.NotApplicable ? (short?)null : (short)value;
        }

        public DueDateRespTypes DueDateRespType { get; set; }

        public Delta<DueDateCalcSaveModel> DueDateCalcDelta { get; set; } = new Delta<DueDateCalcSaveModel>();

        public Delta<NameTypeMapSaveModel> NameTypeMapDelta { get; set; } = new Delta<NameTypeMapSaveModel>();

        public Delta<int> RequiredEventRulesDelta { get; set; } = new Delta<int>();

        public Delta<DateComparisonSaveModel> DateComparisonDelta { get; set; } = new Delta<DateComparisonSaveModel>();

        public Delta<RelatedEventRuleSaveModel> SatisfyingEventsDelta { get; set; } = new Delta<RelatedEventRuleSaveModel>();

        public Delta<RelatedEventRuleSaveModel> EventsToClearDelta { get; set; } = new Delta<RelatedEventRuleSaveModel>();

        public Delta<RelatedEventRuleSaveModel> EventsToUpdateDelta { get; set; } = new Delta<RelatedEventRuleSaveModel>();

        public Delta<ReminderRuleSaveModel> ReminderRuleDelta { get; set; } = new Delta<ReminderRuleSaveModel>();

        public Delta<ReminderRuleSaveModel> DocumentDelta { get; set; } = new Delta<ReminderRuleSaveModel>();

        public Delta<string> DesignatedJurisdictionsDelta { get; set; } = new Delta<string>();

        public Delta<DatesLogicSaveModel> DatesLogicDelta { get; set; } = new Delta<DatesLogicSaveModel>();
    }

    public interface IEventControlSaveModel
    {
        int OriginalHashKey { get; set; }
        int HashKey();
    }

#pragma warning disable CS0618 // Type or member is obsolete
    public class RelatedEventRuleSaveModel : RelatedEventRule, IEventControlSaveModel
    {
        public int OriginalRelatedEventId { get; set; }

        public short? OriginalRelatedCycleId { get; set; }

        public int? SatisfyingEventId
        {
            set => RelatedEventId = value;
        }

        public short RelativeCycle
        {
            set => RelativeCycleId = value;
        }

        public bool HasEventChanged => OriginalRelatedEventId != RelatedEventId;

        public int? EventToUpdateId
        {
            set => RelatedEventId = value;
        }

        public string AdjustDate
        {
            set => DateAdjustmentId = value;
        }

        public int? EventToClearId
        {
            set => RelatedEventId = value;
        }

        public bool ClearEventOnEventChange
        {
            set => IsClearEvent = value;
            get => IsClearEvent;
        }

        public bool ClearDueDateOnEventChange
        {
            set => IsClearDue = value;
            get => IsClearDue;
        }

        public bool ClearEventOnDueDateChange
        {
            set => ClearEventOnDueChange = value;
            get => ClearEventOnDueChange == true;
        }

        public bool ClearDueDateOnDueDateChange
        {
            set => ClearDueOnDueChange = value;
            get => ClearDueOnDueChange == true;
        }

        public int OriginalHashKey { get; set; }

        public new int HashKey()
        {
            return RelatedEventRuleExt.HashKey(this);
        }
    }
#pragma warning restore CS0618 // Type or member is obsolete

#pragma warning disable 618
    public class DueDateCalcSaveModel : DueDateCalc, IEventControlSaveModel
#pragma warning restore 618
    {
        public short? Period
        {
            get => DeadlinePeriod;
            set => DeadlinePeriod = value;
        }

        public short FromTo
        {
            set => EventDateFlag = value;
        }

        public short? RelCycle
        {
            set => RelativeCycle = value;
        }

        public new bool MustExist
        {
            set => base.MustExist = value.ToDecimal();
            get => base.MustExist == 1;
        }

        public short? DocumentId
        {
            set => OverrideLetterId = value;
        }

        public string AdjustBy
        {
            set => Adjustment = value;
        }

        public string ReminderOption
        {
            set
            {
                Message2Flag = value.Equals(ReminderOptions.Alternate, StringComparison.InvariantCultureIgnoreCase).ToDecimal();
                SuppressReminders = value.Equals(ReminderOptions.SuppressAll, StringComparison.InvariantCultureIgnoreCase).ToDecimal();
            }
        }

        public decimal? NonWorkDay
        {
            set => Workday = value;
        }

        public int OriginalHashKey { get; set; }

        public int HashKey()
        {
            return DueDateCalcExt.HashKey(this);
        }
    }

#pragma warning disable 618
    public class DateComparisonSaveModel : DueDateCalcSaveModel
    {
        public DateComparisonSaveModel()
        {
            CompareEventFlag = 1;
        }

        public int EventAId
        {
            set => FromEventId = value;
        }

        public string EventADate
        {
            set => EventDateFlag = DueDateCalcExt.ParseDateOption(value);
        }

        public short EventARelativeCycle
        {
            set => RelativeCycle = value;
        }

        public string ComparisonOperator
        {
            set => Comparison = value;
        }

        public int? EventBId
        {
            set => CompareEventId = value;
        }

        public string EventBDate
        {
            set => CompareEventFlag = DueDateCalcExt.ParseDateOption(value);
        }

        public short? EventBRelativeCycle
        {
            set => CompareCycle = value;
        }
#pragma warning restore 618
    }

    public static class RelatedEventExtensions
    {
        public static bool AreSatisfyingEvents(this IEnumerable<RelatedEventRuleSaveModel> relatedEvents)
        {
            var re = relatedEvents.ToArray();

            return re.Any() && re.All(_ => _.IsSatisfyingEvent);
        }

        public static bool AreEventsToClear(this IEnumerable<RelatedEventRuleSaveModel> relatedEvents)
        {
            var re = relatedEvents.ToArray();

            return re.Any() && re.All(_ => _.IsClearEventRule);
        }

        public static bool AreEventsToUpdate(this IEnumerable<RelatedEventRuleSaveModel> relatedEvents)
        {
            var re = relatedEvents.ToArray();

            return re.Any() && re.All(_ => _.IsUpdateEvent);
        }
    }

#pragma warning disable CS0618 // Type or member is obsolete
    public class NameTypeMapSaveModel : NameTypeMap, IEventControlSaveModel
    {
        public int OriginalHashKey { get; set; }

        public int HashKey()
        {
            return NameTypeMapExt.HashKey(this);
        }
    }

#pragma warning disable CS0618 // Type or member is obsolete
    public class ReminderRuleSaveModel : ReminderRule, IEventControlSaveModel
    {
        public string StandardMessage
        {
            set => Message1 = value;
        }

        public string AlternateMessage
        {
            set => Message2 = value;
        }

        public bool UseOnAndAfterDueDate
        {
            set => UseMessage1 = value.ToDecimal();
        }

        public bool SendEmail
        {
            get => SendElectronically.GetValueOrDefault() == 1;
            set => SendElectronically = value.ToDecimal();
        }

        public short StartBeforeTime
        {
            set => LeadTime = value;
        }

        public string StartBeforePeriod
        {
            set => PeriodType = value;
        }

        public short RepeatEveryTime
        {
            set => Frequency = value;
        }

        public string RepeatEveryPeriod
        {
            set => FreqPeriodType = value;
        }

        public string StopTimePeriod
        {
            set => StopTimePeriodType = value;
        }

        public bool SendToStaff
        {
            set => EmployeeFlag = value.ToDecimal();
        }

        public bool SendToSignatory
        {
            set => SignatoryFlag = value.ToDecimal();
        }

        public bool SendToCriticalList
        {
            set => CriticalFlag = value.ToDecimal();
        }

        public int? Name
        {
            set => RemindEmployeeId = value;
        }

        public string Relationship
        {
            set => RelationshipId = value;
        }

        public int OriginalHashKey { get; set; }

        public int HashKey()
        {
            return ReminderRuleExt.HashKey(this);
        }

        #region Document Properties

        bool _isPayFee;
        bool _isRaiseCharge;

        public short DocumentId
        {
            set => LetterNo = value;
        }

        public string ProduceWhen
        {
            set
            {
                switch (value)
                {
                    case ProduceWhenOptions.EventOccurs:
                        UpdateEvent = 2;
                        break;
                    case ProduceWhenOptions.OnDueDate:
                        UpdateEvent = 1;
                        break;
                    default:
                        UpdateEvent = null;
                        break;
                }
            }
        }

        public short MaxDocuments
        {
            set => MaxLetters = value;
        }

        public int ChargeType
        {
            set => LetterFeeId = value;
        }

        public bool IsPayFee
        {
            get => _isPayFee;
            set
            {
                _isPayFee = value;
                SetPayFeeCode();
            }
        }

        public bool IsRaiseCharge
        {
            get => _isRaiseCharge;
            set
            {
                _isRaiseCharge = value;
                SetPayFeeCode();
            }
        }

        void SetPayFeeCode()
        {
            PayFeeCode = ((IsPayFee ? 2 : 0) + (IsRaiseCharge ? 1 : 0)).ToString();
        }

        public bool IsEstimate
        {
            set => EstimateFlag = value.ToDecimal();
        }

        public bool IsDirectPay
        {
            set => DirectPayFlag = value;
        }

        public bool IsCheckCycleForSubstitute
        {
            set => CheckOverride = value.ToDecimal();
        }

        #endregion
    }

    public class DatesLogicSaveModel : DatesLogic, IEventControlSaveModel
    {
        public string AppliesTo
        {
            set => DateTypeId = (short) (value == DatesLogicDateType.Event.ToString() ? 1 : 2);
        }

        public string CompareType
        {
            set => CompareDateTypeId = value == "Due" ? (short) DatesLogicCompareDateType.Due : value == "Either" ? (short) DatesLogicCompareDateType.Either : (short) DatesLogicCompareDateType.Event;
        }

        public bool EventMustExist
        {
            set => MustExist = value ? 1 : 0;
        }

        public string IfRuleFails
        {
            set => DisplayErrorFlag = value == DatesLogicDisplayErrorOptions.Warn.ToString() ? 0 : 1;
        }

        public string FailureMessage
        {
            set => ErrorMessage = value;
        }

        public int OriginalHashKey { get; set; }

        public int HashKey()
        {
            return DatesLogicExt.HashKey(this);
        }
    }

    public static class ProduceWhenOptions
    {
        public const string EventOccurs = "eventOccurs";
        public const string OnDueDate = "onDueDate";
        public const string AsScheduled = "asScheduled";
    }

    internal static class BoolExt
    {
        public static decimal ToDecimal(this bool b)
        {
            return b ? 1 : 0;
        }
    }

#pragma warning restore CS0618 // Type or member is obsolete

    public static class ReminderOptions
    {
        public const string Standard = "standard";
        public const string Alternate = "alternate";
        public const string SuppressAll = "suppressAll";

        public static string DeriveOption(decimal? useAlternateReminder, decimal? suppressReminders)
        {
            return useAlternateReminder.GetValueOrDefault() == 1
                ? Alternate
                : (suppressReminders.GetValueOrDefault() == 1
                    ? SuppressAll
                    : Standard);
        }
    }

    // Property names must match ValidEvent properties
    public class EventControlFieldsToUpdate : ICloneable
    {
        bool _basisId = true;
        bool _basisIsThisCase = true;
        bool _caseCategoryId = true;
        bool _caseCategoryIsThisCase = true;
        bool _caseTypeId = true;
        bool _changeNameTypeCode = true;
        bool _closeActionId = true;
        bool _copyFromNameTypeCode = true;
        bool _countryCode = true;
        bool _countryCodeIsThisCase = true;

        bool _dateToUse = true;
        bool _deleteCopyFromName = true;
        bool _dueDateRespNameId = true;
        bool _dueDateRespNameTypeCode = true;
        bool _extendDueDate = true;
        bool _extendPeriod = true;
        bool _extendPeriodType = true;
        bool _flagNumber = true;
        bool _initialFee2Id = true;
        bool _initialFeeId = true;
        bool _instructionType = true;
        bool _isDirectPayBool = true;
        bool _isDirectPayBool2 = true;
        bool _isEstimate = true;
        bool _isEstimate2 = true;
        bool _isPayFee = true;
        bool _isPayFee2 = true;
        bool _isRaiseCharge = true;
        bool _isRaiseCharge2 = true;
        bool _isSaveDueDate = true;
        bool _isThirdPartyOff = true;
        bool _moveOldNameToNameTypeCode = true;

        bool _officeId = true;
        bool _officeIsThisCase = true;

        bool _openActionId = true;
        bool _propertyTypeId = true;
        bool _propertyTypeIsThisCase = true;
        bool _recalcEventDate = true;
        bool _relativeCycle = true;

        bool _setThirdPartyOn = true;
        bool _subTypeId = true;
        bool _subTypeIsThisCase = true;
        bool _suppressDueDateCalculation = true;
        bool _syncedCaseRelationshipId = true;
        bool _syncedEventDateAdjustmentId = true;
        bool _syncedEventId = true;
        bool _syncedFromCase = true;
        bool _syncedNumberTypeId = true;
        bool _useReceivingCycle = true;

        public bool Description { get; set; } = true;
        public bool NumberOfCyclesAllowed { get; set; } = true;
        public bool ImportanceLevel { get; set; } = true;
        public bool Notes { get; set; } = true;
        public bool DatesLogicComparison { get; set; } = true;
        public bool ChangeStatusId { get; set; } = true;
        public bool ChangeRenewalStatusId { get; set; } = true;
        public bool UserDefinedStatus { get; set; } = true;
        public bool CheckCountryFlag { get; set; } = true;

        public bool IsSaveDueDate
        {
            get => AllOrNoneDueDateCalcSettings();
            set => _isSaveDueDate = value;
        }

        public bool DateToUse
        {
            get => AllOrNoneDueDateCalcSettings();
            set => _dateToUse = value;
        }

        public bool ExtendDueDate
        {
            get => AllOrNoneDueDateCalcSettings();
            set => _extendDueDate = value;
        }

        public bool ExtendPeriod
        {
            get => AllOrNoneDueDateCalcSettings();
            set => _extendPeriod = value;
        }

        public bool ExtendPeriodType
        {
            get => AllOrNoneDueDateCalcSettings();
            set => _extendPeriodType = value;
        }

        public bool RecalcEventDate
        {
            get => AllOrNoneDueDateCalcSettings();
            set => _recalcEventDate = value;
        }

        public bool SuppressDueDateCalculation
        {
            get => AllOrNoneDueDateCalcSettings();
            set => _suppressDueDateCalculation = value;
        }

        public bool UpdateEventImmediate { get; set; } = true;
        public bool UpdateEventWhenDue { get; set; } = true;

        public bool SyncedFromCase
        {
            get => AllOrNoneLoadEvent();
            set => _syncedFromCase = value;
        }

        public bool UseReceivingCycle
        {
            get => AllOrNoneLoadEvent();
            set => _useReceivingCycle = value;
        }

        public bool SyncedEventId
        {
            get => AllOrNoneLoadEvent();
            set => _syncedEventId = value;
        }

        public bool SyncedCaseRelationshipId
        {
            get => AllOrNoneLoadEvent();
            set => _syncedCaseRelationshipId = value;
        }

        public bool SyncedNumberTypeId
        {
            get => AllOrNoneLoadEvent();
            set => _syncedNumberTypeId = value;
        }

        public bool SyncedEventDateAdjustmentId
        {
            get => AllOrNoneLoadEvent();
            set => _syncedEventDateAdjustmentId = value;
        }

        public bool OpenActionId
        {
            get => AllOrNoneChangeAction();
            set => _openActionId = value;
        }

        public bool CloseActionId
        {
            get => AllOrNoneChangeAction();
            set => _closeActionId = value;
        }

        public bool RelativeCycle
        {
            get => AllOrNoneChangeAction();
            set => _relativeCycle = value;
        }

        public bool InstructionType
        {
            get => _instructionType && _flagNumber;
            set => _instructionType = value;
        }

        public bool FlagNumber
        {
            get => _instructionType && _flagNumber;
            set => _flagNumber = value;
        }

        // Due Date Responsibility fields are treated as one for inheritance
        public bool DueDateRespNameTypeCode
        {
            get => _dueDateRespNameTypeCode && _dueDateRespNameId;
            set => _dueDateRespNameTypeCode = value;
        }

        public bool DueDateRespNameId
        {
            get => _dueDateRespNameTypeCode && _dueDateRespNameId;
            set => _dueDateRespNameId = value;
        }

        public bool SetThirdPartyOn
        {
            get => _setThirdPartyOn && _isThirdPartyOff;
            set => _setThirdPartyOn = value;
        }

        public bool IsThirdPartyOff
        {
            get => _setThirdPartyOn && _isThirdPartyOff;
            set => _isThirdPartyOff = value;
        }

        public bool ChangeNameTypeCode
        {
            get => AllOrNoneNameChangeSettings();
            set => _changeNameTypeCode = value;
        }

        public bool CopyFromNameTypeCode
        {
            get => AllOrNoneNameChangeSettings();
            set => _copyFromNameTypeCode = value;
        }

        public bool DeleteCopyFromName
        {
            get => AllOrNoneNameChangeSettings();
            set => _deleteCopyFromName = value;
        }

        public bool MoveOldNameToNameTypeCode
        {
            get => AllOrNoneNameChangeSettings();
            set => _moveOldNameToNameTypeCode = value;
        }

        public bool InitialFeeId
        {
            get => AllOrNoneCharge1();
            set => _initialFeeId = value;
        }

        public bool IsPayFee
        {
            get => AllOrNoneCharge1();
            set => _isPayFee = value;
        }

        public bool IsRaiseCharge
        {
            get => AllOrNoneCharge1();
            set => _isRaiseCharge = value;
        }

        public bool IsEstimate
        {
            get => AllOrNoneCharge1();
            set => _isEstimate = value;
        }

        public bool IsDirectPayBool
        {
            get => AllOrNoneCharge1();
            set => _isDirectPayBool = value;
        }

        public bool InitialFee2Id
        {
            get => AllOrNoneCharge2();
            set => _initialFee2Id = value;
        }

        public bool IsPayFee2
        {
            get => AllOrNoneCharge2();
            set => _isPayFee2 = value;
        }

        public bool IsRaiseCharge2
        {
            get => AllOrNoneCharge2();
            set => _isRaiseCharge2 = value;
        }

        public bool IsEstimate2
        {
            get => AllOrNoneCharge2();
            set => _isEstimate2 = value;
        }

        public bool IsDirectPayBool2
        {
            get => AllOrNoneCharge2();
            set => _isDirectPayBool2 = value;
        }

        public bool OfficeId
        {
            get => AllOrNoneEventOccurrence();
            set => _officeId = value;
        }

        public bool OfficeIsThisCase
        {
            get => AllOrNoneEventOccurrence();
            set => _officeIsThisCase = value;
        }

        public bool CaseTypeId
        {
            get => AllOrNoneEventOccurrence();
            set => _caseTypeId = value;
        }

        public bool CountryCode
        {
            get => AllOrNoneEventOccurrence();
            set => _countryCode = value;
        }

        public bool CountryCodeIsThisCase
        {
            get => AllOrNoneEventOccurrence();
            set => _countryCodeIsThisCase = value;
        }

        public bool PropertyTypeId
        {
            get => AllOrNoneEventOccurrence();
            set => _propertyTypeId = value;
        }

        public bool PropertyTypeIsThisCase
        {
            get => AllOrNoneEventOccurrence();
            set => _propertyTypeIsThisCase = value;
        }

        public bool CaseCategoryId
        {
            get => AllOrNoneEventOccurrence();
            set => _caseCategoryId = value;
        }

        public bool CaseCategoryIsThisCase
        {
            get => AllOrNoneEventOccurrence();
            set => _caseCategoryIsThisCase = value;
        }

        public bool SubTypeId
        {
            get => AllOrNoneEventOccurrence();
            set => _subTypeId = value;
        }

        public bool SubTypeIsThisCase
        {
            get => AllOrNoneEventOccurrence();
            set => _subTypeIsThisCase = value;
        }

        public bool BasisId
        {
            get => AllOrNoneEventOccurrence();
            set => _basisId = value;
        }

        public bool BasisIsThisCase
        {
            get => AllOrNoneEventOccurrence();
            set => _basisIsThisCase = value;
        }

        public bool PtaDelay { get; set; } = true;

        public Delta<int> DueDateCalcsDelta { get; set; } = new Delta<int>();
        public Delta<int> NameTypeMapsDelta { get; set; } = new Delta<int>();
        public Delta<int> RequiredEventRulesDelta { get; set; } = new Delta<int>();
        public Delta<int> DateComparisonDelta { get; set; } = new Delta<int>();
        public Delta<int> SatisfyingEventsDelta { get; set; } = new Delta<int>();
        public Delta<int> EventsToClearDelta { get; set; } = new Delta<int>();
        public Delta<int> EventsToUpdateDelta { get; set; } = new Delta<int>();
        public Delta<int> ReminderRulesDelta { get; set; } = new Delta<int>();
        public Delta<int> DocumentsDelta { get; set; } = new Delta<int>();
        public Delta<string> DesignatedJurisdictionsDelta { get; set; } = new Delta<string>();
        public Delta<int> DatesLogicDelta { get; set; } = new Delta<int>();

        object ICloneable.Clone()
        {
            var returnClone = (EventControlFieldsToUpdate) MemberwiseClone();
            returnClone.DueDateCalcsDelta = (Delta<int>) DueDateCalcsDelta?.Clone();
            returnClone.NameTypeMapsDelta = (Delta<int>) NameTypeMapsDelta?.Clone();
            returnClone.RequiredEventRulesDelta = (Delta<int>) RequiredEventRulesDelta?.Clone();
            returnClone.DateComparisonDelta = (Delta<int>) DateComparisonDelta?.Clone();
            returnClone.DesignatedJurisdictionsDelta = (Delta<string>) DesignatedJurisdictionsDelta?.Clone();
            returnClone.DatesLogicDelta = (Delta<int>) DatesLogicDelta?.Clone();

            return returnClone;
        }

        bool AllOrNoneDueDateCalcSettings()
        {
            return _isSaveDueDate && _dateToUse && _extendDueDate && _extendPeriod && _extendPeriodType && _recalcEventDate && _suppressDueDateCalculation;
        }

        bool AllOrNoneLoadEvent()
        {
            return _syncedFromCase && _useReceivingCycle && _syncedEventId && _syncedCaseRelationshipId && _syncedNumberTypeId && _syncedEventDateAdjustmentId;
        }

        bool AllOrNoneNameChangeSettings()
        {
            return _changeNameTypeCode && _copyFromNameTypeCode && _deleteCopyFromName && _moveOldNameToNameTypeCode;
        }

        bool AllOrNoneChangeAction()
        {
            return _openActionId && _closeActionId && _relativeCycle;
        }

        bool AllOrNoneCharge1()
        {
            return _initialFeeId && _isPayFee && _isRaiseCharge && _isEstimate && _isDirectPayBool;
        }

        bool AllOrNoneCharge2()
        {
            return _initialFee2Id && _isPayFee2 && _isRaiseCharge2 && _isEstimate2 && _isDirectPayBool2;
        }

        bool AllOrNoneEventOccurrence()
        {
            return _officeId && _officeIsThisCase
                             && _caseTypeId
                             && _countryCode && _countryCodeIsThisCase
                             && _propertyTypeId && _propertyTypeIsThisCase
                             && _caseCategoryId && _caseCategoryIsThisCase
                             && _subTypeId && _subTypeIsThisCase
                             && _basisId && _basisIsThisCase;
        }

        public EventControlFieldsToUpdate Clone()
        {
            return (EventControlFieldsToUpdate) ((ICloneable) this).Clone();
        }
    }
}