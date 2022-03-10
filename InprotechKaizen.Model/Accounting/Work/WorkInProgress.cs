using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Accounting.Work
{
    [Table("WORKINPROGRESS")]
    public class WorkInProgress
    {
        [Key]
        [Column("ENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EntityId { get; set; }

        [Key]
        [Column("TRANSNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TransactionId { get; set; }

        [Key]
        [Column("WIPSEQNO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short WipSequenceNo { get; set; }

        [Column("TRANSDATE")]
        public DateTime? TransactionDate { get; set; }

        [Column("POSTDATE")]
        public DateTime? PostDate { get; set; }

        [Column("RATENO")]
        public int? RateId { get; set; }

        [MaxLength(6)]
        [Column("WIPCODE")]
        public string WipCode { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("ACCTENTITYNO")]
        public int? AccountEntityId { get; set; }

        [Column("ACCTCLIENTNO")]
        public int? AccountClientId { get; set; }

        [Column("EMPLOYEENO")]
        public int? StaffId { get; set; }

        [Column("TOTALTIME")]
        public DateTime? TotalTime { get; set; }

        [Column("TOTALUNITS")]
        public short? TotalUnits { get; set; }

        [Column("UNITSPERHOUR")]
        public short? UnitsPerHour { get; set; }

        [Column("CHARGEOUTRATE")]
        public decimal? ChargeOutRate { get; set; }

        [Column("ASSOCIATENO")]
        public int? AssociateId { get; set; }

        [MaxLength(20)]
        [Column("INVOICENUMBER")]
        public string InvoiceNumber { get; set; }

        [MaxLength(3)]
        [Column("FOREIGNCURRENCY")]
        public string ForeignCurrency { get; set; }

        [Column("FOREIGNVALUE")]
        public decimal? ForeignValue { get; set; }

        [Column("EXCHRATE")]
        public decimal? ExchangeRate { get; set; }

        [Column("LOCALVALUE")]
        public decimal? LocalValue { get; set; }

        [Column("BALANCE")]
        public decimal? Balance { get; set; }

        [MaxLength(6)]
        [Column("EMPPROFITCENTRE")]
        public string StaffProfitCentre { get; set; }

        [MaxLength(6)]
        [Column("CASEPROFITCENTRE")]
        public string CaseProfitCentre { get; set; }

        [Column("NARRATIVENO")]
        public short? NarrativeId { get; set; }

        [MaxLength(254)]
        [Column("SHORTNARRATIVE")]
        public string ShortNarrative { get; set; }

        [Column("LONGNARRATIVE")]
        public string LongNarrative { get; set; }

        [Column("STATUS", TypeName = "numeric")]
        public TransactionStatus? Status { get; set; }

        [Column("VARIABLEFEEAMT")]
        public decimal? VariableFeeAmount { get; set; }

        [Column("VARIABLEFEETYPE")]
        public short? VariableFeeType { get; set; }

        [MaxLength(3)]
        [Column("VARIABLEFEECURR")]
        public string VariableFeeCurrency { get; set; }

        [Column("FEECRITERIANO")]
        public int? FeeCriteriaNo { get; set; }

        [Column("FEEUNIQUEID")]
        public short? FeeUniqueId { get; set; }

        [Column("QUOTATIONNO")]
        public int? QuotationNo { get; set; }

        [Column("EMPFAMILYNO")]
        public short? StaffFamilyId { get; set; }

        [Column("EMPOFFICECODE")]
        public int? StaffOfficeCode { get; set; }

        [MaxLength(20)]
        [Column("VERIFICATIONNUMBER")]
        public string VerificationNumber { get; set; }

        [Column("LOCALCOST")]
        public decimal? LocalCost { get; set; }

        [Column("FOREIGNCOST")]
        public decimal? ForeignCost { get; set; }

        [Column("ENTEREDQUANTITY")]
        public int? EnteredQuantity { get; set; }

        [Column("DISCOUNTFLAG")]
        public decimal? IsDiscount { get; set; }

        [Column("FOREIGNBALANCE")]
        public decimal? ForeignBalance { get; set; }

        [Column("COSTCALCULATION1")]
        public decimal? CostCalculation1 { get; set; }

        [Column("COSTCALCULATION2")]
        public decimal? CostCalculation2 { get; set; }

        [Column("PRODUCTCODE")]
        public int? ProductCode { get; set; }

        [Column("GENERATEDINADVANCE")]
        public decimal? GeneratedInAdvance { get; set; }

        [Column("MARGINNO")]
        public int? MarginId { get; set; }

        [Column("MARGINFLAG")]
        public bool? IsMargin { get; set; }

        [Column("BILLINGDISCOUNTFLAG")]
        public bool? IsBillingDiscount { get; set; }

        [Column("SPLITPERCENTAGE")]
        public decimal? SplitPercentage { get; set; }

        [Column("ADDTOFEELIST")]
        public bool? IsAddToFeeList { get; set; }

        [Column("PREMARGINAMOUNT")]
        public decimal? PreMarginAmount { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LogDateTimeStamp { get; set; }

        public virtual Case Case { get; set; }

        public bool WipIsDiscount()
        {
            return IsDiscount.GetValueOrDefault() == 1;
        }

        public bool WipIsMargin()
        {
            return IsMargin.GetValueOrDefault();
        }
    }
}