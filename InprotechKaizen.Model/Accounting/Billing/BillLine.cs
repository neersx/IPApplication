using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Billing
{
    [Table("BILLLINE")]
    public class BillLine
    {
        [Key]
        [Column("ITEMENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ItemEntityId { get; set; }

        [Key]
        [Column("ITEMTRANSNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ItemTransactionId { get; set; }

        [Key]
        [Column("ITEMLINENO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short ItemLineNo { get; set; }

        [Column("WIPCODE")]
        public string WipCode { get; set; }

        [Column("WIPTYPEID")]
        public string WipTypeId { get; set; }

        [Column("CATEGORYCODE")]
        public string CategoryCode { get; set; }

        [Column("IRN")]
        public string CaseReference { get; set; }

        [Column("VALUE")]
        public decimal? Value { get; set; }

        [Column("DISPLAYSEQUENCE")]
        public short? DisplaySequence { get; set; }

        [Column("PRINTDATE")]
        public DateTime? PrintDate { get; set; }

        [Column("PRINTTIME")]
        public string PrintTime { get; set; }

        [Column("PRINTNAME")]
        public string PrintName { get; set; }

        [Column("NARRATIVENO")]
        public short? NarrativeId { get; set; }

        [Column("SHORTNARRATIVE")]
        public string ShortNarrative { get; set; }

        [Column("LONGNARRATIVE")]
        public string LongNarrative { get; set; }

        [Column("FOREIGNVALUE")]
        public decimal? ForeignValue { get; set; }

        [Column("PRINTCHARGEOUTRATE")]
        public decimal? PrintChargeOutRate { get; set; }

        [Column("PRINTTOTALUNITS")]
        public short? PrintTotalUnits { get; set; }
        
        [Column("UNITSPERHOUR")]
        public short? UnitsPerHour { get; set; }

        [Column("PRINTCHARGECURRNCY")]
        public string PrintChargeCurrency { get; set; }
        
        [Column("LOCALTAX")]
        public decimal? LocalTax { get; set; }

        [Column("GENERATEDFROMTAXCODE")]
        public string GeneratedFromTaxCode { get; set; }
        
        [Column("ISHIDDENFORDRAFT")]
        public bool? IsHiddenForDraft { get; set; }

        [Column("TAXCODE")]
        public string TaxCode { get; set; }
    }
}