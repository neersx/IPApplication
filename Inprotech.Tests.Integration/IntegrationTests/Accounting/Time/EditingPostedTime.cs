using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Time
{
    [Category(Categories.Integration)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release14)]
    public class EditingPostedTime : IntegrationTest
    {
        TestUser _user;
        Diary _diary;
        Name _entityName;
        Case _newCase;
        WipTemplate _newActivity;

        [SetUp]
        public virtual void Setup()
        {
            SetupData();
        }

        void SetupData()
        {
            DbSetup.Do(x =>
            {
                var staffName = new NameBuilder(x.DbContext).CreateStaff();
                _user = new Users(x.DbContext) {Name = staffName}.WithPermission(ApplicationTask.MaintainTimeViaTimeRecording)
                                                                 .WithPermission(ApplicationTask.MaintainPostedTime, Allow.Modify)
                                                                 .Create();
                var startTime = DateTime.Today.Date.AddHours(8);

                var wipTemplateBuilder = new WipTemplateBuilder(x.DbContext);
                var activity = wipTemplateBuilder.Create("E2E", typeId: "E2EWIP");
                _newActivity = wipTemplateBuilder.Create("NEW", typeId: "E2ENEW");

                var caseBuilder = new CaseBuilder(x.DbContext);
                var @case = caseBuilder.Create("e2e", null);
                _newCase = caseBuilder.Create("e2e2", null);

                var debtor = x.DbContext.Set<CaseName>().Single(_ => _.NameTypeId == "D" && _.CaseId == @case.Id);

                _diary = new DiaryBuilder(x.DbContext).Create(_user.NameId, 10, startTime, @case.Id, null, activity.WipCode, "short-narrative", "note1", null, 300, 150, 30);
                _diary.TotalUnits = 20;
                _diary.FinishTime = startTime.AddHours(2);
                _diary.TotalTime = new DateTime(1899, 1, 1, 2, 0, 0);

                x.DbContext.SaveChanges();

                _entityName = new NameBuilder(x.DbContext).Create("E2E-Entity");
                x.Insert(new SpecialName(true, _entityName));
                x.InsertWithNewId(new Discount {NameId = debtor.NameId, DiscountRate = 10, BasedOnAmount = 0});
            });
            AccountingDbHelper.SetupPeriod();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [Test]
        public virtual void RecordsCorrectlyUpdatedOnIncreasingDuration()
        {
            var transNo = PostedTimeTestHelper.PostEntry(_entityName, _diary, _user);
            var editRequest = PostedTimeTestHelper.ChangeDurationBy(PostedTimeTestHelper.GetRecordableTime(_diary, _entityName), 1);

            ApiClient.Put<dynamic>("accounting/posted-time/update", JsonConvert.SerializeObject(editRequest), _user.Username);

            DbSetup.Do(x =>
            {
                var updatedDiary = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.EntryNo == _diary.EntryNo && _.EmployeeNo == _user.NameId);
                Assert.NotNull(updatedDiary);
                Assert.AreEqual(transNo, updatedDiary.TransactionId);

                var wips = x.DbContext.Set<WorkInProgress>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId).ToList();
                PostedTimeTestHelper.AssertWipDetails(wips, new DateTime(1899, 1, 1, 3, 0, 0), 30, 10, 150, 300, 450, -30, -45, "Edited posted entry(Addition of 1 hr)");

                var history = x.DbContext.Set<WorkHistory>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId && _.HistoryLineNo == 2).ToList();
                PostedTimeTestHelper.AssertWorkflowHistory(history, 10, 150, -15, MovementClass.AdjustUp, MovementClass.AdjustDown, "Edited posted entry(Addition of 1 hr)");
            });
        }

        [Test]
        public virtual void RecordsCorrectlyUpdatedOnDecreasingDuration()
        {
            var transNo = PostedTimeTestHelper.PostEntry(_entityName, _diary, _user);
            var editRequest = PostedTimeTestHelper.ChangeDurationBy(PostedTimeTestHelper.GetRecordableTime(_diary, _entityName), -1);

            ApiClient.Put<dynamic>("accounting/posted-time/update", JsonConvert.SerializeObject(editRequest), _user.Username);

            DbSetup.Do(x =>
            {
                var updatedDiary = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.EntryNo == _diary.EntryNo && _.EmployeeNo == _user.NameId);
                Assert.NotNull(updatedDiary);
                Assert.AreEqual(transNo, updatedDiary.TransactionId);

                var wips = x.DbContext.Set<WorkInProgress>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId).ToList();
                PostedTimeTestHelper.AssertWipDetails(wips, new DateTime(1899, 1, 1, 1, 0, 0), 10, 10, 150, 300, 150, -30, -15, "Edited posted entry(Subtraction of 1 hr)");

                var history = x.DbContext.Set<WorkHistory>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId && _.HistoryLineNo == 2).ToList();
                PostedTimeTestHelper.AssertWorkflowHistory(history, -10, -150, 15, MovementClass.AdjustDown, MovementClass.AdjustUp, "Edited posted entry(Subtraction of 1 hr)");
            });
        }

        [Test]
        public virtual void RecordsCorrectlyUpdatedOnChangeOfNarrative()
        {
            var transNo = PostedTimeTestHelper.PostEntry(_entityName, _diary, _user);
            var editRequest = PostedTimeTestHelper.GetRecordableTime(_diary, _entityName);
            editRequest.NarrativeText = "New Narrative!!";

            ApiClient.Put<dynamic>("accounting/posted-time/update", JsonConvert.SerializeObject(editRequest), _user.Username);

            DbSetup.Do(x =>
            {
                var updatedDiary = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.EntryNo == _diary.EntryNo && _.EmployeeNo == _user.NameId);
                Assert.NotNull(updatedDiary);
                Assert.AreEqual(transNo, updatedDiary.TransactionId);

                var wips = x.DbContext.Set<WorkInProgress>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId).ToList();
                PostedTimeTestHelper.AssertWipDetails(wips, new DateTime(1899, 1, 1, 2, 0, 0), 20, 10, 150, 300, 300, -30, -30, "Edited posted entry(Narrative change only)");
                Assert.AreEqual(editRequest.NarrativeText, wips.Single(_=> !_.WipIsDiscount()).ShortNarrative);
                
                var history = x.DbContext.Set<WorkHistory>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId && _.HistoryLineNo == 1).ToList();
                Assert.AreEqual(2, history.Count);
                Assert.AreEqual(editRequest.NarrativeText, history.Single(_=>!_.IsDiscount).ShortNarrative);
            });
        }

        [Test]
        public virtual void RecordsCaseWipTransferCorrectly()
        {
            PostedTimeTestHelper.PostEntry(_entityName, _diary, _user);
            var editRequest = PostedTimeTestHelper.GetRecordableTime(_diary, _entityName);
            editRequest.CaseKey = _newCase.Id;

            ApiClient.Put<dynamic>("accounting/posted-time/update", JsonConvert.SerializeObject(editRequest), _user.Username);

            DbSetup.Do(x =>
            {
                var updatedDiary = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.EntryNo == _diary.EntryNo && _.EmployeeNo == _user.NameId);
                Assert.NotNull(updatedDiary);
                Assert.AreEqual(_newCase.Id, updatedDiary.CaseId);

                var wips = x.DbContext.Set<WorkInProgress>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId).ToList();
                Assert.AreEqual(editRequest.CaseKey, wips.Single(_=> !_.WipIsDiscount()).CaseId);
                
                var history = x.DbContext.Set<WorkHistory>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId && _.HistoryLineNo == 1).ToList();
                Assert.AreEqual(2, history.Count);
                Assert.True(history.All(_=>_.CaseId == editRequest.CaseKey && _.TransactionType == TransactionType.CaseWipTransfer));
            });
        }

        [Test]
        public virtual void RecordsActivityWipTransferCorrectly()
        {
            PostedTimeTestHelper.PostEntry(_entityName, _diary, _user);
            var editRequest = PostedTimeTestHelper.GetRecordableTime(_diary, _entityName);
            editRequest.Activity = _newActivity.WipCode;

            ApiClient.Put<dynamic>("accounting/posted-time/update", JsonConvert.SerializeObject(editRequest), _user.Username);

            DbSetup.Do(x =>
            {
                var updatedDiary = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.EntryNo == _diary.EntryNo && _.EmployeeNo == _user.NameId);
                Assert.NotNull(updatedDiary);
                Assert.AreEqual(_newActivity.WipCode, updatedDiary.Activity);

                var wips = x.DbContext.Set<WorkInProgress>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId).ToList();
                Assert.AreEqual(editRequest.Activity, wips.Single(_=> !_.WipIsDiscount()).WipCode);
                
                var history = x.DbContext.Set<WorkHistory>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId && _.HistoryLineNo == 1).ToList();
                Assert.AreEqual(2, history.Count);
                Assert.NotNull(history.Single(_=> !_.IsDiscount && _.WipCode == editRequest.Activity && _.TransactionType == TransactionType.ActivityWipTransfer));
                Assert.NotNull(history.Single(_=> _.IsDiscount && _.WipCode == "DISC" && _.TransactionType == TransactionType.ActivityWipTransfer));
            });
        }

        [Test]
        public virtual void RecordsCaseAndActivityWipTransferCorrectly()
        {
            PostedTimeTestHelper.PostEntry(_entityName, _diary, _user);
            var editRequest = PostedTimeTestHelper.GetRecordableTime(_diary, _entityName);
            editRequest.Activity = _newActivity.WipCode;
            editRequest.CaseKey = _newCase.Id;

            ApiClient.Put<dynamic>("accounting/posted-time/update", JsonConvert.SerializeObject(editRequest), _user.Username);

            DbSetup.Do(x =>
            {
                var updatedDiary = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.EntryNo == _diary.EntryNo && _.EmployeeNo == _user.NameId);
                Assert.NotNull(updatedDiary);
                Assert.AreEqual(_newActivity.WipCode, updatedDiary.Activity);

                var wips = x.DbContext.Set<WorkInProgress>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId).ToList();
                Assert.NotNull(wips.Single(_=> !_.WipIsDiscount() && _.WipCode == _newActivity.WipCode && _.CaseId == _newCase.Id));
                
                var history = x.DbContext.Set<WorkHistory>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId && _.HistoryLineNo == 1).ToList();
                Assert.AreEqual(2, history.Count);
                Assert.NotNull(history.Single(_=> !_.IsDiscount && _.WipCode == editRequest.Activity && _.TransactionType == TransactionType.ActivityWipTransfer));
                Assert.NotNull(history.Single(_=> _.IsDiscount && _.WipCode == "DISC" && _.TransactionType == TransactionType.ActivityWipTransfer));
            });
        }
    }
}