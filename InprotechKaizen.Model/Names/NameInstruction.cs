using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMEINSTRUCTIONS")]
    public class NameInstruction
    {
        [Obsolete("For persistence only.")]
        public NameInstruction()
        {
        }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("NAMENO", Order = 1)]
        public int Id { get; set; }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("INTERNALSEQUENCE", Order = 2)]
        public int Sequence { get; set; }

        [Column("RESTRICTEDTONAME")]
        public int? RestrictedToName { get; set; }

        [Column("INSTRUCTIONCODE")]
        public short? InstructionId { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyType { get; set; }

        [Column("PERIOD1AMT")]
        public short? Period1Amt { get; set; }

        [Column("PERIOD1TYPE", TypeName = "nchar")]
        [StringLength(1, MinimumLength = 0)]
        public string Period1Type { get; set; }

        [Column("PERIOD2AMT")]
        public short? Period2Amt { get; set; }

        [Column("PERIOD2TYPE", TypeName = "nchar")]
        [StringLength(1, MinimumLength = 0)]
        public string Period2Type { get; set; }

        [Column("PERIOD3AMT")]
        public short? Period3Amt { get; set; }

        [Column("PERIOD3TYPE", TypeName = "nchar")]
        [StringLength(1, MinimumLength = 0)]
        public string Period3Type { get; set; }

        [MaxLength(4)]
        [Column("ADJUSTMENT")]
        public string Adjustment { get; set; }

        [Column("ADJUSTDAY")]
        public byte? AdjustDay { get; set; }

        [Column("ADJUSTSTARTMONTH")]
        public byte? AdjustStartMonth { get; set; }

        [Column("ADJUSTDAYOFWEEK")]
        public byte? AdjustDayOfWeek { get; set; }

        [Column("ADJUSTTODATE")]
        public DateTime? AdjustToDate { get; set; }

        [MaxLength(4000)]
        [Column("STANDINGINSTRTEXT")]
        public string StandingInstructionText { get; set; }
    }
}
