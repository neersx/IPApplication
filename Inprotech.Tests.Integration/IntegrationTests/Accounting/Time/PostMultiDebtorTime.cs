using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Time;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Time
{
    [SplitWipMultiDebtor]
    [Category(Categories.Integration)]
    [TestFixture]
    public class PostMultiDebtorTime : IntegrationTest
    {
        TimeRecordingData _dbData;

        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(withMultiDebtorEnabled: true);
            AccountingDbHelper.SetupPeriod();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [Test]
        public void RecordsSplitWipItems()
        {
            var request = new RecordableTime
            {
                StaffId = _dbData.StaffName.Id,
                CaseKey = _dbData.Case.Id,
                Activity = _dbData.NewActivity.WipCode,
                TotalTime = new DateTime(1899,
                                         1,
                                         1).AddHours(1),
                Start = DateTime.Now.AddHours(-1),
                Finish = DateTime.Now
            };
            var insertTimeResponse = ApiClient.Post<JObject>("accounting/time/save", JsonConvert.SerializeObject(request));
            var timeEntry = insertTimeResponse.SelectToken("response.timeEntry").ToObject<TimeEntry>();
            var postEntry = new PostEntry {EntityKey = _dbData.EntityId, EntryNo = timeEntry.EntryNo, StaffNameId = request.StaffId, PostingParams = null};
            ApiClient.Post<JObject>("accounting/time-posting/postEntry", JsonConvert.SerializeObject(postEntry)).ToObject<PostTimeResult>();

            DbSetup.Do(x =>
            {
                var updatedDiary = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.EntryNo == timeEntry.EntryNo && _.EmployeeNo == timeEntry.StaffId && _.WipEntityId != null && _.TransactionId != null);
                Assert.NotNull(updatedDiary);
                var debtorSplits = x.DbContext.Set<DebtorSplitDiary>().Where(_ => _.EntryNo == timeEntry.EntryNo && _.EmployeeNo == timeEntry.StaffId).ToList();
                var debtor1 = debtorSplits.First();
                var debtor2 = debtorSplits.Last();
                var wips = x.DbContext.Set<WorkInProgress>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId).OrderBy(_ => _.WipSequenceNo).ToList();
                Assert.AreEqual(2, wips.Count);
                AssertWipDetails(wips.First(), new DateTime(1899, 1, 1, 1, 0, 0), 10, 10, debtor1.ChargeOutRate.GetValueOrDefault(), 60, 60, debtor1.DebtorNameNo, "Split Wip for first debtor");
                AssertWipDetails(wips.Last(), new DateTime(1899, 1, 1, 1, 0, 0), 10, 10, debtor2.ChargeOutRate.GetValueOrDefault(), 60, 60, debtor2.DebtorNameNo, "Split Wip for second debtor");
                var history = x.DbContext.Set<WorkHistory>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId).OrderBy(_ => _.WipSequenceNo).ToList();
                Assert.AreEqual(2, history.Count);
                AssertWorkflowHistory(history.First(), 10, 60, MovementClass.Entered, debtor1.DebtorNameNo, "Split Work History for first debtor");
                AssertWorkflowHistory(history.Last(), 10, 60, MovementClass.Entered, debtor2.DebtorNameNo, "Split Work History for second debtor");
            });

            void AssertWipDetails(WorkInProgress wip, DateTime totalTime, int totalUnits, int unitsPerHour, decimal chargeOutRate, int localValue, int balance, int debtorNo, string assertionText)
            {
                Assert.AreEqual(totalTime, wip.TotalTime, $"Total time of wip is checked for: {assertionText}");
                Assert.AreEqual(totalUnits, wip.TotalUnits, $"Total units of wip is checked for: {assertionText}");
                Assert.AreEqual(unitsPerHour, wip.UnitsPerHour, $"UnitsPerHours of wip is checked for: {assertionText}");
                Assert.AreEqual(chargeOutRate, wip.ChargeOutRate, $"ChargeOutRate of wip is checked for: {assertionText}");
                Assert.AreEqual(localValue, wip.LocalValue, $"LocalValue of wip is checked for: {assertionText}");
                Assert.AreEqual(balance, wip.Balance, $"Balance of wip is checked for: {assertionText}");
                Assert.AreEqual(debtorNo, wip.AccountClientId, $"AccountClientNo of wip is checked for: {assertionText}");
            }

            void AssertWorkflowHistory(WorkHistory history, int totalUnits, int localTransactionValue, MovementClass movementClass, int debtorNo, string assertionText)
            {
                Assert.AreEqual(totalUnits, history.TotalUnits, $"Total units of history item is checked for: {assertionText}");
                Assert.AreEqual(localTransactionValue, history.LocalValue, $"Transaction value of history is checked for: {assertionText}");
                Assert.AreEqual(movementClass, history.MovementClass, $"MovementClass value of main is checked for: {assertionText}");
                Assert.AreEqual(debtorNo, history.AccountClientId, $"AccountClientNo value of main is checked for: {assertionText}");
                Assert.AreEqual(TransactionType.Timesheet, history.TransactionType, $"TransactionType value of main is checked for: {assertionText}");
            }
        }
    }
}
