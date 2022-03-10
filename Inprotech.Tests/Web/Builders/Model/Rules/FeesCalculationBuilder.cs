using System;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Rules
{
    public class FeesCalculationBuilder : IBuilder<FeesCalculation>
    {
        public int? CriteriaId { get; protected set; }

        public short? UniqueId { get; set; }

        public int? FromEventId { get; set; }

        public int? AgentId { get; set; }

        public int? OwnerId { get; set; }

        public int? DebtorId { get; set; }

        public int? InstructorId { get; set; }

        public int? DebtorType { get; set; }

        public short? CycleNumber { get; set; }

        public DateTime? ValidFromDate { get; set; }

        public short? DebitNote { get; set; }

        public short? CoveringLetterId { get; set; }

        public decimal? GenerateCharges { get; set; }

        public string FeeType { get; set; }

        public decimal? IsIpOfficeFee { get; set; }

        public int? ProductCode { get; set; }

        public decimal? IsInherited { get; set; }

        public short? ParameterSource { get; set; }

        public short? ParameterSource2 { get; set; }

        public string FeeType2 { get; set; }

        public string WriteUpReason { get; set; }

        public string DisbursementCurrency { get; set; }

        public string DisbursementTaxCode { get; set; }

        public short? DisbursementNarrative { get; set; }

        public string DisbursementWipCode { get; set; }

        public decimal? DisbursementBaseFee { get; set; }

        public decimal? IsDisbursementMinFee { get; set; }

        public decimal? IsDisbursementVariableFee { get; set; }

        public decimal? DisbursementAddPercentage { get; set; }

        public short? DisbursementUnitSize { get; set; }

        public short? DisbursementBaseUnits { get; set; }

        public string DisbursementStaffNameType { get; set; }

        public bool? IsDisbursementDiscountFee { get; set; }

        public short? DisbursementMaxUnits { get; set; }

        public int? DisbursementEmployeeId { get; set; }

        public string ServiceCurrency { get; set; }

        public string ServiceTaxCode { get; set; }

        public short? ServiceNarrative { get; set; }

        public string ServiceWipCode { get; set; }

        public decimal? ServiceBaseFee { get; set; }

        public decimal? IsServiceMinFee { get; set; }

        public decimal? IsServiceVariableFee { get; set; }

        public decimal? ServiceAddPercentage { get; set; }

        public decimal? ServiceDisbursementPercentage { get; set; }

        public short? ServiceUnitSize { get; set; }

        public short? ServiceBaseUnits { get; set; }

        public bool? IsServiceDiscountFee { get; set; }

        public string ServiceStaffNameType { get; set; }

        public short? ServiceMaxUnits { get; set; }

        public int? ServiceEmployeeId { get; set; }

        public decimal? VariableBaseFee { get; set; }

        public short? VariableBaseUnits { get; set; }

        public decimal? VariableVariableFee { get; set; }

        public short? VariableUnitSize { get; set; }

        public short? VariableMaxUnits { get; set; }

        public decimal? IsVariableMinFee { get; set; }

        public string VariableWipCode { get; set; }

        public decimal? VariableFeeApplies { get; set; }

        public FeesCalculation Build()
        {
            return new FeesCalculation
            {
                CriteriaId = CriteriaId ?? Fixture.Integer(),
                UniqueId = UniqueId ?? Fixture.Short(),
                FromEventId = FromEventId ?? Fixture.Integer(),
                AgentId = AgentId ?? Fixture.Integer(),
                OwnerId = OwnerId ?? Fixture.Integer(),
                DebtorId = DebtorId ?? Fixture.Integer(),
                InstructorId = InstructorId ?? Fixture.Integer(),
                DebtorType = DebtorType ?? Fixture.Integer(),
                CycleNumber = CycleNumber ?? Fixture.Short(),
                ValidFromDate = ValidFromDate ?? Fixture.Today(),
                DebitNote = DebitNote ?? Fixture.Short(),
                CoveringLetterId = CoveringLetterId ?? Fixture.Short(),
                ShouldGenerateCharges = GenerateCharges ?? Fixture.Decimal(),
                FeeType = FeeType ?? Fixture.String(),
                IsIpOfficeFee = IsIpOfficeFee ?? Fixture.Decimal(),
                ProductCode = ProductCode ?? Fixture.Integer(),
                IsInherited = IsInherited ?? Fixture.Decimal(),
                ParameterSource = ParameterSource ?? Fixture.Short(),
                ParameterSource2 = ParameterSource2 ?? Fixture.Short(),
                FeeType2 = FeeType2 ?? Fixture.String(),
                WriteUpReason = WriteUpReason ?? Fixture.String(),
                DisbursementCurrency = DisbursementCurrency ?? Fixture.String(),
                DisbursementTaxCode = DisbursementTaxCode ?? Fixture.String(),
                DisbursementNarrative = DisbursementNarrative ?? Fixture.Short(),
                DisbursementWipCode = DisbursementWipCode ?? Fixture.String(),
                DisbursementBaseFee = DisbursementBaseFee ?? Fixture.Decimal(),
                IsDisbursementMinFee = IsDisbursementMinFee ?? Fixture.Decimal(),
                IsDisbursementVariableFee = IsDisbursementVariableFee ?? Fixture.Decimal(),
                DisbursementAddPercentage = DisbursementAddPercentage ?? Fixture.Decimal(),
                DisbursementUnitSize = DisbursementUnitSize ?? Fixture.Short(),
                DisbursementBaseUnits = DisbursementBaseUnits ?? Fixture.Short(),
                DisbursementStaffNameType = DisbursementStaffNameType ?? Fixture.String(),
                IsDisbursementDiscountFee = IsDisbursementDiscountFee ?? Fixture.Boolean(),
                DisbursementMaxUnits = DisbursementMaxUnits ?? Fixture.Short(),
                DisbursementEmployeeId = DisbursementEmployeeId ?? Fixture.Integer(),
                ServiceCurrency = ServiceCurrency ?? Fixture.String(),
                ServiceTaxCode = ServiceTaxCode ?? Fixture.String(),
                ServiceNarrative = ServiceNarrative ?? Fixture.Short(),
                ServiceWipCode = ServiceWipCode ?? Fixture.String(),
                ServiceBaseFee = ServiceBaseFee ?? Fixture.Decimal(),
                IsServiceMinFee = IsServiceMinFee ?? Fixture.Decimal(),
                IsServiceVariableFee = IsServiceVariableFee ?? Fixture.Decimal(),
                ServiceAddPercentage = ServiceAddPercentage ?? Fixture.Decimal(),
                ServiceDisbursementPercentage = ServiceDisbursementPercentage ?? Fixture.Decimal(),
                ServiceUnitSize = ServiceUnitSize ?? Fixture.Short(),
                ServiceBaseUnits = ServiceBaseUnits ?? Fixture.Short(),
                IsServiceDiscountFee = IsServiceDiscountFee ?? Fixture.Boolean(),
                ServiceStaffNameType = ServiceStaffNameType ?? Fixture.String(),
                ServiceMaxUnits = ServiceMaxUnits ?? Fixture.Short(),
                ServiceEmployeeId = ServiceEmployeeId ?? Fixture.Integer(),
                VariableBaseFee = VariableBaseFee ?? Fixture.Decimal(),
                VariableBaseUnits = VariableBaseUnits ?? Fixture.Short(),
                VariableVariableFee = VariableVariableFee ?? Fixture.Decimal(),
                VariableUnitSize = VariableUnitSize ?? Fixture.Short(),
                VariableMaxUnits = VariableMaxUnits ?? Fixture.Short(),
                IsVariableMinFee = IsVariableMinFee ?? Fixture.Decimal(),
                VariableWipCode = VariableWipCode ?? Fixture.String(),
                VariableFeeApplies = VariableFeeApplies ?? Fixture.Decimal()
            };
        }
    }
}