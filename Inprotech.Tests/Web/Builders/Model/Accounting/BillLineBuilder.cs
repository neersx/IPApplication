using InprotechKaizen.Model.Accounting.Billing;

namespace Inprotech.Tests.Web.Builders.Model.Accounting
{
    public class BillLineBuilder : IBuilder<BillLine>
    {
        public int? ItemEntityId { get; set; }
        public int? ItemTransactionId { get; set; }

        public BillLine Build()
        {
            return new BillLine
            {
                ItemEntityId = ItemEntityId ?? Fixture.Integer(),
                ItemTransactionId = ItemTransactionId ?? Fixture.Integer(),
                ItemLineNo = Fixture.Short(),
                WipCode = Fixture.String(),
                WipTypeId = Fixture.String(),
                CategoryCode = Fixture.String(),
                CaseReference = Fixture.String(),
                Value = Fixture.Decimal(),
                DisplaySequence = Fixture.Short(),
                PrintDate = Fixture.Today(),
                PrintName = Fixture.String(),
                PrintChargeOutRate = Fixture.Decimal(),
                PrintTotalUnits = Fixture.Short(),
                UnitsPerHour = Fixture.Short(),
                NarrativeId = Fixture.Short(),
                ShortNarrative = Fixture.String(),
                ForeignValue = Fixture.Decimal(),
                PrintChargeCurrency = Fixture.String(),
                PrintTime = Fixture.String(),
                LocalTax = Fixture.Decimal(),
                GeneratedFromTaxCode = Fixture.String(),
                IsHiddenForDraft = Fixture.Boolean(),
                TaxCode = Fixture.String()
            };
        }
    }
}