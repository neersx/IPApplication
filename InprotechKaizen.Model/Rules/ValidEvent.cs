using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.StandingInstructions;
using Action = InprotechKaizen.Model.Cases.Action;

namespace InprotechKaizen.Model.Rules
{
    public enum InheritanceLevel
    {
        None,
        Partial,
        Full
    }

    public enum DatesLogicComparisonType
    {
        Any,
        All
    }

    public enum SyncedFromCaseOption
    {
        NotApplicable = -2,
        RelatedCase = -1,
        OriginatingCase = 1,
        SameCase = 0
    }

    public enum UseCycleOption
    {
        RelatedCaseEvent = 0,
        CaseRelationship = 1
    }

    [Table("EVENTCONTROL")]
    public class ValidEvent
    {
        [Obsolete("For persistence only.")]
        public ValidEvent()
        {
        }

        public ValidEvent(Criteria criteria, Event @event, string description = null)
        {
            if (criteria == null) throw new ArgumentNullException(nameof(criteria));
            if (@event == null) throw new ArgumentNullException(nameof(@event));

            CriteriaId = criteria.Id;
            EventId = @event.Id;
            Description = description;
        }

        public ValidEvent(int criteriaId, int eventId, string description = null)
        {
            CriteriaId = criteriaId;
            EventId = eventId;
            Description = description;
        }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("CRITERIANO", Order = 1)]
        public int CriteriaId { get; set; }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("EVENTNO", Order = 2)]
        public int EventId { get; set; }

        [MaxLength(100)]
        [Column("EVENTDESCRIPTION")]
        public string Description { get; set; }

        [Column("EVENTDESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        [Column("NUMCYCLESALLOWED")]
        public short? NumberOfCyclesAllowed { get; set; }

        [Column("STATUSCODE")]
        public short? ChangeStatusId { get; set; }

        [Column("RENEWALSTATUS")]
        public short? ChangeRenewalStatusId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("FLAGNUMBER")]
        public short? FlagNumber { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("CHECKCOUNTRYFLAG")]
        public int? CheckCountryFlag { get; set; }

        [MaxLength(3)]
        [Column("INSTRUCTIONTYPE")]
        public string InstructionType { get; set; }

        [MaxLength(2)]
        [Column("IMPORTANCELEVEL")]
        public string ImportanceLevel { get; set; }

        [Column("DISPLAYSEQUENCE")]
        public short? DisplaySequence { get; set; }

        [Column("PARENTCRITERIANO")]
        public int? ParentCriteriaNo { get; set; }

        [Column("PARENTEVENTNO")]
        public int? ParentEventNo { get; set; }

        [Column("LOGIDENTITYID")]
        public int? LogIdentityId { get; set; }

        [MaxLength(128)]
        [Column("LOGAPPLICATION")]
        public string LogApplication { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastChanged { get; set; }

        [Column("INHERITED")]
        public decimal? Inherited { get; set; }

        [Column("NOTES")]
        public string Notes { get; set; }

        //        [Column("NOTES_TID")]
        //        public int? NotesTid { get; set; }  Notes is not in translationsource even though there is a TId column

        [MaxLength(1)]
        [Column("WHICHDUEDATE")]
        public string DateToUse { get; set; }

        [Column("EXTENDPERIOD")]
        public short? ExtendPeriod { get; set; }

        [MaxLength(1)]
        [Column("EXTENDPERIODTYPE")]
        public string ExtendPeriodType { get; set; }

        [Column("RECALCEVENTDATE")]
        public bool? RecalcEventDate { get; set; }

        [Column("SUPPRESSCALCULATION")]
        public bool? SuppressDueDateCalculation { get; set; }

        [Column("SAVEDUEDATE")]
        public short? SaveDueDate { get; set; }

        [NotMapped]
        public bool IsSaveDueDate
        {
            get => (SaveDueDate & 1) == 1;
            set => SetSaveDueDate(value, 1);
        }

        [NotMapped]
        public bool ExtendDueDate
        {
            get => (SaveDueDate & 8) == 8;
            set => SetSaveDueDate(value, 8);
        }

        [NotMapped]
        public bool UpdateEventImmediate
        {
            get => (SaveDueDate & 2) == 2;
            set => SetSaveDueDate(value, 2);
        }

        [NotMapped]
        public bool UpdateEventWhenDue
        {
            get => (SaveDueDate & 4) == 4;
            set => SetSaveDueDate(value, 4);
        }

        void SetSaveDueDate(bool set, short bit)
        {
            if (SaveDueDate == null)
                SaveDueDate = 0;

            if (set && (SaveDueDate & bit) != bit)
                SaveDueDate += bit;

            if (!set && (SaveDueDate & bit) == bit)
                SaveDueDate -= bit;
        }

        [MaxLength(3)]
        [Column("DUEDATERESPNAMETYPE")]
        public string DueDateRespNameTypeCode { get; set; }

        [Column("DUEDATERESPNAMENO")]
        public int? DueDateRespNameId { get; set; }

        [Column("COMPAREBOOLEAN")]
        public decimal? DatesLogicComparison { get; set; }

        [MaxLength(2)]
        [Column("CREATEACTION")]
        public string OpenActionId { get; set; }

        [MaxLength(2)]
        [Column("CLOSEACTION")]
        public string CloseActionId { get; set; }

        [NotMapped]
        public InheritanceLevel InheritanceLevel { get; set; }

        [NotMapped]
        public DatesLogicComparisonType DatesLogicComparisonType
        {
            // policing treats null as "Any" in ip_PoliceCheckDateComparisons
            get => DatesLogicComparison == 1 ? DatesLogicComparisonType.All : DatesLogicComparisonType.Any;
            set => DatesLogicComparison = value == DatesLogicComparisonType.All ? 1 : 0;
        }

        [ForeignKey("EventId")]
        public virtual Event Event { get; set; }

        [ForeignKey("ImportanceLevel")]
        public virtual Importance Importance { get; set; }

        [ForeignKey("InitialFeeId")]
        public virtual ChargeType InitialFee { get; set; }

        [ForeignKey("InitialFee2Id")]
        public virtual ChargeType InitialFee2 { get; set; }

        public virtual NameType DueDateRespNameType { get; set; }

        public virtual Name Name { get; set; }

        public virtual Characteristic RequiredCharacteristic { get; set; }

        public virtual Status ChangeStatus { get; set; }

        public virtual Status ChangeRenewalStatus { get; set; }

        [ForeignKey("OpenActionId")]
        public virtual Action OpenAction { get; set; }

        [ForeignKey("CloseActionId")]
        public virtual Action CloseAction { get; set; }

        public virtual ICollection<DueDateCalc> DueDateCalcs { get; set; }

        public virtual ICollection<RelatedEventRule> RelatedEvents { get; set; }

        public virtual ICollection<DatesLogic> DatesLogic { get; set; }

        public virtual ICollection<ReminderRule> Reminders { get; set; }

        public virtual ICollection<NameTypeMap> NameTypeMaps { get; set; }

        public virtual ICollection<RequiredEventRule> RequiredEvents { get; set; }

        static bool ChectBitValue(string code, int mask)
        {
            int.TryParse(code, out int val);
            return (val & mask) == mask;
        }

        static string SetBitValue(string code, int mask, bool bit)
        {
            int.TryParse(code, out int val);
            return bit ? (val | mask).ToString() : (val & ~mask).ToString();
        }

        [Column("UPDATEFROMEVENT")]
        public int? SyncedEventId { get; set; }

        [MaxLength(3)]
        [Column("FROMRELATIONSHIP")]
        public string SyncedCaseRelationshipId { get; set; }

        [Column("FROMANCESTOR")]
        public decimal? SyncedFromCase { get; set; }

        [Column("RECEIVINGCYCLEFLAG")]
        public bool? UseReceivingCycle { get; set; }

        [MaxLength(4)]
        [Column("ADJUSTMENT")]
        public string SyncedEventDateAdjustmentId { get; set; }

        [Column("LOADNUMBERTYPE")]
        public string SyncedNumberTypeId { get; set; }

        [Column("RELATIVECYCLE")]
        public short? RelativeCycle { get; set; }

        [MaxLength(1)]
        [Column("SPECIALFUNCTION")]
        public string SpecialFunction { get; set; }

        [MaxLength(50)]
        [Column("STATUSDESC")]
        public string UserDefinedStatus { get; set; }

        [Column("STATUSDESC_TID")]
        public int? UserDefinedStatusTId { get; set; }

        [Column("UPDATEMANUALLY")]
        public decimal? UpdateManually { get; set; }

        [Column("DOCUMENTNO")]
        public short? DocumentId { get; set; }

        [Column("NOOFDOCS")]
        public short? NumberOfDocuments { get; set; }

        [Column("MANDATORYDOCS")]
        public short? MandatoryDocs { get; set; }

        [Column("CREATECYCLE")]
        public short? CreateCycle { get; set; }

        [Column("PTADELAY")]
        public short? PtaDelay { get; set; }

        [Column("OFFICEID")]
        public int? OfficeId { get; set; }

        [Column("OFFICEIDISTHISCASE")]
        public bool? OfficeIsThisCase { get; set; }

        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseTypeId { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; set; }

        [Column("COUNTRYCODEISTHISCASE")]
        public bool? CountryCodeIsThisCase { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [Column("PROPERTYTYPEISTHISCASE")]
        public bool? PropertyTypeIsThisCase { get; set; }

        [MaxLength(2)]
        [Column("CASECATEGORY")]
        public string CaseCategoryId { get; set; }

        [Column("CATEGORYISTHISCASE")]
        public bool? CaseCategoryIsThisCase { get; set; }

        [MaxLength(2)]
        [Column("SUBTYPE")]
        public string SubTypeId { get; set; }

        [Column("SUBTYPEISTHISCASE")]
        public bool? SubTypeIsThisCase { get; set; }

        [MaxLength(2)]
        [Column("BASIS")]
        public string BasisId { get; set; }

        [Column("BASISISTHISCASE")]
        public bool? BasisIsThisCase { get; set; }

        [ForeignKey("SyncedEventId")]
        public virtual Event SyncedEvent { get; set; }

        [ForeignKey("SyncedCaseRelationshipId")]
        public virtual CaseRelation SyncedCaseRelationship { get; set; }

        [ForeignKey("SyncedEventDateAdjustmentId")]
        public virtual DateAdjustment SyncedEventDateAdjustment { get; set; }

        [ForeignKey("SyncedNumberTypeId")]
        public virtual NumberType SyncedNumberType { get; set; }

        [NotMapped]
        public SyncedFromCaseOption SyncedFromCaseOption
        {
            get
            {
                if (SyncedEventId == null) return SyncedFromCaseOption.NotApplicable;
                if (SyncedFromCase == null || !string.IsNullOrEmpty(SyncedCaseRelationshipId)) return SyncedFromCaseOption.RelatedCase;

                return (SyncedFromCaseOption)SyncedFromCase;
            }
            set
            {
                switch (value)
                {
                    case SyncedFromCaseOption.NotApplicable:
                    case SyncedFromCaseOption.RelatedCase:
                        SyncedFromCase = null;
                        break;
                    default:
                        SyncedFromCase = (decimal)value;
                        break;
                }
            }
        }

        [NotMapped]
        public UseCycleOption? UseCycle
        {
            get => (UseCycleOption)(UseReceivingCycle.GetValueOrDefault() ? 1 : 0);
            set
            {
                if (value == null) UseReceivingCycle = null;
                UseReceivingCycle = (int?)value == 1;
            }
        }

        [Column("INITIALFEE")]
        public int? InitialFeeId { get; set; }

        [MaxLength(1)]
        [Column("PAYFEECODE")]
        public string PayFeeCode { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("ESTIMATEFLAG")]
        public decimal? EstimateFlag { get; set; }

        [Column("DIRECTPAYFLAG")]
        public bool? IsDirectPay { get; set; }

        [Column("INITIALFEE2")]
        public int? InitialFee2Id { get; set; }

        [MaxLength(1)]
        [Column("PAYFEECODE2")]
        public string PayFeeCode2 { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("ESTIMATEFLAG2")]
        public decimal? EstimateFlag2 { get; set; }

        [Column("DIRECTPAYFLAG2")]
        public bool? IsDirectPay2 { get; set; }

        [Column("SETTHIRDPARTYOFF")]
        public bool? IsThirdPartyOff { get; set; }

        [Column("SETTHIRDPARTYON")]
        public decimal? SetThirdPartyOn { get; set; }

        [NotMapped]
        public bool? IsThirdPartyOn
        {
            get => SetThirdPartyOn == 1;
            set => SetThirdPartyOn = value == true ? 1 : 0;
        }

        [NotMapped]
        public bool IsRaiseCharge
        {
            get => ChectBitValue(PayFeeCode, 1);
            set => PayFeeCode = SetBitValue(PayFeeCode, 1, value);
        }

        [NotMapped]
        public bool IsPayFee
        {
            get => ChectBitValue(PayFeeCode, 2);
            set => PayFeeCode = SetBitValue(PayFeeCode, 2, value);
        }

        [NotMapped]
        public bool IsEstimate
        {
            get => EstimateFlag.GetValueOrDefault(0) != 0;
            set => EstimateFlag = value ? 1 : 0;
        }

        [NotMapped]
        public bool IsDirectPayBool
        {
            get => IsDirectPay.GetValueOrDefault();
            set => IsDirectPay = value;
        }

        [NotMapped]
        public bool IsRaiseCharge2
        {
            get => ChectBitValue(PayFeeCode2, 1);
            set => PayFeeCode2 = SetBitValue(PayFeeCode2, 1, value);
        }

        [NotMapped]
        public bool IsPayFee2
        {
            get => ChectBitValue(PayFeeCode2, 2);
            set => PayFeeCode2 = SetBitValue(PayFeeCode2, 2, value);
        }

        [NotMapped]
        public bool IsEstimate2
        {
            get => EstimateFlag2.GetValueOrDefault(0) != 0;
            set => EstimateFlag2 = value ? 1 : 0;
        }

        [NotMapped]
        public bool IsDirectPayBool2
        {
            get => IsDirectPay2.GetValueOrDefault();
            set => IsDirectPay2 = value;
        }

        [NotMapped]
        public bool IsInherited
        {
            get => Inherited.GetValueOrDefault(0) != 0;
            set => Inherited = value ? 1 : 0;
        }

        public bool IsCyclic => NumberOfCyclesAllowed > 1;

        [MaxLength(3)]
        [Column("CHANGENAMETYPE")]
        public string ChangeNameTypeCode { get; set; }

        [MaxLength(3)]
        [Column("COPYFROMNAMETYPE")]
        public string CopyFromNameTypeCode { get; set; }

        [MaxLength(3)]
        [Column("COPYTONAMETYPE")]
        public string MoveOldNameToNameTypeCode { get; set; }

        [Column("DELCOPYFROMNAME")]
        public bool? DeleteCopyFromName { get; set; }

        [ForeignKey("ChangeNameTypeCode")]
        public virtual NameType ChangeNameType { get; set; }

        [ForeignKey("CopyFromNameTypeCode")]
        public virtual NameType CopyFromNameType { get; set; }

        [ForeignKey("MoveOldNameToNameTypeCode")]
        public virtual NameType MoveOldNameToNameType { get; set; }

    }

    public static class ValidEventExt
    {
        public static void InheritRulesFrom(this ValidEvent validEvent, ValidEvent from)
        {
            validEvent.CopyFrom(from);
            validEvent.ParentCriteriaNo = from.CriteriaId;
            validEvent.ParentEventNo = from.EventId;
            validEvent.IsInherited = true;
        }

        public static IEnumerable<int> DueDateCalcHashList(this ValidEvent validEvent, bool inheritedOnly = false)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            return validEvent.DueDateCalcs.Where(_ => (!inheritedOnly || _.IsInherited) && !_.IsDateComparison).Select(_ => _.HashKey()).Distinct().ToArray();
        }

        public static IEnumerable<int> GetRequiredEventKeys(this ValidEvent validEvent, bool inheritedOnly)
        {
            return validEvent.RequiredEvents.Where(_ => !inheritedOnly || _.Inherited).Select(_ => _.RequiredEventId).Distinct().ToArray();
        }

        public static IEnumerable<int> NameTypeMapHashList(this ValidEvent validEvent, bool inheritedOnly = false)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            return validEvent.NameTypeMaps.Where(_ => !inheritedOnly || _.Inherited).Select(_ => _.HashKey()).Distinct().ToArray();
        }

        public static IEnumerable<int> DateComparisonHashList(this ValidEvent validEvent, bool inheritedOnly = false)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            return validEvent.DueDateCalcs.Where(_ => (!inheritedOnly || _.IsInherited) && _.IsDateComparison).Select(_ => _.HashKey()).Distinct().ToArray();
        }

        public static IEnumerable<object> SatisfyingEventIds(this ValidEvent validEvent, bool inheritedOnly = false)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            return validEvent.RelatedEvents.Where(_ => (!inheritedOnly || _.IsInherited) && _.IsSatisfyingEvent).Select(_ => new { RelatedEventId = _.RelatedEventId.Value, RelativeCycle = _.RelativeCycleId }).Distinct().ToArray();
        }

        public static IEnumerable<int> EventToClearIds(this ValidEvent validEvent, bool inheritedOnly = false)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            return validEvent.RelatedEvents.WhereEventsToClear().Where(_ => !inheritedOnly || _.IsInherited).Select(_ => _.RelatedEventId.Value).Distinct().ToArray();
        }

        public static IEnumerable<int> EventToUpdateIds(this ValidEvent validEvent, bool inheritedOnly = false)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            return validEvent.RelatedEvents.WhereEventsToUpdate().Where(_ => !inheritedOnly || _.IsInherited).Select(_ => _.RelatedEventId.Value).Distinct().ToArray();
        }

        public static IEnumerable<int> ReminderRuleHashList(this ValidEvent validEvent, bool inheritedOnly = false)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            return validEvent.Reminders.WhereReminder().Where(_ => !inheritedOnly || _.IsInherited).Select(_ => _.HashKey()).Distinct().ToArray();
        }

        public static IEnumerable<int> DocumentsHashList(this ValidEvent validEvent, bool inheritedOnly = false)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            return validEvent.Reminders.WhereDocument().Where(_ => !inheritedOnly || _.IsInherited).Select(_ => _.HashKey()).Distinct().ToArray();
        }

        public static IEnumerable<int> DatesLogicHashList(this ValidEvent validEvent, bool inheritedOnly = false)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            return validEvent.DatesLogic.Where(_ => !inheritedOnly || _.IsInherited).Select(_ => _.HashKey()).Distinct().ToArray();
        }

        static void CopyFrom(this ValidEvent validEvent, ValidEvent from)
        {
            validEvent.Description = from.Description;
            validEvent.NumberOfCyclesAllowed = from.NumberOfCyclesAllowed;
            validEvent.ChangeStatusId = from.ChangeStatusId;
            validEvent.ChangeRenewalStatusId = from.ChangeRenewalStatusId;
            validEvent.FlagNumber = from.FlagNumber;
            validEvent.CheckCountryFlag = from.CheckCountryFlag;
            validEvent.InstructionType = from.InstructionType;
            validEvent.ImportanceLevel = from.ImportanceLevel;
            validEvent.Notes = from.Notes;
            validEvent.DateToUse = from.DateToUse;
            validEvent.ExtendPeriod = from.ExtendPeriod;
            validEvent.ExtendPeriodType = from.ExtendPeriodType;
            validEvent.RecalcEventDate = from.RecalcEventDate;
            validEvent.SuppressDueDateCalculation = from.SuppressDueDateCalculation;
            validEvent.SaveDueDate = from.SaveDueDate;
            validEvent.DueDateRespNameTypeCode = from.DueDateRespNameTypeCode;
            validEvent.DueDateRespNameId = from.DueDateRespNameId;
            validEvent.DatesLogicComparison = from.DatesLogicComparison;
            validEvent.OpenActionId = from.OpenActionId;
            validEvent.CloseActionId = from.CloseActionId;
            validEvent.SyncedEventId = from.SyncedEventId;
            validEvent.SyncedCaseRelationshipId = from.SyncedCaseRelationshipId;
            validEvent.SyncedFromCase = from.SyncedFromCase;
            validEvent.UseReceivingCycle = from.UseReceivingCycle;
            validEvent.SyncedEventDateAdjustmentId = from.SyncedEventDateAdjustmentId;
            validEvent.SyncedNumberTypeId = from.SyncedNumberTypeId;
            validEvent.RelativeCycle = from.RelativeCycle;
            validEvent.SpecialFunction = from.SpecialFunction;
            validEvent.UserDefinedStatus = from.UserDefinedStatus;
            validEvent.UpdateManually = from.UpdateManually;
            validEvent.DocumentId = from.DocumentId;
            validEvent.NumberOfDocuments = from.NumberOfDocuments;
            validEvent.MandatoryDocs = from.MandatoryDocs;
            validEvent.CreateCycle = from.CreateCycle;
            validEvent.PtaDelay = from.PtaDelay;
            validEvent.CaseTypeId = from.CaseTypeId;
            validEvent.CountryCode = from.CountryCode;
            validEvent.CountryCodeIsThisCase = from.CountryCodeIsThisCase;
            validEvent.PropertyTypeId = from.PropertyTypeId;
            validEvent.PropertyTypeIsThisCase = from.PropertyTypeIsThisCase;
            validEvent.CaseCategoryId = from.CaseCategoryId;
            validEvent.CaseCategoryIsThisCase = from.CaseCategoryIsThisCase;
            validEvent.SubTypeId = from.SubTypeId;
            validEvent.SubTypeIsThisCase = from.SubTypeIsThisCase;
            validEvent.BasisId = from.BasisId;
            validEvent.BasisIsThisCase = from.BasisIsThisCase;
            validEvent.OfficeId = from.OfficeId;
            validEvent.OfficeIsThisCase = from.OfficeIsThisCase;
            validEvent.InitialFeeId = from.InitialFeeId;
            validEvent.PayFeeCode = from.PayFeeCode;
            validEvent.EstimateFlag = from.EstimateFlag;
            validEvent.IsDirectPay = from.IsDirectPay;
            validEvent.InitialFee2Id = from.InitialFee2Id;
            validEvent.PayFeeCode2 = from.PayFeeCode2;
            validEvent.EstimateFlag2 = from.EstimateFlag2;
            validEvent.IsDirectPay2 = from.IsDirectPay2;
            validEvent.IsThirdPartyOff = from.IsThirdPartyOff;
            validEvent.SetThirdPartyOn = from.SetThirdPartyOn;
            validEvent.ChangeNameTypeCode = from.ChangeNameTypeCode;
            validEvent.CopyFromNameTypeCode = from.CopyFromNameTypeCode;
            validEvent.MoveOldNameToNameTypeCode = from.MoveOldNameToNameTypeCode;
            validEvent.DeleteCopyFromName = from.DeleteCopyFromName;
        }
    }
}