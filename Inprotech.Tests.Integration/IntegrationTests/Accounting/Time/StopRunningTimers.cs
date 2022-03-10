using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Time
{
    [Category(Categories.Integration)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release14)]
    public class StopRunningTimers : IntegrationTest
    {
        TestUser _user;
        Diary _diary;
        Diary _existingTime;
        
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
                _existingTime = new DiaryBuilder(x.DbContext).Create(_user.NameId, 11, DateTime.Today.Date.AddHours(6), null, null, null, "existing-entry");
                var startTime = DateTime.Today.Date.AddHours(8);

                _diary = new DiaryBuilder(x.DbContext).Create(_user.NameId, 10, startTime, null, null, null, "short-narrative");
                _diary.FinishTime = null;
                _diary.TotalTime = null;
                _diary.IsTimer = 1;

                x.DbContext.SaveChanges();
            });
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [Test]
        public virtual void SetsCorrectFinishAndDurationWhenStartingNewTimer()
        {
            ApiClient.Post<dynamic>("accounting/timer/start", new { StartDateTime = DateTime.Today.Date.AddHours(9), StaffNameId = _user.NameId }, _user.Username);
            DbSetup.Do(x =>
            {
                var stoppedTimer = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.EntryNo == _diary.EntryNo && _.EmployeeNo == _user.NameId);
                Assert.NotNull(stoppedTimer);
                Assert.AreEqual(9, stoppedTimer.FinishTime.GetValueOrDefault().Hour);
                Assert.AreEqual(_diary.StartTime.GetValueOrDefault().Date, stoppedTimer.FinishTime.GetValueOrDefault().Date);
            });
        }

        [Test]
        public virtual void SetsCorrectFinishAndDurationWhenContinuingNewTimer()
        {
            ApiClient.Post<dynamic>("accounting/timer/continue", new {StartDateTime = DateTime.Today.Date.AddHours(10), ContinueFromEntryNo = _existingTime.EntryNo, StaffNameId = _user.NameId}, _user.Username);
            DbSetup.Do(x =>
            {
                var stoppedTimer = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.EntryNo == _diary.EntryNo && _.EmployeeNo == _user.NameId);
                Assert.NotNull(stoppedTimer);
                Assert.AreEqual(10, stoppedTimer.FinishTime.GetValueOrDefault().Hour);
                Assert.AreEqual(_diary.StartTime.GetValueOrDefault().Date, stoppedTimer.FinishTime.GetValueOrDefault().Date);
            });
        }

        [Test]
        public virtual void SetsFinishToEndOfDayWhenStoppingTimerNextDay()
        {
            ApiClient.Put<dynamic>("accounting/timer/stop", JsonConvert.SerializeObject(new {EntryNo = _diary.EntryNo, Start = _diary.StartTime, TotalTime = new DateTime(1899, 1, 1, 20, 0, 0), StaffId = _user.NameId}), _user.Username);
            DbSetup.Do(x =>
            {
                var stoppedTimer = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.EntryNo == _diary.EntryNo && _.EmployeeNo == _user.NameId);
                Assert.NotNull(stoppedTimer);
                Assert.AreEqual(23, stoppedTimer.FinishTime.GetValueOrDefault().Hour);
                Assert.AreEqual(59, stoppedTimer.FinishTime.GetValueOrDefault().Minute);
                Assert.AreEqual(59, stoppedTimer.FinishTime.GetValueOrDefault().Second);
                Assert.AreEqual(_diary.StartTime.GetValueOrDefault().Date, stoppedTimer.FinishTime.GetValueOrDefault().Date);
            });
        }
    }
}
