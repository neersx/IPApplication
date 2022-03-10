using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("EXPENSEIMPORT")]
    public class ExpenseImport
    {
        [Key]
        [Column("IMPORTBATCHNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ImportBatchId { get; set; }

        [Key]
        [Column("TRANSNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TransactionId { get; set; }

        [Column("REFENTITYNO")]
        public int? RefEntityId { get; set; }

        [Column("REFTRANSNO")]
        public int? RefTransactionId { get; set; }

        [Column("EMPLOYEENO")]
        public int? StaffId { get; set; }

        [Column("NAMENO")]
        public int? NameId { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [MaxLength(20)]
        [Column("ENTITYNAMECODE")]
        public string EntityNameCode { get; set; }

        [MaxLength(30)]
        [Column("IRN")]
        public string CaseReference { get; set; }

        [MaxLength(20)]
        [Column("NAMECODE")]
        public string NameCode { get; set; }

        [Column("ENTITYNAMENO")]
        public int? EntityNameId { get; set; }

        [Column("TRANSDATE")]
        public DateTime? TransactionDate { get; set; }

        [MaxLength(6)]
        [Column("WIPCODE")]
        public string WipCode { get; set; }

        [Column("RATENO")]
        public int? RateId { get; set; }

        [MaxLength(20)]
        [Column("EMPLOYEECODE")]
        public string StaffCode { get; set; }

        [Column("IMPORTAMOUNT")]
        public decimal? ImportAmount { get; set; }

        [MaxLength(3)]
        [Column("FOREIGNCURRENCY")]
        public string ForeignCurrency { get; set; }

        [Column("FOREIGNAMOUNT")]
        public decimal? ForeignAmount { get; set; }

        [MaxLength(20)]
        [Column("INVOICENO")]
        public string InvoiceNo { get; set; }

        [MaxLength(20)]
        [Column("SUPPLIERNAMECODE")]
        public string SupplierNameCode { get; set; }

        [MaxLength(254)]
        [Column("NARRATIVE")]
        public string Narrative { get; set; }

        [MaxLength(254)]
        [Column("REJECTREASON")]
        public string RejectReason { get; set; }

        [Column("SUPPLIERNAMENO")]
        public int? SupplierNameId { get; set; }
    }
}