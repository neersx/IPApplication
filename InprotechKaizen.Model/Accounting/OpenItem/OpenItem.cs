using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Accounting.OpenItem
{
    [Table("OPENITEM")]
    public class OpenItem
    {
        public OpenItem()
        {
        }
        
        public OpenItem(int itemEntityId, int itemTransactionId, int accountEntityId, Name accountDebtorName)
        {
            if (accountDebtorName == null) throw new ArgumentNullException("accountDebtorName");

            ItemEntityId = itemEntityId;
            ItemTransactionId = itemTransactionId;
            AccountEntityId = accountEntityId;
            AccountDebtorName = accountDebtorName;
            AccountDebtorId = accountDebtorName.Id;
        }

        [Key]
        [Column("OPENITEMID")]
        public int Id { get; protected set; }

        [Column("ITEMENTITYNO")]
        public int ItemEntityId { get; set; }

        [Column("ITEMTRANSNO")]
        public int ItemTransactionId { get; set; }

        [Column("ACCTENTITYNO")]
        public int AccountEntityId { get; set; }

        [Column("ACCTDEBTORNO")]
        [ForeignKey("AccountDebtorName")]
        public int AccountDebtorId { get; set; }

        [Required]
        [MaxLength(12)]
        [Column("OPENITEMNO")]
        public string OpenItemNo { get; set; }

        [Column("LOCALBALANCE")]
        public decimal? LocalBalance { get; set; }

        [Column("LOCALVALUE")]
        public decimal? LocalValue { get; set; }

        [Column("CURRENCY")]
        public string Currency { get; set; }

        [Column("EXCHRATE")]
        public decimal? ExchangeRate { get; set; }

        [Column("EXCHVARIANCE")]
        public decimal? ExchangeRateVariance { get; set; }

        [Column("FOREIGNVALUE")]
        public decimal? ForeignValue { get; set; }

        [Column("FOREIGNBALANCE")]
        public decimal? ForeignBalance { get; set; }

        [Column("FOREIGNEQUIVCURRCY")]
        public string ForeignEquivalentCurrency { get; set; }

        [Column("FOREIGNEQUIVEXRATE")]
        public decimal? ForeignEquivalentExchangeRate { get; set; }

        [Column("CONVERSIONEXCHRATE")]
        public decimal? ConversionExchangeRate { get; set; }

        [Column("STATUS", TypeName = "numeric")]
        public TransactionStatus Status { get; set; }

        [Column("EMPLOYEENO")]
        public int? StaffId { get; set; }

        [Column("EMPPROFITCENTRE")]
        public string StaffProfitCentre { get; set; }

        [Column("CASEPROFITCENTRE")]
        public string CaseProfitCentre { get; set; }

        [Column("ACTION")]
        public string ActionId { get; set; }
        
        [Column("ITEMDATE")]
        public DateTime? ItemDate { get; set; }

        [Column("ITEMDUEDATE")]
        public DateTime? ItemDueDate { get; set; }

        [Column("ITEMTYPE", TypeName = "numeric")]
        public ItemType TypeId { get; set; }

        [Column("ITEMPRETAXVALUE")]
        public decimal? PreTaxValue { get; set; }

        [Column("LOCALTAXAMT")]
        public decimal? LocalTaxAmount { get; set; }

        [Column("FOREIGNTAXAMT")]
        public decimal? ForeignTaxAmount { get; set; }
        
        [MaxLength(1)]
        [Column("PAYPROPERTYTYPE")]
        public string PayPropertyType { get; set; }

        [Column("POSTDATE")]
        public DateTime? PostDate { get; set; }
        
        [Column("CLOSEPOSTDATE")]
        public DateTime? ClosePostDate { get; set; }

        [Column("POSTPERIOD")]
        public int? PostPeriodId { get; set; }
        
        [Column("CLOSEPOSTPERIOD")]
        public int? ClosePostPeriodId { get; set; }

        [MaxLength(12)]
        [Column("ASSOCOPENITEMNO")]
        public string AssociatedOpenItemNo { get; set; }

        [Column("BILLPERCENTAGE")]
        public decimal? BillPercentage { get; set; }

        [Column("STATEMENTREF")]
        public string StatementRef { get; set; }

        [Column("REFERENCETEXT")]
        public string ReferenceText { get; set; }

        [Column("LONGREFTEXT")]
        public string LongReferenceText { get; set; }

        [Column("REFERENCETEXT_TID")]
        public string ReferenceTextTId { get; set; }

        [Column("REGARDING")]
        public string Regarding { get; set; }
        
        [Column("LONGREGARDING")]
        public string LongRegarding { get; set; }
        
        [Column("REGARDING_TID")]
        public int? RegardingTId { get; set; }
        
        [Column("SCOPE")]
        public string Scope { get; set; }

        [Column("SCOPE_TID")]
        public int? ScopeTId { get; set; }

        [Column("MAINCASEID")]
        public int? MainCaseId { get; set; }

        [Column("NAMESNAPNO")]
        public int? NameSnapshotId { get; set; }

        [Column("LOCALORIGTAKENUP")]  
        public decimal? LocalOriginalTakenUp { get; set; }
        
        [Column("FOREIGNORIGTAKENUP")]  
        public decimal? ForeignOriginalTakenUp { get; set; }

        [Column("BILLFORMATID")]
        public short? BillFormatId { get; set; }

        [Column("BILLPRINTEDFLAG")]
        public decimal? IsBillPrinted { get; set; }

        [Column("LANGUAGE")]
        public int? LanguageId { get; set; }

        [Column("IMAGEID")]
        public int? ImageId { get; set; }

        [Column("PENALTYINTEREST")]
        public decimal? PenaltyInterest { get; set; }

        [Column("INCLUDEONLYWIP")]
        public string IncludeOnlyWip { get; set; }

        [Column("PAYFORWIP")]
        public string PayForWip { get; set; }

        [Column("RENEWALDEBTORFLAG")]
        public decimal? IsRenewalDebtor { get; set; }

        [Column("LOCKIDENTITYID")]
        public int? LockIdentityId { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LogDateTimeStamp { get; set; }

        public virtual Name AccountDebtorName { get; protected set; }
    }
}