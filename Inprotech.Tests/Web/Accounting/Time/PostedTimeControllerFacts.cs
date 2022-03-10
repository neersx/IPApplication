using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using AutoMapper;
using Castle.Components.DictionaryAdapter;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class PostedTimeControllerFacts
    {
        public class UpdatePostedTime : FactBase
        {
            [Fact]
            public async Task ReturnsErrorIfWipSplitMultiDebtorEntry()
            {
                var f = new PostedTimeControllerFixture(Db);
                var diary = new DiaryBuilder(Db)
                {
                    EntryNo = Fixture.Integer(), 
                    StaffId = Fixture.Integer(), 
                    EntityId = Fixture.Integer(), 
                    TransNo = Fixture.Integer()
                }.Build();

                diary.DebtorSplits = new List<DebtorSplitDiary> {new DebtorSplitDiary().In(Db)};

                var input = new PostedTime
                {
                    EntryNo = diary.EntryNo, 
                    StaffId = diary.EmployeeNo, 
                    Activity = diary.Activity, 
                    EntryDate = diary.StartTime.GetValueOrDefault().Date, 
                    NameKey = diary.NameNo
                };

                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.UpdatePostedTime(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task PerformsPreValidation()
            {
                var diary = new DiaryBuilder(Db)
                {
                    EntryNo = Fixture.Integer(), 
                    StaffId = Fixture.Integer(), 
                    EntityId = Fixture.Integer(), 
                    TransNo = Fixture.Integer()
                }.Build();
                
                new WorkInProgress
                {
                    EntityId = diary.WipEntityId.GetValueOrDefault(), 
                    TransactionId = diary.TransactionId.GetValueOrDefault(), 
                    Status = TransactionStatus.Active
                }.In(Db);

                var input = new PostedTime
                {
                    EntryNo = diary.EntryNo, 
                    StaffId = diary.EmployeeNo, 
                    Activity = diary.Activity, 
                    EntryDate = diary.StartTime.GetValueOrDefault().Date, 
                    NameKey = diary.NameNo
                };
                var f = new PostedTimeControllerFixture(Db);
                await f.Subject.UpdatePostedTime(input);
                await f.WipStatusEvaluator.Received(1).GetWipStatus(input.EntryNo.Value, input.StaffId.Value);
                f.ValidatePostDates.Received(1).For(input.EntryDate).IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task CallsPostedWipAdjustor(bool withWipItems)
            {
                var diary = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                var newTime = diary.TotalTime.GetValueOrDefault().AddHours(1);
                if (withWipItems)
                {
                    new WorkInProgress
                    {
                        EntityId = diary.WipEntityId.GetValueOrDefault(), 
                        TransactionId = diary.TransactionId.GetValueOrDefault(), 
                        Status = TransactionStatus.Active
                    }.In(Db);
                }
                
                var input = new PostedTime
                {
                    EntryNo = diary.EntryNo,
                    StaffId = diary.EmployeeNo,
                    Activity = diary.Activity,
                    NameKey = diary.NameNo,
                    EntryDate = diary.StartTime.GetValueOrDefault().Date,
                    TotalTime = newTime
                };
                var f = new PostedTimeControllerFixture(Db);
                f.DiaryUpdate.UpdateEntry(Arg.Any<RecordableTime>()).ReturnsForAnyArgs(new TimeEntry
                {
                    EntryNo = diary.EntryNo,
                    StaffId = diary.EmployeeNo,
                    Activity = diary.Activity,
                    TotalTime = newTime
                });
                await f.Subject.UpdatePostedTime(input);
                await f.DiaryUpdate.Received(1).UpdateEntry(Arg.Is<RecordableTime>(_ => _.EntryNo == diary.EntryNo && _.StaffId == diary.EmployeeNo), Arg.Is<int>(_ => _ == diary.TransactionId));
                await f.PostedWipAdjustor.Received(1)
                       .AdjustWipBatch(Arg.Any<IEnumerable<WorkInProgress>>(),
                                       Arg.Is<TimeEntry>(_ => _.TotalTime == newTime),
                                       Arg.Is<TimeEntry>(_ => _.EntryNo == diary.EntryNo && _.StaffId == diary.EmployeeNo));
            }

            [Theory]
            [InlineData(true, true, true)]
            [InlineData(true, true, false)]
            [InlineData(true, false, false)]
            [InlineData(true, false, true)]
            [InlineData(false, false, true)]
            [InlineData(false, true, false)]
            [InlineData(false, false, false)]
            public async Task PerformsWipTransfer(bool withNewCase, bool withNewActivity, bool withWipAdjustment)
            {
                var diary = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.BuildWithCase();
                var input = new PostedTime
                {
                    EntryNo = diary.EntryNo,
                    StaffId = diary.EmployeeNo,
                    Activity = withNewActivity ? diary.Activity + "NEW" : diary.Activity,
                    CaseKey = withNewCase ? diary.CaseId.GetValueOrDefault() + 1 : diary.CaseId,
                    NameKey = Fixture.Integer(),
                    EntryDate = diary.StartTime.GetValueOrDefault().Date
                };

                new WorkInProgress
                {
                    EntityId = diary.WipEntityId.GetValueOrDefault(), 
                    TransactionId = diary.TransactionId.GetValueOrDefault(), 
                    Status = TransactionStatus.Active
                }.In(Db);

                if (withWipAdjustment)
                    input.TotalTime = diary.TotalTime.GetValueOrDefault().AddHours(1);

                var f = new PostedTimeControllerFixture(Db);
                f.DiaryUpdate.UpdateEntry(Arg.Any<RecordableTime>()).ReturnsForAnyArgs(new TimeEntry
                {
                    EntryNo = diary.EntryNo,
                    StaffId = diary.EmployeeNo,
                    Activity = diary.Activity,
                    TotalTime = diary.TotalTime.GetValueOrDefault().AddHours(1)
                });

                await f.Subject.UpdatePostedTime(input);
                if (withNewCase)
                    await f.PostedWipAdjustor.Received(1).TransferWip(Arg.Any<IEnumerable<WorkInProgress>>(), Arg.Is<RecordableTime>(_ => _.CaseKey == input.CaseKey), TransactionType.CaseWipTransfer);

                if (withNewActivity)
                    await f.PostedWipAdjustor.Received(1).TransferWip(Arg.Any<IEnumerable<WorkInProgress>>(), Arg.Is<RecordableTime>(_ => _.Activity == input.Activity), TransactionType.ActivityWipTransfer);

                if (withWipAdjustment)
                {
                    await f.PostedWipAdjustor.Received(1)
                           .AdjustWipBatch(Arg.Any<IEnumerable<WorkInProgress>>(),
                                           Arg.Is<TimeEntry>(_ => _.TotalTime == input.TotalTime.Value),
                                           Arg.Is<TimeEntry>(_ => _.EntryNo == diary.EntryNo && _.StaffId == diary.EmployeeNo));
                }
            }

            [Fact]
            public async Task ReturnsErrorIfMultiDebtorCaseSelected()
            {
                var diary = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.BuildWithCase();
                var input = new PostedTime
                {
                    EntryNo = diary.EntryNo,
                    StaffId = diary.EmployeeNo,
                    Activity = diary.Activity,
                    CaseKey = diary.CaseId + 1,
                    NameKey = Fixture.Integer(),
                    EntryDate = diary.StartTime.GetValueOrDefault().Date
                };
                
                new WorkInProgress
                {
                    EntityId = diary.WipEntityId.GetValueOrDefault(), 
                    TransactionId = diary.TransactionId.GetValueOrDefault(), 
                    Status = TransactionStatus.Active
                }.In(Db);

                input.TotalTime = diary.TotalTime.GetValueOrDefault().AddHours(1);

                var f = new PostedTimeControllerFixture(Db);
                f.DiaryUpdate.UpdateEntry(Arg.Any<RecordableTime>()).ReturnsForAnyArgs(new TimeEntry
                {
                    EntryNo = diary.EntryNo,
                    StaffId = diary.EmployeeNo,
                    Activity = diary.Activity,
                    TotalTime = diary.TotalTime.GetValueOrDefault().AddHours(1),
                    DebtorSplits = new EditableList<DebtorSplit>(){new DebtorSplit()}
                });

                var result = await f.Subject.UpdatePostedTime(input);
                Assert.Equal("ConversionToMultiDebor", ((WipAdjustOrSplitResult)result).Error);
            }

            [Theory]
            [InlineData(true, false)]
            [InlineData(false, true)]
            [InlineData(false, false)]
            public async Task ReturnsErrorForUnsupportedCaseChange(bool withNewCase, bool withCase)
            {
                var diary = withCase ? new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.BuildWithCase() : new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                var f = new PostedTimeControllerFixture(Db);
                var input = new PostedTime
                {
                    StaffId = diary.EmployeeNo,
                    EntryNo = diary.EntryNo,
                    CaseKey = withNewCase ? diary.CaseId + 1 : null
                };
                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.UpdatePostedTime(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Theory]
            [InlineData(true, true)]
            [InlineData(true, false)]
            [InlineData(false, true)]
            [InlineData(false, false)]
            public async Task ReturnsErrorForUnsupportedDebtorChange(bool withNewDebtor, bool withNewCase)
            {
                var diary = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                var f = new PostedTimeControllerFixture(Db);
                var input = new PostedTime
                {
                    StaffId = diary.EmployeeNo,
                    EntryNo = diary.EntryNo,
                    NameKey = withNewDebtor ? diary.NameNo + 1 : null,
                    CaseKey = withNewCase ? Fixture.Integer() : null
                };
                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.UpdatePostedTime(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class UpdatePostedTimeDate : FactBase
        {
            [Fact]
            public async Task ReturnsErrorIfWipSplitMultiDebtor()
            {
                var diary = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                diary.DebtorSplits = new List<DebtorSplitDiary> {new DebtorSplitDiary().In(Db)};
                var input = new PostedTime {EntryNo = diary.EntryNo, StaffId = diary.EmployeeNo, Activity = diary.Activity, EntryDate = diary.StartTime.GetValueOrDefault().Date, NameKey = diary.NameNo};

                var f = new PostedTimeControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.ChangeEntryDate(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task PerformsPreValidation()
            {
                var diary = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                
                new WorkInProgress 
                {
                    EntityId = diary.WipEntityId.GetValueOrDefault(), 
                    TransactionId = diary.TransactionId.GetValueOrDefault(), 
                    Status = TransactionStatus.Active

                }.In(Db);

                var input = new PostedTime {EntryNo = diary.EntryNo, StaffId = diary.EmployeeNo, Activity = diary.Activity, EntryDate = diary.StartTime.GetValueOrDefault().Date};
                var f = new PostedTimeControllerFixture(Db);
                
                await f.Subject.ChangeEntryDate(input);

                f.WipStatusEvaluator.Received(1).GetWipStatus(input.EntryNo.Value, input.StaffId.Value)
                 .IgnoreAwaitForNSubstituteAssertion();
                
                f.ValidatePostDates.Received(1).For(input.EntryDate)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task CallsPostedWipAdjustor()
            {
                var diary = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                
                new WorkInProgress
                {
                    EntityId = diary.WipEntityId.GetValueOrDefault(), 
                    TransactionId = diary.TransactionId.GetValueOrDefault(), 
                    Status = TransactionStatus.Active
                }.In(Db);

                var input = new PostedTime
                {
                    EntryNo = diary.EntryNo,
                    StaffId = diary.EmployeeNo,
                    Activity = diary.Activity,
                    EntryDate = Fixture.PastDate(),
                    TotalTime = diary.TotalTime
                };
                var f = new PostedTimeControllerFixture(Db);
                var updatedEntry = new TimeEntry
                {
                    EntryNo = diary.EntryNo,
                    StaffId = diary.EmployeeNo,
                    Activity = diary.Activity,
                    TotalTime = diary.TotalTime
                };
                f.DiaryUpdate.UpdateEntry(Arg.Any<RecordableTime>()).ReturnsForAnyArgs(updatedEntry);

                await f.Subject.ChangeEntryDate(input);

                f.DiaryUpdate.Received(1).UpdateEntry(Arg.Is<RecordableTime>(_ => _.EntryNo == diary.EntryNo && _.StaffId == diary.EmployeeNo), Arg.Is<int>(_ => _ == diary.TransactionId)).IgnoreAwaitForNSubstituteAssertion();
                f.PostedWipAdjustor.Received(1)
                 .AdjustWipBatch(Arg.Any<IEnumerable<WorkInProgress>>(),
                                 Arg.Is<TimeEntry>(_ => _.TotalTime == diary.TotalTime),
                                 Arg.Is<TimeEntry>(_ => _.EntryNo == diary.EntryNo && _.StaffId == diary.EmployeeNo))
                 .IgnoreAwaitForNSubstituteAssertion();
                f.PostedWipAdjustor.Received(1).AdjustPostedEntryDate(Arg.Is<TimeEntry>(_ => _ == updatedEntry)).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class DeletePostedTime : FactBase
        {
            [Fact]
            public async Task ReturnsErrorForWipSplitMultiDebtorEntry()
            {
                var f = new PostedTimeControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.DeletePostedTime(new PostedTime {EntryNo = Fixture.Integer()}));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            [InlineData(true, false)]
            public async Task ReturnsErrors(bool withTimeEntry, bool withFunctionSecurity = true)
            {
                var f = new PostedTimeControllerFixture(Db);
                f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, Arg.Any<User>(), Arg.Any<int>()).Returns(withFunctionSecurity);
                if (!withFunctionSecurity)
                {
                    var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.DeletePostedTime(withTimeEntry ? new PostedTime {EntryNo = Fixture.Integer()} : null));
                    Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                }
                else
                {
                    if (!withTimeEntry)
                    {
                        var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.DeletePostedTime(null));
                        Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                    }
                }
            }

            [Fact]
            public async Task DeletesTimeEntryAndCallsAdjustorToZeroBalance()
            {
                var diary = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                
                new WorkInProgress
                {
                    EntityId = diary.WipEntityId.GetValueOrDefault(), 
                    TransactionId = diary.TransactionId.GetValueOrDefault(), 
                    Status = TransactionStatus.Active
                }.In(Db);

                var entry = new PostedTime
                {
                    StaffId = diary.EmployeeNo,
                    EntryNo = diary.EntryNo,
                    EntityNo = diary.WipEntityId,
                    TransNo = diary.TransactionId
                };
                var f = new PostedTimeControllerFixture(Db);
                f.PostedWipAdjustor.AdjustWipBatchToZero(Arg.Any<IEnumerable<WorkInProgress>>()).ReturnsForAnyArgs(new WipAdjustOrSplitResult {NewTransKey = Fixture.Short()});
                await f.Subject.DeletePostedTime(entry);
                await f.WipStatusEvaluator.Received(1).GetWipStatus(entry.EntryNo.Value, entry.StaffId.Value);
                await Db.Received(1).SaveChangesAsync();
            }
        }

        public class DeletePostedTimeFromChain : FactBase
        {
            [Fact]
            public async Task ReturnsErrorForWipSplitMultiDebtorEntry()
            {
                var diary = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                diary.DebtorSplits = new List<DebtorSplitDiary> {new DebtorSplitDiary().In(Db)};
                
                var input = new PostedTime
                {
                    EntryNo = diary.EntryNo, 
                    StaffId = diary.EmployeeNo, 
                    Activity = diary.Activity, 
                    EntryDate = diary.StartTime.GetValueOrDefault().Date, 
                    NameKey = diary.NameNo
                };

                var f = new PostedTimeControllerFixture(Db);
                f.TimesheetList.GetWholeChainFor(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime>()).ReturnsForAnyArgs(new[] {diary}.AsEnumerable());
                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.DeletePostedTimeFromChain(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            [InlineData(true, false)]
            public async Task ReturnsErrors(bool withTimeEntry, bool withFunctionSecurity = true)
            {
                var f = new PostedTimeControllerFixture(Db);
                
                f.TimesheetList
                 .GetWholeChainFor(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime?>())
                 .ReturnsForAnyArgs(new[] {new Diary()});

                f.FunctionSecurityProvider
                 .FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, Arg.Any<User>(), Arg.Any<int>())
                 .Returns(withFunctionSecurity);
                
                if (!withFunctionSecurity)
                {
                    var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.DeletePostedTimeFromChain(withTimeEntry ? new PostedTime {EntryNo = Fixture.Integer()} : null));
                    Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                }
                else
                {
                    if (!withTimeEntry)
                    {
                        var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.DeletePostedTimeFromChain(null));
                        Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                    }
                }
            }

            [Fact]
            public async Task DeletesTimeEntryAndCallsAdjustor()
            {
                var diary1 = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer()}.Build();
                var diary2 = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), ParentEntryNo = diary1.EntryNo, StaffId = Fixture.Integer()}.Build();
                var diary3 = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), ParentEntryNo = diary2.EntryNo, StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                var diaries = new[] {diary3, diary2, diary1};
                
                new WorkInProgress
                {
                    EntityId = diary3.WipEntityId.GetValueOrDefault(), 
                    TransactionId = diary3.TransactionId.GetValueOrDefault(), 
                    Status = TransactionStatus.Active
                }.In(Db);

                var entry = new PostedTime
                {
                    StaffId = diary3.EmployeeNo,
                    EntryNo = diary3.EntryNo,
                    EntityNo = diary3.WipEntityId,
                    TransNo = diary3.TransactionId
                };

                var f = new PostedTimeControllerFixture(Db);
                
                f.TimesheetList
                 .GetWholeChainFor(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime?>())
                 .ReturnsForAnyArgs(diaries);

                f.PostedWipAdjustor
                 .AdjustWipBatch(Arg.Any<IEnumerable<WorkInProgress>>(), Arg.Any<TimeEntry>(), Arg.Any<TimeEntry>())
                 .ReturnsForAnyArgs(new WipAdjustOrSplitResult {NewTransKey = Fixture.Short()});

                f.DiaryUpdate
                 .RemoveEntryFromChain(Arg.Any<IEnumerable<Diary>>(), entry)
                 .ReturnsForAnyArgs(x =>
                 {
                     diary2.WipEntityId = diary3.WipEntityId;
                     diary2.TransactionId = diary3.TransactionId;
                     diary2.WipSeqNo = diary3.WipSeqNo;
                     return (diary3, diary2);
                 });

                await f.Subject.DeletePostedTimeFromChain(entry);
                f.WipStatusEvaluator.Received(1).GetWipStatus(diary3.EntryNo, entry.StaffId.Value).IgnoreAwaitForNSubstituteAssertion();
                f.DiaryUpdate.Received(1).RemoveEntryFromChain(Arg.Is<IEnumerable<Diary>>(_ => _.Contains(diary1) && _.Contains(diary2) && _.Contains(diary3)), entry).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class DeletePostedTimeChain : FactBase
        {
            [Fact]
            public async Task ReturnsErrorForWipSplitMultiDebtorEntry()
            {
                var diary = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                diary.DebtorSplits = new List<DebtorSplitDiary> {new DebtorSplitDiary().In(Db)};
                var input = new PostedTime {EntryNo = diary.EntryNo, StaffId = diary.EmployeeNo, Activity = diary.Activity, EntryDate = diary.StartTime.GetValueOrDefault().Date, NameKey = diary.NameNo};

                var f = new PostedTimeControllerFixture(Db);
                f.TimesheetList.GetWholeChainFor(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime>()).ReturnsForAnyArgs(new[] {diary}.AsEnumerable());
                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.DeletePostedTimeChain(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            [InlineData(true, false)]
            public async Task ReturnsErrors(bool withTimeEntry, bool withFunctionSecurity = true)
            {
                var f = new PostedTimeControllerFixture(Db);
                f.TimesheetList.GetWholeChainFor(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime?>()).ReturnsForAnyArgs(new[] {new Diary()});
                f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, Arg.Any<User>(), Arg.Any<int>()).Returns(withFunctionSecurity);
                if (!withFunctionSecurity)
                {
                    var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.DeletePostedTimeChain(withTimeEntry ? new PostedTime {EntryNo = Fixture.Integer()} : null));
                    Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                }
                else
                {
                    if (!withTimeEntry)
                    {
                        var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.DeletePostedTimeChain(null));
                        Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                    }
                }
            }

            [Fact]
            public async Task DeletesTimeEntryAndCallsAdjustor()
            {
                var diary1 = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), StaffId = Fixture.Integer()}.Build();
                var diary2 = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), ParentEntryNo = diary1.EntryNo, StaffId = Fixture.Integer()}.Build();
                var diary3 = new DiaryBuilder(Db) {EntryNo = Fixture.Integer(), ParentEntryNo = diary2.EntryNo, StaffId = Fixture.Integer(), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                
                var diaries = new[] {diary3, diary2, diary1};
                
                var wip = new WorkInProgress
                {
                    EntityId = diary3.WipEntityId.GetValueOrDefault(), 
                    TransactionId = diary3.TransactionId.GetValueOrDefault(), 
                    Status = TransactionStatus.Active
                }.In(Db);

                var entry = new PostedTime
                {
                    StaffId = diary3.EmployeeNo,
                    EntryNo = diary3.EntryNo,
                    EntityNo = diary3.WipEntityId,
                    TransNo = diary3.TransactionId
                };

                var f = new PostedTimeControllerFixture(Db);
                f.TimesheetList.GetWholeChainFor(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime?>()).ReturnsForAnyArgs(diaries);
                f.PostedWipAdjustor.AdjustWipBatchToZero(Arg.Any<IEnumerable<WorkInProgress>>()).ReturnsForAnyArgs(new WipAdjustOrSplitResult {NewTransKey = Fixture.Short()});
                f.DiaryUpdate.RemoveEntryFromChain(Arg.Any<IEnumerable<Diary>>(), entry)
                 .ReturnsForAnyArgs(x =>
                                         {
                                             diary2.WipEntityId = diary3.WipEntityId;
                                             diary2.TransactionId = diary3.TransactionId;
                                             diary2.WipSeqNo = diary3.WipSeqNo;
                                             return (diary3, diary2);
                                         });

                await f.Subject.DeletePostedTimeChain(entry);

                f.WipStatusEvaluator.Received(1).GetWipStatus(diary3.EntryNo, entry.StaffId.Value).IgnoreAwaitForNSubstituteAssertion();
                f.DiaryUpdate.Received(1).BatchDelete(entry.StaffId.Value, Arg.Is<IEnumerable<int>>(_ => _.Contains(diary1.EntryNo) && _.Contains(diary2.EntryNo) && _.Contains(diary3.EntryNo))).IgnoreAwaitForNSubstituteAssertion();
                f.PostedWipAdjustor.Received(1).AdjustWipBatchToZero(Arg.Is<IEnumerable<WorkInProgress>>(_ => _.Contains(wip))).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        class PostedTimeControllerFixture : IFixture<PostedTimeController>
        {
            public PostedTimeControllerFixture(InMemoryDbContext db)
            {
                var m = new Mapper(new MapperConfiguration(cfg =>
                {
                    cfg.AddProfile(new AccountingProfile());
                    cfg.CreateMissingTypeMaps = true;
                }));
                Mapper = m.DefaultContext.Mapper.DefaultContext.Mapper;
                PostedWipAdjustor = Substitute.For<IPostedWipAdjustor>();
                PostedWipAdjustor.TransferWip(Arg.Any<IEnumerable<WorkInProgress>>(), Arg.Any<RecordableTime>(), Arg.Any<TransactionType>()).ReturnsForAnyArgs(new WipAdjustOrSplitResult {NewTransKey = Fixture.Short()});
                DiaryUpdate = Substitute.For<IDiaryUpdate>();
                DiaryUpdate.UpdateEntry(Arg.Any<RecordableTime>()).Returns(new TimeEntry {EntryNo = Fixture.Integer()});
                DiaryUpdate.UpdateEntry(Arg.Any<RecordableTime>(), Arg.Any<int>()).Returns(new TimeEntry {EntryNo = Fixture.Integer()});
                ValidatePostDates = Substitute.For<IValidatePostDates>();
                ValidatePostDates.For(Arg.Any<DateTime>()).Returns((isValid: true, isWarningOnly: false, code: string.Empty));
                WipStatusEvaluator = Substitute.For<IWipStatusEvaluator>();
                WipStatusEvaluator.GetWipStatus(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(WipStatusEnum.Editable);
                FunctionSecurityProvider = Substitute.For<IFunctionSecurityProvider>();
                FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, Arg.Any<User>(), Arg.Any<int>()).Returns(true);
                SecurityContext = Substitute.For<ISecurityContext>();
                CurrentUser = new UserBuilder(db).Build();
                SecurityContext.User.Returns(CurrentUser);
                TimesheetList = Substitute.For<ITimesheetList>();
                Subject = new PostedTimeController(db, PostedWipAdjustor, DiaryUpdate, Mapper, ValidatePostDates, WipStatusEvaluator, SecurityContext, FunctionSecurityProvider, TimesheetList);
            }

            public User CurrentUser { get; set; }

            public ITimesheetList TimesheetList { get; set; }
            public IFunctionSecurityProvider FunctionSecurityProvider { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public IWipStatusEvaluator WipStatusEvaluator { get; set; }
            public IValidatePostDates ValidatePostDates { get; set; }
            public IMapper Mapper { get; set; }
            public IDiaryUpdate DiaryUpdate { get; set; }
            public IPostedWipAdjustor PostedWipAdjustor { get; set; }
            public PostedTimeController Subject { get; }
        }
    }
}