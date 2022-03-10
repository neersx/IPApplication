using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Wip;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.DisbursementDissection
{
    [SplitWipMultiDebtor]
    [Category(Categories.Integration)]
    [TestFixture]
    [TestFrom(16)]
    public class DisbursementDissectionMultiDebtorScenarios : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _wipData = new DataSetup()
                       .WithSplitWipMultiDebtorEnabled()
                       .ForDisbursementDissection();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
            
            SiteControlRestore.ToDefault(SiteControls.WIPSplitMultiDebtor);
        }

        WipData _wipData;

        [Test]
        public void IdentifyMultiDebtorStatus()
        {
            /* 
             * CaseLocalMultiple to have 2 debtors, they are not renewal debtors.
             * CaseLocalSingle to have only 1 debtor and is not a renewal debtor
             */

            CheckMultiDebtorStatusForCaseAndActivity(_wipData.CaseLocalMultiple.Id, _wipData.CaseLocalMultiple.Irn, _wipData.PaidDisbursement1.WipCode, true, false);

            CheckMultiDebtorStatusForCaseAndActivity(_wipData.CaseLocalMultiple.Id, _wipData.CaseLocalMultiple.Irn, _wipData.PaidDisbursement2.WipCode, true, false);

            CheckMultiDebtorStatusForCaseAndActivity(_wipData.CaseLocalSingle.Id, _wipData.CaseLocalSingle.Irn, _wipData.PaidDisbursement1.WipCode, false, false);
        }

        [Test]
        public void WipSplitLocalDebtors()
        {
            /*
             * This scenario dissects $3000 in local currency to
             *  - CaseLocalMultiple (2 debtors) with pd1
             *  - CaseLocalMultiple (2 debtors) with pd2
             *  - CaseLocalSingle (1 debtor) with pd2
             * The test demonstrates
             * - wip are split based on debtor percentages rather than allocated to the first debtor (CaseLocalMultiple)
             * - wip are costed similarly if it is only a single debtor (CaseLocalSingle)
             * - the discounts and margin are appropriately calculated 
             * - the values are saved in WIP and TRANSACTIONHEADER correctly
             */

            /*
             * - case 'local-multiple' (two local debtors 60/40 split) to have 1000 against 'pd1' activity.
             *   -- debtor 1 in this case has an across the board 10% discount
             *   -- 'pd1' activity has default narrative.
             */
            var resultCase1 = CheckWipSplittingCorrectlyBasedOnParameters(new DisbursementWipParameter
                                                                          {
                                                                              CaseKey = _wipData.CaseLocalMultiple.Id,
                                                                              EntityKey = _wipData.EntityId,
                                                                              LocalValueBeforeMargin = 1000,
                                                                              MarginRequired = true,
                                                                              NameKey = _wipData.CaseLocalMultiple.Instructor().NameId,
                                                                              StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                                                                              TransactionDate = DateTime.Today.Date,
                                                                              WIPCode = _wipData.PaidDisbursement1.WipCode
                                                                          },
                                                                          $"Case {_wipData.CaseLocalMultiple.Irn} and {_wipData.PaidDisbursement1.WipCode} #1",
                                                                          new ExpectedCosting
                                                                          {
                                                                              DebtorSplitPercentage = 60,
                                                                              LocalDiscount = 60, /* 10% of local amount (600)  */
                                                                              LocalCost1 = 600, /* local value before margin (600) + margin (0) */
                                                                              LocalCost2 = 600, /* local value before margin (600) + margin (0) */
                                                                              LocalDiscountForMargin = 0,
                                                                              ForeignAmount = 0,
                                                                              LocalAmount = 600,
                                                                              NameKey = _wipData.CaseLocalMultiple.Debtor1().NameId
                                                                          }, new ExpectedCosting
                                                                          {
                                                                              DebtorSplitPercentage = 40,
                                                                              LocalCost1 = 400, /* local value before margin (400) + margin (0) */
                                                                              LocalCost2 = 400, /* local value before margin (400) + margin (0) */
                                                                              ForeignAmount = 0,
                                                                              LocalAmount = 400,
                                                                              NameKey = _wipData.CaseLocalMultiple.Debtor2().NameId
                                                                          });

            /*
             * - case 'local-multiple' (two local debtors 60/40 split) to have 1000 against 'pd2' activity.
             *   -- debtor 1 in this case has an across the board 10% discount
             *   -- debtor 2 in this case has a $50 margin on 'pd2'
             *   -- 'pd2' activity has default narrative.
             *   -- 'pd2' has across the board $20 margin
             */
            var resultCase2 = CheckWipSplittingCorrectlyBasedOnParameters(new DisbursementWipParameter
                                                                          {
                                                                              CaseKey = _wipData.CaseLocalMultiple.Id,
                                                                              EntityKey = _wipData.EntityId,
                                                                              LocalValueBeforeMargin = 1000,
                                                                              MarginRequired = true,
                                                                              NameKey = _wipData.CaseLocalMultiple.Instructor().NameId,
                                                                              StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                                                                              TransactionDate = DateTime.Today.Date,
                                                                              WIPCode = _wipData.PaidDisbursement2.WipCode
                                                                          },
                                                                          $"Case {_wipData.CaseLocalMultiple.Irn} and {_wipData.PaidDisbursement2.WipCode} #2",
                                                                          new ExpectedCosting
                                                                          {
                                                                              DebtorSplitPercentage = 60,
                                                                              LocalDiscount = 62, /* 10% of (local value before margin (600) + margin (20)) */
                                                                              LocalDiscountForMargin = 2, /* 10% of 20 (Margin) */
                                                                              LocalCost1 = 620, /* local value before margin (600) + margin (20) */
                                                                              LocalCost2 = 620, /* local value before margin (600) + margin (20) */
                                                                              LocalAmount = 600,
                                                                              ForeignAmount = 0,
                                                                              NameKey = _wipData.CaseLocalMultiple.Debtor1().NameId,
                                                                              MarginValue = 20
                                                                          }, new ExpectedCosting
                                                                          {
                                                                              DebtorSplitPercentage = 40,
                                                                              LocalCost1 = 450, /* local value before margin (400) + margin (50) */
                                                                              LocalCost2 = 450, /* local value before margin (400) + margin (50) */
                                                                              LocalAmount = 400,
                                                                              ForeignAmount = 0,
                                                                              MarginValue = 50,
                                                                              NameKey = _wipData.CaseLocalMultiple.Debtor2().NameId
                                                                          });

            var saveParams = new[]
            {
                new DisbursementDissectionParameter
                {
                    /* this takes from result above multi debtor case with pd1*/
                    Amount = 1000,
                    CaseKey = _wipData.CaseLocalMultiple.Id,
                    DebitNoteText = _wipData.PaidDisbursement1Narrative.NarrativeText,
                    Description = _wipData.PaidDisbursement1.Description,
                    Discount = 60,
                    IsSplitDebtorWip = true,
                    LocalDiscountForMargin = 0,
                    Margin = 0,
                    MarginNo = null,
                    NameKey = _wipData.CaseLocalMultiple.Instructor().NameId,
                    NarrativeCode = _wipData.PaidDisbursement1Narrative.NarrativeCode,
                    NarrativeText = _wipData.PaidDisbursement1Narrative.NarrativeText,
                    NarrativeKey = _wipData.PaidDisbursement1Narrative.NarrativeId,
                    StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                    TransDate = DateTime.Today,
                    WipCode = _wipData.PaidDisbursement1.WipCode,
                    WipSeqNo = 0,
                    SplitWipItems = resultCase1
                },
                new DisbursementDissectionParameter
                {
                    /* this takes from result above multi debtor case with pd2*/
                    Amount = 1000,
                    CaseKey = _wipData.CaseLocalMultiple.Id,
                    DebitNoteText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                    Description = _wipData.PaidDisbursement2.Description,
                    Discount = 62,
                    LocalDiscountForMargin = 2,
                    Margin = 70,
                    NameKey = _wipData.CaseLocalMultiple.Instructor().NameId,
                    NarrativeCode = _wipData.PaidDisbursement2Narrative.NarrativeCode,
                    NarrativeText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                    NarrativeKey = _wipData.PaidDisbursement2Narrative.NarrativeId,
                    StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                    TransDate = DateTime.Today,
                    WipCode = _wipData.PaidDisbursement2.WipCode,
                    WipSeqNo = 0,
                    SplitWipItems = resultCase2
                },
                new DisbursementDissectionParameter
                {
                    /* single debtor case with pd2 for remainder 1000
                     - demonstrates that the system can save both types together */
                    Amount = 1000,
                    CaseKey = _wipData.CaseLocalSingle.Id,
                    DebitNoteText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                    Description = _wipData.PaidDisbursement2.Description,
                    Discount = 102,
                    LocalDiscountForMargin = 2,
                    LocalCost1 = 1020,
                    LocalCost2 = 1020,
                    IsSplitDebtorWip = false,
                    Margin = 20,
                    MarginNo = 2,
                    NameKey = _wipData.CaseLocalSingle.Instructor().NameId,
                    NarrativeCode = _wipData.PaidDisbursement2Narrative.NarrativeCode,
                    NarrativeText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                    NarrativeKey = _wipData.PaidDisbursement2Narrative.NarrativeId,
                    StaffKey = _wipData.CaseLocalSingle.Staff().NameId,
                    TransDate = DateTime.Today,
                    WipCode = _wipData.PaidDisbursement2.WipCode,
                    WipSeqNo = 0
                }
            };

            /* Saves above costed wip */
            var beforeSaveTime = DateTime.Now;
            ApiClient.Post<bool>("accounting/wip-disbursements",
                                 new
                                 {
                                     TransDate = DateTime.Today,
                                     TotalAmount = 3000,
                                     EntityKey = _wipData.EntityId,
                                     DissectedDisbursements = saveParams
                                 });

            var saved = DbSetup.Do(x =>
            {
                var workInProgress = x.DbContext.Set<WorkInProgress>()
                                      .Where(_ => _.CaseId == _wipData.CaseLocalSingle.Id || _.CaseId == _wipData.CaseLocalMultiple.Id)
                                      .OrderBy(_ => _.WipSequenceNo)
                                      .ToArray();

                var transactionHeader = x.DbContext.Set<TransactionHeader>().Single(_ => _.EntryDate > beforeSaveTime);

                return new
                {
                    WorkInProgress = workInProgress,
                    TransactionHeader = transactionHeader
                };
            });

            var savedWorkInProgress = saved.WorkInProgress;
            var wipSequenceNumbers = savedWorkInProgress.Select(_ => _.WipSequenceNo).ToArray();
            var currentWipValues = string.Join(",", savedWorkInProgress
                                                   .Select(_ => $"'{_.WipCode}' ({_.WipSequenceNo})"));

            Assert.AreEqual(TransactionType.Disbursement, saved.TransactionHeader.TransactionType, "Should be disbursement transaction type");
            Assert.AreEqual(SystemIdentifier.TimeAndBilling, saved.TransactionHeader.Source, "Should be Time & Billing (Accounting System ID)");
            Assert.LessOrEqual(beforeSaveTime, saved.TransactionHeader.EntryDate, "Entry Date is greater than the time these items are submitted for saving");

            Assert.True(savedWorkInProgress.All(_ => _.EntityId == saved.TransactionHeader.EntityId && _.TransactionDate == saved.TransactionHeader.TransactionDate), "Should have same transaction header details for all WIP posted");
            CollectionAssert.AreEqual(new short[] {1, 2, 3, 4, 5, 6, 7, 8}, wipSequenceNumbers, $"Should have 8 WIP items in single transaction, i.e. [WIP, DISC WIP, WIP], [WIP, DISC WIP, WIP], [WIP, DISC WIP] but is ({currentWipValues}) ");

            var wipsForCase1Debtor1 = new CheckResultMap<dynamic>(saveParams[0].SplitWipItems.ElementAt(0), saved.WorkInProgress[0], saved.WorkInProgress[1]);

            var wipsForCase1Debtor2 = new CheckResultMap<dynamic>(saveParams[0].SplitWipItems.ElementAt(1), saved.WorkInProgress[2]);

            var wipsForCase2Debtor1 = new CheckResultMap<dynamic>(saveParams[1].SplitWipItems.ElementAt(0), saved.WorkInProgress[3], saved.WorkInProgress[4]);

            var wipsForCase2Debtor2 = new CheckResultMap<dynamic>(saveParams[1].SplitWipItems.ElementAt(1), saved.WorkInProgress[5]);

            var wipForCase3 = new CheckResultMap<DisbursementDissectionParameter>(saveParams[2], saved.WorkInProgress[6], saved.WorkInProgress[7]);

            CheckDisbursementSavedCorrectly(wipsForCase1Debtor1, null, beforeSaveTime, "disbursement #1 debtor 1");
            CheckDisbursementSavedCorrectly(wipsForCase1Debtor2, null, beforeSaveTime, "disbursement #1 debtor 2");

            CheckDisbursementSavedCorrectly(wipsForCase2Debtor1, null, beforeSaveTime, "disbursement #2 debtor 1");
            CheckDisbursementSavedCorrectly(wipsForCase2Debtor2, null, beforeSaveTime, "disbursement #2 debtor 2");

            CheckDisbursementSavedCorrectly(wipForCase3, null, beforeSaveTime, "disbursement #3 debtor 1");
        }

        [Test]
        public void WipSplitRegardlessForeignOrLocalDebtors()
        {
            /*
             * This scenario dissects $2000 in foreign currency to
             *  - CaseForeignMultiple (2 debtors) with pd2
             *  - CaseLocalMultiple (2 debtors) with pd2
             * The test demonstrates
             * - wip are split based on debtor percentages rather than allocated to the first debtor (CaseLocalMultiple)
             * - wip are costed similarly if it is only a single debtor (CaseLocalSingle)
             * - the discounts and margin are appropriately calculated 
             * - the values are saved in WIP and TRANSACTIONHEADER correctly
             */

            /*
             * - case 'foreign-multiple' (two foreign debtors 40/60 split) to have 1000 against 'pd2' activity.
             *   -- foreign debtor 1 in this case has an across the board 20% discount and margin of 100 for pd2
             *   -- 'pd2' activity has default narrative, which will be overriden with entered text.
             *   -- 'pd2' has across the board $20 margin
             *   -- foreign currency 1 has exchange rate 1.1 (foreign debtor 1 default currency)
             *   -- foreign currency 2 has exchange rate 1.2 (foreign debtor 2 default currency)
             */
            var resultCase1 = CheckWipSplittingCorrectlyBasedOnParameters(new DisbursementWipParameter
                                                                          {
                                                                              CaseKey = _wipData.CaseForeignMultiple.Id,
                                                                              EntityKey = _wipData.EntityId,
                                                                              CurrencyCode = _wipData.ForeignCurrency1.Id,
                                                                              ForeignValueBeforeMargin = 1000,
                                                                              MarginRequired = true,
                                                                              NameKey = _wipData.CaseForeignMultiple.Instructor().NameId,
                                                                              StaffKey = _wipData.CaseForeignMultiple.Staff().NameId,
                                                                              TransactionDate = DateTime.Today.Date,
                                                                              WIPCode = _wipData.PaidDisbursement2.WipCode
                                                                          },
                                                                          $"Case {_wipData.CaseForeignMultiple.Irn} and {_wipData.PaidDisbursement2.WipCode} #1",
                                                                          new ExpectedCosting
                                                                          {
                                                                              DebtorSplitPercentage = 40,
                                                                              MarginValue = 100, /* from pd2 for this debtor */
                                                                              LocalDiscountForMargin = 20, /* 20% of 100 (Margin) */
                                                                              LocalDiscount = (decimal) 92.73, /* 20% of (local value before margin (363.64) + margin (100)) */
                                                                              LocalCost1 = (decimal) 463.64, /* local value before margin (363.64) + margin (100) */
                                                                              LocalCost2 = (decimal) 463.64, /* local value before margin (363.64) + margin (100) */
                                                                              LocalAmount = (decimal) 363.64, /* foreign amount (400) / exchange rate (1.1) */
                                                                              ForeignMargin = 110, /* margin value 100 x exchange rate 1.1 */
                                                                              ForeignDiscountForMargin = 22, /* 20% of 110 (ForeignMargin) */
                                                                              ForeignAmount = 400,
                                                                              ForeignDiscount = 102, /* 20% of (foreign value before margin (400) + foreign margin (110)) */
                                                                              NameKey = _wipData.CaseForeignMultiple.Debtor2().NameId
                                                                          }, new ExpectedCosting
                                                                          {
                                                                              DebtorSplitPercentage = 60,
                                                                              MarginValue = 20,
                                                                              LocalCost1 = (decimal) 565.45, /* local value before margin (545.45) + margin (20) */
                                                                              LocalCost2 = (decimal) 565.45, /* local value before margin (545.45) + margin (20) */
                                                                              LocalAmount = (decimal) 545.45, /* foreign amount (600) / exchange rate (1.1) */
                                                                              ForeignMargin = 22, /* Margin in local currency 20 x Exchange Rate 1.1 */
                                                                              ForeignAmount = 600,
                                                                              NameKey = _wipData.CaseForeignMultiple.Debtor1().NameId
                                                                          });

            /*
             * - case 'local-multiple' (two local debtors 60/40 split) to have 1000 against 'pd2' activity.
             *   -- debtor 1 in this case has an across the board 10% discount
             *   -- debtor 2 in this case has a $50 margin on 'pd2'
             *   -- 'pd2' activity has default narrative.
             *   -- 'pd2' has across the board $20 margin
             */
            var resultCase2 = CheckWipSplittingCorrectlyBasedOnParameters(new DisbursementWipParameter
                                                                          {
                                                                              CaseKey = _wipData.CaseLocalMultiple.Id,
                                                                              EntityKey = _wipData.EntityId,
                                                                              CurrencyCode = _wipData.ForeignCurrency1.Id,
                                                                              ForeignValueBeforeMargin = 1000,
                                                                              MarginRequired = true,
                                                                              NameKey = _wipData.CaseLocalMultiple.Instructor().NameId,
                                                                              StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                                                                              TransactionDate = DateTime.Today.Date,
                                                                              WIPCode = _wipData.PaidDisbursement2.WipCode
                                                                          },
                                                                          $"Case {_wipData.CaseLocalMultiple.Irn} and {_wipData.PaidDisbursement2.WipCode} #2",
                                                                          new ExpectedCosting
                                                                          {
                                                                              DebtorSplitPercentage = 60,
                                                                              MarginValue = 20,
                                                                              LocalDiscount = (decimal) 56.55, /* 10% of (local value before margin (545.45) + margin (20)) */
                                                                              LocalDiscountForMargin = 2, /* 10% of 20 (Margin) */
                                                                              LocalCost1 = (decimal) 565.45, /* local value before margin (545.45) + margin (20) */
                                                                              LocalCost2 = (decimal) 565.45, /* local value before margin (545.45) + margin (20) */
                                                                              LocalAmount = (decimal) 545.45, /* foreign amount (600) / exchange rate (1.1) */
                                                                              ForeignMargin = 22, /* Margin in local currency 20 x Exchange Rate 1.1 */
                                                                              ForeignDiscount = (decimal) 62.2, /* 10% of (foreign value before margin (600) + foreign margin (22)) */
                                                                              ForeignDiscountForMargin = (decimal) 2.2, /* 10% of 22 (ForeignMargin) */
                                                                              ForeignAmount = 600,
                                                                              NameKey = _wipData.CaseLocalMultiple.Debtor1().NameId
                                                                          }, new ExpectedCosting
                                                                          {
                                                                              DebtorSplitPercentage = 40,
                                                                              MarginValue = 50,
                                                                              LocalCost1 = (decimal) 413.64, /* local value before margin (363.64) + margin (50) */
                                                                              LocalCost2 = (decimal) 413.64, /* local value before margin (363.64) + margin (50) */
                                                                              LocalAmount = (decimal) 363.64, /* foreign amount (400) / exchange rate (1.1) */
                                                                              ForeignMargin = 55, /* Margin in local currency 50 x Exchange Rate 1.1 */
                                                                              ForeignAmount = 400,
                                                                              NameKey = _wipData.CaseLocalMultiple.Debtor2().NameId
                                                                          });

            var saveParams = new[]
            {
                new DisbursementDissectionParameter
                {
                    /* this takes from result above multi debtor case with pd1*/
                    Amount = (decimal) 909.09, /* split local amount 1 (363.64) + split local amount 2 (545.45) */
                    ForeignAmount = 1000,
                    CurrencyCode = _wipData.ForeignCurrency1.Id,
                    CaseKey = _wipData.CaseForeignMultiple.Id,
                    DebitNoteText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                    Description = _wipData.PaidDisbursement2.Description,
                    Discount = (decimal) 92.73, /* split local discount 1 (92.73) + split local discount 2 (0) */
                    ForeignDiscount = 102, /* split foreign discount 1 (102) + split foreign discount 2 (0) */
                    IsSplitDebtorWip = true,
                    ExchRate = (decimal) 1.1,
                    LocalDiscountForMargin = 0,
                    ForeignDiscountForMargin = 22, /* split foreign discount for margin 1 (22) + split foreign discount for margin 2 (0) */
                    Margin = 120, /* split local margin 1 (100) + split local margin 2 (20) */
                    ForeignMargin = 132, /* split foreign margin 1 (110) + split foreign margin 2 (22) */
                    MarginNo = null,
                    NameKey = _wipData.CaseForeignMultiple.Instructor().NameId,
                    NarrativeCode = _wipData.PaidDisbursement2Narrative.NarrativeCode,
                    NarrativeText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                    NarrativeKey = _wipData.PaidDisbursement2Narrative.NarrativeId,
                    StaffKey = _wipData.CaseForeignMultiple.Staff().NameId,
                    TransDate = DateTime.Today,
                    WipCode = _wipData.PaidDisbursement1.WipCode,
                    WipSeqNo = 0,
                    SplitWipItems = resultCase1
                },
                new DisbursementDissectionParameter
                {
                    /* this takes from result above multi debtor case with pd2*/
                    Amount = 1000, /* split local amount 1 (545.45) + split local amount 2 (363.64) */
                    ForeignAmount = 1000,
                    CaseKey = _wipData.CaseLocalMultiple.Id,
                    CurrencyCode = _wipData.ForeignCurrency1.Id,
                    DebitNoteText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                    Description = _wipData.PaidDisbursement2.Description,
                    Discount = (decimal) 56.55, /* split local discount 1 (56.55) + split local discount 2 (0) */
                    ForeignDiscount = (decimal) 62.2, /* split foreign discount 1 (62.2) + split foreign discount 2 (0) */
                    LocalDiscountForMargin = 2, /* split local discount for margin 1 (2) + split local discount for margin 2 (0) */
                    ForeignDiscountForMargin = (decimal) 2.2, /* split foreign discount for margin 1 (2.2) + split foreign discount for margin 2 (0) */
                    Margin = 70, /* split local margin 1 (20) + split local margin 2 (50) */
                    ForeignMargin = 77, /* split foreign margin 1 (22) + split foreign margin 2 (55) */
                    NameKey = _wipData.CaseLocalMultiple.Instructor().NameId,
                    NarrativeCode = _wipData.PaidDisbursement2Narrative.NarrativeCode,
                    NarrativeText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                    NarrativeKey = _wipData.PaidDisbursement2Narrative.NarrativeId,
                    StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                    TransDate = DateTime.Today,
                    WipCode = _wipData.PaidDisbursement2.WipCode,
                    WipSeqNo = 0,
                    SplitWipItems = resultCase2
                }
            };

            /* Saves above costed wip */
            var beforeSaveTime = DateTime.Now;
            ApiClient.Post<bool>("accounting/wip-disbursements",
                                 new
                                 {
                                     TransDate = DateTime.Today,
                                     TotalAmount = 3000,
                                     EntityKey = _wipData.EntityId,
                                     Currency = _wipData.ForeignCurrency1.Id,
                                     DissectedDisbursements = saveParams
                                 });

            var saved = DbSetup.Do(x =>
            {
                var workInProgress = x.DbContext.Set<WorkInProgress>()
                                      .Where(_ => _.CaseId == _wipData.CaseForeignMultiple.Id || _.CaseId == _wipData.CaseLocalMultiple.Id)
                                      .OrderBy(_ => _.WipSequenceNo)
                                      .ToArray();

                var transactionHeader = x.DbContext.Set<TransactionHeader>().Single(_ => _.EntryDate > beforeSaveTime);

                return new
                {
                    WorkInProgress = workInProgress,
                    TransactionHeader = transactionHeader
                };
            });

            var savedWorkInProgress = saved.WorkInProgress;
            var wipSequenceNumbers = savedWorkInProgress.Select(_ => _.WipSequenceNo).ToArray();
            var currentWipValues = string.Join(",", savedWorkInProgress
                                                   .Select(_ => $"'{_.WipCode}' ({_.WipSequenceNo})"));

            Assert.AreEqual(TransactionType.Disbursement, saved.TransactionHeader.TransactionType, "Should be disbursement transaction type");
            Assert.AreEqual(SystemIdentifier.TimeAndBilling, saved.TransactionHeader.Source, "Should be Time & Billing (Accounting System ID)");
            Assert.LessOrEqual(beforeSaveTime, saved.TransactionHeader.EntryDate, "Entry Date is greater than the time these items are submitted for saving");

            Assert.True(savedWorkInProgress.All(_ => _.EntityId == saved.TransactionHeader.EntityId && _.TransactionDate == saved.TransactionHeader.TransactionDate), "Should have same transaction header details for all WIP posted");
            CollectionAssert.AreEqual(new short[] {1, 2, 3, 4, 5, 6}, wipSequenceNumbers, $"Should have 6 WIP items in single transaction, i.e. [WIP, DISC WIP, WIP], [WIP, DISC WIP, WIP], but is ({currentWipValues}) ");

            var wipsForCase1Debtor1 = new CheckResultMap<dynamic>(saveParams[0].SplitWipItems.ElementAt(0), saved.WorkInProgress[0], saved.WorkInProgress[1]);

            var wipsForCase1Debtor2 = new CheckResultMap<dynamic>(saveParams[0].SplitWipItems.ElementAt(1), saved.WorkInProgress[2]);

            var wipsForCase2Debtor1 = new CheckResultMap<dynamic>(saveParams[1].SplitWipItems.ElementAt(0), saved.WorkInProgress[3], saved.WorkInProgress[4]);

            var wipsForCase2Debtor2 = new CheckResultMap<dynamic>(saveParams[1].SplitWipItems.ElementAt(1), saved.WorkInProgress[5]);

            CheckDisbursementSavedCorrectly(wipsForCase1Debtor1, _wipData.ForeignCurrency1.Id, beforeSaveTime, "disbursement #1 debtor 1");
            CheckDisbursementSavedCorrectly(wipsForCase1Debtor2, _wipData.ForeignCurrency1.Id, beforeSaveTime, "disbursement #1 debtor 2");

            CheckDisbursementSavedCorrectly(wipsForCase2Debtor1, _wipData.ForeignCurrency1.Id, beforeSaveTime, "disbursement #2 debtor 1");
            CheckDisbursementSavedCorrectly(wipsForCase2Debtor2, _wipData.ForeignCurrency1.Id, beforeSaveTime, "disbursement #2 debtor 2");
        }

        [Test]
        public void WipSplitLocalDebtorsCreditWip()
        {
            /*
             * This scenario dissects $1000 in local currency to
             *  - CaseLocalMultiple (2 debtors) with pd2
             * The test demonstrates
             * - wip are split based on debtor percentages rather than allocated to the first debtor (CaseLocalMultiple)
             * - the discounts and margin are appropriately calculated 
             * - the values are saved in WIP and TRANSACTIONHEADER correctly
             */

            /*
             * - case 'local-multiple' (two local debtors 60/40 split) to have 1000 against 'pd2' activity.
             *   -- debtor 1 in this case has an across the board 10% discount
             *   -- debtor 2 in this case has a $50 margin on 'pd2'
             *   -- 'pd2' activity has default narrative.
             *   -- 'pd2' has across the board $20 margin
             */
            var resultCase2 = CheckWipSplittingCorrectlyBasedOnParameters(new DisbursementWipParameter
                                                                          {
                                                                              CaseKey = _wipData.CaseLocalMultiple.Id,
                                                                              EntityKey = _wipData.EntityId,
                                                                              LocalValueBeforeMargin = 1000,
                                                                              MarginRequired = true,
                                                                              NameKey = _wipData.CaseLocalMultiple.Instructor().NameId,
                                                                              StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                                                                              TransactionDate = DateTime.Today.Date,
                                                                              WIPCode = _wipData.PaidDisbursement2.WipCode
                                                                          },
                                                                          $"Case {_wipData.CaseLocalMultiple.Irn} and {_wipData.PaidDisbursement2.WipCode} #2",
                                                                          new ExpectedCosting
                                                                          {
                                                                              DebtorSplitPercentage = 60,
                                                                              LocalDiscount = 62, /* 10% of (local value before margin (600) + margin (20)) */
                                                                              LocalDiscountForMargin = 2, /* 10% of 20 (Margin) */
                                                                              LocalCost1 = 620, /* local value before margin (600) + margin (20) */
                                                                              LocalCost2 = 620, /* local value before margin (600) + margin (20) */
                                                                              LocalAmount = 600,
                                                                              ForeignAmount = 0,
                                                                              NameKey = _wipData.CaseLocalMultiple.Debtor1().NameId,
                                                                              MarginValue = 20
                                                                          }, new ExpectedCosting
                                                                          {
                                                                              DebtorSplitPercentage = 40,
                                                                              LocalCost1 = 450, /* local value before margin (400) + margin (50) */
                                                                              LocalCost2 = 450, /* local value before margin (400) + margin (50) */
                                                                              LocalAmount = 400,
                                                                              ForeignAmount = 0,
                                                                              MarginValue = 50,
                                                                              NameKey = _wipData.CaseLocalMultiple.Debtor2().NameId
                                                                          });

            var saveParam =
                new DisbursementDissectionParameter
                {
                    /* this takes from result above multi debtor case with pd2*/
                    Amount = 1000,
                    CaseKey = _wipData.CaseLocalMultiple.Id,
                    DebitNoteText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                    Description = _wipData.PaidDisbursement2.Description,
                    Discount = 62,
                    LocalDiscountForMargin = 2,
                    Margin = 70,
                    NameKey = _wipData.CaseLocalMultiple.Instructor().NameId,
                    NarrativeCode = _wipData.PaidDisbursement2Narrative.NarrativeCode,
                    NarrativeText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                    NarrativeKey = _wipData.PaidDisbursement2Narrative.NarrativeId,
                    StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                    TransDate = DateTime.Today,
                    WipCode = _wipData.PaidDisbursement2.WipCode,
                    WipSeqNo = 0,
                    SplitWipItems = resultCase2
                };

            /* Saves above costed wip */
            var beforeSaveTime = DateTime.Now;
            ApiClient.Post<bool>("accounting/wip-disbursements",
                                 new
                                 {
                                     TransDate = DateTime.Today,
                                     TotalAmount = 3000,
                                     EntityKey = _wipData.EntityId,
                                     CreditWIP = true,
                                     DissectedDisbursements = new[] {saveParam}
                                 });

            var saved = DbSetup.Do(x =>
            {
                var workInProgress = x.DbContext.Set<WorkInProgress>()
                                      .Where(_ => _.CaseId == _wipData.CaseLocalMultiple.Id)
                                      .OrderBy(_ => _.WipSequenceNo)
                                      .ToArray();

                var transactionHeader = x.DbContext.Set<TransactionHeader>().Single(_ => _.EntryDate > beforeSaveTime);

                return new
                {
                    WorkInProgress = workInProgress,
                    TransactionHeader = transactionHeader
                };
            });

            var savedWorkInProgress = saved.WorkInProgress;
            var wipSequenceNumbers = savedWorkInProgress.Select(_ => _.WipSequenceNo).ToArray();
            var currentWipValues = string.Join(",", savedWorkInProgress
                                                   .Select(_ => $"'{_.WipCode}' ({_.WipSequenceNo})"));

            Assert.AreEqual(TransactionType.Disbursement, saved.TransactionHeader.TransactionType, "Should be disbursement transaction type");
            Assert.AreEqual(SystemIdentifier.TimeAndBilling, saved.TransactionHeader.Source, "Should be Time & Billing (Accounting System ID)");
            Assert.LessOrEqual(beforeSaveTime, saved.TransactionHeader.EntryDate, "Entry Date is greater than the time these items are submitted for saving");

            Assert.True(savedWorkInProgress.All(_ => _.EntityId == saved.TransactionHeader.EntityId && _.TransactionDate == saved.TransactionHeader.TransactionDate), "Should have same transaction header details for all WIP posted");
            CollectionAssert.AreEqual(new short[] {1, 2, 3}, wipSequenceNumbers, $"Should have 3 WIP items in single transaction, i.e. [WIP, DISC WIP, WIP] but is ({currentWipValues}) ");

            var wipsForCase1Debtor1 = new CheckResultMap<dynamic>(saveParam.SplitWipItems.ElementAt(0), saved.WorkInProgress[0], saved.WorkInProgress[1]);

            var wipsForCase1Debtor2 = new CheckResultMap<dynamic>(saveParam.SplitWipItems.ElementAt(1), saved.WorkInProgress[2]);

            CheckCreditWipDisbursementSavedCorrectly(wipsForCase1Debtor1, null, beforeSaveTime, "disbursement #1 debtor 1");
            CheckCreditWipDisbursementSavedCorrectly(wipsForCase1Debtor2, null, beforeSaveTime, "disbursement #1 debtor 2");
        }

        static IEnumerable<dynamic> CheckWipSplittingCorrectlyBasedOnParameters(DisbursementWipParameter disbursementWip1, string message, params ExpectedCosting[] expectedCostings)
        {
            var result = ApiClient.Post<IEnumerable<BadDisbursementWip>>("accounting/wip-disbursements/split-by-debtors", disbursementWip1, "e2e_ken");

            var splits = result.Skip(1).ToArray();

            for (var i = 0; i < splits.Length; i++)
            {
                var split = splits[i];
                var expected = expectedCostings[i];

                Assert.AreEqual(expected.DebtorSplitPercentage, split.DebtorSplitPercentage, $"{message} debtor {i + 1} DebtorSplitPercentage");
                Assert.AreEqual(expected.NameKey, split.NameKey, $"{message} debtor {i + 1} NameKey");
                Assert.AreEqual(expected.LocalCost1, split.LocalCost1, $"{message} debtor {i + 1} LocalCost1");
                Assert.AreEqual(expected.LocalCost2, split.LocalCost2, $"{message} debtor {i + 1} LocalCost2");
                Assert.AreEqual(expected.LocalDiscount, split.Discount, $"{message} debtor {i + 1}  Discount");
                Assert.AreEqual(expected.LocalAmount, split.Amount, $"{message} debtor {i + 1}  Amount");
                Assert.AreEqual(expected.LocalDiscountForMargin, split.LocalDiscountForMargin, $"{message} debtor {i + 1}  LocalDiscountForMargin");
                Assert.AreEqual(expected.MarginValue, split.Margin, $"{message} debtor {i + 1} MarginValue");

                Assert.AreEqual(expected.ForeignAmount, split.ForeignAmount, $"{message} debtor {i + 1}  ForeignAmount");
                Assert.AreEqual(expected.ForeignDiscount, split.ForeignDiscount, $"{message} debtor {i + 1}  ForeignDiscount");
                Assert.AreEqual(expected.ForeignDiscountForMargin, split.ForeignDiscountForMargin, $"{message} debtor {i + 1}  ForeignDiscountForMargin");
                Assert.AreEqual(expected.ForeignMargin, split.ForeignMargin, $"{message} debtor {i + 1} ForeignMargin");

                Assert.AreEqual(expected.MarginNo, split.MarginNo, $"{message} debtor {i + 1} MarginNo");
            }

            return splits;
        }

        static void CheckMultiDebtorStatusForCaseAndActivity(int caseId, string caseRef, string activityKey, bool expectedIsMultiDebtorWip, bool expectedIsRenewalWip)
        {
            var result = ApiClient.Get<JObject>($"accounting/wip-disbursements/case-activity-multiple-debtors-status?caseId={caseId}&activityKey={activityKey}", "e2e_ken");

            Assert.AreEqual(expectedIsMultiDebtorWip, (bool) result["isMultiDebtorWip"], $"Case {caseRef}, ActivityKey {activityKey} should have IsMultiDebtorWip={expectedIsMultiDebtorWip}");
            Assert.AreEqual(expectedIsRenewalWip, (bool) result["isRenewalWip"], $"Case {caseRef}, ActivityKey {activityKey} should have IsRenewalWip={expectedIsRenewalWip}");
        }

        static void CheckCreditWipDisbursementSavedCorrectly(CheckResultMap<dynamic> data, string foreignCurrency, DateTime beforeSaveTime, string message)
        {
            var disbursementWip = data.Wip;
            var mainWip = data.SavedWip;
            var discountWip = data.SavedDiscountWip;

            CommonAsserts.CheckCreditWipDisbursementSavedCorrectly(disbursementWip, foreignCurrency, beforeSaveTime, mainWip, discountWip, message);
        }
        
        static void CheckDisbursementSavedCorrectly(CheckResultMap<dynamic> data, string foreignCurrency, DateTime beforeSaveTime, string message)
        {
            var disbursementWip = data.Wip;
            var mainWip = data.SavedWip;
            var discountWip = data.SavedDiscountWip;

            CommonAsserts.CheckDisbursementSavedCorrectly(disbursementWip, foreignCurrency, beforeSaveTime, mainWip, discountWip, message);
        }

        static void CheckDisbursementSavedCorrectly(CheckResultMap<DisbursementDissectionParameter> data, string foreignCurrency, DateTime beforeSaveTime, string message)
        {
            var mainWip = data.SavedWip;
            var discountWip = data.SavedDiscountWip;

            CommonAsserts.CheckDisbursementSavedCorrectly(data.Wip, foreignCurrency, beforeSaveTime, mainWip, discountWip, message);
        }

        class CheckResultMap<T>
        {
            public CheckResultMap(T wip, dynamic savedWip, dynamic savedDiscountWip = null)
            {
                Wip = wip;
                SavedWip = savedWip;
                SavedDiscountWip = savedDiscountWip;
            }

            public T Wip { get; }

            public dynamic SavedWip { get; }

            public dynamic SavedDiscountWip { get; }
        }

        class ExpectedCosting
        {
            public decimal? LocalAmount { get; set; }
            public decimal? LocalCost { get; set; }
            public decimal? LocalCost1 { get; set; }
            public decimal? LocalCost2 { get; set; }
            public decimal? LocalDiscount { get; set; }
            public decimal? LocalDiscountForMargin { get; set; }
            public decimal? ExchangeRate { get; set; }
            public decimal? ForeignMargin { get; set; }
            public decimal? ForeignDiscount { get; set; }
            public decimal? ForeignDiscountForMargin { get; set; }
            public decimal? ForeignAmount { get; set; }
            public int? MarginNo { get; set; }
            public decimal? MarginValue { get; set; }
            public int DebtorSplitPercentage { get; set; }
            public int NameKey { get; set; }
        }

        public class BadDisbursementWip : DisbursementWip
        {
            public string WipCode
            {
                get => WIPCode;
                set => WIPCode = value;
            }
        }
    }
}