using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Debtor;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class BilledItemsFacts : FactBase
    {
        BilledItems CreateSubject()
        {
            var logger = Substitute.For<ILogger<BilledItems>>();
            return new BilledItems(Db, logger);
        }

        [Fact]
        public async Task ShouldUnlockWipItemsIncludedInTheBill()
        {
            var wipEntityId = Fixture.Integer();
            var wipTransId = Fixture.Integer();
            var wipSeqNo = Fixture.Short();

            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            var wipItemIncludedInTheBill = new WorkInProgress
            {
                EntityId = wipEntityId,
                TransactionId = wipTransId,
                WipSequenceNo = wipSeqNo,
                Status = TransactionStatus.Locked
            }.In(Db);
            
            new BilledItem
            {
                EntityId = itemEntityId,
                TransactionId = itemTransactionId,
                WipEntityId = wipEntityId,
                WipTransactionId = wipTransId,
                WipSequenceNo = wipSeqNo
            }.In(Db);
            
            var subject = CreateSubject();

            await subject.Reinstate(itemEntityId, itemTransactionId, Guid.NewGuid());

            Assert.Equal(TransactionStatus.Active, wipItemIncludedInTheBill.Status);
        }

        [Fact]
        public async Task ShouldRemoveCreditsAppliedOnTheBill()
        {
            var creditItemEntityId = Fixture.Integer();
            var creditItemTransId = Fixture.Integer();
            var creditAccountEntityId = Fixture.Integer();
            var creditAccountDebtorId = Fixture.Integer();
            var creditItemCaseId = Fixture.Integer();
            
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            /*
             * prepayments and credit notes may be applied to offset the balance on the bill.             
             */

            new BilledCredit
            {
                // This Bill
                DebitItemEntityId = itemEntityId,
                DebitItemTransactionId = itemTransactionId,
                
                // Credit Note Pointer
                CreditCaseId = creditItemCaseId,
                CreditItemEntityId = creditItemEntityId,
                CreditItemTransactionId = creditItemTransId,
                CreditAccountEntityId = creditAccountEntityId,
                CreditAccountDebtorId = creditAccountDebtorId
            }.In(Db);

            var creditNote = new OpenItem
            {
                ItemEntityId = creditItemEntityId,
                ItemTransactionId = creditItemTransId,
                AccountEntityId = creditAccountEntityId,
                AccountDebtorId = creditAccountDebtorId,

                // Taken Up
                LocalOriginalTakenUp = Fixture.Decimal(),
                ForeignOriginalTakenUp = Fixture.Decimal(),

                // Locked
                Status = TransactionStatus.Locked
            }.In(Db);

            var appliedCredits = new OpenItemCase
            {
                ItemEntityId = creditItemEntityId,
                ItemTransactionId = creditItemTransId,
                AccountEntityId = creditAccountEntityId,
                AccountDebtorId = creditAccountDebtorId,
                CaseId = creditItemCaseId,

                // Locked
                Status = TransactionStatus.Locked
            }.In(Db);

            var subject = CreateSubject();

            await subject.Reinstate(itemEntityId, itemTransactionId, Guid.NewGuid());

            // detach the used credits from the current bill.

            Assert.Equal(TransactionStatus.Active, creditNote.Status);
            Assert.Equal(TransactionStatus.Active, appliedCredits.Status);
            Assert.Null(creditNote.LocalOriginalTakenUp);
            Assert.Null(creditNote.ForeignOriginalTakenUp);
        }

        [Fact]
        public async Task ShouldRemoveBilledCredits()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            
            new BilledCredit
            {
                // This Bill
                DebitItemEntityId = itemEntityId,
                DebitItemTransactionId = itemTransactionId
            }.In(Db);

            var subject = CreateSubject();

            await subject.Reinstate(itemEntityId, itemTransactionId, Guid.NewGuid());

            Assert.Empty(Db.Set<BilledCredit>());
        }

        [Fact]
        public async Task ShouldRemoveBillItems()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            
            new BilledItem
            {
                // This Bill
                EntityId = itemEntityId,
                TransactionId = itemTransactionId
            }.In(Db);

            var subject = CreateSubject();

            await subject.Reinstate(itemEntityId, itemTransactionId, Guid.NewGuid());

            Assert.Empty(Db.Set<BilledItem>());
        }

        [Fact]
        public async Task ShouldRemoveBillLines()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            
            new BillLine
            {
                // This Bill
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId
            }.In(Db);

            var subject = CreateSubject();

            await subject.Reinstate(itemEntityId, itemTransactionId, Guid.NewGuid());

            Assert.Empty(Db.Set<BillLine>());
        }

        [Fact]
        public async Task ShouldRemoveOpenItemTax()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            
            new OpenItemTax
            {
                // This Bill
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId
            }.In(Db);

            var subject = CreateSubject();

            await subject.Reinstate(itemEntityId, itemTransactionId, Guid.NewGuid());

            Assert.Empty(Db.Set<OpenItemTax>());
        }

        [Fact]
        public async Task ShouldRemoveDebtorHistory()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            
            new DebtorHistory
            {
                // This Bill
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId
            }.In(Db);

            var subject = CreateSubject();

            await subject.Reinstate(itemEntityId, itemTransactionId, Guid.NewGuid());

            Assert.Empty(Db.Set<DebtorHistory>());
        }

        [Fact]
        public async Task ShouldRemoveEBillingMapping()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            
            new OpenItemXml
            {
                // This Bill
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId
            }.In(Db);

            var subject = CreateSubject();

            await subject.Reinstate(itemEntityId, itemTransactionId, Guid.NewGuid());

            Assert.Empty(Db.Set<OpenItemXml>());
        }

        [Fact]
        public async Task ShouldRemoveCopiesTo()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            
            new OpenItemCopyTo
            {
                // This Bill
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId
            }.In(Db);

            var subject = CreateSubject();

            await subject.Reinstate(itemEntityId, itemTransactionId, Guid.NewGuid());

            Assert.Empty(Db.Set<OpenItemCopyTo>());
        }

        [Fact]
        public async Task ShouldRemoveDebitNotes()
        {
            // Bill is consist of 1 open item for each Debtor,
            // if there are 3 debtors in the case, there will be 3 open items
            // the open item is 'Debit Note'.

            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            
            new OpenItem
            {
                // This Bill
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId
            }.In(Db);

            var subject = CreateSubject();

            await subject.Reinstate(itemEntityId, itemTransactionId, Guid.NewGuid());

            Assert.Empty(Db.Set<OpenItem>());
        }
    }
}
