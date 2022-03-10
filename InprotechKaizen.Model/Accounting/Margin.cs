using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("MARGIN")]
    public class Margin
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("MARGINNO")]
        public int MarginId { get; set; }

        [Required]
        [StringLength(3)]
        [Column("WIPCATEGORY")]
        public string WipCategory { get; set; }

        [Column("ENTITYNO")]
        public int? EntityId { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("INSTRUCTOR")]
        public int? InstructorId { get; set; }

        [Column("DEBTOR")]
        public int? DebtorId { get; set; }

        [Column("DEBTORCURRENCY")]
        public string DebtorCurrency { get; set; }

        [Column("EFFECTIVEDATE")]
        public DateTime? EffectiveDate { get; set; }

        [Column("MARGINAMOUNT")]
        public decimal? MarginAmount { get; set; }

        [Column("AGENT")]
        public int? AgentId { get; set; }

        [Column("MARGINTYPENO")]
        public int? MarginTypeId { get; set; }

        [Column("MARGINCAP")]
        public decimal? MarginCap { get; set; }
        
        [Column("WIPCODE")]
        public string WipCode { get; set; }
    }
}