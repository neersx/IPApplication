using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Cost
{
    [Table("TIMECOSTING")]
    public class TimeCosting
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("COSTINGSEQNO")]
        public int CostingSeqNo { get; set; }

        [Column("OFFICE")]
        public int? Office { get; set; }

        [Column("STAFFCLASS")]
        public int? StaffClass { get; set; }

        [Column("EMPLOYEENO")]
        public int? EmployeeNo { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("NAMENO")]
        public int? NameNo { get; set; }

        [Column("LOCALCLIENTFLAG")]
        public decimal? LocalClientFlag { get; set; }

        [Column("DEBTORTYPE")]
        public int? DebtorType { get; set; }

        [Column("EFFECTIVEDATE")]
        public DateTime? EffectiveDate { get; set; }

        [Column("CHARGEUNITRATE")]
        public decimal? ChargeUnitRate { get; set; }

        [Column("OWNER")]
        public int? Owner { get; set; }

        [Column("INSTRUCTOR")]
        public int? Instructor { get; set; }

        [Column("LOCALOWNERFLAG")]
        public decimal? LocalOwnerFlag { get; set; }

        [Column("LOCALINSTRUCTORFLG")]
        public decimal? LocalInstructorFlag { get; set; }

        [Column("ENDEFFECTIVEDATE")]
        public DateTime? EndEffectiveDate { get; set; }

        [Column("FOREIGNCURRENCY")]
        public string CurrencyCode { get; set; }

        [Column("ACTIVITY")]
        public string ActivityKey { get; set; }
    }
}