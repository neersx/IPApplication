using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Components.Accounting.Billing.Presentation;
using NSubstitute;
using Xunit;

using BillLineEntity = InprotechKaizen.Model.Accounting.Billing.BillLine;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class BillLinePersistenceFacts : FactBase
    {
        BillLinePersistence CreateSubject()
        {
            var logger = Substitute.For<ILogger<BillLinePersistence>>();
            return new BillLinePersistence(Db, logger);
        }

        [Fact]
        public async Task ShouldPersistAndIncrementLineNumber()
        {
            var requestId = Guid.NewGuid();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            var billLine1 = new BillLine
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                CaseRef = Fixture.String(),
                WipCode = Fixture.String(),
                WipTypeId = Fixture.String(),
                CategoryCode = Fixture.String(),
                UnitsPerHour = Fixture.Short(),
                Value = Fixture.Decimal(),
                ForeignValue = Fixture.Decimal(),
                TaxCode = Fixture.String(),
                LocalTax = Fixture.Decimal(),
                NarrativeId = Fixture.Short(),
                Narrative = Fixture.RandomString(2000), // long narrative
                DisplaySequence = Fixture.Short(),
                PrintTime = Fixture.String(),
                PrintDate = Fixture.Today(),
                PrintName = Fixture.String(),
                PrintTotalUnits = Fixture.Short(),
                PrintChargeOutRate = Fixture.Decimal(),
                PrintChargeCurrency = Fixture.String(),
                GeneratedFromTaxCode = Fixture.String(),
                IsHiddenForDraft = Fixture.Boolean()
            };

            var billLine2 = new BillLine
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                CaseRef = Fixture.String(),
                WipCode = Fixture.String(),
                WipTypeId = Fixture.String(),
                CategoryCode = Fixture.String(),
                UnitsPerHour = Fixture.Short(),
                Value = Fixture.Decimal(),
                ForeignValue = Fixture.Decimal(),
                TaxCode = Fixture.String(),
                LocalTax = Fixture.Decimal(),
                NarrativeId = Fixture.Short(),
                Narrative = Fixture.RandomString(200), // short narrative
                DisplaySequence = Fixture.Short(),
                PrintTime = Fixture.String(),
                PrintDate = Fixture.Today(),
                PrintName = Fixture.String(),
                PrintTotalUnits = Fixture.Short(),
                PrintChargeOutRate = Fixture.Decimal(),
                PrintChargeCurrency = Fixture.String(),
                GeneratedFromTaxCode = Fixture.String(),
                IsHiddenForDraft = Fixture.Boolean()
            };
            
            var subject = CreateSubject();

            await subject.Run(2, "es", new BillingSiteSettings(),
                              new OpenItemModel
                              {
                                  ItemEntityId = itemEntityId,
                                  ItemTransactionId = itemTransactionId,
                                  BillLines = new[]
                                  {
                                      billLine1,
                                      billLine2
                                  }
                              },
                              new SaveOpenItemResult(requestId));

            var billLinePersisted1 = Db.Set<BillLineEntity>().Single(_ => _.ItemLineNo == 1);

            Assert.Equal(billLine1.ItemEntityId, billLinePersisted1.ItemEntityId);
            Assert.Equal(billLine1.ItemTransactionId, billLinePersisted1.ItemTransactionId);
            Assert.Equal(1, billLinePersisted1.ItemLineNo);
            Assert.Equal(billLine1.CaseRef, billLinePersisted1.CaseReference);
            Assert.Equal(billLine1.WipCode, billLinePersisted1.WipCode);
            Assert.Equal(billLine1.WipTypeId, billLinePersisted1.WipTypeId);
            Assert.Equal(billLine1.CategoryCode, billLinePersisted1.CategoryCode);
            Assert.Equal(billLine1.UnitsPerHour, billLinePersisted1.UnitsPerHour);
            Assert.Equal(billLine1.Value, billLinePersisted1.Value);
            Assert.Equal(billLine1.ForeignValue, billLinePersisted1.ForeignValue);
            Assert.Equal(billLine1.TaxCode, billLinePersisted1.TaxCode);
            Assert.Equal(billLine1.LocalTax, billLinePersisted1.LocalTax);
            Assert.Equal(billLine1.NarrativeId, billLinePersisted1.NarrativeId);
            Assert.Null(billLinePersisted1.ShortNarrative);
            Assert.Equal(billLine1.Narrative, billLinePersisted1.LongNarrative);
            Assert.Equal(billLine1.DisplaySequence, billLinePersisted1.DisplaySequence);
            Assert.Equal(billLine1.PrintTime, billLinePersisted1.PrintTime);
            Assert.Equal(billLine1.PrintDate, billLinePersisted1.PrintDate);
            Assert.Equal(billLine1.PrintName, billLinePersisted1.PrintName);
            Assert.Equal(billLine1.PrintTotalUnits, billLinePersisted1.PrintTotalUnits);
            Assert.Equal(billLine1.PrintChargeOutRate, billLinePersisted1.PrintChargeOutRate);
            Assert.Equal(billLine1.PrintChargeCurrency, billLinePersisted1.PrintChargeCurrency);
            Assert.Equal(billLine1.GeneratedFromTaxCode, billLinePersisted1.GeneratedFromTaxCode);
            Assert.Equal(billLine1.IsHiddenForDraft, billLinePersisted1.IsHiddenForDraft);
            
            var billLinePersisted2 = Db.Set<BillLineEntity>().Single(_ => _.ItemLineNo == 2);

            Assert.Equal(billLine2.ItemEntityId, billLinePersisted2.ItemEntityId);
            Assert.Equal(billLine2.ItemTransactionId, billLinePersisted2.ItemTransactionId);
            Assert.Equal(2, billLinePersisted2.ItemLineNo);
            Assert.Equal(billLine2.CaseRef, billLinePersisted2.CaseReference);
            Assert.Equal(billLine2.WipCode, billLinePersisted2.WipCode);
            Assert.Equal(billLine2.WipTypeId, billLinePersisted2.WipTypeId);
            Assert.Equal(billLine2.CategoryCode, billLinePersisted2.CategoryCode);
            Assert.Equal(billLine2.UnitsPerHour, billLinePersisted2.UnitsPerHour);
            Assert.Equal(billLine2.Value, billLinePersisted2.Value);
            Assert.Equal(billLine2.ForeignValue, billLinePersisted2.ForeignValue);
            Assert.Equal(billLine2.TaxCode, billLinePersisted2.TaxCode);
            Assert.Equal(billLine2.LocalTax, billLinePersisted2.LocalTax);
            Assert.Equal(billLine2.NarrativeId, billLinePersisted2.NarrativeId);
            Assert.Equal(billLine2.Narrative, billLinePersisted2.ShortNarrative);
            Assert.Null(billLinePersisted2.LongNarrative);
            Assert.Equal(billLine2.DisplaySequence, billLinePersisted2.DisplaySequence);
            Assert.Equal(billLine2.PrintTime, billLinePersisted2.PrintTime);
            Assert.Equal(billLine2.PrintDate, billLinePersisted2.PrintDate);
            Assert.Equal(billLine2.PrintName, billLinePersisted2.PrintName);
            Assert.Equal(billLine2.PrintTotalUnits, billLinePersisted2.PrintTotalUnits);
            Assert.Equal(billLine2.PrintChargeOutRate, billLinePersisted2.PrintChargeOutRate);
            Assert.Equal(billLine2.PrintChargeCurrency, billLinePersisted2.PrintChargeCurrency);
            Assert.Equal(billLine2.GeneratedFromTaxCode, billLinePersisted2.GeneratedFromTaxCode);
            Assert.Equal(billLine2.IsHiddenForDraft, billLinePersisted2.IsHiddenForDraft);
        }
    }
}
