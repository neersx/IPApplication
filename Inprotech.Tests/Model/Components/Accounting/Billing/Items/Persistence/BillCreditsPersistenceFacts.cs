using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class BillCreditsPersistenceFacts : FactBase
    {
        BillCreditsPersistence CreateSubject()
        {
            var logger = Substitute.For<ILogger<BillCreditsPersistence>>();

            return new BillCreditsPersistence(Db, logger);
        }

        [Fact]
        public async Task ShouldPersistBilledCredit()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var creditItem1 = new CreditItem
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                AccountEntityId = Fixture.Integer(),
                AccountDebtorId = Fixture.Integer(),
                CaseId = Fixture.Integer(),
                LocalSelected = Fixture.Decimal(),
                ForeignSelected = Fixture.Decimal(),
                IsForcedPayOut = Fixture.Boolean()
            };

            var creditItem2 = new CreditItem
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                AccountEntityId = Fixture.Integer(),
                AccountDebtorId = Fixture.Integer(),
                CaseId = Fixture.Integer(),
                LocalSelected = Fixture.Decimal(),
                ForeignSelected = Fixture.Decimal(),
                IsForcedPayOut = Fixture.Boolean()
            };

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId
            };

            model.DebitOrCreditNotes.Add(new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                CreditItems = new[] { creditItem1 }
            });

            model.DebitOrCreditNotes.Add(new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                CreditItems = new[] { creditItem2 }
            });

            var saveResult = new SaveOpenItemResult();
            var subject = CreateSubject();

            var r = await subject.Run(1, "en", new BillingSiteSettings(), model, saveResult);

            var bc1 = Db.Set<BilledCredit>().First();
            var bc2 = Db.Set<BilledCredit>().Last();

            Assert.True(r);

            Assert.Equal(itemEntityId, bc1.DebitItemEntityId);
            Assert.Equal(itemTransactionId, bc1.DebitItemTransactionId);
            Assert.Equal(accountEntityId, bc1.DebitAccountEntityId);
            Assert.Equal(accountDebtorId, bc1.DebitAccountDebtorId);
            Assert.Equal(creditItem1.ItemEntityId, bc1.CreditItemEntityId);
            Assert.Equal(creditItem1.ItemTransactionId, bc1.CreditItemTransactionId);
            Assert.Equal(creditItem1.AccountEntityId, bc1.CreditAccountEntityId);
            Assert.Equal(creditItem1.AccountDebtorId, bc1.CreditAccountDebtorId);
            Assert.Equal(creditItem1.CaseId, bc1.CreditCaseId);
            Assert.Equal(creditItem1.LocalSelected, bc1.LocalSelected);
            Assert.Equal(creditItem1.ForeignSelected, bc1.ForeignSelected);
            Assert.Equal(creditItem1.IsForcedPayOut, bc1.ForcedPayout == 1);

            Assert.Equal(itemEntityId, bc2.DebitItemEntityId);
            Assert.Equal(itemTransactionId, bc2.DebitItemTransactionId);
            Assert.Equal(accountEntityId, bc2.DebitAccountEntityId);
            Assert.Equal(accountDebtorId, bc2.DebitAccountDebtorId);
            Assert.Equal(creditItem2.ItemEntityId, bc2.CreditItemEntityId);
            Assert.Equal(creditItem2.ItemTransactionId, bc2.CreditItemTransactionId);
            Assert.Equal(creditItem2.AccountEntityId, bc2.CreditAccountEntityId);
            Assert.Equal(creditItem2.AccountDebtorId, bc2.CreditAccountDebtorId);
            Assert.Equal(creditItem2.CaseId, bc2.CreditCaseId);
            Assert.Equal(creditItem2.LocalSelected, bc2.LocalSelected);
            Assert.Equal(creditItem2.ForeignSelected, bc2.ForeignSelected);
            Assert.Equal(creditItem2.IsForcedPayOut, bc2.ForcedPayout == 1);
        }

        [Fact]
        public async Task ShouldLockAnyAppliedCasePrepaymentCredits()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId
            };

            var creditItem = new CreditItem
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                AccountEntityId = Fixture.Integer(),
                AccountDebtorId = Fixture.Integer(),
                CaseId = Fixture.Integer(),
                LocalSelected = Fixture.Decimal(),
                ForeignSelected = Fixture.Decimal(),
                IsForcedPayOut = Fixture.Boolean()
            };

            model.DebitOrCreditNotes.Add(new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                CreditItems = new[] { creditItem }
            });

            var openItemCase = new OpenItemCase
            {
                ItemEntityId = creditItem.ItemEntityId,
                ItemTransactionId = creditItem.ItemTransactionId,
                AccountEntityId = creditItem.AccountEntityId,
                AccountDebtorId = creditItem.AccountDebtorId,
                Status = TransactionStatus.Draft
            }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Run(2, "en", new BillingSiteSettings(), model, new SaveOpenItemResult());

            Assert.True(r);
            Assert.Equal(TransactionStatus.Locked, openItemCase.Status);
        }

        [Fact]
        public async Task ShouldLockAnyAppliedCredits()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId
            };

            var creditItem = new CreditItem
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                AccountEntityId = Fixture.Integer(),
                AccountDebtorId = Fixture.Integer(),
                CaseId = Fixture.Integer(),
                LocalSelected = Fixture.Decimal(),
                ForeignSelected = Fixture.Decimal(),
                IsForcedPayOut = Fixture.Boolean()
            };

            model.DebitOrCreditNotes.Add(new DebitOrCreditNote
            {
                DebtorNameId = accountDebtorId,
                CreditItems = new[] { creditItem }
            });

            var openItem = new OpenItem
            {
                ItemEntityId = creditItem.ItemEntityId,
                ItemTransactionId = creditItem.ItemTransactionId,
                AccountEntityId = creditItem.AccountEntityId,
                AccountDebtorId = creditItem.AccountDebtorId,
                Status = TransactionStatus.Draft
            }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Run(2, "en", new BillingSiteSettings(), model, new SaveOpenItemResult());

            Assert.True(r);
            Assert.Equal(TransactionStatus.Locked, openItem.Status);
        }
    }
}
