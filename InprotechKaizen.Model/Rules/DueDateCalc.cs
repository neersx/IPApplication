using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Documents;

namespace InprotechKaizen.Model.Rules
{
    [Table("DUEDATECALC")]
    public class DueDateCalc
    {
        [Obsolete("For persistence only.")]
        public DueDateCalc()
        {
        }

        public DueDateCalc(ValidEvent validEvent, short sequence) : this(validEvent.CriteriaId, validEvent.EventId, sequence)
        {
        }

        public DueDateCalc(int criteriaId, int eventId, short sequence)
        {
            CriteriaId = criteriaId;
            EventId = eventId;
            Sequence = sequence;
            Inherited = 0;
        }

        [Key]
        [Column("CRITERIANO", Order = 1)]
        public int CriteriaId { get; set; }

        [Key]
        [Column("EVENTNO", Order = 2)]
        public int EventId { get; set; }

        [Key]
        [Column("SEQUENCE", Order = 3)]
        public short Sequence { get; set; }

        [Column("CYCLENUMBER")]
        public short? Cycle { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string JurisdictionId { get; set; }

        [Column("FROMEVENT")]
        public int? FromEventId { get; set; }

        [Column("RELATIVECYCLE")]
        public short? RelativeCycle { get; set; }

        [MaxLength(1)]
        [Column("OPERATOR")]
        public string Operator { get; set; }

        [Column("DEADLINEPERIOD")]
        public short? DeadlinePeriod { get; set; }

        [MaxLength(1)]
        [Column("PERIODTYPE")]
        public string PeriodType { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("EVENTDATEFLAG")]
        public short? EventDateFlag { get; set; }

        [MaxLength(4)]
        [Column("ADJUSTMENT")]
        public string Adjustment { get; set; }

        [Column("MUSTEXIST")]
        public decimal? MustExist { get; set; }

        [MaxLength(2)]
        [Column("COMPARISON")]
        public string Comparison { get; set; }

        [Column("COMPAREEVENT")]
        public int? CompareEventId { get; set; }

        [Column("WORKDAY")]
        public decimal? Workday { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("MESSAGE2FLAG")]
        public decimal? Message2Flag { get; set; }

        [Column("SUPPRESSREMINDERS")]
        public decimal? SuppressReminders { get; set; }

        [Column("OVERRIDELETTER")]
        public short? OverrideLetterId { get; set; }

        [Column("INHERITED")]
        public decimal? Inherited { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("COMPAREEVENTFLAG")]
        public short? CompareEventFlag { get; set; }

        [Column("COMPARECYCLE")]
        public short? CompareCycle { get; set; }

        [MaxLength(3)]
        [Column("COMPARERELATIONSHIP")]
        public string CompareRelationshipId { get; set; }

        [Column("COMPAREDATE")]
        public DateTime? CompareDate { get; set; }

        [Column("COMPARESYSTEMDATE")]
        public bool? CompareSystemDate { get; set; }

        public virtual Criteria Criteria { get; set; }

        public virtual ValidEvent ValidEvent { get; set; }

        public virtual Event FromEvent { get; set; }

        public virtual Event CompareEvent { get; set; }

        public virtual Country Jurisdiction { get; set; }

        public virtual Document OverrideLetter { get; set; }

        public virtual CaseRelation CompareRelationship { get; set; }

        [NotMapped]
        public bool IsInherited
        {
            get { return Inherited == 1; }
            set { Inherited = value ? 1 : 0; }
        }

        [NotMapped]
        public bool IsDateComparison => Comparison != null;

        [NotMapped]
        public bool IsDesignatedJurisdiction => !string.IsNullOrEmpty(JurisdictionId) && FromEventId == null;
    }

    public static class DueDateCalcExt
    {
        [SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
        public enum DateOption
        {
            Event = 1,
            Due = 2,
            EventOrDue = 3
        }

        public static short? ParseDateOption(string dateOption)
        {
            if (string.IsNullOrEmpty(dateOption))
            {
                return null;
            }

            Enum.TryParse(dateOption, out DateOption option);
            return (short?) option;
        }

        public static int HashKey(this DueDateCalc dueDateCalc)
        {
            if (dueDateCalc == null) throw new ArgumentNullException(nameof(dueDateCalc));

            return dueDateCalc.IsDateComparison 
                ? new {dueDateCalc.FromEventId, dueDateCalc.RelativeCycle, dueDateCalc.EventDateFlag, dueDateCalc.Comparison, dueDateCalc.CompareEventId, dueDateCalc.CompareCycle, dueDateCalc.CompareEventFlag, dueDateCalc.CompareRelationshipId, dueDateCalc.CompareSystemDate, dueDateCalc.CompareDate}.GetHashCode() 
                : new {dueDateCalc.Cycle, JurisdictionCode = dueDateCalc.JurisdictionId, dueDateCalc.FromEventId, dueDateCalc.RelativeCycle, dueDateCalc.PeriodType, dueDateCalc.DeadlinePeriod}.GetHashCode();
        }

        public static IQueryable<DueDateCalc> WhereDueDateCalc(this IQueryable<DueDateCalc> dueDateCalc)
        {
            return dueDateCalc.Where(d => d.Comparison == null && d.FromEventId != null);
        }

        public static IQueryable<DueDateCalc> WhereDateComparison(this IQueryable<DueDateCalc> dueDateCalc)
        {
            return dueDateCalc.Where(d => d.Comparison != null);
        }

        public static IQueryable<DueDateCalc> WhereDesignatedJurisdiction(this IQueryable<DueDateCalc> dueDateCalc)
        {
            return dueDateCalc.Where(d => !string.IsNullOrEmpty(d.JurisdictionId) && d.FromEventId == null);
        }

        public static DueDateCalc InheritRuleFrom(this DueDateCalc dueDateCalc, DueDateCalc from)
        {
            dueDateCalc.CopyFrom(from, true);
            return dueDateCalc;
        }

        public static ICollection<string> GetDesignatedJurisdictions(this ICollection<DueDateCalc> dueDateCalc, bool inheritedOnly)
        {
            return dueDateCalc.Where(_ => _.IsDesignatedJurisdiction && (!inheritedOnly || _.IsInherited)).Select(_ => _.JurisdictionId).ToList();
        }

        public static DueDateCalc CopyFrom(this DueDateCalc dueDateCalc, DueDateCalc from, bool? isInherited = null)
        {
            if (dueDateCalc == null) throw new ArgumentNullException(nameof(dueDateCalc));
            if (from == null) throw new ArgumentNullException(nameof(from));

            if (isInherited.HasValue)
            {
                dueDateCalc.IsInherited = isInherited.Value;
            }

            dueDateCalc.Cycle = from.Cycle;
            dueDateCalc.JurisdictionId = from.JurisdictionId;
            dueDateCalc.FromEventId = from.FromEventId;
            dueDateCalc.RelativeCycle = from.RelativeCycle;
            dueDateCalc.Operator = from.Operator;
            dueDateCalc.DeadlinePeriod = from.DeadlinePeriod;
            dueDateCalc.PeriodType = from.PeriodType;
            dueDateCalc.EventDateFlag = from.EventDateFlag;
            dueDateCalc.Adjustment = from.Adjustment;
            dueDateCalc.MustExist = from.MustExist;
            dueDateCalc.Comparison = from.Comparison;
            dueDateCalc.CompareEventId = from.CompareEventId;
            dueDateCalc.Workday = from.Workday;
            dueDateCalc.Message2Flag = from.Message2Flag;
            dueDateCalc.SuppressReminders = from.SuppressReminders;
            dueDateCalc.OverrideLetterId = from.OverrideLetterId;
            dueDateCalc.CompareEventFlag = from.CompareEventFlag;
            dueDateCalc.CompareCycle = from.CompareCycle;
            dueDateCalc.CompareRelationshipId = from.CompareRelationshipId;
            dueDateCalc.CompareDate = from.CompareDate;
            dueDateCalc.CompareSystemDate = from.CompareSystemDate;

            return dueDateCalc;
        }
    }
}