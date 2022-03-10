using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("DEBTORSPLITDIARY")]
    public class DebtorSplitDiary
    {
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }
        
        [ForeignKey("Diary")]
        [Column("EMPLOYEENO", Order = 0)]
        public int EmployeeNo { get; set; }

        [ForeignKey("Diary")]
        [Column("ENTRYNO", Order = 1)]
        public int? EntryNo { get; set; }

        [Column("NAMENO")]
        public int DebtorNameNo { get; set; }

        [Column("TIMEVALUE")]
        public decimal? LocalValue { get; set; }

        [Column("CHARGEOUTRATE")]
        public decimal? ChargeOutRate { get; set; }

        [Column("NARRATIVENO")]
        public short? NarrativeNo { get; set; }

        [Column("NARRATIVE")]
        public string Narrative { get; set; }

        [Column("DISCOUNTVALUE")]
        public decimal? LocalDiscount { get; set; }

        [Column("FOREIGNCURRENCY")]
        public string ForeignCurrency { get; set; }

        [Column("FOREIGNVALUE")]
        public decimal? ForeignValue { get; set; }

        [Column("EXCHRATE")]
        public decimal? ExchRate { get; set; }

        [Column("FOREIGNDISCOUNT")]
        public decimal? ForeignDiscount { get; set; }

        [Column("COSTCALCULATION1")]
        public decimal? CostCalculation1 { get; set; }

        [Column("COSTCALCULATION2")]
        public decimal? CostCalculation2 { get; set; }

        [Column("MARGINNO")]
        public int? MarginId { get; set; }

        [Column("SPLITPERCENTAGE")]
        public decimal? SplitPercentage { get; set; }

        public virtual Diary Diary { get; set; }
    }
}