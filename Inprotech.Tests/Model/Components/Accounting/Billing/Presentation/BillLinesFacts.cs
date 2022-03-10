using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Presentation;
using Xunit;
using BillLineModel = InprotechKaizen.Model.Accounting.Billing.BillLine;
using BillLineDto = InprotechKaizen.Model.Components.Accounting.Billing.Presentation.BillLine;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Presentation
{
    public class BillLinesFacts : FactBase
    {
        [Fact]
        public async Task ShouldReturnRequestedBillLinesFromSingleBill()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            var billLine1 = new BillLineBuilder
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId
            }.Build().In(Db);

            var billLine2 = new BillLineBuilder
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId
            }.Build().In(Db);

            var subject = new BillLines(Db);

            var result = (await subject.Retrieve(itemEntityId, itemTransactionId))
                .ToArray();

            AssertBillLineEqual(billLine1, result.First());
            AssertBillLineEqual(billLine2, result.Last());
        }

        [Fact]
        public async Task ShouldReturnRequestedBillLinesFromMergedBill()
        {
            var keySet1 = (Fixture.Integer(), Fixture.Integer());
            var keySet2 = (Fixture.Integer(), Fixture.Integer());

            var billLine1 = new BillLineBuilder
            {
                ItemEntityId = keySet1.Item1,
                ItemTransactionId = keySet1.Item2
            }.Build().In(Db);

            var billLine2 = new BillLineBuilder
            {
                ItemEntityId = keySet1.Item1,
                ItemTransactionId = keySet1.Item2
            }.Build().In(Db);

            var billLine3 = new BillLineBuilder
            {
                ItemEntityId = keySet2.Item1,
                ItemTransactionId = keySet2.Item2
            }.Build().In(Db);

            // merging 2 bills, first bill has 2 bill lines, second bill has 1 bill line.

            var mergeXmlKeys = new MergeXmlKeys
            {
                OpenItemXmls =
                {
                    new OpenItemXmlKey
                    {
                        ItemEntityNo = keySet1.Item1,
                        ItemTransNo = keySet1.Item2
                    },
                    new OpenItemXmlKey
                    {
                        ItemEntityNo = keySet2.Item1,
                        ItemTransNo = keySet2.Item2
                    }
                }
            };

            var subject = new BillLines(Db);
            var result = (await subject.Retrieve(mergeXmlKeys))
                .ToArray();

            AssertBillLineEqual(billLine1, result.ElementAt(0));
            AssertBillLineEqual(billLine2, result.ElementAt(1));
            AssertBillLineEqual(billLine3, result.ElementAt(2));
        }

        static void AssertBillLineEqual(BillLineModel billLine, BillLineDto actual)
        {
            Assert.Equal(billLine.ItemEntityId, actual.ItemEntityId);
            Assert.Equal(billLine.ItemTransactionId, actual.ItemTransactionId);
            Assert.Equal(billLine.ItemLineNo, actual.ItemLineNo);
            Assert.Equal(billLine.WipCode, actual.WipCode);
            Assert.Equal(billLine.WipTypeId, actual.WipTypeId);
            Assert.Equal(billLine.CategoryCode, actual.CategoryCode);
            Assert.Equal(billLine.CaseReference, actual.CaseRef);
            Assert.Equal(billLine.Value, actual.Value);
            Assert.Equal(billLine.DisplaySequence, actual.DisplaySequence);
            Assert.Equal(billLine.PrintDate, actual.PrintDate);
            Assert.Equal(billLine.PrintName, actual.PrintName);
            Assert.Equal(billLine.PrintChargeOutRate, actual.PrintChargeOutRate);
            Assert.Equal(billLine.PrintTotalUnits, actual.PrintTotalUnits);
            Assert.Equal(billLine.UnitsPerHour, actual.UnitsPerHour);
            Assert.Equal(billLine.NarrativeId, actual.NarrativeId);
            Assert.Equal(billLine.ShortNarrative, actual.Narrative);
            Assert.Equal(billLine.ForeignValue, actual.ForeignValue);
            Assert.Equal(billLine.PrintChargeCurrency, actual.PrintChargeCurrency);
            Assert.Equal(billLine.PrintTime, actual.PrintTime);
            Assert.Equal(billLine.LocalTax, actual.LocalTax);
            Assert.Equal(billLine.GeneratedFromTaxCode, actual.GeneratedFromTaxCode);
            Assert.Equal(billLine.IsHiddenForDraft, actual.IsHiddenForDraft);
            Assert.Equal(billLine.TaxCode, actual.TaxCode);
        }
    }
}
