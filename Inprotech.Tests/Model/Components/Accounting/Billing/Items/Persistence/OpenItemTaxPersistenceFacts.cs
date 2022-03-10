using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class OpenItemTaxPersistenceFacts : FactBase
    {
        OpenItemTaxPersistence CreateSubject()
        {
            var logger = Substitute.For<ILogger<OpenItemTaxPersistence>>();

            return new OpenItemTaxPersistence(Db, logger);
        }

        [Fact]
        public async Task ShouldNotAddOpenItemTaxIfTaxRequiredSettingIsNotOn()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var debtorId = Fixture.Integer();

            var subject = CreateSubject();
            var r = await subject.Run(2, "pt",
                                      new BillingSiteSettings { TaxRequired = false },
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = accountEntityId,
                                          DebitOrCreditNotes = new[]
                                          {
                                              new DebitOrCreditNote
                                              {
                                                  DebtorNameId = debtorId,
                                                  Taxes = new[]
                                                  {
                                                      new DebitOrCreditNoteTax()
                                                  }
                                              }
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);
            Assert.Empty(Db.Set<OpenItemTax>()); // nothing was persisted
        }

        [Fact]
        public async Task ShouldAddLocalOpenItemTaxIfTaxRequiredSettingIsOn()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var debtorId = Fixture.Integer();
            var taxCode = Fixture.String();
            var taxRate = Fixture.Decimal();
            var taxableAmount = Fixture.Decimal();
            var taxAmount = Fixture.Decimal();
            
            var subject = CreateSubject();
            var r = await subject.Run(2, "pt",
                                      new BillingSiteSettings { TaxRequired = true },
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = accountEntityId,
                                          DebitOrCreditNotes = new[]
                                          {
                                              new DebitOrCreditNote
                                              {
                                                  DebtorNameId = debtorId,
                                                  Taxes = new[]
                                                  {
                                                      new DebitOrCreditNoteTax
                                                      {
                                                          TaxCode = taxCode,
                                                          TaxRate = taxRate,
                                                          TaxableAmount = taxableAmount,
                                                          TaxAmount = taxAmount
                                                      }
                                                  }
                                              }
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var persisted = Db.Set<OpenItemTax>().Single();

            Assert.Equal(itemEntityId, persisted.ItemEntityId);
            Assert.Equal(itemTransactionId, persisted.ItemTransactionId);
            Assert.Equal(accountEntityId, persisted.AccountEntityId);
            Assert.Equal(debtorId, persisted.AccountDebtorId);
            Assert.Equal(taxCode, persisted.TaxCode);
            Assert.Equal(taxRate, persisted.TaxRate);
            Assert.Equal(taxableAmount, persisted.TaxableAmount);
            Assert.Equal(taxAmount, persisted.TaxAmount);
        }

        [Fact]
        public async Task ShouldAddForeignOpenItemTaxIfTaxRequiredSettingIsOn()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var debtorId = Fixture.Integer();
            var taxCode = Fixture.String();
            var taxRate = Fixture.Decimal();
            var taxableAmount = Fixture.Decimal();
            var taxAmount = Fixture.Decimal();
            var foreignTaxableAmount = Fixture.Decimal();
            var foreignTaxAmount = Fixture.Decimal();
            var currency = Fixture.String();

            var subject = CreateSubject();
            var r = await subject.Run(2, "pt",
                                      new BillingSiteSettings { TaxRequired = true },
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = accountEntityId,
                                          DebitOrCreditNotes = new[]
                                          {
                                              new DebitOrCreditNote
                                              {
                                                  DebtorNameId = debtorId,
                                                  Taxes = new[]
                                                  {
                                                      new DebitOrCreditNoteTax
                                                      {
                                                          TaxCode = taxCode,
                                                          TaxRate = taxRate,
                                                          TaxableAmount = taxableAmount,
                                                          TaxAmount = taxAmount,
                                                          ForeignTaxableAmount = foreignTaxableAmount,
                                                          ForeignTaxAmount = foreignTaxAmount,
                                                          Currency = currency
                                                      }
                                                  }
                                              }
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var persisted = Db.Set<OpenItemTax>().Single();

            Assert.Equal(itemEntityId, persisted.ItemEntityId);
            Assert.Equal(itemTransactionId, persisted.ItemTransactionId);
            Assert.Equal(accountEntityId, persisted.AccountEntityId);
            Assert.Equal(debtorId, persisted.AccountDebtorId);
            Assert.Equal(taxCode, persisted.TaxCode);
            Assert.Equal(taxRate, persisted.TaxRate);
            Assert.Equal(taxableAmount, persisted.TaxableAmount);
            Assert.Equal(taxAmount, persisted.TaxAmount);
            Assert.Equal(foreignTaxableAmount, persisted.ForeignTaxableAmount);
            Assert.Equal(foreignTaxAmount, persisted.ForeignTaxAmount);
            Assert.Equal(currency, persisted.Currency);
        }
    }
}
