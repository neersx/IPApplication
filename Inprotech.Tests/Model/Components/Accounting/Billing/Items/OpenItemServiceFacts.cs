using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Components.Accounting.Billing.Presentation;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items
{
    public class OpenItemServiceFacts
    {
        public class PrepareForNewDraftBillMethod
        {
            [Theory]
            [InlineData(ItemTypesForBilling.DebitNote)]
            [InlineData(ItemTypesForBilling.CreditNote)]
            [InlineData(ItemTypesForBilling.InternalDebitNote)]
            [InlineData(ItemTypesForBilling.InternalCreditNote)]
            public async Task ShouldReturnDefaultOpenItemMetadataForRequestedItemType(ItemTypesForBilling itemTypeForBilling)
            {
                var userId = Fixture.Integer();
                var culture = Fixture.String();
                var result = new OpenItemModel();

                var f = new OpenItemServiceFixture();

                f.GetOpenItemCommand.GetOpenItemDefaultForItemType(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>())
                 .Returns(result);

                var openItem = await f.Subject.PrepareForNewDraftBill(userId, culture, itemTypeForBilling);

                Assert.Equal(result, openItem);

                f.GetOpenItemCommand.Received(1)
                 .GetOpenItemDefaultForItemType(userId, culture, (int)itemTypeForBilling)
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class RetrieveForExistingBillMethod
        {
            [Theory]
            [InlineData(ItemTypesForBilling.DebitNote)]
            [InlineData(ItemTypesForBilling.InternalDebitNote)]
            public async Task ShouldReturnRequestedDebitNote(ItemTypesForBilling itemType)
            {
                var userId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemNo = Fixture.String();

                var fromDb = new OpenItemModel
                {
                    ItemType = (int)itemType,
                    LocalValue = Fixture.Decimal(),
                    LocalBalance = Fixture.Decimal(),
                    LocalTaxAmount = Fixture.Decimal(),
                    ItemPreTaxValue = Fixture.Decimal(),
                    BillTotal = Fixture.Decimal(),

                    Currency = Fixture.String(),
                    ForeignValue = Fixture.Decimal(),
                    ForeignBalance = Fixture.Decimal(),
                    ForeignTaxAmount = Fixture.Decimal(),
                    ExchangeRateVariance = Fixture.Decimal(),

                    BillLines = new List<BillLine>
                    {
                        new()
                        {
                            Value = Fixture.Decimal(),
                            ForeignValue = Fixture.Decimal(),
                            LocalTax = Fixture.Decimal()
                        }
                    },

                    DebitOrCreditNotes = new List<DebitOrCreditNote>
                    {
                        new()
                        {
                            LocalValue = Fixture.Decimal(),
                            LocalBalance = Fixture.Decimal(),
                            LocalTaxAmount = Fixture.Decimal(),
                            Currency = Fixture.String(),
                            ForeignValue = Fixture.Decimal(),
                            ForeignBalance = Fixture.Decimal(),
                            ForeignTaxAmount = Fixture.Decimal(),
                            ExchangeRateVariance = Fixture.Decimal(),

                            Taxes = new List<DebitOrCreditNoteTax>
                            {
                                new()
                                {
                                    TaxAmount = Fixture.Decimal(),
                                    TaxableAmount = Fixture.Decimal(),
                                    ForeignTaxAmount = Fixture.Decimal(),
                                    ForeignTaxableAmount = Fixture.Decimal()
                                }
                            }
                        }
                    },

                    AvailableWipItems = new List<AvailableWipItem>
                    {
                        new()
                        {
                            Balance = Fixture.Decimal(),
                            ForeignBalance = Fixture.Decimal(),
                            LocalBilled = Fixture.Decimal(),
                            ForeignBilled = Fixture.Decimal(),
                            LocalVariation = Fixture.Decimal(),
                            ForeignVariation = Fixture.Decimal(),
                            VariableFeeAmount = Fixture.Decimal()
                        }
                    }
                };

                var f = new OpenItemServiceFixture();

                f.GetOpenItemCommand.GetOpenItem(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<string>())
                 .Returns(fromDb);

                var openItem = await f.Subject.RetrieveForExistingBill(userId, culture, itemEntityId, openItemNo);

                Assert.Equal(fromDb.LocalValue, openItem.LocalValue);
                Assert.Equal(fromDb.LocalBalance, openItem.LocalBalance);
                Assert.Equal(fromDb.LocalTaxAmount, openItem.LocalTaxAmount);
                Assert.Equal(fromDb.ItemPreTaxValue, openItem.ItemPreTaxValue);
                Assert.Equal(fromDb.BillTotal, openItem.BillTotal);
                Assert.Equal(fromDb.Currency, openItem.Currency);
                Assert.Equal(fromDb.ForeignValue, openItem.ForeignValue);

                Assert.Equal(fromDb.ForeignBalance, openItem.ForeignBalance);
                Assert.Equal(fromDb.ForeignTaxAmount, openItem.ForeignTaxAmount);
                Assert.Equal(fromDb.ExchangeRateVariance, openItem.ExchangeRateVariance);

                var billLineFromDb = fromDb.BillLines.First();
                var openItemBillLine = openItem.BillLines.First();

                Assert.Equal(billLineFromDb.Value, openItemBillLine.Value);
                Assert.Equal(billLineFromDb.ForeignValue, openItemBillLine.ForeignValue);
                Assert.Equal(billLineFromDb.LocalTax, openItemBillLine.LocalTax);

                var debitOrCreditNoteFromDb = fromDb.DebitOrCreditNotes.First();
                var openItemDebitOrCreditNote = openItem.DebitOrCreditNotes.First();

                Assert.Equal(debitOrCreditNoteFromDb.LocalValue, openItemDebitOrCreditNote.LocalValue);
                Assert.Equal(debitOrCreditNoteFromDb.LocalBalance, openItemDebitOrCreditNote.LocalBalance);
                Assert.Equal(debitOrCreditNoteFromDb.LocalTaxAmount, openItemDebitOrCreditNote.LocalTaxAmount);
                Assert.Equal(debitOrCreditNoteFromDb.Currency, openItemDebitOrCreditNote.Currency);
                Assert.Equal(debitOrCreditNoteFromDb.ForeignValue, openItemDebitOrCreditNote.ForeignValue);
                Assert.Equal(debitOrCreditNoteFromDb.ForeignBalance, openItemDebitOrCreditNote.ForeignBalance);
                Assert.Equal(debitOrCreditNoteFromDb.ForeignTaxAmount, openItemDebitOrCreditNote.ForeignTaxAmount);
                Assert.Equal(debitOrCreditNoteFromDb.ExchangeRateVariance, openItemDebitOrCreditNote.ExchangeRateVariance);

                var taxFromDb = debitOrCreditNoteFromDb.Taxes.First();
                var openItemDebitOrCreditNoteTax = openItemDebitOrCreditNote.Taxes.First();

                Assert.Equal(taxFromDb.TaxAmount, openItemDebitOrCreditNoteTax.TaxAmount);
                Assert.Equal(taxFromDb.TaxableAmount, openItemDebitOrCreditNoteTax.TaxableAmount);
                Assert.Equal(taxFromDb.ForeignTaxAmount, openItemDebitOrCreditNoteTax.ForeignTaxAmount);
                Assert.Equal(taxFromDb.ForeignTaxableAmount, openItemDebitOrCreditNoteTax.ForeignTaxableAmount);

                var availableWipFromDb = fromDb.AvailableWipItems.First();
                var openItemAvailableWip = openItem.AvailableWipItems.First();

                Assert.Equal(availableWipFromDb.Balance, openItemAvailableWip.Balance);
                Assert.Equal(availableWipFromDb.ForeignBalance, openItemAvailableWip.ForeignBalance);
                Assert.Equal(availableWipFromDb.LocalBilled, openItemAvailableWip.LocalBilled);
                Assert.Equal(availableWipFromDb.ForeignBilled, openItemAvailableWip.ForeignBilled);
                Assert.Equal(availableWipFromDb.LocalVariation, openItemAvailableWip.LocalVariation);
                Assert.Equal(availableWipFromDb.ForeignVariation, openItemAvailableWip.ForeignVariation);
                Assert.Equal(availableWipFromDb.VariableFeeAmount, openItemAvailableWip.VariableFeeAmount);

                f.GetOpenItemCommand.Received(1)
                 .GetOpenItem(userId, culture, itemEntityId, openItemNo)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(ItemTypesForBilling.CreditNote)]
            [InlineData(ItemTypesForBilling.InternalCreditNote)]
            public async Task ShouldReturnRequestedCreditBillWithSignsSwapped(ItemTypesForBilling itemType)
            {
                var userId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemNo = Fixture.String();

                var retFromDb = new OpenItemModel
                {
                    ItemType = (int)itemType,
                    LocalValue = Fixture.Decimal(),
                    LocalBalance = Fixture.Decimal(),
                    LocalTaxAmount = Fixture.Decimal(),
                    ItemPreTaxValue = Fixture.Decimal(),
                    BillTotal = Fixture.Decimal(),

                    Currency = Fixture.String(),
                    ForeignValue = Fixture.Decimal(),
                    ForeignBalance = Fixture.Decimal(),
                    ForeignTaxAmount = Fixture.Decimal(),
                    ExchangeRateVariance = Fixture.Decimal(),

                    BillLines = new List<BillLine>
                    {
                        new()
                        {
                            Value = Fixture.Decimal(),
                            ForeignValue = Fixture.Decimal(),
                            LocalTax = Fixture.Decimal()
                        }
                    },

                    DebitOrCreditNotes = new List<DebitOrCreditNote>
                    {
                        new()
                        {
                            LocalValue = Fixture.Decimal(),
                            LocalBalance = Fixture.Decimal(),
                            LocalTaxAmount = Fixture.Decimal(),
                            Currency = Fixture.String(),
                            ForeignValue = Fixture.Decimal(),
                            ForeignBalance = Fixture.Decimal(),
                            ForeignTaxAmount = Fixture.Decimal(),
                            ExchangeRateVariance = Fixture.Decimal(),

                            Taxes = new List<DebitOrCreditNoteTax>
                            {
                                new()
                                {
                                    TaxAmount = Fixture.Decimal(),
                                    TaxableAmount = Fixture.Decimal(),
                                    ForeignTaxAmount = Fixture.Decimal(),
                                    ForeignTaxableAmount = Fixture.Decimal()
                                }
                            }
                        }
                    },

                    AvailableWipItems = new List<AvailableWipItem>
                    {
                        new()
                        {
                            Balance = Fixture.Decimal(),
                            ForeignBalance = Fixture.Decimal(),
                            LocalBilled = Fixture.Decimal(),
                            ForeignBilled = Fixture.Decimal(),
                            LocalVariation = Fixture.Decimal(),
                            ForeignVariation = Fixture.Decimal(),
                            VariableFeeAmount = Fixture.Decimal()
                        }
                    }
                };

                var expected = JObject.FromObject(retFromDb).ToObject<OpenItemModel>(); /* make a copy */

                var f = new OpenItemServiceFixture();

                f.GetOpenItemCommand.GetOpenItem(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<string>())
                 .Returns(retFromDb);

                var openItem = await f.Subject.RetrieveForExistingBill(userId, culture, itemEntityId, openItemNo);

                Assert.Equal(expected.LocalValue * -1, openItem.LocalValue);
                Assert.Equal(expected.LocalBalance * -1, openItem.LocalBalance);
                Assert.Equal(expected.LocalTaxAmount * -1, openItem.LocalTaxAmount);
                Assert.Equal(expected.ItemPreTaxValue * -1, openItem.ItemPreTaxValue);
                Assert.Equal(expected.BillTotal * -1, openItem.BillTotal);
                Assert.Equal(expected.Currency, openItem.Currency);
                Assert.Equal(expected.ForeignValue * -1, openItem.ForeignValue);

                Assert.Equal(expected.ForeignBalance * -1, openItem.ForeignBalance);
                Assert.Equal(expected.ForeignTaxAmount * -1, openItem.ForeignTaxAmount);
                Assert.Equal(expected.ExchangeRateVariance * -1, openItem.ExchangeRateVariance);

                var billLineFromDb = expected.BillLines.First();
                var openItemBillLine = openItem.BillLines.First();

                Assert.Equal(billLineFromDb.Value * -1, openItemBillLine.Value);
                Assert.Equal(billLineFromDb.ForeignValue * -1, openItemBillLine.ForeignValue);
                Assert.Equal(billLineFromDb.LocalTax * -1, openItemBillLine.LocalTax);

                var debitOrCreditNoteFromDb = expected.DebitOrCreditNotes.First();
                var openItemDebitOrCreditNote = openItem.DebitOrCreditNotes.First();

                Assert.Equal(debitOrCreditNoteFromDb.LocalValue * -1, openItemDebitOrCreditNote.LocalValue);
                Assert.Equal(debitOrCreditNoteFromDb.LocalBalance * -1, openItemDebitOrCreditNote.LocalBalance);
                Assert.Equal(debitOrCreditNoteFromDb.LocalTaxAmount * -1, openItemDebitOrCreditNote.LocalTaxAmount);
                Assert.Equal(debitOrCreditNoteFromDb.Currency, openItemDebitOrCreditNote.Currency);
                Assert.Equal(debitOrCreditNoteFromDb.ForeignValue * -1, openItemDebitOrCreditNote.ForeignValue);
                Assert.Equal(debitOrCreditNoteFromDb.ForeignBalance * -1, openItemDebitOrCreditNote.ForeignBalance);
                Assert.Equal(debitOrCreditNoteFromDb.ForeignTaxAmount * -1, openItemDebitOrCreditNote.ForeignTaxAmount);
                Assert.Equal(debitOrCreditNoteFromDb.ExchangeRateVariance * -1, openItemDebitOrCreditNote.ExchangeRateVariance);

                var taxFromDb = debitOrCreditNoteFromDb.Taxes.First();
                var openItemDebitOrCreditNoteTax = openItemDebitOrCreditNote.Taxes.First();

                Assert.Equal(taxFromDb.TaxAmount * -1, openItemDebitOrCreditNoteTax.TaxAmount);
                Assert.Equal(taxFromDb.TaxableAmount * -1, openItemDebitOrCreditNoteTax.TaxableAmount);
                Assert.Equal(taxFromDb.ForeignTaxAmount * -1, openItemDebitOrCreditNoteTax.ForeignTaxAmount);
                Assert.Equal(taxFromDb.ForeignTaxableAmount * -1, openItemDebitOrCreditNoteTax.ForeignTaxableAmount);

                var availableWipFromDb = expected.AvailableWipItems.First();
                var openItemAvailableWip = openItem.AvailableWipItems.First();

                Assert.Equal(availableWipFromDb.Balance * -1, openItemAvailableWip.Balance);
                Assert.Equal(availableWipFromDb.ForeignBalance * -1, openItemAvailableWip.ForeignBalance);
                Assert.Equal(availableWipFromDb.LocalBilled * -1, openItemAvailableWip.LocalBilled);
                Assert.Equal(availableWipFromDb.ForeignBilled * -1, openItemAvailableWip.ForeignBilled);
                Assert.Equal(availableWipFromDb.LocalVariation * -1, openItemAvailableWip.LocalVariation);
                Assert.Equal(availableWipFromDb.ForeignVariation * -1, openItemAvailableWip.ForeignVariation);
                Assert.Equal(availableWipFromDb.VariableFeeAmount * -1, openItemAvailableWip.VariableFeeAmount);

                f.GetOpenItemCommand.Received(1)
                 .GetOpenItem(userId, culture, itemEntityId, openItemNo)
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class MergeSelectedDraftDebitNotesMethod
        {
            readonly string _culture = Fixture.String();
            readonly string _openItemNo1 = Fixture.String();
            readonly string _openItemNo2 = Fixture.String();
            readonly string _openItemNo3 = Fixture.String();
            readonly int _userId = Fixture.Integer();

            [Fact]
            public async Task ShouldReturnItemsConsolidatedIntoOneWithDetailsFromTheFirst()
            {
                var f = new OpenItemServiceFixture()
                    .WithOpenItems(new OpenItemModel { ItemEntityId = 1, AccountEntityId = 1, StaffId = 1, ItemType = (int)ItemType.DebitNote, BillFormatId = 2, LanguageId = 3 },
                                   new OpenItemModel { ItemEntityId = 2, AccountEntityId = 2, StaffId = 2, ItemType = (int)ItemType.DebitNote, BillFormatId = 3, LanguageId = 4 },
                                   new OpenItemModel { ItemEntityId = 3, AccountEntityId = 3, StaffId = 3, ItemType = (int)ItemType.DebitNote, BillFormatId = 4, LanguageId = 5 });

                var r = await f.Subject.MergeSelectedDraftDebitNotes(_userId, _culture, _openItemNo1 + "|" + _openItemNo2 + "|" + _openItemNo3);

                Assert.Equal(1, r.ItemEntityId);
                Assert.Equal(1, r.AccountEntityId);
                Assert.Equal(1, r.StaffId);
                Assert.Equal((short) 2, r.BillFormatId);
                Assert.Equal(3, r.LanguageId);
                Assert.Equal(Fixture.Today(), r.ItemDate);
                Assert.Equal((int)TransactionStatus.Draft, r.Status);
                Assert.Equal((int)ItemType.DebitNote, r.ItemType);
                Assert.False(r.ShouldUseRenewalDebtor);
                Assert.False(r.IsWriteDownWip);
            }

            [Fact]
            public async Task ShouldSumLocalValues()
            {
                var f = new OpenItemServiceFixture()
                    .WithOpenItems(new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 1, ItemPreTaxValue = 10, LocalTaxAmount = 1, LocalOriginalTakenUp = 0, WriteDown = 0, WriteUp = 1, BillTotal = 11 },
                                   new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 2, ItemPreTaxValue = 20, LocalTaxAmount = 2, LocalOriginalTakenUp = 4, WriteDown = 1, WriteUp = 0, BillTotal = 22 },
                                   new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 3, ItemPreTaxValue = 30, LocalTaxAmount = 3, LocalOriginalTakenUp = null, WriteDown = 0, WriteUp = 0, BillTotal = 33 });

                var r = await f.Subject.MergeSelectedDraftDebitNotes(_userId, _culture, _openItemNo1 + "|" + _openItemNo2 + "|" + _openItemNo3);

                Assert.Equal(60, r.ItemPreTaxValue);
                Assert.Equal(6, r.LocalTaxAmount);
                Assert.Equal(4, r.LocalOriginalTakenUp); // Old Web may return this as null if any of the LocalOriginalTakenUp is null
                Assert.Equal(1, r.WriteDown);
                Assert.Equal(1, r.WriteUp);
                Assert.Equal(66, r.BillTotal);
            }

            [Fact]
            public async Task ShouldSumForeignValuesIfAllItemsAreInSameCurrency()
            {
                var f = new OpenItemServiceFixture()
                    .WithOpenItems(new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 1, Currency = "USD", ForeignTaxAmount = 1, ForeignOriginalTakenUp = 0, ForeignBalance = 123, ForeignValue = 234 },
                                   new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 2, Currency = "USD", ForeignTaxAmount = 2, ForeignOriginalTakenUp = 4, ForeignBalance = 456, ForeignValue = 345 },
                                   new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 3, Currency = "USD", ForeignTaxAmount = 3, ForeignOriginalTakenUp = null, ForeignBalance = 789, ForeignValue = 456 });

                var r = await f.Subject.MergeSelectedDraftDebitNotes(_userId, _culture, _openItemNo1 + "|" + _openItemNo2 + "|" + _openItemNo3);

                // Old Web returns currency as null, when clearly it should return the currency here. bug
                Assert.Equal("USD", r.Currency);

                // Old Web may return all the following as null if any of the value being sum was null
                Assert.Equal(6, r.ForeignTaxAmount);
                Assert.Equal(4, r.ForeignOriginalTakenUp);
                Assert.Equal(123 + 456 + 789, r.ForeignBalance);
                Assert.Equal(234 + 345 + 456, r.ForeignValue);
            }

            [Fact]
            public async Task ShouldClearForeignValuesIfCurrencyIsDifferent()
            {
                var f = new OpenItemServiceFixture()
                    .WithOpenItems(new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 1, Currency = "USD", ForeignTaxAmount = 1, ForeignOriginalTakenUp = 0, ForeignBalance = 123, ForeignValue = 234 },
                                   new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 2, Currency = "SGY", ForeignTaxAmount = 2, ForeignOriginalTakenUp = 4, ForeignBalance = 456, ForeignValue = 345 },
                                   new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 3, Currency = "USD", ForeignTaxAmount = 3, ForeignOriginalTakenUp = null, ForeignBalance = 789, ForeignValue = 456 });

                var r = await f.Subject.MergeSelectedDraftDebitNotes(_userId, _culture, _openItemNo1 + "|" + _openItemNo2 + "|" + _openItemNo3);

                Assert.Null(r.Currency);
                Assert.Null(r.ForeignTaxAmount);
                Assert.Null(r.ForeignOriginalTakenUp);
                Assert.Null(r.ForeignBalance);
                Assert.Null(r.ForeignValue);
            }

            [Fact]
            public async Task ShouldConcatenateReferenceTexts()
            {
                var f = new OpenItemServiceFixture()
                    .WithOpenItems(new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 1, ReferenceText = "hello" },
                                   new OpenItemModel { ItemEntityId = 2, ItemTransactionId = 2, ReferenceText = null },
                                   new OpenItemModel { ItemEntityId = 3, ItemTransactionId = 3, ReferenceText = "this is great" });

                var r = await f.Subject.MergeSelectedDraftDebitNotes(_userId, _culture, _openItemNo1 + "|" + _openItemNo2 + "|" + _openItemNo3);

                Assert.Equal($"hello{Environment.NewLine}this is great", r.ReferenceText);
            }

            [Fact]
            public async Task ShouldConcatenateStatementScopeTexts()
            {
                var f = new OpenItemServiceFixture()
                    .WithOpenItems(new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 1, Scope = "hello" },
                                   new OpenItemModel { ItemEntityId = 2, ItemTransactionId = 2, Scope = null },
                                   new OpenItemModel { ItemEntityId = 3, ItemTransactionId = 3, Scope = "this is great" });

                var r = await f.Subject.MergeSelectedDraftDebitNotes(_userId, _culture, _openItemNo1 + "|" + _openItemNo2 + "|" + _openItemNo3);

                Assert.Equal($"hello{Environment.NewLine}this is great", r.Scope);
            }

            [Fact]
            public async Task ShouldConcatenateStatementRegardingTexts()
            {
                var f = new OpenItemServiceFixture()
                    .WithOpenItems(new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 1, Regarding = "hello" },
                                   new OpenItemModel { ItemEntityId = 2, ItemTransactionId = 2, Regarding = null },
                                   new OpenItemModel { ItemEntityId = 3, ItemTransactionId = 3, Regarding = "this is great" });

                var r = await f.Subject.MergeSelectedDraftDebitNotes(_userId, _culture, _openItemNo1 + "|" + _openItemNo2 + "|" + _openItemNo3);

                Assert.Equal($"hello{Environment.NewLine}this is great", r.Regarding);
            }

            [Fact]
            public async Task ShouldConcatenateStatementRefTexts()
            {
                var f = new OpenItemServiceFixture()
                    .WithOpenItems(new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 1, StatementRef = "hello" },
                                   new OpenItemModel { ItemEntityId = 2, ItemTransactionId = 2, StatementRef = null },
                                   new OpenItemModel { ItemEntityId = 3, ItemTransactionId = 3, StatementRef = "this is great" });

                var r = await f.Subject.MergeSelectedDraftDebitNotes(_userId, _culture, _openItemNo1 + "|" + _openItemNo2 + "|" + _openItemNo3);

                Assert.Equal($"hello{Environment.NewLine}this is great", r.StatementRef);
            }

            [Fact]
            public async Task ShouldReturnMergedKeysFromAllItems()
            {
                var f = new OpenItemServiceFixture()
                    .WithOpenItems(new OpenItemModel { ItemEntityId = 1, ItemTransactionId = 1 },
                                   new OpenItemModel { ItemEntityId = 2, ItemTransactionId = 2 },
                                   new OpenItemModel { ItemEntityId = 3, ItemTransactionId = 3 });

                var r = await f.Subject.MergeSelectedDraftDebitNotes(_userId, _culture, _openItemNo1 + "|" + _openItemNo2 + "|" + _openItemNo3);

                var expectedKey1 = "<Key><ItemEntityNo>1</ItemEntityNo><ItemTransNo>1</ItemTransNo></Key>";
                var expectedKey2 = "<Key><ItemEntityNo>2</ItemEntityNo><ItemTransNo>2</ItemTransNo></Key>";
                var expectedKey3 = "<Key><ItemEntityNo>3</ItemEntityNo><ItemTransNo>3</ItemTransNo></Key>";

                Assert.Equal($"<Keys>{expectedKey1}{expectedKey2}{expectedKey3}</Keys>", r.MergedItemKeysInXml
                                                                                          .Replace(Environment.NewLine, string.Empty)
                                                                                          .Replace(" ", string.Empty));
            }
        }

        public class ValidateItemDateMethod
        {
            [Fact]
            public async Task ShouldReturnValidIfIndicated()
            {
                var fixture = new OpenItemServiceFixture()
                    .WithValidPostDate();

                var r = await fixture.Subject.ValidateItemDate(Fixture.Date());

                Assert.Empty(r.ValidationErrorList);
            }

            [Theory]
            [InlineData("AC124", "The item date is not within the period it will be posted to.  Please check that the transaction is dated correctly.")]
            public async Task ShouldReturnWarningWithMessageIfIndicated(string warningCode, string warningMessage)
            {
                var fixture = new OpenItemServiceFixture()
                    .WithInvalidPostDate(warningCode, true);

                var r = await fixture.Subject.ValidateItemDate(Fixture.Date());

                Assert.Equal(warningCode, r.ValidationErrorList.Single().WarningCode);
                Assert.Equal(warningMessage, r.ValidationErrorList.Single().WarningDescription);
            }

            [Theory]
            [InlineData("AC126", "An accounting period could not be determined for the given date. Please check the period definitions and try again.")]
            [InlineData("AC208", "The item date cannot be in the future. It must be within the current accounting period or up to and including the current date.")]
            public async Task ShouldReturnErrorWithMessageIfIndicated(string errorCode, string errorMessage)
            {
                var fixture = new OpenItemServiceFixture()
                    .WithInvalidPostDate(errorCode, false);

                var r = await fixture.Subject.ValidateItemDate(Fixture.Date());

                Assert.Equal(errorCode, r.ValidationErrorList.Single().ErrorCode);
                Assert.Equal(errorMessage, r.ValidationErrorList.Single().ErrorDescription);
            }
        }

        public class ValidateOpenItemNoIsUniqueMethod
        {
            [Fact]
            public async Task ShouldReturnResultFromOpenItemsComponent()
            {
                var isUnique = Fixture.Boolean();
                var openItemNo = Fixture.String();

                var fixture = new OpenItemServiceFixture();
                fixture.GetOpenItemCommand.IsOpenItemNoUnique(openItemNo).Returns(isUnique);

                var r = await fixture.Subject.ValidateOpenItemNoIsUnique(openItemNo);

                Assert.Equal(isUnique, r);
            }
        }

        public class ValidateBeforeFinaliseMethod
        {
            [Fact]
            public async Task ShouldReturnValidationSummaryFromComponent()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var request = new FinaliseRequest();
                var validationSummary = new FinaliseValidationSummary();

                var fixture = new OpenItemServiceFixture();

                fixture.FinaliseBillValidator.Validate(userIdentityId, culture, Arg.Any<Guid>(), request).Returns(new[] { validationSummary });

                var result = await fixture.Subject.ValidateBeforeFinalise(userIdentityId, culture, Guid.Empty, request);

                Assert.Equal(validationSummary, result[request].Single());
            }
        }

        public class SaveNewDraftBillMethod : FactBase
        {
            [Fact]
            public async Task ShouldPreventSaveWhenEntityIsRestrictedByCurrency()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemModel = new OpenItemModel { ItemEntityId = itemEntityId };

                var fixture = new OpenItemServiceFixture().WithDraftBillPersistenceOrchestrator();

                fixture.Entities.IsRestrictedByCurrency(itemEntityId).Returns(true);

                var result = await fixture.Subject.SaveNewDraftBill(userIdentityId, culture, openItemModel, Guid.Empty);

                Assert.True(result.HasError);
                Assert.Equal(KnownErrors.EntityRestrictedByCurrency, result.ErrorCode);
            }

            [Fact]
            public async Task ShouldPreventSaveWhenCasesHaveStatusesBlockedFromBilling()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemModel = new OpenItemModel
                {
                    ItemEntityId = itemEntityId,
                    AvailableWipItems = new List<AvailableWipItem>
                    {
                        new() { CaseId = 1 },
                        new() { CaseId = 2 }
                    }
                };

                var fixture = new OpenItemServiceFixture().WithDraftBillPersistenceOrchestrator();

                fixture.Entities.IsRestrictedByCurrency(itemEntityId).Returns(false);
                fixture.CaseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                       .Returns(_ =>
                       {
                           new Case().In(Db);
                           return Db.Set<Case>();
                       });

                var result = await fixture.Subject.SaveNewDraftBill(userIdentityId, culture, openItemModel, Guid.Empty);

                Assert.True(result.HasError);
                Assert.Equal(KnownErrors.BillCaseHasStatusRestrictedForBilling, result.ErrorCode);
            }

            [Fact]
            public async Task ShouldPreventDraftBillsFromBeingSavedWithLocalValueLessThanZero()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemModel = new OpenItemModel
                {
                    ItemEntityId = itemEntityId,
                    DebitOrCreditNotes = new List<DebitOrCreditNote>
                    {
                        new() { LocalValue = -1 }
                    }
                };

                var fixture = new OpenItemServiceFixture().WithDraftBillPersistenceOrchestrator();

                fixture.Entities.IsRestrictedByCurrency(itemEntityId).Returns(false);
                fixture.CaseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                       .Returns(_ => Db.Set<Case>());

                var result = await fixture.Subject.SaveNewDraftBill(userIdentityId, culture, openItemModel, Guid.Empty);

                Assert.True(result.HasError);
                Assert.Equal(KnownErrors.TotalOfDebitOrCreditNoteMustBeGreaterThanZero, result.ErrorCode);
            }

            [Fact]
            public async Task ShouldPreventDraftBillsFromBeingSavedIfDebtorNotConfiguredForBilling()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var debtorNameId = Fixture.Integer();

                var openItemModel = new OpenItemModel
                {
                    ItemEntityId = itemEntityId,
                    DebitOrCreditNotes = new List<DebitOrCreditNote>
                    {
                        new() { DebtorNameId = debtorNameId } // debtor not configured for billing
                    }
                };

                var fixture = new OpenItemServiceFixture().WithDraftBillPersistenceOrchestrator();
                fixture.Entities.IsRestrictedByCurrency(itemEntityId).Returns(false);
                fixture.CaseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                       .Returns(_ => Db.Set<Case>());

                fixture.DebtorRestriction.HasDebtorsNotConfiguredForBilling(debtorNameId).Returns(true);

                var result = await fixture.Subject.SaveNewDraftBill(userIdentityId, culture, openItemModel, Guid.Empty);

                Assert.True(result.HasError);
                Assert.Equal(KnownErrors.DebtorNotAClientOrNotConfiguredForBilling, result.ErrorCode);
            }

            [Fact]
            public async Task ShouldGetOrchestratorToSaveDraftBill()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemModel = new OpenItemModel { ItemEntityId = itemEntityId };

                var fixture = new OpenItemServiceFixture().WithDraftBillPersistenceOrchestrator();
                var requestId = Guid.NewGuid();

                fixture.Entities.IsRestrictedByCurrency(itemEntityId).Returns(false);
                fixture.CaseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                       .Returns(_ => Db.Set<Case>());

                var result = await fixture.Subject.SaveNewDraftBill(userIdentityId, culture, openItemModel, requestId);

                Assert.False(result.HasError);

                fixture.Orchestrator
                       .Received(1)
                       .SaveNewDraftBill(userIdentityId, culture, openItemModel, requestId)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class UpdateDraftBillMethod : FactBase
        {
            [Fact]
            public async Task ShouldPreventSaveWhenCasesHaveStatusesBlockedFromBilling()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemModel = new OpenItemModel
                {
                    ItemEntityId = itemEntityId,
                    AvailableWipItems = new List<AvailableWipItem>
                    {
                        new() { CaseId = 1 },
                        new() { CaseId = 2 }
                    }
                };

                var fixture = new OpenItemServiceFixture().WithDraftBillPersistenceOrchestrator();

                fixture.Entities.IsRestrictedByCurrency(itemEntityId).Returns(false);
                fixture.CaseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                       .Returns(_ =>
                       {
                           new Case().In(Db);
                           return Db.Set<Case>();
                       });

                var result = await fixture.Subject.UpdateDraftBill(userIdentityId, culture, openItemModel, Guid.Empty);

                Assert.True(result.HasError);
                Assert.Equal(KnownErrors.BillCaseHasStatusRestrictedForBilling, result.ErrorCode);
            }

            [Fact]
            public async Task ShouldPreventDraftBillsFromBeingSavedWithLocalValueLessThanZero()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemModel = new OpenItemModel
                {
                    ItemEntityId = itemEntityId,
                    DebitOrCreditNotes = new List<DebitOrCreditNote>
                    {
                        new() { LocalValue = -1 }
                    }
                };

                var fixture = new OpenItemServiceFixture().WithDraftBillPersistenceOrchestrator();

                fixture.CaseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                       .Returns(_ => Db.Set<Case>());

                var result = await fixture.Subject.UpdateDraftBill(userIdentityId, culture, openItemModel, Guid.Empty);

                Assert.True(result.HasError);
                Assert.Equal(KnownErrors.TotalOfDebitOrCreditNoteMustBeGreaterThanZero, result.ErrorCode);
            }

            [Fact]
            public async Task ShouldPreventDraftBillsFromBeingSavedIfDebtorNotConfiguredForBilling()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var debtorNameId = Fixture.Integer();

                var openItemModel = new OpenItemModel
                {
                    ItemEntityId = itemEntityId,
                    DebitOrCreditNotes = new List<DebitOrCreditNote>
                    {
                        new() { DebtorNameId = debtorNameId }
                    }
                };

                var fixture = new OpenItemServiceFixture().WithDraftBillPersistenceOrchestrator();

                fixture.CaseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                       .Returns(_ => Db.Set<Case>());

                fixture.DebtorRestriction.HasDebtorsNotConfiguredForBilling(debtorNameId).Returns(true);

                var result = await fixture.Subject.UpdateDraftBill(userIdentityId, culture, openItemModel, Guid.Empty);

                Assert.True(result.HasError);
                Assert.Equal(KnownErrors.DebtorNotAClientOrNotConfiguredForBilling, result.ErrorCode);
            }

            [Fact]
            public async Task ShouldGetOrchestratorToUpdateDraftBill()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemModel = new OpenItemModel
                {
                    ItemEntityId = itemEntityId,
                    ItemType = (int)ItemType.CreditNote
                };

                var fixture = new OpenItemServiceFixture().WithDraftBillPersistenceOrchestrator();
                var requestId = Guid.NewGuid();

                fixture.CaseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                       .Returns(_ => Db.Set<Case>());

                var result = await fixture.Subject.UpdateDraftBill(userIdentityId, culture, openItemModel, requestId);

                Assert.False(result.HasError);

                fixture.Orchestrator
                       .Received(1)
                       .UpdateDraftBill(userIdentityId, culture, openItemModel, requestId)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class FinaliseDraftBillMethod : FactBase
        {
            [Fact]
            public async Task ShouldPreventSaveWhenCasesHaveStatusesBlockedFromBilling()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var itemTransactionId = Fixture.Integer();
                var sendBillToReviewer = Fixture.Boolean();
                var billGenerationTracking = new BillGenerationTracking
                {
                    ConnectionId = Fixture.String(),
                    ContentId = Fixture.Integer()
                };

                var finaliseRequests = new[]
                {
                    new FinaliseRequest
                    {
                        ItemEntityId = itemEntityId,
                        ItemTransactionId = itemTransactionId
                    }
                };
                
                var fixture = new OpenItemServiceFixture();

                fixture.WipItemsService.GetAvailableWipItems(userIdentityId, culture, Arg.Any<WipSelectionCriteria>())
                       .Returns(new[]
                       {
                           new AvailableWipItem { CaseId = 1 },
                           new AvailableWipItem { CaseId = 2 }
                       });

                fixture.Entities.IsRestrictedByCurrency(itemEntityId).Returns(false);
                fixture.CaseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                       .Returns(_ =>
                       {
                           new Case().In(Db);
                           return Db.Set<Case>();
                       });

                var result = await fixture.Subject.FinaliseDraftBill(userIdentityId, culture, finaliseRequests, Guid.Empty, billGenerationTracking, sendBillToReviewer);

                Assert.All(result.Values, _ =>
                {
                    Assert.True(_.HasError);
                    Assert.Equal(KnownErrors.BillCaseHasStatusRestrictedForBilling, _.ErrorCode);
                });
            }

            [Fact]
            public async Task ShouldGetOrchestratorToFinaliseDraftBill()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var itemTransactionId = Fixture.Integer();
                var sendBillToReviewer = Fixture.Boolean();
                var billGenerationTracking = new BillGenerationTracking
                {
                    ConnectionId = Fixture.String(),
                    ContentId = Fixture.Integer()
                };

                var finaliseRequests = new[]
                {
                    new FinaliseRequest
                    {
                        ItemEntityId = itemEntityId,
                        ItemTransactionId = itemTransactionId
                    }
                };

                var fixture = new OpenItemServiceFixture().WithDraftBillPersistenceOrchestrator();
                var requestId = Guid.NewGuid();

                fixture.CaseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                       .Returns(_ => Db.Set<Case>());

                var result = await fixture.Subject.FinaliseDraftBill(userIdentityId, culture, finaliseRequests, requestId, billGenerationTracking, sendBillToReviewer);

                Assert.All(result.Values,  _ =>
                {
                    Assert.False(_.HasError);
                });

                fixture.Orchestrator
                       .Received(1)
                       .FinaliseDraftBill(userIdentityId, culture, finaliseRequests.Single(), requestId, billGenerationTracking, sendBillToReviewer)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class DeleteDraftBillMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallComponentToDeleteDraftBill()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemNo = Fixture.String();
                var fixture = new OpenItemServiceFixture();

                var _ = await fixture.Subject.DeleteDraftBill(userIdentityId, culture, itemEntityId, openItemNo);

                fixture.DeleteBillCommand
                       .Received(1)
                       .Delete(userIdentityId, culture, itemEntityId, openItemNo)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class PrintBillsMethod
        {
            public async Task ShouldForwardRequestToPrintBills()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var billGenerationRequests = new[]
                {
                    new BillGenerationRequest(),
                    new BillGenerationRequest()
                };

                var trackingDetails = new BillGenerationTracking();
                var sendBillsToReviewer = Fixture.Boolean();

                var f = new OpenItemServiceFixture();

                await f.Subject.PrintBills(userIdentityId, culture, billGenerationRequests, trackingDetails, sendBillsToReviewer);

                f.Orchestrator.Received().PrintBills(userIdentityId, culture, billGenerationRequests, trackingDetails, sendBillsToReviewer)
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class GenerateCreditBillMethod
        {
            [Fact]
            public async Task ShouldForwardRequestToGenerateCreditBill()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var sendBillsToReviewer = Fixture.Boolean();
                var billGenerationRequests = new[]
                {
                    new BillGenerationRequest()
                };

                var trackingDetails = new BillGenerationTracking();

                var f = new OpenItemServiceFixture();

                await f.Subject.GenerateCreditBill(userIdentityId, culture, billGenerationRequests, trackingDetails, sendBillsToReviewer);

                f.Orchestrator.Received().GenerateCreditBill(userIdentityId, culture, billGenerationRequests, trackingDetails, sendBillsToReviewer)
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class OpenItemServiceFixture : IFixture<OpenItemService>
        {
            public OpenItemServiceFixture()
            {
                Subject = new OpenItemService(GetOpenItemCommand,
                                              CaseStatusValidator,
                                              ValidateTransactionDates,
                                              DeleteBillCommand,
                                              FinaliseBillValidator,
                                              DebtorRestriction,
                                              WipItemsService,
                                              Orchestrator,
                                              Entities,
                                              Fixture.Today);
            }

            public IDraftBillManagementCommands DeleteBillCommand { get; } = Substitute.For<IDraftBillManagementCommands>();

            public ICaseStatusValidator CaseStatusValidator { get; } = Substitute.For<ICaseStatusValidator>();

            public IFinaliseBillValidator FinaliseBillValidator { get; } = Substitute.For<IFinaliseBillValidator>();

            public IDebtorRestriction DebtorRestriction { get; } = Substitute.For<IDebtorRestriction>();

            public IWipItemsService WipItemsService { get; } = Substitute.For<IWipItemsService>();

            public IBillingSiteSettingsResolver BillingSiteSettingsResolver { get; } = Substitute.For<IBillingSiteSettingsResolver>();

            public IEntities Entities { get; } = Substitute.For<IEntities>();

            public IOrchestrator Orchestrator { get; } = Substitute.For<IOrchestrator>();

            public IValidateTransactionDates ValidateTransactionDates { get; } = Substitute.For<IValidateTransactionDates>();

            public IGetOpenItemCommand GetOpenItemCommand { get; } = Substitute.For<IGetOpenItemCommand>();

            public OpenItemService Subject { get; }

            public OpenItemServiceFixture WithOpenItems(params OpenItemModel[] openItems)
            {
                GetOpenItemCommand.GetOpenItems(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<string>())
                                  .Returns(new List<OpenItemModel>(openItems));

                return this;
            }

            public OpenItemServiceFixture WithValidPostDate()
            {
                ValidateTransactionDates.For(Arg.Any<DateTime>())
                                        .Returns((true, false, string.Empty));
                return this;
            }

            public OpenItemServiceFixture WithInvalidPostDate(string code, bool isWarning)
            {
                ValidateTransactionDates.For(Arg.Any<DateTime>())
                                        .Returns((false, isWarning, code));
                return this;
            }

            public OpenItemServiceFixture WithDraftBillPersistenceOrchestrator()
            {
                Orchestrator.SaveNewDraftBill(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<OpenItemModel>(), Arg.Any<Guid>())
                            .Returns(x =>
                            {
                                var requestId = (Guid) x[3];
                                return new SaveOpenItemResult(requestId);
                            });

                Orchestrator.UpdateDraftBill(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<OpenItemModel>(), Arg.Any<Guid>())
                            .Returns(x =>
                            {
                                var requestId = (Guid) x[3];
                                return new SaveOpenItemResult(requestId);
                            });

                Orchestrator.FinaliseDraftBill(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<FinaliseRequest>(), 
                                               Arg.Any<Guid>(), Arg.Any<BillGenerationTracking>(), Arg.Any<bool>())
                            .Returns(x =>
                            {
                                var requestId = (Guid) x[3];
                                return new SaveOpenItemResult(requestId);
                            });

                return this;
            }
        }
    }
}