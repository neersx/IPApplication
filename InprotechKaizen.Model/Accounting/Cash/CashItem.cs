using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Cash
{
    [Table("CASHITEM")]
    public class CashItem
    {

        [Key]
        [Column("ENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EntityId { get; set; }

        [Key]
        [Column("BANKNAMENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int BankNameId { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int SequenceNo { get; set; }

        [Key]
        [Column("TRANSENTITYNO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TransactionEntityId { get; set; }

        [Key]
        [Column("TRANSNO", Order = 4)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TransactionId { get; set; }

        [Column("ITEMDATE")]
        public DateTime ItemDate { get; set; }

        [StringLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("STATUS", TypeName = "numeric")]
        public TransactionStatus Status { get; set; }

        [Column("ITEMTYPE")]
        public PaymentMethod PaymentMethod { get; set; }

        [Column("POSTDATE")]
        public DateTime? PostDate { get; set; }

        [Column("POSTPERIOD")]
        public int? PostPeriodId { get; set; }

        [Column("CLOSEPOSTDATE")]
        public DateTime? ClosePostDate { get; set; }

        [Column("CLOSEPOSTPERIOD")]
        public int? ClosePostPeriodId { get; set; }

        [StringLength(254)]
        [Column("TRADER")]
        public string Trader { get; set; }

        [Column("ACCTENTITYNO")]
        public int? AccountEntityId { get; set; }

        [Column("ACCTNAMENO")]
        public int? AccountNameId { get; set; }

        [Column("BANKEDBYENTITYNO")]
        public int? BankedByEntityId { get; set; }

        [Column("BANKEDBYTRANSNO")]
        public int? BankedByTransactionId { get; set; }

        [Column("BANKCATEGORY")]
        public short? BankCategory { get; set; }

        [StringLength(10)]
        [Column("ITEMBANKBRANCHNO")]
        public string ItemBankBranchNo { get; set; }

        [StringLength(30)]
        [Column("ITEMREFNO")]
        public string ItemRefNo { get; set; }

        [StringLength(60)]
        [Column("ITEMBANKNAME")]
        public string ItemBankName { get; set; }

        [StringLength(60)]
        [Column("ITEMBANKBRANCH")]
        public string ItemBankBranch { get; set; }

        [Column("CREDITCARDTYPE")]
        public int? CreditCardType { get; set; }

        [Column("CARDEXPIRYDATE")]
        public int? CardExpiryDate { get; set; }

        [StringLength(3)]
        [Column("PAYMENTCURRENCY")]
        public string PaymentCurrency { get; set; }

        [Column("PAYMENTAMOUNT")]
        public decimal? PaymentAmount { get; set; }

        [Column("BANKEXCHANGERATE")]
        public decimal? BankExchangeRate { get; set; }

        [Column("BANKAMOUNT")]
        public decimal? BankAmount { get; set; }

        [Column("BANKCHARGES")]
        public decimal? BankCharges { get; set; }

        [Column("BANKNET")]
        public decimal? BankNet { get; set; }

        [StringLength(3)]
        [Column("DISSECTIONCURRENCY")]
        public string DissectionCurrency { get; set; }

        [Column("DISSECTIONAMOUNT")]
        public decimal? DissectionAmount { get; set; }

        [Column("DISSECTIONUNALLOC")]
        public decimal? DissectionUnallocated { get; set; }

        [Column("DISSECTIONEXCHANGE")]
        public decimal? DissectionExchange { get; set; }

        [Column("LOCALAMOUNT")]
        public decimal? LocalAmount { get; set; }

        [Column("LOCALCHARGES")]
        public decimal? LocalCharges { get; set; }

        [Column("LOCALEXCHANGERATE")]
        public decimal? LocalExchangeRate { get; set; }

        [Column("LOCALNET")]
        public decimal? LocalNet { get; set; }

        [Column("LOCALUNALLOCATED")]
        public decimal? LocalUnallocated { get; set; }

        [Column("BANKOPERATIONCODE")]
        public int? BankOperationCode { get; set; }

        [Column("DETAILSOFCHARGES")]
        public int? DetailsOfCharges { get; set; }

        [Column("EFTFILEFORMAT")]
        public int? EftFileFormat { get; set; }

        [StringLength(254)]
        [Column("EFTPAYMENTFILE")]
        public string EftPaymentFile { get; set; }

        [StringLength(16)]
        [Column("FXDEALERREF")]
        public string FxDealerRef { get; set; }

        [Column("TRANSFERENTITYNO")]
        public int? TransferEntityId { get; set; }

        [Column("TRANSFERTRANSNO")]
        public int? TransferTransactionId { get; set; }

        [Column("INSTRUCTIONCODE")]
        public int? InstructionCode { get; set; }

    }
}
