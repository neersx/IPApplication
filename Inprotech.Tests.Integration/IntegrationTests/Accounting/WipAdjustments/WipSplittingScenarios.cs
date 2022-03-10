using System;
using System.Diagnostics.CodeAnalysis;
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
    public class WipSplittingScenarios : IntegrationTest
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
        public void SplitInLocalCurrency()
        {
            /*
             * original item belongs to 'local-multiple' with wipcode SC1 
             * - this is to split to
             *   - local-multiple against SC2 at 66.67%
             *   - foreign-multiple against SC1 at 33.33%             
             */

            var itemToSplit = GetItemToSplit(_wipData.LocalWip);

            var split1 = CreateParameter(_wipData.CaseLocalMultiple.Id, _wipData.ServiceCharge2.WipCode, itemToSplit);
            split1.LocalAmount = (decimal) 666.67;
            split1.ReasonCode = "ER";
            split1.SplitPercentage = (decimal) 66.67;

            var split2 = CreateParameter(_wipData.CaseForeignMultiple.Id, _wipData.ServiceCharge1.WipCode, itemToSplit);
            split2.LocalAmount = (decimal) 333.33;
            split2.ReasonCode = "ER";
            split2.SplitPercentage = (decimal) 33.33;

            var beforeSaveTime = DateTime.Now;

            CallSplitItemsApi(split1, split2);

            CommonAssert(beforeSaveTime,
                         new ExpectedTransactionHeaderValues {AdjustmentType = TransactionType.WipSplit},
                         new[]
                         {
                             new ExpectedWipValues
                             {
                                 WipCode = _wipData.LocalWip.WipCode,
                                 CaseKey = _wipData.CaseLocalMultiple.Id,
                                 StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                                 Narrative = _wipData.ServiceCharge2Narrative.NarrativeText,
                                 LocalValue = (decimal) 666.67,
                                 Balance = (decimal) 666.67
                             },
                             new ExpectedWipValues
                             {
                                 WipCode = _wipData.LocalWip.WipCode,
                                 CaseKey = _wipData.CaseForeignMultiple.Id,
                                 StaffKey = _wipData.CaseForeignMultiple.Staff().NameId,
                                 Narrative = _wipData.ServiceCharge1Narrative.NarrativeText,
                                 LocalValue = (decimal) 333.33,
                                 Balance = (decimal) 333.33
                             }
                         },
                         new[]
                         {
                             new ExpectedWorkHistoryValues
                             {
                                 TransactionId = _wipData.LocalWip.TransactionId, /* original trans no - this records the original being adjusted off */
                                 WipCode = _wipData.LocalWip.WipCode,
                                 StaffKey = _wipData.LocalWip.StaffId,
                                 CaseKey = _wipData.CaseLocalMultiple.Id,
                                 Narrative = _wipData.LocalWip.ShortNarrative,
                                 LocalValue = -1000, /* being adjusted off */
                                 ReasonCode = "ER",
                                 MovementClass = MovementClass.AdjustDown,
                                 CommandId = CommandId.AdjustDown
                             },
                             new ExpectedWorkHistoryValues
                             {
                                 WipCode = _wipData.LocalWip.WipCode,
                                 CaseKey = _wipData.CaseLocalMultiple.Id,
                                 StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                                 Narrative = _wipData.ServiceCharge2Narrative.NarrativeText,
                                 LocalValue = (decimal) 666.67, /* new wip split from original */
                                 ReasonCode = "ER",
                                 MovementClass = MovementClass.AdjustUp,
                                 CommandId = CommandId.NewAdjustUp,
                                 ItemImpact = ItemImpact.Created
                             },
                             new ExpectedWorkHistoryValues
                             {
                                 WipCode = _wipData.LocalWip.WipCode,
                                 CaseKey = _wipData.CaseForeignMultiple.Id,
                                 StaffKey = _wipData.CaseForeignMultiple.Staff().NameId,
                                 Narrative = _wipData.ServiceCharge1Narrative.NarrativeText,
                                 LocalValue = (decimal) 333.33, /* new wip split from original */
                                 ReasonCode = "ER",
                                 MovementClass = MovementClass.Entered,
                                 CommandId = CommandId.Generate,
                                 ItemImpact = ItemImpact.Created
                             }
                         });
        }

        [Test]
        public void SplitInForeignCurrency()
        {
            /*
             * original item belongs to 'foreign-multiple' with wipcode SC2 
             * - this is to split to
             *   - foreign-multiple against SC2 at 50% in foreign currency 1
             *   - local-multiple against SC1 at 50% in foreign currency 1
             */

            var itemToSplit = GetItemToSplit(_wipData.ForeignWip);

            var split1 = CreateParameter(_wipData.CaseForeignMultiple.Id, _wipData.ServiceCharge2.WipCode, itemToSplit);
            split1.ForeignAmount = (decimal) 500;
            split1.LocalAmount = (decimal) 333.34;
            split1.ReasonCode = "ER";
            split1.SplitPercentage = 50;

            var split2 = CreateParameter(_wipData.CaseLocalMultiple.Id, _wipData.ServiceCharge1.WipCode, itemToSplit);
            split2.ForeignAmount = (decimal) 500;
            split2.LocalAmount = (decimal) 333.33;
            split2.ReasonCode = "ER";
            split2.SplitPercentage = 50;

            var beforeSaveTime = DateTime.Now;

            CallSplitItemsApi(split1, split2);

            CommonAssert(beforeSaveTime,
                         new ExpectedTransactionHeaderValues {AdjustmentType = TransactionType.WipSplit},
                         new[]
                         {
                             new ExpectedWipValues
                             {
                                 /*
                                    original local value is 666.67,  (foreign value 1000 / exchange rate 1.5)
                                    for even splits 50/50, 333.33 + 333.33 != 666.67
                                    so the 1 cent is allocated to the first of the splits 
                                 */
                                 WipCode = _wipData.ForeignWip.WipCode,
                                 CaseKey = _wipData.CaseForeignMultiple.Id,
                                 StaffKey = _wipData.CaseForeignMultiple.Staff().NameId,
                                 Narrative = _wipData.ServiceCharge2Narrative.NarrativeText,
                                 ExchangeRate = (decimal) 1.5,
                                 ForeignCurrency = _wipData.ForeignCurrency1.Id,
                                 ForeignValue = 500,
                                 LocalValue = (decimal) 333.34,
                                 Balance = (decimal) 333.34
                             },
                             new ExpectedWipValues
                             {
                                 WipCode = _wipData.ForeignWip.WipCode,
                                 CaseKey = _wipData.CaseLocalMultiple.Id,
                                 StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                                 Narrative = _wipData.ServiceCharge1Narrative.NarrativeText,
                                 ExchangeRate = (decimal) 1.5,
                                 ForeignCurrency = _wipData.ForeignCurrency1.Id,
                                 ForeignValue = 500,
                                 LocalValue = (decimal) 333.33,
                                 Balance = (decimal) 333.33
                             }
                         },
                         new[]
                         {
                             new ExpectedWorkHistoryValues
                             {
                                 TransactionId = _wipData.ForeignWip.TransactionId, /* original trans no - this records the original being adjusted off */
                                 WipCode = _wipData.ForeignWip.WipCode,
                                 StaffKey = _wipData.ForeignWip.StaffId,
                                 CaseKey = _wipData.CaseForeignMultiple.Id,
                                 Narrative = _wipData.ForeignWip.ShortNarrative,
                                 ForeignCurrency = _wipData.ForeignCurrency1.Id,
                                 ForeignValue = -1000,
                                 LocalValue = (decimal) -666.67, /* new wip split from original */
                                 ReasonCode = "ER",
                                 MovementClass = MovementClass.AdjustDown,
                                 CommandId = CommandId.AdjustDown
                             },
                             new ExpectedWorkHistoryValues
                             {
                                 WipCode = _wipData.ForeignWip.WipCode,
                                 CaseKey = _wipData.CaseForeignMultiple.Id,
                                 StaffKey = _wipData.CaseForeignMultiple.Staff().NameId,
                                 Narrative = _wipData.ServiceCharge2Narrative.NarrativeText,
                                 ForeignCurrency = _wipData.ForeignCurrency1.Id,
                                 ForeignValue = 500,
                                 LocalValue = (decimal) 333.34, /* new wip split from original */
                                 ReasonCode = "ER",
                                 MovementClass = MovementClass.AdjustUp,
                                 CommandId = CommandId.NewAdjustUp,
                                 ItemImpact = ItemImpact.Created
                             },
                             new ExpectedWorkHistoryValues
                             {
                                 WipCode = _wipData.ForeignWip.WipCode,
                                 CaseKey = _wipData.CaseLocalMultiple.Id,
                                 StaffKey = _wipData.CaseLocalMultiple.Staff().NameId,
                                 Narrative = _wipData.ServiceCharge1Narrative.NarrativeText,
                                 ForeignCurrency = _wipData.ForeignCurrency1.Id,
                                 ForeignValue = 500,
                                 LocalValue = (decimal) 333.33, /* new wip split from original */
                                 ReasonCode = "ER",
                                 MovementClass = MovementClass.Entered,
                                 CommandId = CommandId.Generate,
                                 ItemImpact = ItemImpact.Created
                             }
                         });
        }

        static dynamic GetItemToSplit(WorkInProgress wip)
        {
            var data = ApiClient.Get<JObject>($"accounting/wip-adjustments/split-item?entityKey={wip.EntityId}&transKey={wip.TransactionId}&wipSeqKey={wip.WipSequenceNo}",
                                              "e2e_ken");

            return data.ToObject<dynamic>();
        }

        static SplitParameter CreateParameter(int caseId, string wipCode, dynamic itemToSplit)
        {
            var data = ApiClient.Get<JObject>($"accounting/wip-adjustments/wip-defaults?caseKey={caseId}&activityKey={wipCode}",
                                              "e2e_ken");

            var split = data.ToObject<SplitParameter>();

            split.EntityKey = itemToSplit.entityKey;
            split.WipSeqKey = itemToSplit.wipSeqKey;
            split.TransKey = itemToSplit.transKey;
            split.WipCode = (string) data["wipTemplateKey"];
            split.DebitNoteText = (string) data["narrativeText"];
            split.IsCreditWip = itemToSplit.isCreditWip;
            split.LogDateTimeStamp = itemToSplit.logDateTimeStamp;
            split.TransDate = DateTime.Today;

            return split;
        }

        static void CallSplitItemsApi(params SplitParameter[] splits)
        {
            var index = 0;
            ApiClient.Post<JArray>("accounting/wip-adjustments/split-item",
                                   splits.Select(entry => new
                                   {
                                       Entity = entry,
                                       HasMemberChanges = true,
                                       Id = index++,
                                       Operation = 2
                                   }).ToArray(),
                                   "e2e_ken");
        }

        static void CommonAssert(DateTime beforeSaveTime, ExpectedTransactionHeaderValues expectedTransactionHeader,
                                 ExpectedWipValues[] expectedWipValues,
                                 ExpectedWorkHistoryValues[] expectedWorkHistories)
        {
            var saved = DbSetup.Do(x =>
            {
                var workHistoryAdjustedOffTransNo = x.DbContext.Set<WorkHistory>()
                                                     .Where(_ => _.LogDateTimeStamp >= beforeSaveTime)
                                                     .GroupBy(_ => _.TransactionId)
                                                     .Select(_ => new
                                                     {
                                                         _.Key,
                                                         Count = _.Count()
                                                     })
                                                     .OrderBy(_ => _.Count)
                                                     .First().Key;

                var workHistoryAdjustedOff = x.DbContext.Set<WorkHistory>()
                                              .Single(_ => _.LogDateTimeStamp >= beforeSaveTime && _.TransactionId == workHistoryAdjustedOffTransNo);

                var workHistoryOther = x.DbContext.Set<WorkHistory>()
                                        .Where(_ => _.LogDateTimeStamp >= beforeSaveTime && _.TransactionId != workHistoryAdjustedOffTransNo)
                                        .OrderBy(_ => _.WipSequenceNo)
                                        .ToArray();

                var wip = x.DbContext.Set<WorkInProgress>()
                           .Where(_ => _.LogDateTimeStamp >= beforeSaveTime && _.IsDiscount != 1)
                           .OrderBy(_ => _.LogDateTimeStamp)
                           .ToArray();

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
                    WorkHistory = new[] {workHistoryAdjustedOff}.Concat(workHistoryOther).ToArray(),
                    WorkInProgress = wip,
                    TransactionHeader = transactionHeader
                };
            });

            Assert.AreEqual(expectedWorkHistories.Length, saved.WorkHistory.Length, $"There should be {expectedWorkHistories.Length + 1} work history rows updated");
            Assert.AreEqual(expectedTransactionHeader.AdjustmentType, saved.TransactionHeader.TransactionType, "Adjustment Type");

            Assert.AreEqual(saved.TransactionHeader.EntityId, saved.WorkHistory.Last().RefEntityId, $"New WorkHistory RefEntityId and New TransactionHeader EntityNo {saved.TransactionHeader.EntityId}");
            Assert.AreEqual(saved.TransactionHeader.TransactionId, saved.WorkHistory.Last().RefTransactionId, "New Transaction Number");

            for (var i = 0; i < expectedWorkHistories.Length; i++)
            {
                Assert.AreEqual(expectedWorkHistories[i].TransactionId ?? saved.TransactionHeader.TransactionId, saved.WorkHistory[i].TransactionId,
                                $"WorkHistory #{i}, expected {expectedWorkHistories[i].TransactionId ?? saved.TransactionHeader.TransactionId}, but was {saved.WorkHistory[i].TransactionId}");
                Assert.AreEqual(expectedWorkHistories[i].LocalValue, saved.WorkHistory[i].LocalValue, $"WorkHistory #{i} LocalTransValue");
                Assert.AreEqual(expectedWorkHistories[i].ForeignValue, saved.WorkHistory[i].ForeignValue, $"WorkHistory #{i} ForeignTranValue");
                Assert.AreEqual(expectedWorkHistories[i].ForeignCurrency, saved.WorkHistory[i].ForeignCurrency, $"WorkHistory #{i} ForeignCurrency");
                Assert.AreEqual(expectedWorkHistories[i].WipCode, saved.WorkHistory[i].WipCode, $"WorkHistory #{i} WipCode");
                Assert.AreEqual(expectedWorkHistories[i].StaffKey, saved.WorkHistory[i].StaffId, $"WorkHistory #{i} EmployeeNo");
                Assert.AreEqual(expectedWorkHistories[i].CaseKey, saved.WorkHistory[i].CaseId, $"WorkHistory #{i} CaseId");
                Assert.AreEqual(expectedWorkHistories[i].ReasonCode, saved.WorkHistory[i].ReasonCode, $"WorkHistory #{i} ReasonCode");
                Assert.AreEqual(expectedWorkHistories[i].MovementClass, saved.WorkHistory[i].MovementClass,
                                $"WorkHistory #{i} Movement Class, expected {expectedWorkHistories[i].MovementClass}, but was {saved.WorkHistory[i].MovementClass}");
                Assert.AreEqual(expectedWorkHistories[i].CommandId, saved.WorkHistory[i].CommandId,
                                $"WorkHistory #{i} Command Id, expected {expectedWorkHistories[i].CommandId}, but was {saved.WorkHistory[i].CommandId}");
                Assert.AreEqual(expectedWorkHistories[i].ItemImpact, saved.WorkHistory[i].ItemImpact,
                                $"WorkHistory #{i} Item Impact, expected {expectedWorkHistories[i].ItemImpact}, but was {saved.WorkHistory[i].ItemImpact}");
                Assert.AreEqual(expectedWorkHistories[i].Narrative, saved.WorkHistory[i].ShortNarrative, $"WorkHistory #{i} Narrative");
            }

            for (var i = 0; i < expectedWipValues.Length; i++)
            {
                Assert.AreEqual(expectedWipValues[i].WipCode, saved.WorkInProgress[i].WipCode, $"WIP #{i} WipCode");
                Assert.AreEqual(expectedWipValues[i].Balance, saved.WorkInProgress[i].Balance, $"WIP #{i} Balance");
                Assert.AreEqual(expectedWipValues[i].LocalValue, saved.WorkInProgress[i].LocalValue, $"WIP #{i} Local Value");
                Assert.AreEqual(expectedWipValues[i].ForeignValue, saved.WorkInProgress[i].ForeignValue, $"WIP #{i} Foreign Value");
                Assert.AreEqual(expectedWipValues[i].ForeignCurrency, saved.WorkInProgress[i].ForeignCurrency, $"WIP #{i} Foreign Currency");
                Assert.AreEqual(expectedWipValues[i].ExchangeRate, saved.WorkInProgress[i].ExchangeRate, $"WIP #{i} Exchange Rate");
                Assert.AreEqual(expectedWipValues[i].CaseKey, saved.WorkInProgress[i].CaseId, $"WIP #{i} Case");
                Assert.AreEqual(expectedWipValues[i].StaffKey, saved.WorkInProgress[i].StaffId, $"WIP #{i} Staff");
                Assert.AreEqual(expectedWipValues[i].Narrative, saved.WorkInProgress[i].ShortNarrative, $"WIP #{i} Narrative");
            }
        }

        [SuppressMessage("ReSharper", "UnusedMember.Local")]
        [SuppressMessage("ReSharper", "UnusedAutoPropertyAccessor.Local")]
        class SplitParameter
        {
            public int CaseKey { get; set; }

            public string DebitNoteText { get; set; }

            public decimal? ForeignAmount { get; set; }

            public decimal? LocalAmount { get; set; }

            public bool IsCreditWip { get; set; }

            public DateTime LogDateTimeStamp { get; set; }

            public int NameKey { get; set; }

            public short? NarrativeKey { get; set; }

            public string NarrativeTitle { get; set; }

            public string ReasonCode { get; set; }

            public decimal SplitPercentage { get; set; }

            public int StaffKey { get; set; }

            public DateTime TransDate { get; set; }

            public int TransKey { get; set; }

            public string WipCode { get; set; }

            public short WipSeqKey { get; set; }

            public int EntityKey { get; set; }
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

            public int? TransactionId { get; set; }
        }
    }
}