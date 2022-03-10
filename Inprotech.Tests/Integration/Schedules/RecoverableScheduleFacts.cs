using System;
using System.Linq;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.Schedules
{
    public class RecoverableScheduleFacts
    {
        public class FindBySchedule : FactBase
        {
            [Theory]
            [InlineData(RecoveryScheduleStatus.Pending)]
            [InlineData(RecoveryScheduleStatus.Running)]
            public void PreventsDoubleRecoveryOfSameSchedule(RecoveryScheduleStatus status)
            {
                var f = new RecovereableScheduleControllerFixture(Db)
                        .WithRecoveryStatus(status)
                        .WithBrokenSchedule();

                var brokenSchedule = f.BrokenSchedule.Id;

                f.Subject.Recover(brokenSchedule);

                Assert.Empty(Db.Set<Schedule>().Where(_ => _.Id != brokenSchedule));
            }

            [Fact]
            public void CreatesRecoverySchedule()
            {
                var recoveryInfo = new RecoveryInfo
                {
                    CaseIds = new[] {1},
                    ScheduleRecoverableIds = new[] {1L},
                    DocumentIds = new[] {1}
                };

                var f = new RecovereableScheduleControllerFixture(Db)
                        .WithBrokenSchedule()
                        .WithRecoveryInfo(recoveryInfo);

                var brokenSchedule = f.BrokenSchedule.Id;

                f.Subject.Recover(brokenSchedule);

                var recoverySchedule =
                    Db.Set<Schedule>().Single(_ => _.Type == ScheduleType.Retry);
                var tempStorageId = (long) JObject.Parse(recoverySchedule.ExtendedSettings)["TempStorageId"];
                var tempStorage = Db.Set<TempStorage>().Single();

                Assert.Equal(f.BrokenSchedule, recoverySchedule.Parent);
                Assert.Equal(ScheduleType.Retry, recoverySchedule.Type);
                Assert.Equal(ScheduleState.RunNow, recoverySchedule.State);
                Assert.Equal(tempStorage.Id, tempStorageId);
            }

            [Fact]
            public void CreatesRecoveryScheduleWithContinuousScheduleError()
            {
                var recoveryInfo = new RecoveryInfo
                {
                    CaseIds = new[] {1},
                    ScheduleRecoverableIds = new[] {1L},
                    DocumentIds = new[] {1}
                };

                var f = new RecovereableScheduleControllerFixture(Db)
                        .WithDisabledSchedule(null, false)
                        .WithRecoveryInfo(recoveryInfo);

                var brokenSchedule = f.BrokenSchedule.Id;

                var e = Record.Exception(() => f.Subject.Recover(brokenSchedule));
                Assert.IsType<NotSupportedException>(e);
            }

            [Fact]
            public void CreatesRecoveryScheduleWithContinuousScheduleInstead()
            {
                var recoveryInfo = new RecoveryInfo
                {
                    CaseIds = new[] {1},
                    ScheduleRecoverableIds = new[] {1L},
                    DocumentIds = new[] {1}
                };

                var f = new RecovereableScheduleControllerFixture(Db)
                        .WithDisabledSchedule()
                        .WithRecoveryInfo(recoveryInfo);

                var brokenSchedule = f.BrokenSchedule.Id;

                f.Subject.Recover(brokenSchedule);

                var recoverySchedule =
                    Db.Set<Schedule>().Single(_ => _.Type == ScheduleType.Retry);
                var tempStorageId = (long) JObject.Parse(recoverySchedule.ExtendedSettings)["TempStorageId"];
                var tempStorage = Db.Set<TempStorage>().Single();

                Assert.Equal(f.ContinurousSchedule, recoverySchedule.Parent);
                Assert.Equal(ScheduleType.Retry, recoverySchedule.Type);
                Assert.Equal(ScheduleState.RunNow, recoverySchedule.State);
                Assert.Equal(tempStorage.Id, tempStorageId);
            }

            [Fact]
            public void CreatesSingleRecoveryScheduleForAllCustomersCombined()
            {
                var recoveryInfo1 = new RecoveryInfo
                {
                    CorrelationId = "12345",
                    /* Private Pair Customer included in broken schedule */
                    CaseIds = new[] {1},
                    ScheduleRecoverableIds = new[] {1L},
                    DocumentIds = new[] {1}
                };

                var recoveryInfo2 = new RecoveryInfo
                {
                    CorrelationId = "45678",
                    /* Private Pair Customer included in broken schedule */
                    CaseIds = new[] {1},
                    ScheduleRecoverableIds = new[] {1L},
                    DocumentIds = new[] {1}
                };

                var f = new RecovereableScheduleControllerFixture(Db)
                        .WithBrokenSchedule(new Schedule
                        {
                            ExtendedSettings = JsonConvert.SerializeObject(new {CustomerNumbers = "12345,45678,67890"})
                        })
                        .WithRecoveryInfo(recoveryInfo1, recoveryInfo2);

                var brokenSchedule = f.BrokenSchedule.Id;

                f.Subject.Recover(brokenSchedule);

                var recoverySchedule =
                    Db.Set<Schedule>().Single(_ => _.Type == ScheduleType.Retry);
                var tempStorageId = (long) JObject.Parse(recoverySchedule.ExtendedSettings)["TempStorageId"];
                var tempStorage = Db.Set<TempStorage>().Single();

                Assert.Equal(f.BrokenSchedule, recoverySchedule.Parent);
                Assert.Equal(ScheduleType.Retry, recoverySchedule.Type);
                Assert.Equal(ScheduleState.RunNow, recoverySchedule.State);
                Assert.Equal(tempStorage.Id, tempStorageId);
            }

            [Fact]
            public void PreventsRecoveryIfScheduleIsntBroken()
            {
                var recoveryInfo = new RecoveryInfo();

                var f = new RecovereableScheduleControllerFixture(Db)
                        .WithBrokenSchedule()
                        .WithRecoveryInfo(new RecoveryInfo());

                var unbrokenSchedule = f.BrokenSchedule.Id;

                f.Subject.Recover(unbrokenSchedule);

                Assert.True(recoveryInfo.IsEmpty);

                Assert.Empty(Db.Set<Schedule>().Where(_ => _.Id != unbrokenSchedule));
            }
        }

        public class RecovereableScheduleControllerFixture : IFixture<IRecoverableSchedule>
        {
            readonly InMemoryDbContext _db;

            public RecovereableScheduleControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                var securityContext = Substitute.For<ISecurityContext>();

                securityContext.User.Returns(new User());

                var recoveryScheduleStatusReader = Substitute.For<IRecoveryScheduleStatusReader>();

                RecoverableItems = Substitute.For<IRecoverableItems>();

                recoveryScheduleStatusReader.Read(Arg.Any<int>()).Returns(RecoveryScheduleStatus);

                Subject = new RecoverableSchedule(db,
                                                  recoveryScheduleStatusReader,
                                                  RecoverableItems, securityContext,
                                                  new RecoveryInfoManager(db),
                                                  () => DateTime.Now);
            }

            public RecoveryScheduleStatus RecoveryScheduleStatus { get; set; }

            public IRecoverableItems RecoverableItems { get; set; }

            public Schedule BrokenSchedule { get; set; }

            public Schedule ContinurousSchedule { get; set; }

            public IRecoverableSchedule Subject { get; set; }

            public RecovereableScheduleControllerFixture WithRecoveryInfo(params RecoveryInfo[] recoveryInfos)
            {
                RecoverableItems.FindBySchedule(BrokenSchedule.Id)
                                .Returns(recoveryInfos);

                return this;
            }

            public RecovereableScheduleControllerFixture WithRecoveryStatus(RecoveryScheduleStatus status)
            {
                RecoveryScheduleStatus = status;
                return this;
            }

            public RecovereableScheduleControllerFixture WithBrokenSchedule(Schedule schedule = null)
            {
                BrokenSchedule = (schedule ?? new Schedule
                {
                    Id = 1,
                    ExtendedSettings = JsonConvert.SerializeObject(new {Key = "Value"})
                }).In(_db);
                return this;
            }

            public RecovereableScheduleControllerFixture WithDisabledSchedule(Schedule schedule = null, bool withContinuousSchedule = true)
            {
                BrokenSchedule = (schedule ?? new Schedule
                {
                    Id = 1,
                    ExtendedSettings = JsonConvert.SerializeObject(new {Key = "Value"}),
                    State = ScheduleState.Disabled
                }).In(_db);

                ContinurousSchedule = withContinuousSchedule
                    ? new Schedule
                    {
                        Id = 11,
                        ExtendedSettings = JsonConvert.SerializeObject(new {Key = "Value"}),
                        State = ScheduleState.Active,
                        Type = ScheduleType.Continuous,
                        DataSourceType = BrokenSchedule.DataSourceType
                    }.In(_db)
                    : null;

                return this;
            }
        }
    }
}