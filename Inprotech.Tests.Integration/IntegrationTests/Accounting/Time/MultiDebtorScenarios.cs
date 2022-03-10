using System;
using System.Data.Entity;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Time
{
    [SplitWipMultiDebtor]
    [Category(Categories.Integration)]
    [TestFixture]
    public class MultiDebtorScenarios : IntegrationTest
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

        public Diary GetDiaryFor(int empNo, int entryNo)
        {
            Diary diary = null;
            DbSetup.Do(x =>
            {
                diary = x.DbContext.Set<Diary>().Include(_ => _.DebtorSplits)
                         .SingleOrDefault(_ => _.EntryNo == entryNo && _.EmployeeNo == empNo);
            });

            return diary;
        }

        public Diary AddOneMultiDebtorEntry(int caseId)
        {
            var request = new RecordableTime
            {
                StaffId = _dbData.StaffName.Id,
                CaseKey = caseId,
                Activity = _dbData.NewActivity.WipCode,
                TotalTime = new DateTime(1899,
                                         1,
                                         1).AddHours(1),
                Start = DateTime.Now.AddHours(-1),
                Finish = DateTime.Now
            };
            var insertTimeResponse = ApiClient.Post<JObject>("accounting/time/save", JsonConvert.SerializeObject(request));
            var timeEntry = insertTimeResponse.SelectToken("response.timeEntry").ToObject<TimeEntry>();

            return GetDiaryFor(_dbData.StaffName.Id, timeEntry.EntryNo.Value);
        }

        [Test]
        public void ChangeDate()
        {
            var newDiary = AddOneMultiDebtorEntry(_dbData.Case.Id);
            var request = new RecordableTime
            {
                EntryDate = DateTime.Now.Date.AddDays(-5),
                Start = newDiary.StartTime,
                Finish = newDiary.FinishTime,
                StaffId = newDiary.EmployeeNo,
                EntryNo = newDiary.EntryNo
            };

            ApiClient.Put<JObject>("accounting/time/updateDate", JsonConvert.SerializeObject(request));

            var updatedDiary = GetDiaryFor(newDiary.EmployeeNo, newDiary.EntryNo);
            Assert.AreEqual(request.EntryDate.Date.Add(request.Start.Value.TimeOfDay), updatedDiary.StartTime.Value, "Start time is updated to the new entry date");
            Assert.AreEqual(request.EntryDate.Date.Add(request.Finish.Value.TimeOfDay), updatedDiary.FinishTime.Value, "Finish time is updated to the new entry date");
            Assert.AreEqual(newDiary.DebtorSplits.Count, updatedDiary.DebtorSplits.Count, "Same number of debtor splits added after update");

            Assert.AreNotEqual(newDiary.DebtorSplits.First().Id, updatedDiary.DebtorSplits.First().Id, "Debtor splits are reevaluated and newly added");
        }

        [Test]
        public void UpdateNarrative()
        {
            var newDiary1 = AddOneMultiDebtorEntry(_dbData.Case.Id);
            var newDiary2 = AddOneMultiDebtorEntry(_dbData.Case.Id);
            var request = new TimeRecordingBatchController.BatchNarrativeRequest
            {
                NewNarrative = new TimeRecordingBatchController.NewNarrative {NarrativeText = Fixture.String(50)},
                SelectionDetails = new BatchSelectionDetails {StaffNameId = _dbData.StaffName.Id, EntryNumbers = new[] {newDiary1.EntryNo, newDiary2.EntryNo}}
            };
            ApiClient.Put<JObject>("accounting/time/batch/update-narrative", JsonConvert.SerializeObject(request));
            var updatedDiary = GetDiaryFor(newDiary1.EmployeeNo, newDiary1.EntryNo);
            Assert.AreEqual(request.NewNarrative.NarrativeText, updatedDiary.ShortNarrative, "Expected Narrative Text to be updated");
            Assert.True(updatedDiary.DebtorSplits.All(_ => _.Narrative == request.NewNarrative.NarrativeText), "Narrative text is updated for all splits");

            updatedDiary = GetDiaryFor(newDiary1.EmployeeNo, newDiary1.EntryNo);
            Assert.AreEqual(request.NewNarrative.NarrativeText, updatedDiary.ShortNarrative, "Expected Narrative Text to be updated");
            Assert.True(updatedDiary.DebtorSplits.All(_ => _.Narrative == request.NewNarrative.NarrativeText), "Narrative text is updated for all splits for other entries");
        }
    }
}