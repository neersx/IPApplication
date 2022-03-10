using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.WipAdjustments
{
    [Category(Categories.Integration)]
    [TestFixture]
    [TestFrom(16)]
    public class WipAdjustmentScenarios : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _wipData = new DataSetup().ForWipAdjustments();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        WipData _wipData;

        [Test]
        public void AdjustUp()
        {
            var adjustItem = GetItemToAdjust(_wipData.LocalWip);

            var original = adjustItem.originalWIPItem;

            adjustItem.originalWIPItem = null;
            adjustItem.newLocal = 1500;
            adjustItem.localAdjustment = 500;
            adjustItem.reasonCode = "ER";
            adjustItem.newDebitNoteText = "I think I can charge him more";
            adjustItem.adjustmentType = TransactionType.DebitWipAdjustment;

            var beforeSaveTime = DateTime.Now;

            CallAdjustItemApi(adjustItem, original);

            CommonAssert(beforeSaveTime,
                         new ExpectedTransactionHeaderValues {AdjustmentType = TransactionType.DebitWipAdjustment},
                         new ExpectedWipValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseLocalMultiple.Id,
                             LocalValue = 1000,
                             Balance = 1500,
                             Narrative = "I think I can charge him more"
                         },
                         new ExpectedWorkHistoryValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseLocalMultiple.Id,
                             LocalValue = 500, /* an increase of 500 (1000 -> 1500) */
                             ReasonCode = "ER",
                             MovementClass = MovementClass.AdjustUp,
                             CommandId = CommandId.AdjustUp,
                             Narrative = "I think I can charge him more"
                         });
        }

        [Test]
        public void AdjustDown()
        {
            var adjustItem = GetItemToAdjust(_wipData.LocalWip);

            var original = adjustItem.originalWIPItem;

            adjustItem.originalWIPItem = null;
            adjustItem.newLocal = 500;
            adjustItem.localAdjustment = -500;
            adjustItem.reasonCode = "RV";
            adjustItem.newDebitNoteText = "won't recover";
            adjustItem.adjustmentType = TransactionType.CreditWipAdjustment;

            var beforeSaveTime = DateTime.Now;

            CallAdjustItemApi(adjustItem, original);

            CommonAssert(beforeSaveTime,
                         new ExpectedTransactionHeaderValues {AdjustmentType = TransactionType.CreditWipAdjustment},
                         new ExpectedWipValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseLocalMultiple.Id,
                             LocalValue = 1000,
                             Balance = 500,
                             Narrative = "won't recover"
                         },
                         new ExpectedWorkHistoryValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseLocalMultiple.Id,
                             LocalValue = -500, /* a reduction of 500 (1000 -> 500) */
                             ReasonCode = "RV",
                             MovementClass = MovementClass.AdjustDown,
                             CommandId = CommandId.AdjustDown,
                             Narrative = "won't recover"
                         });
        }

        [Test]
        public void TransferWipToAnotherCase()
        {
            var adjustItem = GetItemToAdjust(_wipData.LocalWip);

            var original = adjustItem.originalWIPItem;

            adjustItem.originalWIPItem = null;
            adjustItem.newCaseKey = _wipData.CaseForeignMultiple.Id;
            adjustItem.reasonCode = "ER";
            adjustItem.newDebitNoteText = "WRONG CASE!";
            adjustItem.adjustmentType = TransactionType.CaseWipTransfer;

            var beforeSaveTime = DateTime.Now;

            CallAdjustItemApi(adjustItem, original);

            CommonAssert(beforeSaveTime,
                         new ExpectedTransactionHeaderValues {AdjustmentType = TransactionType.CaseWipTransfer},
                         new ExpectedWipValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseForeignMultiple.Id,
                             LocalValue = 1000,
                             Balance = 1000,
                             Narrative = "WRONG CASE!"
                         },
                         new ExpectedWorkHistoryValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseLocalMultiple.Id, /* original case */
                             LocalValue = -1000, /* a reduction of all the amount 1000, it is being transferred to a different case */
                             MovementClass = MovementClass.AdjustDown,
                             CommandId = CommandId.AdjustDown,
                             ReasonCode = "ER",
                             Narrative = "WRONG CASE!"
                         },
                         new ExpectedWorkHistoryValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseForeignMultiple.Id, /* transferred to case */
                             LocalValue = 1000, /* an increase of the full amount 1000, being sent here. */
                             ReasonCode = "ER",
                             MovementClass = MovementClass.AdjustUp,
                             CommandId = CommandId.NewAdjustUp,
                             Narrative = "WRONG CASE!",
                             ItemImpact = ItemImpact.Created /* a new work history is created for the adjustment to case */
                         });
        }

        [Test]
        public void TransferWipToAnotherCaseWithDiscount()
        {
            var adjustItem = GetItemToAdjust(_wipData.LocalWipWithDiscount);

            var original = adjustItem.originalWIPItem;

            adjustItem.adjustDiscount = true;

            adjustItem.newCaseKey = _wipData.CaseForeignMultiple.Id;
            adjustItem.reasonCode = "ER";
            adjustItem.newDebitNoteText = "WRONG CASE! Includes Discounts!";
            adjustItem.adjustmentType = TransactionType.CaseWipTransfer;

            var beforeSaveTime = DateTime.Now;

            CallAdjustItemApi(adjustItem, original);

            CommonAssert(beforeSaveTime,
                         new ExpectedTransactionHeaderValues {AdjustmentType = TransactionType.CaseWipTransfer},
                         new ExpectedWipValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseForeignMultiple.Id,
                             LocalValue = 2000,
                             Balance = 2000,
                             Narrative = "WRONG CASE! Includes Discounts!"
                         },
                         new ExpectedWipValues
                         {
                             WipCode = "DISC",
                             CaseKey = _wipData.CaseForeignMultiple.Id,
                             LocalValue = -200,
                             Balance = -200,
                             Narrative = "Discount as agreed"
                         },
                         new ExpectedWorkHistoryValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseLocalMultiple.Id, /* original case */
                             LocalValue = -2000, /* a reduction of all the amount 2000, it is being transferred to a different case */
                             MovementClass = MovementClass.AdjustDown,
                             CommandId = CommandId.AdjustDown,
                             ReasonCode = "ER",
                             Narrative = "WRONG CASE! Includes Discounts!"
                         },
                         new ExpectedWorkHistoryValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseForeignMultiple.Id, /* transferred to case */
                             LocalValue = 2000, /* an increase of the full amount 2000, being sent here. */
                             ReasonCode = "ER",
                             MovementClass = MovementClass.AdjustUp,
                             CommandId = CommandId.NewAdjustUp,
                             Narrative = "WRONG CASE! Includes Discounts!",
                             ItemImpact = ItemImpact.Created /* a new work history is created for the adjustment to case */
                         },
                         new ExpectedWorkHistoryValues
                         {
                             WipCode = "DISC",
                             CaseKey = _wipData.CaseLocalMultiple.Id, /* original case */
                             LocalValue = 200, /* a top up of all the discount amount 200, it is being transferred to a different case */
                             MovementClass = MovementClass.AdjustUp,
                             CommandId = CommandId.AdjustUp,
                             ReasonCode = "ER",
                             Narrative = "Discount as agreed"
                         },
                         new ExpectedWorkHistoryValues
                         {
                             WipCode = "DISC",
                             CaseKey = _wipData.CaseForeignMultiple.Id, /* transferred to case */
                             LocalValue = -200, /* an reduction of the full discount amount 200, being sent here. */
                             ReasonCode = "ER",
                             MovementClass = MovementClass.AdjustDown,
                             CommandId = CommandId.NewAdjustDown,
                             Narrative = "Discount as agreed",
                             ItemImpact = ItemImpact.Created /* a new work history is created for the adjustment to case */
                         });
        }

        [Test]
        public void TransferWipToAnotherStaff()
        {
            var adjustItem = GetItemToAdjust(_wipData.LocalWip);

            var original = adjustItem.originalWIPItem;

            adjustItem.originalWIPItem = null;
            adjustItem.newStaffKey = _wipData.CaseForeignMultiple.Staff().NameId; /* original is null */
            adjustItem.reasonCode = "ER";
            adjustItem.newDebitNoteText = "WRONG STAFF!";
            adjustItem.adjustmentType = TransactionType.StaffWipTransfer;

            var beforeSaveTime = DateTime.Now;

            CallAdjustItemApi(adjustItem, original);

            CommonAssert(beforeSaveTime,
                         new ExpectedTransactionHeaderValues {AdjustmentType = TransactionType.StaffWipTransfer},
                         new ExpectedWipValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseLocalMultiple.Id,
                             StaffKey = _wipData.CaseForeignMultiple.Staff().NameId,
                             LocalValue = 1000,
                             Balance = 1000,
                             Narrative = "WRONG STAFF!"
                         },
                         new ExpectedWorkHistoryValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseLocalMultiple.Id,
                             StaffKey = null, /* not set initially */
                             LocalValue = -1000, /* a reduction of all the amount 1000, it is being transferred to a different case */
                             MovementClass = MovementClass.AdjustDown,
                             CommandId = CommandId.AdjustDown,
                             ReasonCode = "ER",
                             Narrative = "WRONG STAFF!"
                         },
                         new ExpectedWorkHistoryValues
                         {
                             WipCode = _wipData.LocalWip.WipCode,
                             CaseKey = _wipData.CaseLocalMultiple.Id,
                             StaffKey = _wipData.CaseForeignMultiple.Staff().NameId, /* transferred to new staff */
                             LocalValue = 1000, /* an increase of the full amount 1000, being sent here. */
                             ReasonCode = "ER",
                             MovementClass = MovementClass.AdjustUp,
                             CommandId = CommandId.NewAdjustUp,
                             Narrative = "WRONG STAFF!",
                             ItemImpact = ItemImpact.Created /* a new work history is created for the adjustment to staff */
                         });
        }

        [Test]
        public void AdjustForeignWip()
        {
            var adjustItem = GetItemToAdjust(_wipData.ForeignWip);

            var original = adjustItem.originalWIPItem;

            adjustItem.originalWIPItem = null;
            adjustItem.newForeign = 500;
            adjustItem.foreignAdjustment = -500;
            adjustItem.newLocal = 333.33;
            adjustItem.localAdjustment = -333.33;
            adjustItem.reasonCode = "RV";
            adjustItem.newDebitNoteText = "won't recover";
            adjustItem.adjustmentType = TransactionType.CreditWipAdjustment;

            var beforeSaveTime = DateTime.Now;

            CallAdjustItemApi(adjustItem, original);

            CommonAssert(beforeSaveTime,
                         new ExpectedTransactionHeaderValues {AdjustmentType = TransactionType.CreditWipAdjustment},
                         new ExpectedWipValues
                         {
                             WipCode = _wipData.ForeignWip.WipCode,
                             CaseKey = _wipData.CaseForeignMultiple.Id,
                             LocalValue = (decimal) 666.67, /* Total value = 666.67 because (Foreign Value 1000 / exchange rate 1.5) */
                             Balance = (decimal) 333.33,
                             ForeignCurrency = _wipData.ForeignCurrency1.Id,
                             ForeignValue = 1000,
                             ExchangeRate = _wipData.ForeignWip.ExchangeRate, /* 1.5 */
                             Narrative = "won't recover"
                         },
                         new ExpectedWorkHistoryValues
                         {
                             WipCode = _wipData.ForeignWip.WipCode,
                             CaseKey = _wipData.CaseForeignMultiple.Id,
                             LocalValue = (decimal) -333.34, /* Total value = 666.67 because (Foreign Value 1000 / exchange rate 1.5), 
                                                             * take away 333.33 (Foreign Value 500 / exchange rate 1.5) */
                             ForeignValue = -500,
                             ForeignCurrency = _wipData.ForeignCurrency1.Id,
                             ReasonCode = "RV",
                             MovementClass = MovementClass.AdjustDown,
                             CommandId = CommandId.AdjustDown,
                             Narrative = "won't recover"
                         });
        }

        static dynamic GetItemToAdjust(WorkInProgress wip)
        {
            var data = ApiClient.Get<JObject>($"accounting/wip-adjustments/adjust-item?entityKey={wip.EntityId}&transKey={wip.TransactionId}&wipSeqKey={wip.WipSequenceNo}",
                                              "e2e_ken");

            return data.ToObject<dynamic>().adjustWipItem;
        }

        static void CallAdjustItemApi(dynamic modified, dynamic original)
        {
            ApiClient.Post<JObject>("accounting/wip-adjustments/adjust-item",
                                    new
                                    {
                                        Entity = modified,
                                        HasMemberChanges = true,
                                        Id = 0,
                                        Operation = 3,
                                        OriginalEntity = original
                                    },
                                    "e2e_ken");
        }

        static void CommonAssert(DateTime beforeSaveTime, ExpectedTransactionHeaderValues expectedTransactionHeader, ExpectedWipValues expectedWipValues, params ExpectedWorkHistoryValues[] expectedWorkHistories)
        {
            CommonAssert(beforeSaveTime, expectedTransactionHeader, expectedWipValues, null, expectedWorkHistories);
        }

        static void CommonAssert(DateTime beforeSaveTime, ExpectedTransactionHeaderValues expectedTransactionHeader,
                                 ExpectedWipValues expectedWipValues,
                                 ExpectedWipValues expectedDiscountWipValues,
                                 params ExpectedWorkHistoryValues[] expectedWorkHistories)
        {
            var saved = DbSetup.Do(x =>
            {
                var workHistory = x.DbContext.Set<WorkHistory>()
                                   .Where(_ => _.PostDate >= beforeSaveTime)
                                   .OrderBy(_ => _.LogDateTimeStamp)
                                   .ToArray();

                var wip = x.DbContext.Set<WorkInProgress>()
                           .Single(_ => _.LogDateTimeStamp >= beforeSaveTime && _.IsDiscount != 1);

                var discountWip = x.DbContext.Set<WorkInProgress>()
                                   .SingleOrDefault(_ => _.LogDateTimeStamp >= beforeSaveTime && _.IsDiscount == 1);

                var transactionHeader = x.DbContext.Set<TransactionHeader>().First(_ => _.EntryDate > beforeSaveTime);

                return new
                {
                    /*
                     * each existing wip should already have 1 corresponding work history
                     *  for each adjustment one work history row will be added to explain the change
                     *  if the adjustment involved changing
                     *     - case,
                     *     - staff,
                     *     - debtor, etc
                     *  that was not part of the original wip, an additional work history row will be recorded.
                     */
                    WorkHistory = workHistory,
                    WorkInProgress = wip,
                    Discount = discountWip,
                    TransactionHeader = transactionHeader
                };
            });

            Assert.AreEqual(expectedWorkHistories.Length, saved.WorkHistory.Length, $"There should be {expectedWorkHistories.Length + 1} work history rows updated");
            Assert.AreEqual(expectedTransactionHeader.AdjustmentType, saved.TransactionHeader.TransactionType, "Adjustment Type");

            Assert.AreEqual(saved.TransactionHeader.EntityId, saved.WorkHistory.Last().RefEntityId, $"New WorkHistory RefEntityId and New TransactionHeader EntityId {saved.TransactionHeader.EntityId}");
            Assert.AreEqual(saved.TransactionHeader.TransactionId, saved.WorkHistory.Last().RefTransactionId, "New Transaction Number");

            for (var i = 0; i < expectedWorkHistories.Length; i++)
            {
                Assert.AreEqual(expectedWorkHistories[i].LocalValue, saved.WorkHistory[i].LocalValue, $"#{i} WorkHistory LocalTransValue");
                Assert.AreEqual(expectedWorkHistories[i].ForeignValue, saved.WorkHistory[i].ForeignValue, $"#{i} WorkHistory ForeignTranValue");
                Assert.AreEqual(expectedWorkHistories[i].ForeignCurrency, saved.WorkHistory[i].ForeignCurrency, $"#{i} WorkHistory ForeignCurrency");
                Assert.AreEqual(expectedWorkHistories[i].WipCode, saved.WorkHistory[i].WipCode, $"#{i} WorkHistory WipCode");
                Assert.AreEqual(expectedWorkHistories[i].StaffKey, saved.WorkHistory[i].StaffId, $"#{i} WorkHistory StaffId");
                Assert.AreEqual(expectedWorkHistories[i].CaseKey, saved.WorkHistory[i].CaseId, $"#{i} WorkHistory CaseId");
                Assert.AreEqual(expectedWorkHistories[i].ReasonCode, saved.WorkHistory[i].ReasonCode, $"#{i} WorkHistory ReasonCode");
                Assert.AreEqual(expectedWorkHistories[i].MovementClass, saved.WorkHistory[i].MovementClass,
                                $"#{i} WorkHistory Movement Class, expected {expectedWorkHistories[i].MovementClass}, but was {saved.WorkHistory[i].MovementClass}");
                Assert.AreEqual(expectedWorkHistories[i].CommandId, saved.WorkHistory[i].CommandId,
                                $"#{i} WorkHistory Command Id, expected {expectedWorkHistories[i].CommandId}, but was {saved.WorkHistory[i].CommandId}");
                Assert.AreEqual(expectedWorkHistories[i].ItemImpact, saved.WorkHistory[i].ItemImpact,
                                $"#{i} WorkHistory Item Impact, expected {expectedWorkHistories[i].ItemImpact}, but was {saved.WorkHistory[i].ItemImpact}");
                Assert.AreEqual(expectedWorkHistories[i].Narrative, saved.WorkHistory[i].ShortNarrative, "WorkHistory Narrative");
            }

            Assert.AreEqual(expectedWipValues.WipCode, saved.WorkInProgress.WipCode, "WipCode");
            Assert.AreEqual(expectedWipValues.Balance, saved.WorkInProgress.Balance, "Balance");
            Assert.AreEqual(expectedWipValues.LocalValue, saved.WorkInProgress.LocalValue, "Local Value");
            Assert.AreEqual(expectedWipValues.ForeignValue, saved.WorkInProgress.ForeignValue, "Foreign Value");
            Assert.AreEqual(expectedWipValues.ForeignCurrency, saved.WorkInProgress.ForeignCurrency, "Foreign Currency");
            Assert.AreEqual(expectedWipValues.ExchangeRate, saved.WorkInProgress.ExchangeRate, "Exchange Rate");
            Assert.AreEqual(expectedWipValues.CaseKey, saved.WorkInProgress.CaseId, "Case");
            Assert.AreEqual(expectedWipValues.StaffKey, saved.WorkInProgress.StaffId, "Staff");
            Assert.AreEqual(expectedWipValues.Narrative, saved.WorkInProgress.ShortNarrative, "Narrative");

            if (expectedDiscountWipValues != null)
            {
                Assert.AreEqual(expectedDiscountWipValues.WipCode, saved.Discount.WipCode, "WipCode");
                Assert.AreEqual(expectedDiscountWipValues.Balance, saved.Discount.Balance, "Balance");
                Assert.AreEqual(expectedDiscountWipValues.LocalValue, saved.Discount.LocalValue, "Local Value");
                Assert.AreEqual(expectedDiscountWipValues.ForeignValue, saved.Discount.ForeignValue, "Foreign Value");
                Assert.AreEqual(expectedDiscountWipValues.ForeignCurrency, saved.Discount.ForeignCurrency, "Foreign Currency");
                Assert.AreEqual(expectedDiscountWipValues.ExchangeRate, saved.Discount.ExchangeRate, "Exchange Rate");
                Assert.AreEqual(expectedDiscountWipValues.CaseKey, saved.Discount.CaseId, "Case");
                Assert.AreEqual(expectedDiscountWipValues.StaffKey, saved.Discount.StaffId, "Staff");
                Assert.AreEqual(expectedDiscountWipValues.Narrative, saved.Discount.ShortNarrative, "Narrative");
            }
        }

        class ExpectedTransactionHeaderValues
        {
            public TransactionType AdjustmentType { get; set; }
        }

        class ExpectedWipValues
        {
            public string WipCode { get; set; }

            public decimal? CaseKey { get; set; }

            public decimal? StaffKey { get; set; }

            public decimal? Balance { get; set; }

            public decimal? LocalValue { get; set; }

            public decimal? ForeignValue { get; set; }

            public string ForeignCurrency { get; set; }

            public decimal? ExchangeRate { get; set; }

            public string Narrative { get; set; }
        }

        class ExpectedWorkHistoryValues
        {
            public decimal? LocalValue { get; set; }

            public decimal? ForeignValue { get; set; }

            public string ForeignCurrency { get; set; }

            public decimal? StaffKey { get; set; }

            public decimal? CaseKey { get; set; }

            public string WipCode { get; set; }

            public string Narrative { get; set; }

            public string ReasonCode { get; set; }

            public MovementClass? MovementClass { get; set; }

            public CommandId? CommandId { get; set; }

            public ItemImpact? ItemImpact { get; set; }
        }
    }
}