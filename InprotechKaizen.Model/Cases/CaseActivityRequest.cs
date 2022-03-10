using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Cases
{
    [Table("ACTIVITYREQUEST")]
    public class CaseActivityRequest
    {
        public CaseActivityRequest()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public CaseActivityRequest(Case @case, DateTime whenRequested, string sqlUser)
        {
            if (@case == null) throw new ArgumentNullException("case");
            if (sqlUser == null) throw new ArgumentNullException("sqlUser");

            WhenRequested = whenRequested;
            SqlUser = sqlUser;
            CaseId = @case.Id;
            Case = @case;
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("ACTIVITYID", Order = 1)]
        public int Id { get; protected set; }

        [Key]
        [MaxLength(40)]
        [Column("SQLUSER", Order = 2)]
        public string SqlUser { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("WHENREQUESTED")]
        public DateTime WhenRequested { get; set; }

        [MaxLength(2)]
        [Column("ACTION")]
        public string ActionId { get; set; }

        [Column("EVENTNO")]
        public int? EventId { get; set; }

        [Column("CYCLE")]
        public short? Cycle { get; set; }

        [Column("LETTERNO")]
        public short? LetterNo { get; set; }

        [Column("ALTERNATELETTER")]
        public short? AlternateLetter { get; set; }

        [Column("COVERINGLETTERNO")]
        public short? CoveringLetterNo { get; set; }
        
        [MaxLength(50)]
        [Column("EMAILOVERRIDE")]
        public string EmailOverride {get; set; }

        [Column("STATUSCODE")]
        public short? CaseStatusCode { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("HOLDFLAG")]
        public decimal? HoldFlag { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("SPLITBILLFLAG")]
        public decimal? SplitBillFlag { get; set; }
        
        [Column("LETTERDATE")]
        public DateTime? LetterDate { get; set; }

        [Column("DELIVERYID")]
        public short? DeliveryMethodId { get; set; }

        [Column("ACTIVITYTYPE")]
        public short? ActivityType { get; set; }

        [Column("ACTIVITYCODE")]
        public int? ActivityCode { get; set; }

        [Column("PROCESSED")]
        public decimal? Processed { get; set; }

        [MaxLength(8)]
        [Column("PROGRAMID")]
        public string ProgramId { get; set; }

        [Column("DEBTOR")]
        public int? Debtor { get; set; }

        [Column("DISBEMPLOYEENO")]
        public int? DisbEmployeeNo { get; set; }

        [MaxLength(3)]
        [Column("DISBCURRENCY")]
        public string DisbCurrency { get; set; }

        [Column("DISBEXCHANGERATE")]
        public decimal? DisbExchangeRate { get; set; }

        [MaxLength(3)]
        [Column("DISBTAXCODE")]
        public string DisbTaxCode { get; set; }
        
        [Column("DISBNARRATIVE")]
        public short? DisbNarrative { get; set; }

        [Column("DISBAMOUNT")]
        public decimal? DisbAmount { get; set; }

        [Column("DISBTAXAMOUNT")]
        public decimal? DisbTaxAmount { get; set; }

        [MaxLength(6)]
        [Column("DISBWIPCODE")]
        public string DisbWipCode { get; set; }
        
        [Column("DISBORIGINALAMOUNT")]
        public decimal? DisbOriginalAmount { get; set; }

        [Column("DISBBILLAMOUNT")]
        public decimal? DisbBillAmount { get; set; }

        [Column("DISBDISCOUNT")]
        public decimal? DisbDiscount { get; set; }

        [Column("DISBBILLDISCOUNT")]
        public decimal? DisbBillDiscount { get; set; }
        
        [Column("DISBCOSTLOCAL")]
        public decimal? DisbCostLocal { get; set; }

        [Column("DISBCOSTORIGINAL")]
        public decimal? DisbCostOriginal { get; set; }

        [Column("DISBCOSTCALC1")]
        public decimal? DisbCostCalculation1 { get; set; }
        
        [Column("DISBCOSTCALC2")]
        public decimal? DisbCostCalculation2 { get; set; }
        
        [Column("DISBDISCORIGINAL")]
        public decimal? DisbDiscountOriginal { get; set; }

        [MaxLength(3)]
        [Column("DISBSTATETAXCODE")]
        public string DisbStateTaxCode { get; set; }
        
        [Column("DISBSTATETAXAMT")]
        public decimal? DisbStateTaxAmount { get; set; }

        [Column("DISBMARGINNO")]
        public int? DisbMarginId { get; set; }
        
        [Column("DISBMARGIN")]
        public decimal? DisbMargin { get; set; }
        
        [Column("DISBHOMEMARGIN")]
        public decimal? DisbHomeMargin { get; set; }
        
        [Column("DISBBILLMARGIN")]
        public decimal? DisbBillMargin { get; set; }
        
        [Column("DISBDISCFORMARGIN")]
        public decimal? DisbDiscountForeignMargin { get; set; }
        
        [Column("DISBHOMEDISCFORMARGIN")]
        public decimal? DisbHomeDiscountForeignMargin { get; set; }

        [Column("DISBBILLDISCFORMARGIN")]
        public decimal? DisbBillDiscountForeignMargin { get; set; }

        [Column("EMPLOYEENO")]
        public int? EmployeeNo { get; set; }

        [Column("INSTRUCTOR")]
        public int? Instructor { get; set; }

        [Column("OWNER")]
        public int? Owner { get; set; }

        [MaxLength(254)]
        [Column("SYSTEMMESSAGE")]
        public string SystemMessage { get; set; }

        [Column("SERVEMPLOYEENO")]
        public int? ServiceEmployeeNo { get; set; }

        [MaxLength(3)]
        [Column("SERVICECURRENCY")]
        public string ServiceCurrency { get; set; }

        [Column("SERVEXCHANGERATE")]
        public decimal? ServiceExchangeRate { get; set; }

        [MaxLength(3)]
        [Column("SERVICETAXCODE")]
        public string ServiceTaxCode { get; set; }

        [Column("SERVICENARRATIVE")]
        public short? ServiceNarrative { get; set; }
        
        [Column("SERVICEAMOUNT")]
        public decimal? ServiceAmount { get; set; }

        [Column("SERVICETAXAMOUNT")]
        public decimal? ServiceTaxAmount { get; set; }

        [MaxLength(6)]
        [Column("SERVICEWIPCODE")]
        public string ServiceWipCode { get; set; }

        [Column("SERVORIGINALAMOUNT")]
        public decimal? ServiceOriginalAmount { get; set; }

        [Column("SERVBILLAMOUNT")]
        public decimal? ServiceBillAmount { get; set; }

        [Column("SERVDISCOUNT")]
        public decimal? ServiceDiscount { get; set; }

        [Column("SERVBILLDISCOUNT")]
        public decimal? ServiceBillDiscount { get; set; }
        
        [Column("SERVCOSTLOCAL")]
        public decimal? ServiceCostLocal { get; set; }

        [Column("SERVCOSTORIGINAL")]
        public decimal? ServiceCostOriginal { get; set; }

        [Column("SERVCOSTCALC1")]
        public decimal? ServiceCostCalculation1 { get; set; }
        
        [Column("SERVCOSTCALC2")]
        public decimal? ServiceCostCalculation2 { get; set; }

        [Column("SERVDISCORIGINAL")]
        public decimal? ServiceDiscountOriginal { get; set; }

        [MaxLength(3)]
        [Column("SERVSTATETAXCODE")]
        public string ServiceStateTaxCode { get; set; }
        
        [Column("SERVSTATETAXAMT")]
        public decimal? ServiceStateTaxAmount { get; set; }

        [Column("SERVMARGINNO")]
        public int? ServiceMarginId { get; set; }
        
        [Column("SERVMARGIN")]
        public decimal? ServiceMargin { get; set; }
        
        [Column("SERVHOMEMARGIN")]
        public decimal? ServiceHomeMargin { get; set; }
        
        [Column("SERVBILLMARGIN")]
        public decimal? ServiceBillMargin { get; set; }
        
        [Column("SERVDISCFORMARGIN")]
        public decimal? ServiceDiscountForeignMargin { get; set; }
        
        [Column("SERVHOMEDISCFORMARGIN")]
        public decimal? ServiceHomeDiscountForeignMargin { get; set; }

        [Column("SERVBILLDISCFORMARGIN")]
        public decimal? ServiceBillDiscountForeignMargin { get; set; }

        [Column("ENTEREDQUANTITY")]
        public int? EnteredQuantity { get; set; }

        [Column("ENTEREDAMOUNT")]
        public decimal? EnteredAmount { get; set; }

        [Column("DISCBILLAMOUNT")]
        public decimal? DiscountBillAmount { get; set; }

        [Column("TOTALDISCOUNT")]
        public decimal? TotalDiscount { get; set; }
        
        [Column("TAKENUPAMOUNT")]
        public decimal? TakenUpAmount { get; set; }

        [Column("QUESTIONNO")]
        public short? QuestionId { get; set; }

        [Column("CHECKLISTTYPE")]
        public short? ChecklistType { get; set; }

        [Column("TRANSACTIONFLAG")]
        public decimal? TransactionFlag { get; set; }

        [Column("PRODUCTCODE")]
        public int? ProductCode { get; set; }
        
        [Column("PRODUCECHARGES")]
        public decimal? ProduceCharges { get; set; }
        
        [Column("XMLINSTRUCTIONID")]
        public int? XmlInstructionId { get; set; }

        [MaxLength(254)]
        [Column("XMLFILTER")]
        public string XmlFilter { get; set; }

        [Column("RATENO")]
        public int? RateId { get; set; }

        [MaxLength(1)]
        [Column("PAYFEECODE")]
        public string PayFeeCode { get; set; }

        [Column("ESTIMATEFLAG")]
        public decimal? EstimateFlag { get; set; }

        [Column("DIRECTPAYFLAG")]
        public bool? DirectPayFlag { get; set; }

        [Column("SEPARATEDEBTORFLAG")]
        public decimal? SeparateDebtorFlag { get; set; }

        [Column("BILLPERCENTAGE")]
        public decimal? BillPercentage { get; set; }

        [MaxLength(3)]
        [Column("BILLCURRENCY")]
        public string BillCurrency { get; set; }

        [Column("BILLEXCHANGERATE")]
        public decimal? BillExchangeRate { get; set; }

        [MaxLength(12)]
        [Column("DEBITNOTENO")]
        public string DebitNoteNo { get; set; }

        [Column("ENTITYNO")]
        public int? EntityId { get; set; }

        [MaxLength(3)]
        [Column("DEBTORNAMETYPE")]
        public string DebtorNameTypeId { get; set; }

        [MaxLength(10)]
        [Column("DEBITNOTEDETAIL")]
        public string DebitNoteDetail { get; set; }

        [Column("IDENTITYID")]
        public int? IdentityId { get; set; }

        [Column("GROUPACTIVITYID")]
        public int? GroupActivityId { get; set; }

        [Column("BATCHNO")]
        public int? BatchId { get; set; }

        [Column("EDEOUTPUTTYPE")]
        public int? EdeOutputType { get; set; }
        
        [Column("REQUESTID")]
        public int? RequestId { get; set; }
        
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Case")]
        public virtual Case Case { get; set; }

        [Column("WHENOCCURRED")]
        public DateTime? WhenOccurred { get; set; }

        [MaxLength(254)]
        [Column("FILENAME")]
        public string FileName { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }
    }
}