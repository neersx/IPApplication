using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("QUOTATION")]
    public class Quotation
    {
        [Key]
        [Column("QUOTATIONNO")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; set; }

        [Required]
        [MaxLength(10)]
        [Column("QUOTATIONID")]
        public string Reference { get; set; }

        [Column("QUOTATIONDATE")]
        public DateTime? Date { get; set; }

        [Column("ACCEPTEDDATE")]
        public DateTime? AcceptedDate { get; set; }

        [MaxLength(50)]
        [Column("QUOTATIONTYPE")]
        public string QuotationType { get; set; }

        [Column("LANGUAGECODE")]
        public int? LanguageCode { get; set; }

        [Column("DESCRIPTIONNO")]
        public short? DescriptionNo { get; set; }

        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("QUOTATIONNAMENO")]
        public int? NameId { get; set; }

        [Column("REFTEXT")]
        public string ReferenceText { get; set; }

        [Column("RAISEDBYNO")]
        public int? RaisedById { get; set; }

        [MaxLength(3)]
        [Column("FOREIGNCURRENCY")]
        public string ForeignCurrency { get; set; }

        [Column("EXCHANGERATE")]
        public decimal? ExchangeRate { get; set; }

        [Column("HEADERNO")]
        public short? HeaderNo { get; set; }

        [Column("HEADER")]
        public string Header { get; set; }

        [Column("FOOTERNO")]
        public short? FooterNo { get; set; }

        [Column("FOOTER")]
        public string Footer { get; set; }

        [Column("STATUS")]
        public int? Status { get; set; }

        [Column("USEINFLATIONINDEX")]
        public decimal? UseInflationIndex { get; set; }
    }
}