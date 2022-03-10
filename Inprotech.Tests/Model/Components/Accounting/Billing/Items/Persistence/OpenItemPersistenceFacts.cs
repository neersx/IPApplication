using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class OpenItemPersistenceFacts : FactBase
    {
        readonly IExactNameAddressSnapshot _exactNameAddressSnapshot = Substitute.For<IExactNameAddressSnapshot>();
        readonly IOpenItemNumbers _openItemNumbers = Substitute.For<IOpenItemNumbers>();
        readonly ISiteControlReader _siteControlReader = Substitute.For<ISiteControlReader>();

        OpenItemPersistence CreateSubject()
        {
            var logger = Substitute.For<ILogger<OpenItemPersistence>>();

            return new OpenItemPersistence(Db, _openItemNumbers, _exactNameAddressSnapshot, _siteControlReader, logger);
        }

        [Fact]
        public async Task ShouldAddOpenItemForIncludedDebitNoteInLocalCurrency()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var debitOrCreditNote = new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                DebtorNameType = KnownNameTypes.Debtor,
                BillPercentage = 100,
                LocalValue = Fixture.Decimal(),
                LocalBalance = Fixture.Decimal(),
                OpenItemNo = Fixture.String() // this is typically generated, will be tested in a different test
            };

            var debtor = new DebtorData
            {
                NameId = accountDebtorId,
                NameType = KnownNameTypes.Debtor
            };

            var openItemModel = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                AccountDebtorNameId = accountDebtorId,
                Action = Fixture.String(),
                ItemDate = Fixture.PastDate(),
                PostDate = Fixture.Today(), // typically only has a value when it is finalises (Status=1).
                PostPeriodId = Fixture.Integer(), // typically only has a value when it is finalises (Status=1).
                ClosePostDate = Fixture.Today(), // typically only has a value when it is reversed (Status=9).
                ClosePostPeriodId = Fixture.Integer(), // typically only has a value when it is reversed (Status=9).
                Status = (int)TransactionStatus.Draft,
                ItemType = (int)ItemType.DebitNote,
                StaffId = Fixture.Integer(),
                StaffProfitCentre = Fixture.String(),
                StatementRef = Fixture.String(),
                ReferenceText = Fixture.String(),
                Regarding = Fixture.String(),
                Scope = Fixture.String(),
                BillFormatId = Fixture.Short(),
                HasBillBeenPrinted = Fixture.Boolean(),
                LanguageId = Fixture.Integer(),
                AssociatedOpenItemNo = Fixture.String(), // this holds the Credit Invoices' open number if it was applied onto this bill
                ImageId = Fixture.Integer(),
                PenaltyInterest = Fixture.Decimal(),
                LocalOriginalTakenUp = Fixture.Decimal(),
                IncludeOnlyWip = Fixture.String(),
                PayForWip = Fixture.String(),
                PayPropertyType = Fixture.String(),
                CaseProfitCentre = Fixture.String(),
                LockIdentityId = Fixture.Integer(),
                MainCaseId = Fixture.Integer(),
                Debtors = new[] { debtor },
                DebitOrCreditNotes = new[] { debitOrCreditNote }
            };

            var subject = CreateSubject();

            var r = await subject.Run(4, "en", new BillingSiteSettings(), openItemModel, new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var persisted = Db.Set<OpenItem>().Single();

            Assert.Equal(openItemModel.ItemEntityId, persisted.ItemEntityId);
            Assert.Equal(openItemModel.ItemTransactionId, persisted.ItemTransactionId);
            Assert.Equal(openItemModel.AccountEntityId, persisted.AccountEntityId);
            Assert.Equal(openItemModel.AccountDebtorNameId, debitOrCreditNote.DebtorNameId);
            Assert.Equal(openItemModel.Action, persisted.ActionId);
            Assert.Equal(openItemModel.ItemDate, persisted.ItemDate);
            Assert.Equal(openItemModel.PostDate, persisted.PostDate);
            Assert.Equal(openItemModel.PostPeriodId, persisted.PostPeriodId);
            Assert.Equal(openItemModel.ClosePostDate, persisted.ClosePostDate);
            Assert.Equal(openItemModel.ClosePostPeriodId, persisted.ClosePostPeriodId);
            Assert.Equal(openItemModel.Status, (int)persisted.Status);
            Assert.Equal(openItemModel.ItemType, (int)persisted.TypeId);
            Assert.Equal(openItemModel.StaffId, persisted.StaffId);
            Assert.Equal(openItemModel.StaffProfitCentre, persisted.StaffProfitCentre);
            Assert.Equal(debitOrCreditNote.OpenItemNo, persisted.OpenItemNo);
            Assert.Equal(debitOrCreditNote.BillPercentage, persisted.BillPercentage);
            Assert.Equal(debitOrCreditNote.LocalBalance, persisted.LocalBalance);
            Assert.Equal(openItemModel.StatementRef, persisted.StatementRef);
            Assert.Equal(openItemModel.ReferenceText, persisted.ReferenceText);
            Assert.Equal(openItemModel.BillFormatId, persisted.BillFormatId);
            Assert.Equal(openItemModel.HasBillBeenPrinted, Convert.ToBoolean(persisted.IsBillPrinted));
            Assert.Equal(openItemModel.Regarding, persisted.Regarding);
            Assert.Equal(openItemModel.Scope, persisted.Scope);
            Assert.Equal(openItemModel.LanguageId, persisted.LanguageId);
            Assert.Equal(openItemModel.AssociatedOpenItemNo, persisted.AssociatedOpenItemNo);
            Assert.Equal(openItemModel.ImageId, persisted.ImageId);
            Assert.Equal(openItemModel.PenaltyInterest, persisted.PenaltyInterest);
            Assert.Equal(openItemModel.LocalOriginalTakenUp, persisted.LocalOriginalTakenUp);
            Assert.Equal(openItemModel.IncludeOnlyWip, persisted.IncludeOnlyWip);
            Assert.Equal(openItemModel.PayForWip, persisted.PayForWip);
            Assert.Equal(openItemModel.PayPropertyType, persisted.PayPropertyType);
            Assert.Equal(openItemModel.CaseProfitCentre, persisted.CaseProfitCentre);
            Assert.Equal(openItemModel.LockIdentityId, persisted.LockIdentityId);
            Assert.Equal(openItemModel.MainCaseId, persisted.MainCaseId);

            Assert.Equal(debitOrCreditNote.LocalValue, persisted.PreTaxValue); // tax is null in test data setup
            Assert.Equal(0, persisted.LocalTaxAmount); // tax is null in test data setup
            Assert.False(Convert.ToBoolean(persisted.IsRenewalDebtor)); // debtor name type is 'D' not 'R'Assert.Equal(openItemModel.LocalValue, debitOrCreditNote.LocalValue);

            Assert.Null(persisted.Currency);
            Assert.Null(persisted.ExchangeRate);
            Assert.Null(persisted.ForeignBalance);
            Assert.Null(persisted.ForeignValue);
            Assert.Null(persisted.ExchangeRateVariance);
            Assert.Null(persisted.ForeignTaxAmount);
            Assert.Null(persisted.ForeignEquivalentCurrency);
            Assert.Null(persisted.ForeignEquivalentExchangeRate);
            Assert.Null(persisted.ForeignOriginalTakenUp);
        }

        [Fact]
        public async Task ShouldAddOpenItemForIncludedDebitNoteInForeignCurrency()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var debitOrCreditNote = new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                DebtorNameType = KnownNameTypes.Debtor,
                BillPercentage = 100,
                LocalValue = Fixture.Decimal(),
                LocalBalance = Fixture.Decimal(),
                ForeignValue = Fixture.Decimal(),
                ForeignTaxAmount = Fixture.Decimal(),
                ForeignBalance = Fixture.Decimal(),
                OpenItemNo = Fixture.String() // this is typically generated, will be tested in a different test
            };

            var debtor = new DebtorData
            {
                NameId = accountDebtorId,
                NameType = KnownNameTypes.Debtor
            };

            var openItemModel = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                AccountDebtorNameId = accountDebtorId,
                Action = Fixture.String(),
                ItemDate = Fixture.PastDate(),
                PostDate = Fixture.Today(), // typically only has a value when it is finalises (Status=1).
                PostPeriodId = Fixture.Integer(), // typically only has a value when it is finalises (Status=1).
                ClosePostDate = Fixture.Today(), // typically only has a value when it is reversed (Status=9).
                ClosePostPeriodId = Fixture.Integer(), // typically only has a value when it is reversed (Status=9).
                Status = (int)TransactionStatus.Draft,
                ItemType = (int)ItemType.DebitNote,
                StaffId = Fixture.Integer(),
                StaffProfitCentre = Fixture.String(),
                StatementRef = Fixture.String(),
                ReferenceText = Fixture.String(),
                Regarding = Fixture.String(),
                Scope = Fixture.String(),
                BillFormatId = Fixture.Short(),
                HasBillBeenPrinted = Fixture.Boolean(),
                LanguageId = Fixture.Integer(),
                AssociatedOpenItemNo = Fixture.String(), // this holds the Credit Invoices' open number if it was applied onto this bill
                ImageId = Fixture.Integer(),
                PenaltyInterest = Fixture.Decimal(),
                LocalOriginalTakenUp = Fixture.Decimal(),
                IncludeOnlyWip = Fixture.String(),
                PayForWip = Fixture.String(),
                PayPropertyType = Fixture.String(),
                CaseProfitCentre = Fixture.String(),
                LockIdentityId = Fixture.Integer(),
                MainCaseId = Fixture.Integer(),

                Currency = Fixture.String(),
                ExchangeRate = Fixture.Decimal(),
                ForeignOriginalTakenUp = Fixture.Decimal(),
                ForeignEquivalentCurrency = Fixture.String(),
                ForeignEquivalentExchangeRate = Fixture.Decimal(),

                Debtors = new[] { debtor },
                DebitOrCreditNotes = new[] { debitOrCreditNote }
            };

            var subject = CreateSubject();

            var r = await subject.Run(4, "en", new BillingSiteSettings(), openItemModel, new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var persisted = Db.Set<OpenItem>().Single();

            Assert.Equal(openItemModel.ItemEntityId, persisted.ItemEntityId);
            Assert.Equal(openItemModel.ItemTransactionId, persisted.ItemTransactionId);
            Assert.Equal(openItemModel.AccountEntityId, persisted.AccountEntityId);
            Assert.Equal(openItemModel.AccountDebtorNameId, debitOrCreditNote.DebtorNameId);
            Assert.Equal(openItemModel.Action, persisted.ActionId);
            Assert.Equal(openItemModel.ItemDate, persisted.ItemDate);
            Assert.Equal(openItemModel.PostDate, persisted.PostDate);
            Assert.Equal(openItemModel.PostPeriodId, persisted.PostPeriodId);
            Assert.Equal(openItemModel.ClosePostDate, persisted.ClosePostDate);
            Assert.Equal(openItemModel.ClosePostPeriodId, persisted.ClosePostPeriodId);
            Assert.Equal(openItemModel.Status, (int)persisted.Status);
            Assert.Equal(openItemModel.ItemType, (int)persisted.TypeId);
            Assert.Equal(openItemModel.StaffId, persisted.StaffId);
            Assert.Equal(openItemModel.StaffProfitCentre, persisted.StaffProfitCentre);
            Assert.Equal(openItemModel.StatementRef, persisted.StatementRef);
            Assert.Equal(openItemModel.ReferenceText, persisted.ReferenceText);
            Assert.Equal(openItemModel.BillFormatId, persisted.BillFormatId);
            Assert.Equal(openItemModel.HasBillBeenPrinted, Convert.ToBoolean(persisted.IsBillPrinted));
            Assert.Equal(openItemModel.Regarding, persisted.Regarding);
            Assert.Equal(openItemModel.Scope, persisted.Scope);
            Assert.Equal(openItemModel.LanguageId, persisted.LanguageId);
            Assert.Equal(openItemModel.AssociatedOpenItemNo, persisted.AssociatedOpenItemNo);
            Assert.Equal(openItemModel.ImageId, persisted.ImageId);
            Assert.Equal(openItemModel.PenaltyInterest, persisted.PenaltyInterest);
            Assert.Equal(openItemModel.LocalOriginalTakenUp, persisted.LocalOriginalTakenUp);
            Assert.Equal(openItemModel.IncludeOnlyWip, persisted.IncludeOnlyWip);
            Assert.Equal(openItemModel.PayForWip, persisted.PayForWip);
            Assert.Equal(openItemModel.PayPropertyType, persisted.PayPropertyType);
            Assert.Equal(openItemModel.CaseProfitCentre, persisted.CaseProfitCentre);
            Assert.Equal(openItemModel.LockIdentityId, persisted.LockIdentityId);
            Assert.Equal(openItemModel.MainCaseId, persisted.MainCaseId);
            Assert.Equal(openItemModel.Currency, persisted.Currency);
            Assert.Equal(openItemModel.ExchangeRate, persisted.ExchangeRate);

            Assert.Equal(openItemModel.ForeignEquivalentCurrency, persisted.ForeignEquivalentCurrency);
            Assert.Equal(openItemModel.ForeignEquivalentExchangeRate, persisted.ForeignEquivalentExchangeRate);
            Assert.Equal(openItemModel.ForeignOriginalTakenUp, persisted.ForeignOriginalTakenUp);

            Assert.Equal(debitOrCreditNote.OpenItemNo, persisted.OpenItemNo);
            Assert.Equal(debitOrCreditNote.BillPercentage, persisted.BillPercentage);
            Assert.Equal(debitOrCreditNote.LocalBalance, persisted.LocalBalance);
            Assert.Equal(debitOrCreditNote.LocalValue, persisted.PreTaxValue); // tax is null in test data setup
            Assert.Equal(debitOrCreditNote.ForeignBalance, persisted.ForeignBalance);
            Assert.Equal(debitOrCreditNote.ForeignValue, persisted.ForeignValue);
            Assert.Equal(debitOrCreditNote.ExchangeRateVariance, persisted.ExchangeRateVariance);
            Assert.Equal(debitOrCreditNote.ForeignTaxAmount, persisted.ForeignTaxAmount);

            Assert.Equal(0, persisted.LocalTaxAmount); // tax is null in test data setup
            Assert.False(Convert.ToBoolean(persisted.IsRenewalDebtor)); // debtor name type is 'D' not 'R'Assert.Equal(openItemModel.LocalValue, debitOrCreditNote.LocalValue);
        }

        [Fact]
        public async Task ShouldDeriveNameSnapshotId()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var debitOrCreditNote = new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                DebtorNameType = KnownNameTypes.Debtor,
                OpenItemNo = Fixture.String() // this is typically generated, will be tested in a different test
            };

            var debtor = new DebtorData
            {
                NameId = accountDebtorId,
                NameType = KnownNameTypes.Debtor,
                AddressId = Fixture.Integer(),
                Address = Fixture.String(),
                AttentionNameId = Fixture.Integer(),
                AttentionName = Fixture.String(),
                AddressChangeReasonId = Fixture.Integer(),
                FormattedName = Fixture.String(),
                ReferenceNo = Fixture.String(),
                HasReferenceNoChanged = true
            };

            var openItemModel = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                AccountDebtorNameId = accountDebtorId,
                ItemDate = Fixture.PastDate(),
                Status = (int)TransactionStatus.Draft,
                ItemType = (int)ItemType.DebitNote,
                Debtors = new[] { debtor },
                DebitOrCreditNotes = new[] { debitOrCreditNote }
            };

            var derivedSnapshotId = Fixture.Integer();
            _exactNameAddressSnapshot.Derive(Arg.Any<NameAddressSnapshotParameter>()).Returns(derivedSnapshotId);

            var subject = CreateSubject();

            var r = await subject.Run(4, "en", new BillingSiteSettings(), openItemModel, new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var persisted = Db.Set<OpenItem>().Single();

            Assert.Equal(derivedSnapshotId, persisted.NameSnapshotId);

            _exactNameAddressSnapshot.Received(1)
                                     .Derive(Arg.Is<NameAddressSnapshotParameter>(_ =>
                                                                                      _.AccountDebtorId == debtor.NameId &&
                                                                                      _.FormattedName == debtor.FormattedName &&
                                                                                      _.AddressId == debtor.AddressId &&
                                                                                      _.FormattedAddress == debtor.Address &&
                                                                                      _.AttentionNameId == debtor.AttentionNameId &&
                                                                                      _.FormattedAttention == debtor.AttentionName &&
                                                                                      _.AddressChangeReasonId == debtor.AddressChangeReasonId &&
                                                                                      _.FormattedReference == debtor.ReferenceNo))
                                     .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldUseEnteredOpenItemNoIfProvided()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var debitOrCreditNote = new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                DebtorNameType = KnownNameTypes.Debtor,
                EnteredOpenItemNo = Fixture.String()
            };

            var debtor = new DebtorData
            {
                NameId = accountDebtorId,
                NameType = KnownNameTypes.Debtor
            };

            var openItemModel = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                AccountDebtorNameId = accountDebtorId,
                ItemDate = Fixture.PastDate(),
                Status = (int)TransactionStatus.Draft,
                ItemType = (int)ItemType.DebitNote,
                Debtors = new[] { debtor },
                DebitOrCreditNotes = new[] { debitOrCreditNote }
            };

            var subject = CreateSubject();

            var r = await subject.Run(4, "en", new BillingSiteSettings(), openItemModel, new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var persisted = Db.Set<OpenItem>().Single();

            Assert.Equal(debitOrCreditNote.EnteredOpenItemNo, persisted.OpenItemNo);
        }

        [Fact]
        public async Task ShouldGenerateOpenItemNoWhenOpenItemNoAndEnteredOpenItemNoAreBothNotProvided()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var debitOrCreditNote = new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                DebtorNameType = KnownNameTypes.Debtor
            };

            var debtor = new DebtorData
            {
                NameId = accountDebtorId,
                NameType = KnownNameTypes.Debtor
            };

            var openItemModel = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                AccountDebtorNameId = accountDebtorId,
                ItemDate = Fixture.PastDate(),
                Status = (int)TransactionStatus.Draft,
                ItemType = (int)ItemType.DebitNote,
                StaffId = Fixture.Integer(),
                Debtors = new[] { debtor },
                DebitOrCreditNotes = new[] { debitOrCreditNote }
            };

            var openItemNumberAcquired = Fixture.String();
            _openItemNumbers.AcquireNextDraftNumber(itemEntityId, openItemModel.StaffId).Returns(openItemNumberAcquired);

            var subject = CreateSubject();

            var r = await subject.Run(4, "en", new BillingSiteSettings(), openItemModel, new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var persisted = Db.Set<OpenItem>().Single();

            Assert.Equal(openItemNumberAcquired, persisted.OpenItemNo);
        }

        [Fact]
        public async Task ShouldDeriveItemDueDateFromDebtorsPreferredTradingTermSetting()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();

            var client = new ClientDetail
            {
                TradingTerms = Fixture.Short()
            }.In(Db);

            var accountDebtorId = client.Id;

            var debitOrCreditNote = new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                DebtorNameType = KnownNameTypes.Debtor,
                OpenItemNo = Fixture.String()
            };

            var debtor = new DebtorData
            {
                NameId = accountDebtorId,
                NameType = KnownNameTypes.Debtor
            };

            var openItemModel = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                AccountDebtorNameId = accountDebtorId,
                ItemDate = Fixture.Today(),
                Status = (int)TransactionStatus.Draft,
                ItemType = (int)ItemType.DebitNote,
                Debtors = new[] { debtor },
                DebitOrCreditNotes = new[] { debitOrCreditNote }
            };

            var subject = CreateSubject();

            var r = await subject.Run(4, "en", new BillingSiteSettings(), openItemModel, new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var persisted = Db.Set<OpenItem>().Single();

            var expectedItemDueDate = openItemModel.ItemDate + TimeSpan.FromDays(client.TradingTerms.GetValueOrDefault());

            Assert.Equal(expectedItemDueDate, persisted.ItemDueDate);
        }

        [Fact]
        public async Task ShouldDeriveItemDueDateFromSiteTradingTerm()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();

            var client = new ClientDetail
            {
                TradingTerms = null
            }.In(Db);

            var accountDebtorId = client.Id;

            var debitOrCreditNote = new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                DebtorNameType = KnownNameTypes.Debtor,
                OpenItemNo = Fixture.String()
            };

            var debtor = new DebtorData
            {
                NameId = accountDebtorId,
                NameType = KnownNameTypes.Debtor
            };

            var openItemModel = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                AccountDebtorNameId = accountDebtorId,
                ItemDate = Fixture.Today(),
                Status = (int)TransactionStatus.Draft,
                ItemType = (int)ItemType.DebitNote,
                Debtors = new[] { debtor },
                DebitOrCreditNotes = new[] { debitOrCreditNote }
            };

            var siteTradingTerms = Fixture.Short();
            _siteControlReader.Read<int>(SiteControls.TradingTerms).Returns(siteTradingTerms);

            var subject = CreateSubject();

            var r = await subject.Run(4, "en", new BillingSiteSettings(), openItemModel, new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var persisted = Db.Set<OpenItem>().Single();

            var expectedItemDueDate = openItemModel.ItemDate + TimeSpan.FromDays(siteTradingTerms);

            Assert.Equal(expectedItemDueDate, persisted.ItemDueDate);
        }

        [Fact]
        public async Task ShouldStoreInLongColumnsIfTextOver254Characters()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var debitOrCreditNote = new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                DebtorNameType = KnownNameTypes.Debtor,
                OpenItemNo = Fixture.String()
            };

            var debtor = new DebtorData
            {
                NameId = accountDebtorId,
                NameType = KnownNameTypes.Debtor
            };

            var openItemModel = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                AccountDebtorNameId = accountDebtorId,
                ItemDate = Fixture.PastDate(),
                Status = (int)TransactionStatus.Draft,
                ItemType = (int)ItemType.DebitNote,
                Regarding = Fixture.RandomString(256),
                ReferenceText = Fixture.RandomString(256),
                Debtors = new[] { debtor },
                DebitOrCreditNotes = new[] { debitOrCreditNote }
            };

            var subject = CreateSubject();

            var r = await subject.Run(4, "en", new BillingSiteSettings(), openItemModel, new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var persisted = Db.Set<OpenItem>().Single();

            Assert.Null(persisted.Regarding);
            Assert.Null(persisted.ReferenceText);
            Assert.Equal(openItemModel.Regarding, persisted.LongRegarding);
            Assert.Equal(openItemModel.ReferenceText, persisted.LongReferenceText);
        }

        [Fact]
        public async Task ShouldCreateAccountForDebtorIfNotExist()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var debitOrCreditNote = new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                DebtorNameType = KnownNameTypes.Debtor,
                OpenItemNo = Fixture.String()
            };

            var debtor = new DebtorData
            {
                NameId = accountDebtorId,
                NameType = KnownNameTypes.Debtor
            };

            var openItemModel = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                AccountDebtorNameId = accountDebtorId,
                ItemDate = Fixture.PastDate(),
                Status = (int)TransactionStatus.Draft,
                ItemType = (int)ItemType.DebitNote,
                Debtors = new[] { debtor },
                DebitOrCreditNotes = new[] { debitOrCreditNote }
            };

            var subject = CreateSubject();

            var r = await subject.Run(4, "en", new BillingSiteSettings(), openItemModel, new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var account = Db.Set<Account>().SingleOrDefault(_ => debtor.NameId == _.NameId && _.EntityId == accountEntityId);

            Assert.NotNull(account);
            Assert.Equal(0, account.Balance);
            Assert.Equal(0, account.CreditBalance);
        }
    }
}