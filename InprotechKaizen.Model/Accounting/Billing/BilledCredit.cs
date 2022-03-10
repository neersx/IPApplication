using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Billing
{
    [Table("BILLEDCREDIT")]
    public class BilledCredit
    {
        [Key]
        [Column("CREDITID")]
        public int CreditId { get; set; }

        [Column("DRACCTDEBTORNO")]
        public int DebitAccountDebtorId { get; set; }

        [Column("CRACCTDEBTORNO")]
        public int CreditAccountDebtorId { get; set; }

        [Column("DRITEMENTITYNO")]
        public int DebitItemEntityId { get; set; }

        [Column("DRITEMTRANSNO")]
        public int DebitItemTransactionId { get; set; }

        [Column("DRACCTENTITYNO")]
        public int DebitAccountEntityId { get; set; }

        [Column("CRITEMENTITYNO")]
        public int CreditItemEntityId { get; set; }

        [Column("CRITEMTRANSNO")]
        public int CreditItemTransactionId { get; set; }

        [Column("CRACCTENTITYNO")]
        public int CreditAccountEntityId { get; set; }
        
        [Column("CRCASEID")]
        public int? CreditCaseId { get; set; }

        [Column("LOCALSELECTED")]
        public decimal? LocalSelected { get; set; }

        [Column("FOREIGNSELECTED")]
        public decimal? ForeignSelected { get; set; }

        [Column("FORCEDPAYOUT")]
        public decimal? ForcedPayout { get; set; }

        [Column("SELECTEDRENEWAL")]
        public decimal SelectedRenewal { get; set; }

        [Column("SELECTEDNONRENEWAL")]
        public decimal SelectedNonRenewal { get; set; }

        [Column("CREXCHVARIANCE")]
        public decimal? CreditExchangeVariance { get; set; }

        [Column("CRFORCEDPAYOUT")]
        public decimal? CreditForcedPayout { get; set; }
    }
}
