using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Components.Accounting.Billing.Presentation;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using NSubstitute;
using Xunit;
using BillLine = InprotechKaizen.Model.Components.Accounting.Billing.Presentation.BillLine;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class BilledItemsPersistenceFacts : FactBase
    {
        BilledItemsPersistence CreateSubject()
        {
            var logger = Substitute.For<ILogger<BilledItemsPersistence>>();

            return new BilledItemsPersistence(Db, logger);
        }

        [Fact]
        public async Task ShouldMapBillLineToWip()
        {
            var availableWipItem1 = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                UniqueReferenceId = Fixture.Short()
            };

            var availableWipItem2 = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                UniqueReferenceId = Fixture.Short()
            };

            var billLine1 = new BillLine
            {
                ItemLineNo = 1,  // set in BillLinePersistence component
                WipItems = new[]
                {
                    new BillLineWip
                    {
                        UniqueReferenceId = availableWipItem1.UniqueReferenceId
                    }
                }
            };

            var billLine2 = new BillLine
            {
                ItemLineNo = 2,  // set in BillLinePersistence component
                WipItems = new[]
                {
                    new BillLineWip
                    {
                        UniqueReferenceId = availableWipItem2.UniqueReferenceId
                    }
                }
            };

            var subject = CreateSubject();

            var _ = await subject.Run(2, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = Fixture.Integer(),
                                          ItemTransactionId = Fixture.Integer(),
                                          AccountEntityId = Fixture.Integer(),
                                          AvailableWipItems = new[]
                                          {
                                              availableWipItem1, availableWipItem2
                                          },
                                          BillLines = new[] 
                                          {
                                              billLine1, billLine2
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            Assert.Equal(billLine1.ItemLineNo, availableWipItem1.BillLineNo);
            Assert.Equal(billLine2.ItemLineNo, availableWipItem2.BillLineNo);
        }

        [Fact]
        public async Task ShouldApplyWriteDownToDraftWip()
        {
            var writeDownReason = Fixture.String();

            var availableWipItem1 = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                LocalBilled = Fixture.Decimal(),
                IsDraft = true
            };

            var availableWipItem2 = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                LocalBilled = Fixture.Decimal(),
                IsDraft = false
            };

            var subject = CreateSubject();

            var _ = await subject.Run(2, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = Fixture.Integer(),
                                          ItemTransactionId = Fixture.Integer(),
                                          AccountEntityId = Fixture.Integer(),
                                          WriteDownReason = writeDownReason,
                                          AvailableWipItems = new[]
                                          {
                                              availableWipItem1, availableWipItem2
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            // draft wip
            Assert.Equal(writeDownReason, availableWipItem1.ReasonCode);
            Assert.Equal(availableWipItem1.LocalBilled * -1, availableWipItem1.LocalVariation);

            // non-draft
            Assert.Null(availableWipItem2.ReasonCode);
            Assert.Null(availableWipItem2.LocalVariation);
        }

        [Fact]
        public async Task ShouldAbortIfWipAlreadyLockedOnAnotherBill()
        {
            var lockedInAnotherBill = new WorkInProgress
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSequenceNo = Fixture.Short(),
                Status = TransactionStatus.Locked
            }.In(Db);

            var wipIncludeInThisDraft = new AvailableWipItem
            {
                EntityId = lockedInAnotherBill.EntityId,
                TransactionId = lockedInAnotherBill.TransactionId,
                WipSeqNo = lockedInAnotherBill.WipSequenceNo
            };

            var result = new SaveOpenItemResult(Guid.NewGuid());

            var subject = CreateSubject();

            var r = await subject.Run(2, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = Fixture.Integer(),
                                          ItemTransactionId = Fixture.Integer(),
                                          AccountEntityId = Fixture.Integer(),
                                          AvailableWipItems = new[]
                                          {
                                              wipIncludeInThisDraft
                                          }
                                      },
                                      result);

            Assert.False(r);
            Assert.Equal(KnownErrors.WipAlreadyOnDifferentBill, result.ErrorCode);
        }

        [Fact]
        public async Task ShouldCreateAccountForDebtorIfNotExist()
        {
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var subject = CreateSubject();

            var r = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = Fixture.Integer(),
                                          ItemTransactionId = Fixture.Integer(),
                                          AccountEntityId = accountEntityId,
                                          AccountDebtorNameId = accountDebtorId,
                                          AvailableWipItems = new[]
                                          {
                                              new AvailableWipItem
                                              {
                                                  EntityId = Fixture.Integer(),
                                                  TransactionId = Fixture.Integer(),
                                                  WipSeqNo = Fixture.Short(),
                                                  CaseId = Fixture.Integer()
                                              }
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            var account = Db.Set<Account>().SingleOrDefault(_ => accountDebtorId == _.NameId && _.EntityId == accountEntityId);

            Assert.NotNull(account);
            Assert.Equal(0, account.Balance);
            Assert.Equal(0, account.CreditBalance);
        }

        [Fact]
        public async Task ShouldInsertTheBilledItemForTheLocalWip()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var wipToBeBilled = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                LocalBilled = Fixture.Decimal(),
                CaseId = Fixture.Integer(), // presence of CaseId causes accountEntityId to be persisted
                IsCreditWip = Fixture.Boolean() // signs reversal is not applied if the wip item is not draft
            };

            var subject = CreateSubject();

            var _ = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = accountEntityId,
                                          AccountDebtorNameId = accountDebtorId,
                                          AvailableWipItems = new[]
                                          {
                                              wipToBeBilled
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            var persisted = Db.Set<BilledItem>().Single();

            Assert.Equal(itemEntityId, persisted.ItemEntityId);
            Assert.Equal(itemTransactionId, persisted.ItemTransactionId);
            Assert.Equal(accountEntityId, persisted.AccountEntityId);
            Assert.Equal(accountDebtorId, persisted.AccountDebtorId);
            Assert.Equal(wipToBeBilled.EntityId, persisted.WipEntityId);
            Assert.Equal(wipToBeBilled.TransactionId, persisted.WipTransactionId);
            Assert.Equal(wipToBeBilled.WipSeqNo, persisted.WipSequenceNo);
            Assert.Equal(wipToBeBilled.LocalBilled, persisted.BilledValue);
            Assert.Null(persisted.ForeignCurrency);
            Assert.Null(persisted.ForeignBilledValue);
            Assert.Null(persisted.AdjustedValue);
        }

        [Fact]
        public async Task ShouldInsertTheBilledItemForTheLocalDraftWip()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var draftWipToBeBilled = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                LocalBilled = Fixture.Decimal(),
                CaseId = Fixture.Integer(), // presence of CaseId causes accountEntityId to be persisted
                IsDraft = true
            };

            var subject = CreateSubject();

            var _ = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = accountEntityId,
                                          AccountDebtorNameId = accountDebtorId,
                                          AvailableWipItems = new[]
                                          {
                                              draftWipToBeBilled
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            var persisted = Db.Set<BilledItem>().Single();

            Assert.Equal(itemEntityId, persisted.ItemEntityId);
            Assert.Equal(itemTransactionId, persisted.ItemTransactionId);
            Assert.Equal(accountEntityId, persisted.AccountEntityId);
            Assert.Equal(accountDebtorId, persisted.AccountDebtorId);
            Assert.Equal(draftWipToBeBilled.EntityId, persisted.WipEntityId);
            Assert.Equal(draftWipToBeBilled.TransactionId, persisted.WipTransactionId);
            Assert.Equal(draftWipToBeBilled.WipSeqNo, persisted.WipSequenceNo);
            Assert.Equal(draftWipToBeBilled.LocalBilled, persisted.BilledValue);
            Assert.Equal(draftWipToBeBilled.LocalVariation, persisted.AdjustedValue);
            Assert.Null(persisted.ForeignCurrency);
            Assert.Null(persisted.ForeignBilledValue);
        }

        [Fact]
        public async Task ShouldInsertTheBilledItemForTheForeignWip()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var wipToBeBilled = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                LocalBilled = Fixture.Decimal(),
                CaseId = Fixture.Integer(), // presence of CaseId causes accountEntityId to be persisted
                ForeignBilled = Fixture.Decimal(),
                ForeignCurrency = Fixture.String(),
                IsCreditWip = Fixture.Boolean() // signs reversal is not applied if the wip item is not draft
            };

            var subject = CreateSubject();

            var _ = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = accountEntityId,
                                          AccountDebtorNameId = accountDebtorId,
                                          AvailableWipItems = new[]
                                          {
                                              wipToBeBilled
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            var persisted = Db.Set<BilledItem>().Single();

            Assert.Equal(itemEntityId, persisted.ItemEntityId);
            Assert.Equal(itemTransactionId, persisted.ItemTransactionId);
            Assert.Equal(accountEntityId, persisted.AccountEntityId);
            Assert.Equal(accountDebtorId, persisted.AccountDebtorId);
            Assert.Equal(wipToBeBilled.EntityId, persisted.WipEntityId);
            Assert.Equal(wipToBeBilled.TransactionId, persisted.WipTransactionId);
            Assert.Equal(wipToBeBilled.WipSeqNo, persisted.WipSequenceNo);
            Assert.Equal(wipToBeBilled.LocalBilled, persisted.BilledValue);
            Assert.Equal(wipToBeBilled.ForeignCurrency, persisted.ForeignCurrency);
            Assert.Equal(wipToBeBilled.ForeignBilled, persisted.ForeignBilledValue);
            Assert.Null(persisted.AdjustedValue);
            Assert.Null(persisted.ForeignAdjustedValue);
        }

        [Fact]
        public async Task ShouldInsertTheBilledItemForTheForeignDraftWip()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var draftWipToBeBilled = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                LocalBilled = Fixture.Decimal(),
                CaseId = Fixture.Integer(),
                // presence of CaseId causes accountEntityId to be persisted
                ForeignBilled = Fixture.Decimal(),
                ForeignCurrency = Fixture.String(),
                IsDraft = true
            };

            var subject = CreateSubject();

            var _ = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = accountEntityId,
                                          AccountDebtorNameId = accountDebtorId,
                                          AvailableWipItems = new[]
                                          {
                                              draftWipToBeBilled
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            var persisted = Db.Set<BilledItem>().Single();

            Assert.Equal(itemEntityId, persisted.ItemEntityId);
            Assert.Equal(itemTransactionId, persisted.ItemTransactionId);
            Assert.Equal(accountEntityId, persisted.AccountEntityId);
            Assert.Equal(accountDebtorId, persisted.AccountDebtorId);
            Assert.Equal(draftWipToBeBilled.EntityId, persisted.WipEntityId);
            Assert.Equal(draftWipToBeBilled.TransactionId, persisted.WipTransactionId);
            Assert.Equal(draftWipToBeBilled.WipSeqNo, persisted.WipSequenceNo);
            Assert.Equal(draftWipToBeBilled.LocalBilled, persisted.BilledValue);
            Assert.Equal(draftWipToBeBilled.LocalVariation, persisted.AdjustedValue);
            Assert.Equal(draftWipToBeBilled.ForeignCurrency, persisted.ForeignCurrency);
            Assert.Equal(draftWipToBeBilled.ForeignBilled, persisted.ForeignBilledValue);
            Assert.Equal(draftWipToBeBilled.ForeignVariation, persisted.ForeignAdjustedValue);
        }

        [Fact]
        public async Task ShouldInsertTheBilledItemForTheLocalDraftCreditWipWithSignsReversed()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var draftWipToBeBilled = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                LocalBilled = Fixture.Decimal(),
                CaseId = Fixture.Integer(),
                // presence of CaseId causes accountEntityId to be persisted
                IsDraft = true,
                IsCreditWip = true
            };

            var subject = CreateSubject();

            var _ = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = accountEntityId,
                                          AccountDebtorNameId = accountDebtorId,
                                          AvailableWipItems = new[]
                                          {
                                              draftWipToBeBilled
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            var persisted = Db.Set<BilledItem>().Single();

            Assert.Equal(itemEntityId, persisted.ItemEntityId);
            Assert.Equal(itemTransactionId, persisted.ItemTransactionId);
            Assert.Equal(accountEntityId, persisted.AccountEntityId);
            Assert.Equal(accountDebtorId, persisted.AccountDebtorId);
            Assert.Equal(draftWipToBeBilled.EntityId, persisted.WipEntityId);
            Assert.Equal(draftWipToBeBilled.TransactionId, persisted.WipTransactionId);
            Assert.Equal(draftWipToBeBilled.WipSeqNo, persisted.WipSequenceNo);
            Assert.Equal(draftWipToBeBilled.LocalBilled * -1, persisted.BilledValue);
            Assert.Equal(draftWipToBeBilled.LocalVariation * -1, persisted.AdjustedValue);
            Assert.Null(persisted.ForeignCurrency);
            Assert.Null(persisted.ForeignBilledValue);
        }

        [Fact]
        public async Task ShouldInsertTheBilledItemForTheForeignDraftCreditWipWithSignsReversed()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var draftWipToBeBilled = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                LocalBilled = Fixture.Decimal(),
                CaseId = Fixture.Integer(),
                // presence of CaseId causes accountEntityId to be persisted
                ForeignBilled = Fixture.Decimal(),
                ForeignCurrency = Fixture.String(),
                IsDraft = true,
                IsCreditWip = true
            };

            var subject = CreateSubject();

            var _ = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = accountEntityId,
                                          AccountDebtorNameId = accountDebtorId,
                                          AvailableWipItems = new[]
                                          {
                                              draftWipToBeBilled
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            var persisted = Db.Set<BilledItem>().Single();

            Assert.Equal(itemEntityId, persisted.ItemEntityId);
            Assert.Equal(itemTransactionId, persisted.ItemTransactionId);
            Assert.Equal(accountEntityId, persisted.AccountEntityId);
            Assert.Equal(accountDebtorId, persisted.AccountDebtorId);
            Assert.Equal(draftWipToBeBilled.EntityId, persisted.WipEntityId);
            Assert.Equal(draftWipToBeBilled.TransactionId, persisted.WipTransactionId);
            Assert.Equal(draftWipToBeBilled.WipSeqNo, persisted.WipSequenceNo);
            Assert.Equal(draftWipToBeBilled.LocalBilled * -1, persisted.BilledValue);
            Assert.Equal(draftWipToBeBilled.LocalVariation * -1, persisted.AdjustedValue);
            Assert.Equal(draftWipToBeBilled.ForeignCurrency, persisted.ForeignCurrency);
            Assert.Equal(draftWipToBeBilled.ForeignBilled * -1, persisted.ForeignBilledValue);
            Assert.Equal(draftWipToBeBilled.ForeignVariation * -1, persisted.ForeignAdjustedValue);
        }

        [Fact]
        public async Task ShouldLockWipIncludedInTheBill()
        {
            var wipInDb = new WorkInProgress
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSequenceNo = Fixture.Short(),
                Status = TransactionStatus.Active
            }.In(Db);

            var wipIncludeInThisDraft = new AvailableWipItem
            {
                EntityId = wipInDb.EntityId,
                TransactionId = wipInDb.TransactionId,
                WipSeqNo = wipInDb.WipSequenceNo
            };

            var result = new SaveOpenItemResult(Guid.NewGuid());

            var subject = CreateSubject();

            var _ = await subject.Run(2, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = Fixture.Integer(),
                                          ItemTransactionId = Fixture.Integer(),
                                          AccountEntityId = Fixture.Integer(),
                                          AvailableWipItems = new[]
                                          {
                                              wipIncludeInThisDraft
                                          }
                                      },
                                      result);

            Assert.Equal(TransactionStatus.Locked, wipInDb.Status);
        }

        [Fact]
        public async Task ShouldUpdateWipBalanceOnDraftBill()
        {
            // set billed value from billed item earlier in the process
            // if the draft wip was recording negative values,
            // the billed value should be made negative as well

            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var draftWipInDb = new WorkInProgress
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSequenceNo = Fixture.Short(),
                LocalValue = Fixture.Decimal(),
                Balance = Fixture.Decimal(),
                ForeignValue = Fixture.Decimal(),
                ForeignBalance = Fixture.Decimal(),
                Status = TransactionStatus.Draft
            }.In(Db);

            var draftWipToBeBilled = new AvailableWipItem
            {
                EntityId = draftWipInDb.EntityId,
                TransactionId = draftWipInDb.TransactionId,
                WipSeqNo = draftWipInDb.WipSequenceNo,
                LocalBilled = Fixture.Decimal(),
                ForeignBilled = Fixture.Decimal(),
                ForeignCurrency = Fixture.String(),
                CaseId = Fixture.Integer(), // presence of CaseId causes accountEntityId to be persisted
                IsDraft = true
            };

            var subject = CreateSubject();

            var _ = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = accountEntityId,
                                          AccountDebtorNameId = accountDebtorId,
                                          AvailableWipItems = new[]
                                          {
                                              draftWipToBeBilled
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            Assert.Equal(draftWipToBeBilled.LocalBilled, draftWipInDb.LocalValue);
            Assert.Equal(draftWipToBeBilled.LocalBilled, draftWipInDb.Balance);
            Assert.Equal(draftWipToBeBilled.ForeignBilled, draftWipInDb.ForeignValue);
            Assert.Equal(draftWipToBeBilled.ForeignBilled, draftWipInDb.ForeignBalance);
        }

        [Fact]
        public async Task ShouldUpdateWorkHistoryBalanceForTheWipOnDraftBill()
        {
            // set billed value from billed item earlier in the process
            // if the work history record for draft wip was recording negative values,
            // the billed value should be made negative as well
            // Bill line on the WH should be set to null if not already billed

            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var accountDebtorId = Fixture.Integer();

            var workHistoryForDraftWipInDb = new WorkHistory
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSequenceNo = Fixture.Short(),
                LocalValue = Fixture.Decimal(),
                ForeignValue = Fixture.Decimal()
            }.In(Db);

            new WorkInProgress
            {
                EntityId = workHistoryForDraftWipInDb.EntityId,
                TransactionId = workHistoryForDraftWipInDb.TransactionId,
                WipSequenceNo = workHistoryForDraftWipInDb.WipSequenceNo,
                Status = TransactionStatus.Draft
            }.In(Db);

            var draftWipToBeBilled = new AvailableWipItem
            {
                EntityId = workHistoryForDraftWipInDb.EntityId,
                TransactionId = workHistoryForDraftWipInDb.TransactionId,
                WipSeqNo = workHistoryForDraftWipInDb.WipSequenceNo,
                LocalBilled = Fixture.Decimal(),
                ForeignBilled = Fixture.Decimal(),
                ForeignCurrency = Fixture.String(),
                CaseId = Fixture.Integer(), // presence of CaseId causes accountEntityId to be persisted
                IsDraft = true
            };

            var subject = CreateSubject();

            var _ = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = accountEntityId,
                                          AccountDebtorNameId = accountDebtorId,
                                          AvailableWipItems = new[]
                                          {
                                              draftWipToBeBilled
                                          }
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            Assert.Equal(draftWipToBeBilled.LocalBilled, workHistoryForDraftWipInDb.LocalValue);
            Assert.Equal(draftWipToBeBilled.ForeignBilled, workHistoryForDraftWipInDb.ForeignValue);
        }

        [Fact]
        public async Task ShouldDeleteUnusedDraftWipItems()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            new WorkInProgress
            {
                EntityId = itemEntityId,
                TransactionId = itemTransactionId,
                WipSequenceNo = Fixture.Short(),
                LocalValue = Fixture.Decimal(),
                Balance = Fixture.Decimal(),
                ForeignValue = Fixture.Decimal(),
                ForeignBalance = Fixture.Decimal(),
                Status = TransactionStatus.Draft
            }.In(Db);

            var subject = CreateSubject();

            var _ = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = Fixture.Integer(),
                                          AccountDebtorNameId = Fixture.Integer()
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            Assert.Empty(Db.Set<WorkInProgress>());
        }

        [Fact]
        public async Task ShouldDeleteWorkHistoryOfUnusedDraftWipItems()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            new WorkInProgress
            {
                EntityId = itemEntityId,
                TransactionId = itemTransactionId,
                WipSequenceNo = Fixture.Short(),
                LocalValue = Fixture.Decimal(),
                Balance = Fixture.Decimal(),
                ForeignValue = Fixture.Decimal(),
                ForeignBalance = Fixture.Decimal(),
                Status = TransactionStatus.Draft
            }.In(Db);

            new WorkHistory
            {
                EntityId = itemEntityId,
                TransactionId = itemTransactionId,
                WipSequenceNo = Fixture.Short()
            }.In(Db);

            var subject = CreateSubject();

            var _ = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          AccountEntityId = Fixture.Integer(),
                                          AccountDebtorNameId = Fixture.Integer()
                                      },
                                      new SaveOpenItemResult(Guid.NewGuid()));

            Assert.Empty(Db.Set<WorkInProgress>());
            Assert.Empty(Db.Set<WorkHistory>());
        }
    }
}