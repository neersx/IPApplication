using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Rules
{
    [Table("REMINDERS")]
    public class ReminderRule
    {
        [Obsolete("For persistence only.")]
        public ReminderRule()
        {
        }

        public ReminderRule(ValidEvent validEvent, short sequence)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            CriteriaId = validEvent.CriteriaId;
            EventId = validEvent.EventId;
            Sequence = sequence;
        }

        [Key]
        [Column("CRITERIANO", Order = 1)]
        public int CriteriaId { get; set; }

        [Key]
        [Column("EVENTNO", Order = 2)]
        public int EventId { get; set; }

        [Key]
        [Column("REMINDERNO", Order = 3)]
        public short Sequence { get; set; }

        [MaxLength(1)]
        [Column("PERIODTYPE")]
        public string PeriodType { get; set; }

        [Column("LEADTIME")]
        public short? LeadTime { get; set; }

        [Column("FREQUENCY")]
        public short? Frequency { get; set; }

        [Column("STOPTIME")]
        public short? StopTime { get; set; }

        [Column("UPDATEEVENT")]
        public decimal? UpdateEvent { get; set; }

        [Column("LETTERNO")]
        public short? LetterNo { get; set; }

        [Column("CHECKOVERRIDE")]
        public decimal? CheckOverride { get; set; }

        [Column("MAXLETTERS")]
        public short? MaxLetters { get; set; }

        [Column("LETTERFEE")]
        public int? LetterFeeId { get; set; }

        [MaxLength(1)]
        [Column("PAYFEECODE")]
        public string PayFeeCode { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("EMPLOYEEFLAG")]
        public decimal? EmployeeFlag { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("SIGNATORYFLAG")]
        public decimal? SignatoryFlag { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("INSTRUCTORFLAG")]
        public decimal? InstructorFlag { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("CRITICALFLAG")]
        public decimal? CriticalFlag { get; set; }

        [Column("REMINDEMPLOYEE")]
        public int? RemindEmployeeId { get; set; }

        [Column("USEMESSAGE1")]
        public decimal? UseMessage1 { get; set; }
        
        [Column("MESSAGE1")]
        public string Message1 { get; set; }

        [Column("MESSAGE1_TID")]
        public int? Message1TId { get; set; }

        [Column("MESSAGE2")]
        public string Message2 { get; set; }

        [Column("MESSAGE2_TID")]
        public int? Message2TId { get; set; }

        [Column("INHERITED")]
        public decimal? Inherited { get; set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameTypeId { get; set; }

        [Column("SENDELECTRONICALLY")]
        public decimal? SendElectronically { get; set; }

        [MaxLength(100)]
        [Column("EMAILSUBJECT")]
        public string EmailSubject { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("ESTIMATEFLAG")]
        public decimal? EstimateFlag { get; set; }

        [MaxLength(1)]
        [Column("FREQPERIODTYPE")]
        public string FreqPeriodType { get; set; }

        [MaxLength(1)]
        [Column("STOPTIMEPERIODTYPE")]
        public string StopTimePeriodType { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("DIRECTPAYFLAG")]
        public bool? DirectPayFlag { get; set; }

        [MaxLength(3)]
        [Column("RELATIONSHIP")]
        public string RelationshipId { get; set; }

        [MaxLength(254)]
        [Column("EXTENDEDNAMETYPE")]
        public string ExtendedNameType { get; set; }

        [NotMapped]
        public IEnumerable<string> NameTypes
        {
            get { return (NameTypeId ?? ExtendedNameType) == null ? new string[0] : (NameTypeId ?? ExtendedNameType).Split(';').Select(_ => _.Trim()); }
            set
            {
                if (value == null || !value.Any())
                {
                    NameTypeId = null;
                    ExtendedNameType = null;
                    return;
                }

                NameTypeId = value.Count() == 1 ? value.Single() : null;
                ExtendedNameType = value.Count() == 1 ? null : string.Join(";", value);
            }
        }

        public virtual ValidEvent ValidEvent { get; set; }

        public virtual NameRelation NameRelation { get; set; }

        public virtual Document Letter { get; set; }

        public virtual Name RemindEmployee { get; set; }

        public virtual NameType NameType { get; set; }

        public virtual ChargeType LetterFee { get; set; }

        [NotMapped]
        public bool IsInherited
        {
            get { return Inherited == 1; }
            set { Inherited = value ? 1 : 0; }
        }
    }

    public static class ReminderRuleExt
    {
        public static int HashKey(this ReminderRule rule)
        {
            if (rule == null) throw new ArgumentNullException(nameof(rule));

            if (rule.IsReminderRule())
            {
                return new
                       {
                           rule.Message1,
                           rule.Message2,
                           rule.UseMessage1,
                           rule.SendElectronically,
                           rule.EmailSubject,
                           rule.LeadTime,
                           rule.PeriodType,
                           rule.Frequency,
                           rule.FreqPeriodType,
                           rule.StopTime,
                           rule.StopTimePeriodType,
                           rule.EmployeeFlag,
                           rule.SignatoryFlag,
                           rule.CriticalFlag,
                           RemindEmployee = rule.RemindEmployeeId,
                           rule.NameType,
                           rule.ExtendedNameType,
                           Relationship = rule.RelationshipId
                       }.GetHashCode();
            }

            return new
                   {
                       rule.LetterNo,
                       rule.UpdateEvent,
                       rule.LeadTime,
                       rule.PeriodType,
                       rule.Frequency,
                       rule.FreqPeriodType,
                       rule.StopTime,
                       rule.StopTimePeriodType,
                       rule.MaxLetters,
                       rule.LetterFeeId,
                       rule.PayFeeCode,
                       rule.EstimateFlag,
                       rule.DirectPayFlag,
                       rule.CheckOverride
                   }.GetHashCode();
        }

        public static bool IsReminderRule(this ReminderRule rule)
        {
            if (rule == null) throw new ArgumentNullException(nameof(rule));

            return !string.IsNullOrWhiteSpace(rule.Message1) || !string.IsNullOrEmpty(rule.Message2);
        }

        public static IEnumerable<ReminderRule> WhereReminder(this IEnumerable<ReminderRule> reminderRules)
        {
            return reminderRules.Where(_ => _.IsReminderRule());
        }

        [SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "ToDays")]
        public static int LeadTimeToDays(this ReminderRule reminderRule)
        {
            if (reminderRule == null) throw new ArgumentNullException(nameof(reminderRule));

            var days = 1;
            switch (reminderRule.PeriodType)
            {
                case "W":
                    days = 7;
                    break;
                case "M":
                    days = 30;
                    break;
                case "Y":
                    days = 365;
                    break;
            }

            return reminderRule.LeadTime.GetValueOrDefault() * days;
        }

        public static IEnumerable<ReminderRule> WhereDocument(this IEnumerable<ReminderRule> reminderRules)
        {
            return reminderRules.Where(_ => _.LetterNo != null);
        }

        public static ReminderRule InheritRuleFrom(this ReminderRule reminderRule, ReminderRule from)
        {
            if (reminderRule == null) throw new ArgumentNullException(nameof(reminderRule));
            if (from == null) throw new ArgumentNullException(nameof(from));

            reminderRule.IsInherited = true;
            reminderRule.CopyFrom(from);
            return reminderRule;
        }

        public static ReminderRule CopyFrom(this ReminderRule reminderRule, ReminderRule from, bool? isInherited = null)
        {
            if (reminderRule == null) throw new ArgumentNullException(nameof(reminderRule));
            if (from == null) throw new ArgumentNullException(nameof(from));

            if (isInherited.HasValue)
            {
                reminderRule.IsInherited = isInherited.Value;
            }

            reminderRule.PeriodType = from.PeriodType;
            reminderRule.LeadTime = from.LeadTime;
            reminderRule.Frequency = from.Frequency;
            reminderRule.StopTime = from.StopTime;
            reminderRule.UpdateEvent = from.UpdateEvent;
            reminderRule.LetterNo = from.LetterNo;
            reminderRule.CheckOverride = from.CheckOverride;
            reminderRule.MaxLetters = from.MaxLetters;
            reminderRule.LetterFeeId = from.LetterFeeId;
            reminderRule.PayFeeCode = from.PayFeeCode;
            reminderRule.EmployeeFlag = from.EmployeeFlag;
            reminderRule.SignatoryFlag = from.SignatoryFlag;
            reminderRule.InstructorFlag = from.InstructorFlag;
            reminderRule.CriticalFlag = from.CriticalFlag;
            reminderRule.RemindEmployeeId = from.RemindEmployeeId;
            reminderRule.UseMessage1 = from.UseMessage1;
            reminderRule.Message1 = from.Message1;
            reminderRule.Message2 = from.Message2;
            reminderRule.NameTypeId = from.NameTypeId;
            reminderRule.SendElectronically = from.SendElectronically;
            reminderRule.EmailSubject = from.EmailSubject;
            reminderRule.EstimateFlag = from.EstimateFlag;
            reminderRule.FreqPeriodType = from.FreqPeriodType;
            reminderRule.StopTimePeriodType = from.StopTimePeriodType;
            reminderRule.DirectPayFlag = from.DirectPayFlag;
            reminderRule.RelationshipId = from.RelationshipId;
            reminderRule.ExtendedNameType = from.ExtendedNameType;

            return reminderRule;
        }
    }
}