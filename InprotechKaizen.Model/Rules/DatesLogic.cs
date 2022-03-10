using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;

namespace InprotechKaizen.Model.Rules
{
    [SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum DatesLogicDateType
    {
        Event = 1,
        Due = 2
    }

    [SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum DatesLogicCompareDateType
    {
        Event = 1,
        Due = 2,
        Either = 3
    }

    public enum DatesLogicDisplayErrorOptions
    {
        Block = 1,
        Warn = 0
    }

    [Table("DATESLOGIC")]
    public class DatesLogic
    {
        [Obsolete("For persistence only.")]
        public DatesLogic()
        {
        }

        public DatesLogic(ValidEvent validEvent, int sequence)
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
        [Column("SEQUENCENO", Order = 3)]
        public int Sequence { get; set; }

        [Column("DATETYPE")]
        public short DateTypeId { get; set; }

        [MaxLength(2)]
        [Column("OPERATOR")]
        public string Operator { get; set; }

        [Column("COMPAREEVENT")]
        public int? CompareEventId { get; set; }

        [Column("MUSTEXIST")]
        public decimal MustExist { get; set; }

        [Column("RELATIVECYCLE")]
        public short? RelativeCycle { get; set; }

        [Column("COMPAREDATETYPE")]
        public short CompareDateTypeId { get; set; }

        [MaxLength(3)]
        [Column("CASERELATIONSHIP")]
        public string CaseRelationshipId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("DISPLAYERRORFLAG")]
        public decimal? DisplayErrorFlag { get; set; }

        [MaxLength(254)]
        [Column("ERRORMESSAGE")]
        public string ErrorMessage { get; set; }

        [Column("INHERITED")]
        public decimal? Inherited { get; set; }

        public virtual ValidEvent ValidEvent { get; set; }

        public virtual Event CompareEvent { get; set; }

        public virtual CaseRelation CaseRelationship { get; set; }

        [NotMapped]
        public bool IsInherited
        {
            get { return Inherited == 1; }
            set { Inherited = value ? 1 : 0; }
        }

        public DatesLogicDateType DateType => DateTypeId == 0 ? DatesLogicDateType.Event : (DatesLogicDateType) DateTypeId;

        public DatesLogicCompareDateType CompareDateType => CompareDateTypeId == 0 ? DatesLogicCompareDateType.Event : (DatesLogicCompareDateType) CompareDateTypeId;
    }

    public static class DatesLogicExt
    {
        public static int HashKey(this DatesLogic logic)
        {
            if (logic == null) throw new ArgumentNullException(nameof(logic));
            return new {logic.DateTypeId, logic.Operator, logic.CompareEventId, logic.MustExist, logic.RelativeCycle, logic.CompareDateTypeId, logic.CaseRelationshipId, logic.DisplayErrorFlag, logic.ErrorMessage}.GetHashCode();
        }

        public static DatesLogic InheritRuleFrom(this DatesLogic datesLogic, DatesLogic from)
        {
            datesLogic.CopyFrom(from, true);
            return datesLogic;
        }

        public static DatesLogic CopyFrom(this DatesLogic datesLogic, DatesLogic from, bool? isInherited)
        {
            if (datesLogic == null) throw new ArgumentNullException(nameof(datesLogic));
            if (from == null) throw new ArgumentNullException(nameof(from));

            if (isInherited.HasValue)
            {
                datesLogic.IsInherited = isInherited.Value;
            }

            datesLogic.DateTypeId = from.DateTypeId;
            datesLogic.Operator = from.Operator;
            datesLogic.CompareEventId = from.CompareEventId;
            datesLogic.MustExist = from.MustExist;
            datesLogic.RelativeCycle = from.RelativeCycle;
            datesLogic.CompareDateTypeId = from.CompareDateTypeId;
            datesLogic.CaseRelationshipId = from.CaseRelationshipId;
            datesLogic.DisplayErrorFlag = from.DisplayErrorFlag;
            datesLogic.ErrorMessage = from.ErrorMessage;

            return datesLogic;
        }
    }
}