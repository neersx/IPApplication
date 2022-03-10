using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Banking
{
    [Table("EFTDETAIL")]
    public class ElectronicFundsTransferDetail
    {
        [Key]
        [Column("ACCOUNTOWNER", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountOwner { get; set; }

        [Key]
        [Column("BANKNAMENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int BankNameNo { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int SequenceNo { get; set; }

        [MaxLength(4)]
        [Column("BANKCODE")]
        public string BankCode { get; set; }

        [MaxLength(2)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; set; }

        [MaxLength(2)]
        [Column("LOCATIONCODE")]
        public string LocationCode { get; set; }

        [MaxLength(3)]
        [Column("BRANCHCODE")]
        public string BranchCode { get; set; }

        [Column("BANKOPERATIONCODE")]
        public int? BankOperationCode { get; set; }

        [Column("DETAILSOFCHARGES")]
        public int? DetailsOfCharges { get; set; }

        [Column("FILEFORMATUSED")]
        public int? FileFormatUsed { get; set; }

        [MaxLength(16)]
        [Column("ALIAS")]
        public string Alias { get; set; }

        [MaxLength(6)]
        [Column("USERREFNO")]
        public string UserRefNo { get; set; }

        [MaxLength(9)]
        [Column("APPLICATIONID")]
        public string ApplicationId { get; set; }

        [MaxLength(254)]
        [Column("FORMATFILE")]
        public string FormatFile { get; set; }

        [MaxLength(254)]
        [Column("SQLTEMPLATE")]
        public string SQLTemplate { get; set; }

        [MaxLength(8)]
        [Column("PAYMENTREFPREFIX")]
        public string PaymentRefPrefix { get; set; }

        [Column("LASTPAYMENTREFNO")]
        public int? LastPaymentRefNo { get; set; }

        [Column("SELFBALANCING")]
        public bool? IsSelfBalancing { get; set; }
    }
}