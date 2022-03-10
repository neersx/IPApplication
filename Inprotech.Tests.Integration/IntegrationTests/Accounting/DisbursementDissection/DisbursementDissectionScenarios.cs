using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.DisbursementDissection
{
    [Category(Categories.Integration)]
    [TestFixture]
    [TestFrom(16)]
    public class DisbursementDissectionScenarios : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _wipData = new DataSetup().ForDisbursementDissection();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        WipData _wipData;

        [Test]
        public void DissectDisbursementsForeignDebtors()
        {
            /*
            * This scenario dissects $2000 in foreign currency to 2 cases with foreign debtors
            * The test demonstrates
            * - the discounts and margin are appropriately calculated
            * - foreign currencies and their exchange rates are correctly derived and used
            * - the values are saved in WIP and TRANSACTIONHEADER correctly
            */
            CheckCallToWipDefaultsForCase(_wipData.CaseForeignSingle.Id,
                                          _wipData.CaseForeignSingle.Instructor().NameId,
                                          _wipData.CaseForeignSingle.Staff().NameId,
                                          "CaseForeignSingle wip defaulting");
            /*
             * - case 'foreign-single' (single foreign debtor) to have 1000 against 'pd1' activity. 
             *   -- foreign debtor 1 in this case has an across the board 20% discount
             *   -- 'pd1' activity has default narrative, which will be overriden with 'other narrative'
             *   -- foreign currency 1 has exchange rate 1.1
             */
            CheckCallToWipCostingForCaseAndActivity(
                                                    _wipData.CaseForeignSingle.Id,
                                                    _wipData.PaidDisbursement1.WipCode,
                                                    _wipData.EntityId,
                                                    _wipData.CaseForeignSingle.Instructor().NameId,
                                                    _wipData.CaseForeignSingle.Staff().NameId,
                                                    null, 1000, _wipData.ForeignCurrency1.Id,
                                                    new ExpectedCosting
                                                    {
                                                        /* ForeignValueBeforeMargin is 1000
                                                           Given there is no margin, ForeignValue stays at 1000
                                                           Divide that with Exchange Rate at 1.1 and rounded to 1000 becomes 909.09
                                                         */
                                                        LocalCost = (decimal)909.09,
                                                        LocalCost1 = (decimal)909.09, /* Cost Calculation 1 */
                                                        LocalCost2 = (decimal)909.09, /* Cost Calculation 2 */
                                                        LocalDiscount = (decimal)181.82, /* 20% of 909.09, rounded to 2 decimals */
                                                        LocalDiscountForMargin = 0,
                                                        LocalValue = (decimal)909.09,
                                                        ForeignDiscount = 200, /* 20% of 1000 */
                                                        ForeignDiscountForMargin = 0,
                                                        ExchangeRate = (decimal)1.1,
                                                        ForeignValue = 1000,
                                                        MarginValue = null,
                                                        MarginNo = null
                                                    },
                                                    "CaseForeignSingle + Pd1 costing");

            CheckCallToWipDefaultsForCase(_wipData.CaseForeignMultiple.Id,
                                          _wipData.CaseForeignMultiple.Instructor().NameId,
                                          _wipData.CaseForeignMultiple.Staff().NameId,
                                          "CaseForeignMultiple wip defaulting");

            /*
             * - case 'foreign-multiple' (two foreign debtors 60/40 split) to have 1000 against 'pd2' activity.
             *   -- foreign debtor 1 in this case has an across the board 20% discount             
             *   -- 'pd2' activity has default narrative, which will be overriden with entered text.
             *   -- 'pd2' has across the board $20 margin
             *   -- foreign currency 1 has exchange rate 1.1
             *   -- foreign currency 2 has exchange rate 1.2
             */
            CheckCallToWipCostingForCaseAndActivity(
                                                    _wipData.CaseForeignMultiple.Id,
                                                    _wipData.PaidDisbursement2.WipCode,
                                                    _wipData.EntityId,
                                                    _wipData.CaseForeignMultiple.Instructor().NameId,
                                                    _wipData.CaseForeignMultiple.Staff().NameId,
                                                    null, 1000, _wipData.ForeignCurrency1.Id,
                                                    new ExpectedCosting
                                                    {
                                                        /* ForeignValueBeforeMargin is 1000
                                                           Discount of 20% for foreign debtor 1 is ignored because not the first debtor in case.
                                                           pd2 has $20 margin, and no currency is defined for that amount, assumed home currency.
                                                           The exchange rate of 1.1 means 20 * 1.1 for margin value.
                                                           LocalCost = Divide that with Exchange Rate at 1.1 and rounded to 1000 becomes 909.09
                                                           LocalValue = LocalCost + Margin = 929.0
                                                         */
                                                        LocalCost = (decimal)909.09, /* ForeignValue 1022 / ExchangeRate 1.1, rounded to 2 decimals */
                                                        LocalCost1 = (decimal)929.09, /* Cost Calculation 1 */
                                                        LocalCost2 = (decimal)929.09, /* Cost Calculation 2 */
                                                        LocalDiscount = null,
                                                        LocalDiscountForMargin = null,
                                                        LocalValue = (decimal)929.09,
                                                        ForeignDiscount = null,
                                                        ForeignDiscountForMargin = null,
                                                        ForeignValue = 1022, /* ForeignValueBeforeMargin 1000 + Margin 22 */
                                                        ExchangeRate = (decimal)1.1,
                                                        MarginValue = 22, /* Exchange Rate 1.1 x Margin 20 */
                                                        MarginNo = _wipData.MarginForAll.MarginId
                                                    },
                                                    "CaseForeignMultiple + Pd2 costing");

            var disbursementWip1 = new DisbursementDissectionParameter
            {
                Amount = (decimal)909.09,
                CaseKey = _wipData.CaseForeignSingle.Id,
                DebitNoteText = _wipData.PaidDisbursement1Narrative.NarrativeText,
                Description = _wipData.PaidDisbursement1.Description,
                Discount = (decimal)181.82,
                ExchRate = (decimal)1.1,
                ForeignAmount = 1000,
                ForeignDiscount = 200,
                ForeignDiscountForMargin = 0,
                ForeignMargin = null,
                LocalCost1 = (decimal)909.09,
                LocalCost2 = (decimal)909.09,
                LocalDiscountForMargin = 0,
                Margin = null,
                MarginNo = null,
                NameKey = _wipData.CaseForeignSingle.Instructor().NameId,
                NarrativeCode = _wipData.PaidDisbursement1Narrative.NarrativeCode,
                NarrativeText = _wipData.PaidDisbursement1Narrative.NarrativeText,
                NarrativeKey = _wipData.PaidDisbursement1Narrative.NarrativeId,
                StaffKey = _wipData.CaseForeignSingle.Staff().NameId,
                TransDate = DateTime.Today,
                WipCode = _wipData.PaidDisbursement1.WipCode,
                WipSeqNo = 0
            };

            var disbursementWip2 = new DisbursementDissectionParameter
            {
                Amount = (decimal)909.09,
                CaseKey = _wipData.CaseForeignMultiple.Id,
                DebitNoteText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                Description = _wipData.PaidDisbursement2.Description,
                Discount = null,
                ExchRate = (decimal)1.1,
                ForeignAmount = 1000,
                ForeignDiscount = null,
                ForeignDiscountForMargin = null,
                ForeignMargin = 22,
                LocalCost1 = (decimal)929.09,
                LocalCost2 = (decimal)929.09,
                LocalDiscountForMargin = null,
                Margin = 20,
                MarginNo = 2,
                NameKey = _wipData.CaseForeignMultiple.Instructor().NameId,
                NarrativeCode = _wipData.PaidDisbursement2Narrative.NarrativeCode,
                NarrativeText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                NarrativeKey = _wipData.PaidDisbursement2Narrative.NarrativeId,
                StaffKey = _wipData.CaseForeignMultiple.Staff().NameId,
                TransDate = DateTime.Today,
                WipCode = _wipData.PaidDisbursement2.WipCode,
                WipSeqNo = 0
            };

            /* Saves above costed wip */
            var beforeSaveTime = DateTime.Now;
            ApiClient.Post<bool>("accounting/wip-disbursements",
                                 new
                                 {
                                     TransDate = DateTime.Today,
                                     TotalAmount = 2000,
                                     EntityKey = _wipData.EntityId,
                                     Currency = _wipData.ForeignCurrency1.Id,
                                     DissectedDisbursements = new[] { disbursementWip1, disbursementWip2 }
                                 });

            var saved = DbSetup.Do(x =>
            {
                var workInProgress = x.DbContext.Set<WorkInProgress>()
                                      .Where(_ => _.CaseId == _wipData.CaseForeignSingle.Id || _.CaseId == _wipData.CaseForeignMultiple.Id)
                                      .ToArray();

                var transactionHeader = x.DbContext.Set<TransactionHeader>().Single(_ => _.EntryDate > beforeSaveTime);

                return new
                {
                    WorkInProgress = workInProgress,
                    TransactionHeader = transactionHeader
                };
            });

            var savedWorkInProgress = saved.WorkInProgress;
            var wipSequenceNumbers = savedWorkInProgress.Select(_ => _.WipSequenceNo).OrderBy(_ => _).ToArray();
            var currentWipValues = string.Join(",", savedWorkInProgress.OrderBy(_ => _.WipSequenceNo)
                                                                       .Select(_ => $"'{_.WipCode}' ({_.WipSequenceNo})"));

            Assert.AreEqual(TransactionType.Disbursement, saved.TransactionHeader.TransactionType, "Should be disbursement transaction type");
            Assert.AreEqual(SystemIdentifier.TimeAndBilling, saved.TransactionHeader.Source, "Should be Time & Billing (Accounting System ID)");
            Assert.LessOrEqual(beforeSaveTime, saved.TransactionHeader.EntryDate, "Entry Date is greater than the time these items are submitted for saving");

            Assert.True(savedWorkInProgress.All(_ => _.EntityId == saved.TransactionHeader.EntityId && _.TransactionDate == saved.TransactionHeader.TransactionDate), "Should have same transaction header details for all WIP posted");
            CollectionAssert.AreEqual(new short[] {1, 2, 3}, wipSequenceNumbers, $"Should have 3 WIP items in single transaction, i.e. WIP, DISC WIP, WIP but is ({currentWipValues}) ");

            CheckDisbursementSavedCorrectly(disbursementWip1, _wipData.ForeignCurrency1.Id, beforeSaveTime, saved, "disbursement #1");

            CheckDisbursementSavedCorrectly(disbursementWip2, _wipData.ForeignCurrency1.Id, beforeSaveTime, saved, "disbursement #2");
        }

        [Test]
        public void DissectDisbursementsLocalDebtors()
        {
            /*
             * This scenario dissects $2000 to 2 cases with local debtors, with different margin and discount setup
             * The test demonstrates
             * - the discounts and margin are appropriately calculated
             * - the values are saved in WIP and TRANSACTIONHEADER correctly
             */

            CheckCallToWipDefaultsForCase(_wipData.CaseLocalSingle.Id,
                                          _wipData.CaseLocalSingle.Instructor().NameId,
                                          _wipData.CaseLocalSingle.Staff().NameId,
                                          "CaseLocalSingle wip defaulting");

            /*
             * - case 'local-single' (single local debtor) to have 1000 against 'pd1' activity. 
             *   -- debtor 1 in this case has an across the board 10% discount
             *   -- 'pd1' activity has default narrative.
             */
            CheckCallToWipCostingForCaseAndActivity(
                                                    _wipData.CaseLocalSingle.Id,
                                                    _wipData.PaidDisbursement1.WipCode,
                                                    _wipData.EntityId,
                                                    _wipData.CaseLocalSingle.Instructor().NameId,
                                                    _wipData.CaseLocalSingle.Staff().NameId,
                                                    1000, null, null,
                                                    new ExpectedCosting
                                                    {
                                                        LocalCost = 1000, /* LocalValueBeforeMargin */
                                                        LocalCost1 = 1000, /* Cost Calculation 1 */
                                                        LocalCost2 = 1000, /* Cost Calculation 2 */
                                                        LocalDiscount = 100, /* 10% of 1000 */
                                                        LocalDiscountForMargin = 0,
                                                        LocalValue = 1000
                                                    },
                                                    "CaseLocalSingle + Pd1 costing");

            CheckCallToWipDefaultsForCase(_wipData.CaseLocalMultiple.Id,
                                          _wipData.CaseLocalMultiple.Instructor().NameId,
                                          _wipData.CaseLocalMultiple.Staff().NameId,
                                          "CaseLocalMultiple wip defaulting");
            /*
             * - case 'local-multiple' (two local debtors 60/40 split) to have 1000 against 'pd2' activity.
             *   -- debtor 1 in this case has an across the board 10% discount
             *   -- debtor 2 in this case has a $50 margin on 'pd2'
             *   -- 'pd2' activity has default narrative.
             *   -- 'pd2' has across the board $20 margin
             */
            CheckCallToWipCostingForCaseAndActivity(
                                                    _wipData.CaseLocalMultiple.Id,
                                                    _wipData.PaidDisbursement2.WipCode,
                                                    _wipData.EntityId,
                                                    _wipData.CaseLocalMultiple.Instructor().NameId,
                                                    _wipData.CaseForeignMultiple.Staff().NameId,
                                                    1000, null, null,
                                                    new ExpectedCosting
                                                    {
                                                        LocalCost = 1000, /* LocalValueBeforeMargin */
                                                        LocalCost1 = 1020, /* CostCalculation1 = local cost + margin */
                                                        LocalCost2 = 1020, /* CostCalculation2 = local cost + margin*/
                                                        LocalDiscount = 102, /* 10% of 1000 + 2 (local discount for margin) */
                                                        LocalDiscountForMargin = 2, /* 10% of 20 (margin is 20) */
                                                        MarginValue = 20, /* pd2 default margin */
                                                        MarginNo = _wipData.MarginForAll.MarginId,
                                                        LocalValue = 1020
                                                    },
                                                    "CaseLocalMultiple + Pd2 costing");

            var disbursementWip1 = new DisbursementDissectionParameter
            {
                Amount = 1000,
                CaseKey = _wipData.CaseLocalSingle.Id,
                DebitNoteText = _wipData.PaidDisbursement1Narrative.NarrativeText,
                Description = _wipData.PaidDisbursement1.Description,
                Discount = 100,
                LocalCost1 = 1000,
                LocalCost2 = 1000,
                LocalDiscountForMargin = 0,
                Margin = null,
                MarginNo = null,
                NameKey = _wipData.CaseLocalSingle.Instructor().NameId,
                NarrativeCode = _wipData.PaidDisbursement1Narrative.NarrativeCode,
                NarrativeText = _wipData.PaidDisbursement1Narrative.NarrativeText,
                NarrativeKey = _wipData.PaidDisbursement1Narrative.NarrativeId,
                StaffKey = _wipData.CaseLocalSingle.Staff().NameId,
                TransDate = DateTime.Today,
                WipCode = _wipData.PaidDisbursement1.WipCode,
                WipSeqNo = 0
            };

            var disbursementWip2 = new DisbursementDissectionParameter
            {
                Amount = 1000,
                CaseKey = _wipData.CaseLocalMultiple.Id,
                DebitNoteText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                Description = _wipData.PaidDisbursement2.Description,
                Discount = 102,
                LocalCost1 = 1020,
                LocalCost2 = 1020,
                LocalDiscountForMargin = 2,
                Margin = 20,
                MarginNo = 2,
                NameKey = _wipData.CaseLocalMultiple.Instructor().NameId,
                NarrativeCode = _wipData.PaidDisbursement2Narrative.NarrativeCode,
                NarrativeText = _wipData.PaidDisbursement2Narrative.NarrativeText,
                NarrativeKey = _wipData.PaidDisbursement2Narrative.NarrativeId,
                StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                TransDate = DateTime.Today,
                WipCode = _wipData.PaidDisbursement2.WipCode,
                WipSeqNo = 0
            };

            /* Saves above costed wip */
            var beforeSaveTime = DateTime.Now;
            ApiClient.Post<bool>("accounting/wip-disbursements",
                                 new
                                 {
                                     TransDate = DateTime.Today,
                                     TotalAmount = 2000,
                                     EntityKey = _wipData.EntityId,
                                     DissectedDisbursements = new[] { disbursementWip1, disbursementWip2 }
                                 });

            var saved = DbSetup.Do(x =>
            {
                var workInProgress = x.DbContext.Set<WorkInProgress>()
                                      .Where(_ => _.CaseId == _wipData.CaseLocalSingle.Id || _.CaseId == _wipData.CaseLocalMultiple.Id)
                                      .ToArray();

                var transactionHeader = x.DbContext.Set<TransactionHeader>().Single(_ => _.EntryDate > beforeSaveTime);

                return new
                {
                    WorkInProgress = workInProgress,
                    TransactionHeader = transactionHeader
                };
            });

            var savedWorkInProgress = saved.WorkInProgress;
            var wipSequenceNumbers = savedWorkInProgress.Select(_ => _.WipSequenceNo).OrderBy(_ => _).ToArray();
            var currentWipValues = string.Join(",", savedWorkInProgress.OrderBy(_ => _.WipSequenceNo)
                                                                       .Select(_ => $"'{_.WipCode}' ({_.WipSequenceNo})"));

            Assert.AreEqual(TransactionType.Disbursement, saved.TransactionHeader.TransactionType, "Should be disbursement transaction type");
            Assert.AreEqual(SystemIdentifier.TimeAndBilling, saved.TransactionHeader.Source, "Should be Time & Billing (Accounting System ID)");
            Assert.LessOrEqual(beforeSaveTime, saved.TransactionHeader.EntryDate, "Entry Date is greater than the time these items are submitted for saving");

            Assert.True(savedWorkInProgress.All(_ => _.EntityId == saved.TransactionHeader.EntityId && _.TransactionDate == saved.TransactionHeader.TransactionDate), "Should have same transaction header details for all WIP posted");
            CollectionAssert.AreEqual(new short[] {1, 2, 3, 4}, wipSequenceNumbers, $"Should have 4 WIP items in single transaction, i.e. WIP, DISC WIP, WIP, DISC WIP but is ({currentWipValues}) ");

            CheckDisbursementSavedCorrectly(disbursementWip1, null, beforeSaveTime, saved, "disbursement #1");

            CheckDisbursementSavedCorrectly(disbursementWip2, null, beforeSaveTime, saved, "disbursement #2");
        }

        [Test]
        public void DissectCreditWipDisbursements()
        {
            /*
             * This scenario dissects $1000 credit wip to local debtor
             * The test demonstrates
             * - the discounts and margin are appropriately calculated
             * - the values are saved in WIP and TRANSACTIONHEADER correctly
             */

            /*
             * - case 'local-single' (single local debtor) to have 1000 against 'pd1' activity. 
             *   -- debtor 1 in this case has an across the board 10% discount
             *   -- 'pd1' activity has default narrative.
             */

            var disbursementWip = new DisbursementDissectionParameter
            {
                Amount = 1000,
                CaseKey = _wipData.CaseLocalSingle.Id,
                DebitNoteText = _wipData.PaidDisbursement1Narrative.NarrativeText,
                Description = _wipData.PaidDisbursement1.Description,
                Discount = 100,
                LocalCost1 = 1000,
                LocalCost2 = 1000,
                LocalDiscountForMargin = 0,
                Margin = null,
                MarginNo = null,
                NameKey = _wipData.CaseLocalSingle.Instructor().NameId,
                NarrativeCode = _wipData.PaidDisbursement1Narrative.NarrativeCode,
                NarrativeText = _wipData.PaidDisbursement1Narrative.NarrativeText,
                NarrativeKey = _wipData.PaidDisbursement1Narrative.NarrativeId,
                StaffKey = _wipData.CaseLocalSingle.Staff().NameId,
                TransDate = DateTime.Today,
                WipCode = _wipData.PaidDisbursement1.WipCode,
                WipSeqNo = 0
            };

            /* Saves above costed wip */
            var beforeSaveTime = DateTime.Now;
            ApiClient.Post<bool>("accounting/wip-disbursements",
                                 new
                                 {
                                     TransDate = DateTime.Today,
                                     TotalAmount = 2000,
                                     EntityKey = _wipData.EntityId,
                                     CreditWIP = true,
                                     DissectedDisbursements = new[] { disbursementWip }
                                 });

            var saved = DbSetup.Do(x =>
            {
                var workInProgress = x.DbContext.Set<WorkInProgress>()
                                      .Where(_ => _.CaseId == _wipData.CaseLocalSingle.Id)
                                      .ToArray();

                var transactionHeader = x.DbContext.Set<TransactionHeader>().Single(_ => _.EntryDate > beforeSaveTime);

                return new
                {
                    WorkInProgress = workInProgress,
                    TransactionHeader = transactionHeader
                };
            });

            var savedWorkInProgress = saved.WorkInProgress;
            var wipSequenceNumbers = savedWorkInProgress.Select(_ => _.WipSequenceNo).OrderBy(_ => _).ToArray();
            var currentWipValues = string.Join(",", savedWorkInProgress.OrderBy(_ => _.WipSequenceNo)
                                                                       .Select(_ => $"'{_.WipCode}' ({_.WipSequenceNo})"));

            Assert.AreEqual(TransactionType.Disbursement, saved.TransactionHeader.TransactionType, "Should be disbursement transaction type");
            Assert.AreEqual(SystemIdentifier.TimeAndBilling, saved.TransactionHeader.Source, "Should be Time & Billing (Accounting System ID)");
            Assert.LessOrEqual(beforeSaveTime, saved.TransactionHeader.EntryDate, "Entry Date is greater than the time these items are submitted for saving");

            Assert.True(savedWorkInProgress.All(_ => _.EntityId == saved.TransactionHeader.EntityId && _.TransactionDate == saved.TransactionHeader.TransactionDate), "Should have same transaction header details for all WIP posted");
            CollectionAssert.AreEqual(new short[] {1, 2}, wipSequenceNumbers, $"Should have 4 WIP items in single transaction, i.e. WIP, DISC WIP but is ({currentWipValues}) ");

            CheckCreditWipDisbursementSavedCorrectly(disbursementWip, null, beforeSaveTime, saved, "disbursement #1");
        }

        static void CheckDisbursementSavedCorrectly(DisbursementDissectionParameter disbursementWip, string foreignCurrency, DateTime beforeSaveTime, dynamic saved, string message)
        {
            var caseId = disbursementWip.CaseKey;
            var savedWorkInProgress = (WorkInProgress[])saved.WorkInProgress;

            var mainWip = savedWorkInProgress.Single(_ => _.CaseId == caseId && _.IsDiscount == 0);
            var discountWip = savedWorkInProgress.SingleOrDefault(_ => _.CaseId == caseId && _.IsDiscount == 1);

            CommonAsserts.CheckDisbursementSavedCorrectly(disbursementWip, foreignCurrency, beforeSaveTime, mainWip, discountWip, message);
        }

        static void CheckCreditWipDisbursementSavedCorrectly(DisbursementDissectionParameter disbursementWip, string foreignCurrency, DateTime beforeSaveTime, dynamic saved, string message)
        {
            var caseId = disbursementWip.CaseKey;
            var savedWorkInProgress = (WorkInProgress[])saved.WorkInProgress;

            var mainWip = savedWorkInProgress.Single(_ => _.CaseId == caseId && _.IsDiscount == 0);
            var discountWip = savedWorkInProgress.SingleOrDefault(_ => _.CaseId == caseId && _.IsDiscount == 1);

            CommonAsserts.CheckCreditWipDisbursementSavedCorrectly(disbursementWip, foreignCurrency, beforeSaveTime, mainWip, discountWip, message);
        }

        static void CheckCallToWipCostingForCaseAndActivity(int caseId, string wipCode, int entityKey, int nameKey, int staffKey, decimal? localValueBeforeMargin, decimal? foreignValueBeforeMargin, string foreignCurrencyCode, ExpectedCosting expected, string message)
        {
            var result = ApiClient.Post<WipCost>("accounting/wip-disbursements/wip-costing",
                                                    new
                                                    {
                                                        CaseKey = caseId,
                                                        EntityKey = entityKey,
                                                        CurrencyCode = foreignCurrencyCode,
                                                        LocalValueBeforeMargin = localValueBeforeMargin,
                                                        ForeignValueBeforeMargin = foreignValueBeforeMargin,
                                                        MarginRequired = true,
                                                        NameKey = nameKey,
                                                        StaffKey = staffKey,
                                                        TransactionDate = DateTime.Today,
                                                        WipCode = wipCode
                                                    },
                                                    "e2e_ken");

            Assert.AreEqual(expected.LocalCost, result.LocalValueBeforeMargin, message + " LocalCost");
            Assert.AreEqual(expected.LocalCost1, result.CostCalculation1, message + " LocalCost1");
            Assert.AreEqual(expected.LocalCost2, result.CostCalculation2, message + " LocalCost2");
            Assert.AreEqual(expected.LocalValue, result.LocalValue, message + " LocalValue");
            Assert.AreEqual(expected.LocalDiscount, result.LocalDiscount, message + " LocalDiscount");

            Assert.AreEqual(expected.LocalDiscountForMargin, result.LocalDiscountForMargin, message + " LocalDiscountForMargin");
            Assert.AreEqual(expected.MarginValue, result.MarginValue, message + " MarginValue");

            Assert.AreEqual(expected.MarginNo, result.MarginNo, message + " MarginNo");
        }

        static void CheckCallToWipDefaultsForCase(int caseId, int expectedNameKey, int expectedStaffKey, string message)
        {
            var result = ApiClient.Get<WipDefaults>($"accounting/wip-disbursements/wip-defaults?caseKey={caseId}", "e2e_ken");

            Assert.AreEqual(caseId, result.CaseKey, message + " CaseKey");
            Assert.AreEqual(expectedNameKey, result.NameKey, message + " NameKey (Instructor)");
            Assert.AreEqual(expectedStaffKey, result.StaffKey, message + " StaffKey");
        }

        class ExpectedCosting
        {
            public decimal? LocalValue { get; set; }
            public decimal? LocalCost { get; set; }
            public decimal? LocalCost1 { get; set; }
            public decimal? LocalCost2 { get; set; }
            public decimal? LocalDiscount { get; set; }
            public decimal? LocalDiscountForMargin { get; set; }
            public decimal? ExchangeRate { get; set; }
            public decimal? ForeignDiscount { get; set; }
            public decimal? ForeignDiscountForMargin { get; set; }
            public decimal? ForeignValue { get; set; }
            public int? MarginNo { get; set; }
            public decimal? MarginValue { get; set; }
        }
    }
}