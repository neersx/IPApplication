using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases.Events;

namespace InprotechKaizen.Model.Rules
{
    [Table("FEESCALCULATION")]
    public class FeesCalculation
    {
        [Obsolete("For persistence only.")]
        public FeesCalculation()
        {
        }

        [Key]
        [Column("CRITERIANO", Order = 0)]
        public int CriteriaId { get; set; }

        [Key]
        [Column("UNIQUEID", Order = 1)]
        public short UniqueId { get; set; }

        [Column("FROMEVENTNO")]
        public int FromEventId { get; set; }

        [ForeignKey("CriteriaId")]
        public virtual Criteria Criteria { get; set; }

        [ForeignKey("FromEventId")]
        public virtual Event FromEvent { get; set; }

        [Column("AGENT")]
        public int? AgentId { get; set; }

        [Column("OWNER")]
        public int? OwnerId { get; set; }

        [Column("DEBTOR")]
        public int? DebtorId { get; set; }

        [Column("INSTRUCTOR")]
        public int? InstructorId { get; set; }

        [Column("DEBTORTYPE")]
        public int? DebtorType { get; set; }

        [Column("CYCLENUMBER")]
        public short? CycleNumber { get; set; }

        [Column("VALIDFROMDATE")]
        public DateTime? ValidFromDate { get; set; }

        [Column("DEBITNOTE")]
        public short? DebitNote { get; set; }

        [Column("COVERINGLETTER")]
        public short? CoveringLetterId { get; set; }

        [Column("GENERATECHARGES")]
        public decimal? ShouldGenerateCharges { get; set; }

        [Column("FEETYPE")]
        public string FeeType { get; set; }

        [Column("IPOFFICEFEEFLAG")]
        public decimal? IsIpOfficeFee { get; set; }

        [Column("PRODUCTCODE")]
        public int? ProductCode { get; set; }

        [Column("INHERITED")]
        public decimal? IsInherited { get; set; }

        [Column("PARAMETERSOURCE")]
        public short? ParameterSource { get; set; }

        [Column("PARAMETERSOURCE2")]
        public short? ParameterSource2 { get; set; }

        [MaxLength(6)]
        [Column("FEETYPE2")]
        public string FeeType2 { get; set; }

        [MaxLength(2)]
        [Column("WRITEUPREASON")]
        public string WriteUpReason { get; set; }

        [MaxLength(3)]
        [Column("DISBCURRENCY")]
        public string DisbursementCurrency { get; set; }

        [MaxLength(3)]
        [Column("DISBTAXCODE")]
        public string DisbursementTaxCode { get; set; }

        [Column("DISBNARRATIVE")]
        public short? DisbursementNarrative { get; set; }

        [MaxLength(6)]
        [Column("DISBWIPCODE")]
        public string DisbursementWipCode { get; set; }

        [Column("DISBBASEFEE")]
        public decimal? DisbursementBaseFee { get; set; }

        [Column("DISBMINFEEFLAG")]
        public decimal? IsDisbursementMinFee { get; set; }

        [Column("DISBVARIABLEFEE")]
        public decimal? IsDisbursementVariableFee { get; set; }

        [Column("DISBADDPERCENTAGE")]
        public decimal? DisbursementAddPercentage { get; set; }

        [Column("DISBUNITSIZE")]
        public short? DisbursementUnitSize { get; set; }

        [Column("DISBBASEUNITS")]
        public short? DisbursementBaseUnits { get; set; }

        [MaxLength(3)]
        [Column("DISBSTAFFNAMETYPE")]
        public string DisbursementStaffNameType { get; set; }

        [Column("DISBDISCFEEFLAG")]
        public bool? IsDisbursementDiscountFee { get; set; }

        [Column("DISBMAXUNITS")]
        public short? DisbursementMaxUnits { get; set; }

        [Column("DISBEMPLOYEENO")]
        public int? DisbursementEmployeeId { get; set; }

        [MaxLength(3)]
        [Column("SERVICECURRENCY")]
        public string ServiceCurrency { get; set; }

        [MaxLength(3)]
        [Column("SERVTAXCODE")]
        public string ServiceTaxCode { get; set; }

        [Column("SERVICENARRATIVE")]
        public short? ServiceNarrative { get; set; }

        [MaxLength(6)]
        [Column("SERVWIPCODE")]
        public string ServiceWipCode { get; set; }

        [Column("SERVBASEFEE")]
        public decimal? ServiceBaseFee { get; set; }

        [Column("SERVMINFEEFLAG")]
        public decimal? IsServiceMinFee { get; set; }

        [Column("SERVVARIABLEFEE")]
        public decimal? IsServiceVariableFee { get; set; }

        [Column("SERVADDPERCENTAGE")]
        public decimal? ServiceAddPercentage { get; set; }

        [Column("SERVDISBPERCENTAGE")]
        public decimal? ServiceDisbursementPercentage { get; set; }

        [Column("SERVUNITSIZE")]
        public short? ServiceUnitSize { get; set; }

        [Column("SERVBASEUNITS")]
        public short? ServiceBaseUnits { get; set; }

        [Column("SERVDISCFEEFLAG")]
        public bool? IsServiceDiscountFee { get; set; }

        [MaxLength(3)]
        [Column("SERVSTAFFNAMETYPE")]
        public string ServiceStaffNameType { get; set; }

        [Column("SERVMAXUNITS")]
        public short? ServiceMaxUnits { get; set; }

        [Column("SERVEMPLOYEENO")]
        public int? ServiceEmployeeId { get; set; }

        [Column("VARBASEFEE")]
        public decimal? VariableBaseFee { get; set; }

        [Column("VARBASEUNITS")]
        public short? VariableBaseUnits { get; set; }

        [Column("VARVARIABLEFEE")]
        public decimal? VariableVariableFee { get; set; }

        [Column("VARUNITSIZE")]
        public short? VariableUnitSize { get; set; }

        [Column("VARMAXUNITS")]
        public short? VariableMaxUnits { get; set; }

        [Column("VARMINFEEFLAG")]
        public decimal? IsVariableMinFee { get; set; }

        [MaxLength(6)]
        [Column("VARWIPCODE")]
        public string VariableWipCode { get; set; }

        [Column("VARFEEAPPLIES")]
        public decimal? VariableFeeApplies { get; set; }
    }
}