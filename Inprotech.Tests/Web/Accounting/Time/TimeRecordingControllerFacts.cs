using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using AutoMapper;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Messages;
using InprotechKaizen.Model.Security;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;
using Exception = System.Exception;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class TimeRecordingControllerFacts
    {
        public class Save : FactBase
        {
            [Fact]
            public async Task ReturnsErrorWhenNoEntryProvided()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Save(null));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await Db.DidNotReceive().SaveChangesAsync();
                await f.WipCosting.DidNotReceiveWithAnyArgs().For(Arg.Any<RecordableTime>());
            }

            [Fact]
            public async Task ShouldNotAllowUpdatingOfEntry()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today(),
                    CaseKey = Fixture.Integer(),
                    NameKey = null,
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today(),
                    EntryNo = Fixture.Integer()
                };
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Save(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await Db.DidNotReceive().SaveChangesAsync();
                await f.WipCosting.DidNotReceiveWithAnyArgs().For(Arg.Any<RecordableTime>());
            }

            [Fact]
            public async Task ThrowsExceptionIfCaseHasRestriction()
            {
                var caseKey = Fixture.Integer();
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today(),
                    CaseKey = caseKey,
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today()
                };
                var f = new TimeRecordingControllerFixture(Db);
                f.WipWarningCheck.For(caseKey, null).Throws(new HttpResponseException(HttpStatusCode.BadRequest));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Save(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipWarningCheck.Received().For(caseKey, null);
                await f.WipCosting.DidNotReceive().For(Arg.Any<RecordableTime>());
                await Db.DidNotReceive().SaveChangesAsync();
            }

            [Fact]
            public async Task ThrowsExceptionIfNameForDebtorOnlyEntryIsRestricted()
            {
                var nameKey = Fixture.Integer();
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today(),
                    NameKey = nameKey,
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today()
                };
                var f = new TimeRecordingControllerFixture(Db);
                f.WipWarningCheck.For(null, nameKey).Throws(new HttpResponseException(HttpStatusCode.BadRequest));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Save(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipWarningCheck.Received().For(null, nameKey);
                await f.WipCosting.DidNotReceive().For(Arg.Any<RecordableTime>());
                await Db.DidNotReceive().SaveChangesAsync();
            }

            [Fact]
            public async Task SaveTimeForOtherStaff()
            {
                var nameId = Fixture.Integer();
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today(),
                    StaffId = nameId,
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today(),
                };

                var f = new TimeRecordingControllerFixture(Db);
                f.DiaryUpdate.AddEntry(Arg.Any<RecordableTime>()).ReturnsForAnyArgs(new TimeEntry() {EntryNo = 10});
                await f.Subject.Save(input);
                f.DiaryUpdate.Received(1).AddEntry(Arg.Is<RecordableTime>(_ => _ == input)).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ThrowsExceptionIfNotAllowedForStaff()
            {
                var staffId = Fixture.Integer();
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today(),
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today(),
                    StaffId = staffId
                };
                var f = new TimeRecordingControllerFixture(Db);
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanInsert, Arg.Any<User>(), staffId).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Save(input));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                await Db.DidNotReceive().SaveChangesAsync();
            }
        }

        public class DeleteForStaff : FactBase
        {
            [Fact]
            public async Task DeleteTime()
            {
                var entryNo = Fixture.Short();
                var f = new TimeRecordingControllerFixture(Db, false);
                var entry = new DiaryBuilder(Db) {StaffId = f.CurrentStaffId, EntryNo = entryNo}.BuildWithCase();
                f.DiaryUpdate.DeleteEntry(Arg.Any<RecordableTime>()).Returns(entry);

                var entryToDelete = new RecordableTime {EntryNo = entryNo};
                await f.Subject.DeleteStaffTimeEntry(entryToDelete);
                f.DiaryUpdate.Received(1).DeleteEntry(entryToDelete).IgnoreAwaitForNSubstituteAssertion();

                f.Bus.DidNotReceive().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task DeletesTimerAndPublishesMessage()
            {
                var entryNo = Fixture.Short();
                var f = new TimeRecordingControllerFixture(Db, false);
                var entry = new DiaryBuilder(Db) {StaffId = f.CurrentStaffId, EntryNo = entryNo, IsTimer = true}.BuildWithCase();
                f.DiaryUpdate.DeleteEntry(Arg.Any<RecordableTime>()).Returns(entry);

                var entryToDelete = new RecordableTime {EntryNo = entryNo};
                await f.Subject.DeleteStaffTimeEntry(entryToDelete);
                f.DiaryUpdate.Received(1).DeleteEntry(Arg.Is(entryToDelete)).IgnoreAwaitForNSubstituteAssertion();

                f.Bus.Received(1).Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task DeleteTimeForOtherStaff(bool isTimer)
            {
                var entryNo = Fixture.Short();
                var f = new TimeRecordingControllerFixture(Db, false);
                new DiaryBuilder(Db) {StaffId = f.CurrentStaffId, EntryNo = entryNo, IsTimer = isTimer}.BuildWithCase();
                var entry = new DiaryBuilder(Db) {StaffId = f.CurrentStaffId + 1, EntryNo = entryNo, IsTimer = isTimer}.BuildWithCase();
                f.DiaryUpdate.DeleteEntry(Arg.Any<RecordableTime>()).Returns(entry);

                var entryToDelete = new RecordableTime {EntryNo = entryNo, StaffId = f.CurrentStaffId + 1};
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, f.CurrentUser, entryToDelete.StaffId).Returns(true);

                await f.Subject.DeleteStaffTimeEntry(entryToDelete);
                f.DiaryUpdate.Received(1).DeleteEntry(Arg.Is(entryToDelete)).IgnoreAwaitForNSubstituteAssertion();

                f.Bus.DidNotReceive().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task ThrowsExceptionIfEntryNoNotPresent()
            {
                var f = new TimeRecordingControllerFixture(Db, false);
                f.DiaryUpdate.DeleteEntry(Arg.Any<RecordableTime>()).Throws(new Exception());

                await Assert.ThrowsAsync<Exception>(async () => await f.Subject.DeleteStaffTimeEntry(new RecordableTime {EntryNo = 1}));
                f.Bus.DidNotReceive().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task ThrowsExceptionIfNotAllowedToDeleteForOtherStaff()
            {
                var newEntryForStaff = Fixture.Short();
                var newStaffId = Fixture.Integer();
                var f = new TimeRecordingControllerFixture(Db, false);

                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, f.CurrentUser, newStaffId).Returns(false);
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, f.CurrentUser, newStaffId + 1).Returns(true);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.DeleteStaffTimeEntry(new RecordableTime {EntryNo = newEntryForStaff, StaffId = newStaffId}));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                await Db.DidNotReceive().SaveChangesAsync();
                f.Bus.DidNotReceive().Publish(Arg.Any<BroadcastMessageToClient>());
            }
        }

        public class DefaultActivityForCase : FactBase
        {
            [Fact]
            public async Task ReturnsActivityAndNarrativeWhereAvailable()
            {
                var caseId = Fixture.Integer();
                var wipDefaults = new WipDefaults
                {
                    WIPTemplateKey = Fixture.RandomString(6), 
                    WIPTemplateDescription = Fixture.RandomString(30), 
                    NarrativeKey = Fixture.Short(), 
                    NarrativeTitle = Fixture.RandomString(50), 
                    NarrativeText = Fixture.String()
                };
                var f = new TimeRecordingControllerFixture(Db);
                f.WipDefaulting.ForCase(Arg.Any<WipTemplateFilterCriteria>(),
                                        Arg.Any<int>()).Returns(wipDefaults);
                var result = await f.Subject.DefaultWipFromCase(caseId);
                await f.WipDefaulting.Received(1)
                       .ForCase(Arg.Is<WipTemplateFilterCriteria>(_ => _.WipCategory.IsServices == true && _.UsedByApplication.IsTimesheet == true && _.ContextCriteria.CaseKey == caseId), caseId);
                Assert.Equal(wipDefaults.WIPTemplateKey, result.Activity.Key);
                Assert.Equal(wipDefaults.WIPTemplateDescription, result.Activity.Value);
                Assert.Equal(wipDefaults.NarrativeKey, result.Narrative.Key);
                Assert.Equal(wipDefaults.NarrativeTitle, result.Narrative.Value);
                Assert.Equal(wipDefaults.NarrativeText, result.Narrative.Text);
            }
        }

        public class GetDefaultNarrative : FactBase
        {
            [Fact]
            public async Task GetsDefaultForActivity()
            {
                var activityKey = Fixture.RandomString(6);
                var f = new TimeRecordingControllerFixture(Db);
                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int>()).Returns(new BestNarrative {Key = 123});
                var result = await f.Subject.DefaultNarrative(activityKey);
                await f.BestNarrativeResolver.Received(1).Resolve(Arg.Any<string>(), activityKey, f.CurrentStaffId);
                Assert.Equal(123, result.Key);
            }

            [Fact]
            public async Task GetsDefaultForActivityAndStaff()
            {
                var activityKey = Fixture.RandomString(6);
                var staffNameId = Fixture.Integer();
                var f = new TimeRecordingControllerFixture(Db);
                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int>()).Returns(new BestNarrative {Key = 789});
                var result = await f.Subject.DefaultNarrative(activityKey, staffNameId: staffNameId);
                await f.BestNarrativeResolver.Received(1).Resolve(Arg.Any<string>(), activityKey, staffNameId: staffNameId);
                Assert.Equal(789, result.Key);
            }

            [Fact]
            public async Task GetsDefaultForActivityAndCase()
            {
                var activityKey = Fixture.RandomString(6);
                var caseKey = Fixture.Integer();
                var f = new TimeRecordingControllerFixture(Db);
                await f.Subject.DefaultNarrative(activityKey, caseKey);
                await f.BestNarrativeResolver.Received(1).Resolve(Arg.Any<string>(), activityKey, f.CurrentStaffId, caseKey);
            }

            [Fact]
            public async Task GetsDefaultForActivityAndDebtorIfNoCaseSpecified()
            {
                var activityKey = Fixture.RandomString(6);
                
                var debtorKey = Fixture.Integer();
                var f = new TimeRecordingControllerFixture(Db);
                await f.Subject.DefaultNarrative(activityKey, null, debtorKey);
                await f.BestNarrativeResolver.Received(1).Resolve(Arg.Any<string>(), activityKey, f.CurrentStaffId, null, debtorKey);
            }
        }

        public class CheckStatus : FactBase
        {
            [Fact]
            public async Task CallsServiceToCheckStatus()
            {
                var caseKey = Fixture.Integer();
                var f = new TimeRecordingControllerFixture(Db);
                await f.Subject.CheckStatus(caseKey);
                await f.WipWarnings.Received(1).AllowWipFor(caseKey);
            }
        }

        public class UpdateTime : FactBase
        {
            [Fact]
            public async Task ChecksFunctionSecurity()
            {
                var f = new TimeRecordingControllerFixture(Db);
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanUpdate, Arg.Any<User>(), Arg.Any<int?>()).Returns(false);
                var request = new RecordableTime {EntryNo = 1};

                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Update(request));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ReturnsErrorWhenNoEntryNumberProvided()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today(),
                    CaseKey = Fixture.Integer(),
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today()
                };
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Update(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await Db.DidNotReceive().SaveChangesAsync();
                await f.WipCosting.DidNotReceiveWithAnyArgs().For(Arg.Any<RecordableTime>());
            }

            [Fact]
            public async Task ReturnsErrorWhenNoEntryProvided()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Update(null));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await Db.DidNotReceive().SaveChangesAsync();
                await f.WipCosting.DidNotReceiveWithAnyArgs().For(Arg.Any<RecordableTime>());
            }

            [Fact]
            public async Task DoesNotUpdateIfThereAreWipWarnings()
            {
                var nameId = Fixture.Integer();
                var staffId = Fixture.Integer();
                var f = new TimeRecordingControllerFixture(Db);
                f.WipWarningCheck.For(Arg.Any<int?>(), Arg.Any<int?>()).Throws(new HttpResponseException(HttpStatusCode.BadRequest));
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today(),
                    CaseKey = null,
                    NameKey = nameId,
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today(),
                    EntryNo = f.EntryNo,
                    StaffId = staffId
                };
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Update(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.DiaryUpdate.DidNotReceive().UpdateEntry(Arg.Any<RecordableTime>());
            }

            [Fact]
            public async Task ThrowsExceptionIfUpdateUnsuccessful()
            {
                var nameId = Fixture.Integer();
                var staffId = Fixture.Integer();
                var f = new TimeRecordingControllerFixture(Db);
                f.DiaryUpdate.UpdateEntry(Arg.Any<RecordableTime>()).Throws(new HttpResponseException(HttpStatusCode.Forbidden));
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today(),
                    CaseKey = null,
                    NameKey = nameId,
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today(),
                    EntryNo = f.EntryNo,
                    StaffId = staffId
                };
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Update(input));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ReturnsWhenUpdateIsSuccessful()
            {
                var input = new RecordableTime()
                {
                    EntryNo = Fixture.Integer(),
                    CaseKey = Fixture.Integer(),
                    NameKey = Fixture.Integer(),
                    Start = Fixture.Today().AddHours(8),
                    TotalTime = Fixture.BaseDate().AddMinutes(10)
                };
                var f = new TimeRecordingControllerFixture(Db);
                f.DiaryUpdate.UpdateEntry(Arg.Any<RecordableTime>()).Returns(Task.FromResult(new TimeEntry {EntryNo = input.EntryNo}));
                var result = await f.Subject.Update(input);
                await f.WipWarningCheck.Received(1).For(input.CaseKey, input.NameKey);
                await f.DiaryUpdate.Received(1).UpdateEntry(input);
                Assert.Equal(input.EntryNo, result.Response.EntryNo);
            }
        }

        public class UpdateEntryDate : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionIfNoEntryNo()
            {
                var f = new TimeRecordingControllerFixture(Db);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UpdateDate(new RecordableTime()));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionIfNotAllowedForStaff()
            {
                var staffId = Fixture.Integer();
                var input = new RecordableTime
                {
                    EntryNo = 10,
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    StaffId = staffId
                };
                var f = new TimeRecordingControllerFixture(Db);
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanUpdate, Arg.Any<User>(), staffId).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UpdateDate(input));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                f.DiaryUpdate.DidNotReceive().UpdateDate(Arg.Any<RecordableTime>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task CallsDiaryUpdator()
            {
                var staffId = Fixture.Integer();
                var input = new RecordableTime
                {
                    EntryNo = 10,
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    StaffId = staffId
                };
                var f = new TimeRecordingControllerFixture(Db);
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanUpdate, Arg.Any<User>(), staffId).Returns(true);
                await f.Subject.UpdateDate(input);
                f.DiaryUpdate.Received(1).UpdateDate(input).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class EvaluateTime : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task CallsCommandToGetTimeValuation(bool forOtherStaff)
            {
                var totalTime = new TimeSpan(0, 10, 10, 10);
                var timeCarriedForward = new TimeSpan(0, 2, 20, 20);
                var input = new RecordableTime
                {
                    TotalTime = new DateTime(2020, 1, 1).Add(totalTime),
                    TimeCarriedForward = new DateTime(2020, 1, 1).Add(timeCarriedForward),
                    NameKey = Fixture.Integer(),
                    CaseKey = Fixture.Integer(),
                    Activity = "Blue"
                };
                if (forOtherStaff)
                    input.StaffId = Fixture.Integer();

                var f = new TimeRecordingControllerFixture(Db);
                await f.Subject.EvaluateTime(input);
                await f.ValueTime.Received(1).For(Arg.Is<RecordableTime>(_ => _ == input), "fr-FR");
            }
        }

        public class PreviewCost : FactBase
        {
            [Fact]
            public async Task RetrievesCostForAdjustedValue()
            {
                var newLocalAmount = Fixture.Decimal();
                var request = new WipCost {LocalValueBeforeMargin = newLocalAmount};

                var f = new TimeRecordingControllerFixture(Db);
                f.WipCosting.For(Arg.Any<WipCost>()).Returns(new WipCost {LocalValue = newLocalAmount + 10, LocalValueBeforeMargin = newLocalAmount});
                var result = await f.Subject.CostPreview(request);

                await f.WipCosting.Received(1).For(Arg.Is<WipCost>(_ => _.LocalValueBeforeMargin == newLocalAmount && _.StaffKey == f.CurrentStaffId));
                Assert.Equal(newLocalAmount + 10, result.LocalValue);
                Assert.Equal(newLocalAmount, result.LocalValueBeforeMargin);
            }

            [Fact]
            public async Task RetrievesCostForAdjustedForeignValue()
            {
                var newForeignAmount = Fixture.Decimal();
                var request = new WipCost {ForeignValueBeforeMargin = newForeignAmount};

                var f = new TimeRecordingControllerFixture(Db);
                f.WipCosting.For(Arg.Any<WipCost>()).Returns(new WipCost {LocalValue = newForeignAmount - 10, ForeignValue = newForeignAmount + 10, ForeignValueBeforeMargin = newForeignAmount});
                var result = await f.Subject.CostPreview(request);

                await f.WipCosting.Received(1).For(Arg.Is<WipCost>(_ => _.ForeignValueBeforeMargin == newForeignAmount && _.StaffKey == f.CurrentStaffId));
                Assert.Equal(newForeignAmount + 10, result.ForeignValue);
                Assert.Equal(newForeignAmount, result.ForeignValueBeforeMargin);
                Assert.Equal(newForeignAmount - 10, result.LocalValue);
            }
        }

        public class UpdateValue : FactBase
        {
            [Fact]
            public async Task ChecksFunctionSecurity()
            {
                var f = new TimeRecordingControllerFixture(Db);
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanAdjustValue, Arg.Any<User>(), Arg.Any<int?>()).Returns(false);
                var request = new TimeCost
                {
                    LocalValue = Fixture.Decimal(),
                    StaffKey = f.CurrentStaffId,
                    EntryNo = f.EntryNo
                };
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UpdateValue(request));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                await f.WipWarnings.DidNotReceive().AllowWipFor(Arg.Any<int>());
                await f.WipWarnings.DidNotReceive().HasDebtorRestriction(Arg.Any<int>());
                await f.DbContext.DidNotReceive().SaveChangesAsync();
            }

            [Fact]
            public async Task EnsuresRecordabilityOfCase()
            {
                var caseKey = Fixture.Integer();
                var f = new TimeRecordingControllerFixture(Db);
                var request = new TimeCost
                {
                    LocalValue = Fixture.Decimal(),
                    LocalDiscount = Fixture.Decimal(),
                    LocalMargin = Fixture.Decimal(),
                    CaseKey = caseKey,
                    StaffKey = f.CurrentStaffId,
                    EntryNo = f.EntryNo
                };
                f.WipWarnings.AllowWipFor(Arg.Any<int>()).Returns(true);
                f.WipWarnings.HasDebtorRestriction(Arg.Any<int>()).Returns(false);

                await f.Subject.UpdateValue(request);
                await f.WipWarningCheck.Received(1).For(caseKey, null);
                await f.WipWarnings.DidNotReceive().HasNameRestriction(Arg.Any<int>());
            }

            [Fact]
            public async Task EnsuresRecordabilityOfName()
            {
                var nameKey = Fixture.Integer();
                var f = new TimeRecordingControllerFixture(Db);
                var request = new TimeCost
                {
                    LocalValue = Fixture.Decimal(),
                    LocalDiscount = Fixture.Decimal(),
                    LocalMargin = Fixture.Decimal(),
                    NameKey = nameKey,
                    StaffKey = f.CurrentStaffId,
                    EntryNo = f.EntryNo
                };

                await f.Subject.UpdateValue(request);
                await f.WipWarningCheck.Received(1).For(null, nameKey);
            }

            [Fact]
            public async Task ThrowsExceptionIfEntryNotFound()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var request = new TimeCost
                {
                    LocalValue = Fixture.Decimal(),
                    LocalDiscount = Fixture.Decimal(),
                    LocalMargin = Fixture.Decimal(),
                    StaffKey = f.CurrentStaffId,
                    EntryNo = f.EntryNo + 999
                };

                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UpdateValue(request));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.DbContext.DidNotReceive().SaveChangesAsync();
            }

            [Fact]
            public async Task ThrowsExceptionIfMultiDebtorEntry()
            {
                var f = new TimeRecordingControllerFixture(Db);
                new Diary() {EntryNo = f.EntryNo + 999, EmployeeNo = f.CurrentStaffId, DebtorSplits = new List<DebtorSplitDiary>() {new DebtorSplitDiary().In(Db)}}.In(Db);
                var request = new TimeCost
                {
                    LocalValue = Fixture.Decimal(),
                    LocalDiscount = Fixture.Decimal(),
                    LocalMargin = Fixture.Decimal(),
                    StaffKey = f.CurrentStaffId,
                    EntryNo = f.EntryNo + 999
                };

                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UpdateValue(request));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.DbContext.DidNotReceive().SaveChangesAsync();
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task SavesAdjustedValuesToDatabase(bool forOtherStaff)
            {
                var f = new TimeRecordingControllerFixture(Db);
                var entryNo = Fixture.Integer();
                var request = new TimeCost
                {
                    LocalValue = Fixture.Decimal(),
                    LocalDiscount = Fixture.Decimal(),
                    ForeignValue = Fixture.Decimal(),
                    ForeignDiscount = Fixture.Decimal(),
                    LocalMargin = Fixture.Decimal(),
                    StaffKey = forOtherStaff ? Fixture.Integer() : f.CurrentStaffId,
                    EntryNo = forOtherStaff ? entryNo : f.EntryNo,
                    ExchangeRate = Fixture.Decimal(false, 4),
                    MarginNo = Fixture.Integer()
                };
                new DiaryBuilder(Db) {StaffId = request.StaffKey, EntryNo = entryNo, TotalUnits = 100, UnitsPerHour = 10}.BuildWithCase(true);
                await f.Subject.UpdateValue(request);

                await f.DbContext.Received(1).SaveChangesAsync();
                var updatedEntry = f.DbContext.Set<Diary>().Single(_ => _.EmployeeNo == request.StaffKey && _.EntryNo == request.EntryNo);
                Assert.Equal(request.LocalValue, updatedEntry.TimeValue);
                Assert.Equal(request.LocalDiscount, updatedEntry.DiscountValue);
                Assert.Equal(request.ForeignValue, updatedEntry.ForeignValue);
                Assert.Equal(request.ForeignDiscount, updatedEntry.ForeignDiscount);
                Assert.Equal(request.ExchangeRate, updatedEntry.ExchRate);
                Assert.Equal(request.MarginNo, updatedEntry.MarginId);
                Assert.Equal(request.StaffKey, updatedEntry.EmployeeNo);
            }

            [Fact]
            public async Task SavesAdjustedChargeRateToDatabase()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var entryNo = f.NextEntryNo + 3;
                new DiaryBuilder(Db) {StaffId = f.CurrentUser.NameId, EntryNo = entryNo, TotalUnits = 100, UnitsPerHour = 10}.BuildWithCase(true);
                var request = new TimeCost
                {
                    LocalValue = Fixture.Decimal(),
                    LocalDiscount = Fixture.Decimal(),
                    ForeignValue = Fixture.Decimal(),
                    ForeignDiscount = Fixture.Decimal(),
                    LocalMargin = Fixture.Decimal(),
                    StaffKey = f.CurrentStaffId,
                    EntryNo = entryNo
                };

                await f.Subject.UpdateValue(request);

                await f.DbContext.Received(1).SaveChangesAsync();
                var updatedEntry = f.DbContext.Set<Diary>().Single(_ => _.EmployeeNo == f.CurrentStaffId && _.EntryNo == entryNo);
                Assert.Equal(request.LocalValue, updatedEntry.TimeValue);
                Assert.Equal(request.LocalDiscount, updatedEntry.DiscountValue);
                Assert.Equal(request.ForeignValue, updatedEntry.ForeignValue);
                Assert.Equal(request.ForeignDiscount, updatedEntry.ForeignDiscount);
                Assert.Equal(Math.Round((decimal) request.ForeignValue / 10, 2, MidpointRounding.AwayFromZero), updatedEntry.ChargeOutRate);
            }
        }

        public class SaveTimeGaps : FactBase
        {
            [Fact]
            public async Task ThrowsErrorWhenNoGapsSpecified()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.SaveGaps(new TimeGap[] { }));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.FunctionSecurity.DidNotReceive().FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int?>());
                await f.DbContext.DidNotReceive().SaveChangesAsync();
            }

            [Fact]
            public async Task ChecksFunctionSecurity()
            {
                var f = new TimeRecordingControllerFixture(Db);
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanInsert, Arg.Any<User>(), Arg.Any<int?>()).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.SaveGaps(new[] {new TimeGap {EntryDate = Fixture.Today(), StaffId = f.CurrentStaffId}}));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                await f.DbContext.DidNotReceive().SaveChangesAsync();
            }

            [Fact]
            public async Task SaveTimeWithIncrementedEntryNo()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var input = new TimeGap
                {
                    StaffId = f.CurrentStaffId + Fixture.Integer(),
                    StartTime = Fixture.Today(),
                    FinishTime = Fixture.Today(),
                    EntryDate = Fixture.Today()
                };
                await f.Subject.SaveGaps(new[] {input});
                await f.FunctionSecurity.Received(1).FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanInsert, f.CurrentUser, input.StaffId);
                await f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "fr-FR");
                Assert.NotNull(Db.Set<Diary>().Single(_ => _.EmployeeNo == input.StaffId && _.CaseId == null && _.NameNo == null && _.Activity == null && _.EntryNo == 0));
            }

            [Fact]
            public async Task SaveMultipleTimeGaps()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var staffId = f.CurrentStaffId + Fixture.Integer();
                var input1 = new TimeGap
                {
                    StaffId = staffId,
                    StartTime = Fixture.Today(),
                    FinishTime = Fixture.Today(),
                    EntryDate = Fixture.Today()
                };
                var input2 = new TimeGap
                {
                    StaffId = staffId,
                    StartTime = Fixture.Today(),
                    FinishTime = Fixture.Today(),
                    EntryDate = Fixture.Today()
                };
                await f.Subject.SaveGaps(new[] {input1, input2});
                await f.FunctionSecurity.Received(1).FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanInsert, f.CurrentUser, staffId);
                await f.ValueTime.Received(2).For(Arg.Any<RecordableTime>(), "fr-FR");
                Assert.Equal(2, Db.Set<Diary>().Count(_ => _.EmployeeNo == staffId && _.CaseId == null && _.NameNo == null && _.Activity == null));
                Assert.NotNull(Db.Set<Diary>().Single(_ => _.EmployeeNo == staffId && _.CaseId == null && _.NameNo == null && _.Activity == null && _.EntryNo == 0));
                Assert.NotNull(Db.Set<Diary>().Single(_ => _.EmployeeNo == staffId && _.CaseId == null && _.NameNo == null && _.Activity == null && _.EntryNo == 1));
            }
        }

        public class DeleteContinuedChain : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionWhenTimeEntryHasNoEntryNo()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.DeleteChain(new RecordableTime()));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.FunctionSecurity.DidNotReceive().FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int?>());
                f.DiaryUpdate.DidNotReceive().DeleteChainFor(Arg.Any<RecordableTime>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ChecksFunctionSecurity()
            {
                var f = new TimeRecordingControllerFixture(Db);
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, Arg.Any<User>(), Arg.Any<int?>()).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.DeleteChain(new RecordableTime {EntryNo = Fixture.Integer(), StaffId = f.CurrentStaffId}));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                f.DiaryUpdate.DidNotReceive().DeleteChainFor(Arg.Any<RecordableTime>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task CallsToDeleteChain()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var input = new RecordableTime {EntryNo = Fixture.Integer(), StaffId = f.CurrentStaffId};
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, Arg.Any<User>(), Arg.Any<int?>()).Returns(true);
                await f.Subject.DeleteChain(input);

                f.DiaryUpdate.Received(1).DeleteChainFor(Arg.Is<RecordableTime>(_ => _ == input)).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class Copy : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionIfNotAllowedForStaff()
            {
                var staffId = Fixture.Integer();
                var input = new TimeRecordingController.TimeCopyRequest
                {
                    EntryNo = Fixture.Integer(),
                    StaffId = staffId,
                    Start = Fixture.Date()
                };
                var f = new TimeRecordingControllerFixture(Db);
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanInsert, Arg.Any<User>(), staffId).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Copy(input));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                await f.WipCosting.DidNotReceive().For(Arg.Any<RecordableTime>());
                await Db.DidNotReceive().SaveChangesAsync();
            }

            [Fact]
            public async Task ThrowsExceptionIfEnryNoFound()
            {
                var staffId = Fixture.Integer();
                var input = new TimeRecordingController.TimeCopyRequest
                {
                    EntryNo = Fixture.Integer(),
                    StaffId = staffId,
                    Start = Fixture.Date()
                };
                var f = new TimeRecordingControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Copy(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipCosting.DidNotReceive().For(Arg.Any<RecordableTime>());
                await Db.DidNotReceive().SaveChangesAsync();
            }

            [Fact]
            public async Task ThrowsExceptionIfDateRangeMoreThan3Months()
            {
                var staffId = Fixture.Integer();
                var input = new TimeRecordingController.TimeCopyRequest
                {
                    EntryNo = Fixture.Integer(),
                    StaffId = staffId,
                    Start = Fixture.Date(),
                    End = Fixture.Date().AddMonths(3).AddDays(1)
                };
                var f = new TimeRecordingControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Copy(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipCosting.DidNotReceive().For(Arg.Any<RecordableTime>());
                await Db.DidNotReceive().SaveChangesAsync();
            }

            [Fact]
            public async Task DuplicatesEntryForSpecifiedDays()
            {
                var f = new TimeRecordingControllerFixture(Db);
                var staffId = Fixture.Integer();
                var entryNo = Fixture.Integer();
                var date = Fixture.Today();
                var entryStart = Fixture.Short(10);
                var @case = new CaseBuilder().Build().In(Db);
                var diary = new DiaryBuilder(Db) {Case = @case, NarrativeNo = Fixture.Short(), StaffId = staffId, StartTime = Fixture.Monday.AddHours(entryStart), EntryNo = entryNo}.BuildWithCase();
                f.DiaryUpdate.AddEntries(Arg.Any<Diary>(), Arg.Any<IOrderedEnumerable<DateTime>>()).ReturnsForAnyArgs(Task.FromResult(1));
                var input = new TimeRecordingController.TimeCopyRequest
                {
                    EntryNo = entryNo,
                    StaffId = staffId,
                    Start = date,
                    End = date.AddDays(14),
                    Days = new[] {DayOfWeek.Monday, DayOfWeek.Tuesday}
                };

                var result = await f.Subject.Copy(input);
                f.DiaryUpdate.Received(1).AddEntries(Arg.Is<Diary>(_ => _ == diary),
                                                     Arg.Is<IOrderedEnumerable<DateTime>>(_ => _.First() == date.AddDays(2) && _.Skip(1).First() == date.AddDays(3) && _.Skip(2).First() == date.AddDays(9) && _.Skip(3).First() == date.AddDays(10)))
                 .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(1, result);
            }
        }

        public class TimeRecordingControllerFixture : IFixture<TimeRecordingController>
        {
            public TimeRecordingControllerFixture(InMemoryDbContext db, bool withEntries = true)
            {
                DbContext = db;
                EntryNo = Fixture.Short();
                Now = Substitute.For<Func<DateTime>>();
                Now().Returns(Fixture.Today());
                SecurityContext = Substitute.For<ISecurityContext>();
                CurrentUser = new UserBuilder(db).Build();
                SecurityContext.User.Returns(CurrentUser);
                NextEntryNo = EntryNo + 2;
                WipCosting = Substitute.For<IWipCosting>();
                WipCosting.For(Arg.Any<RecordableTime>()).Returns(new WipCost());
                WipCosting.For(Arg.Any<WipCost>()).Returns(new WipCost());
                WipDefaulting = Substitute.For<IWipDefaulting>();
                BestNarrativeResolver = Substitute.For<IBestTranslatedNarrativeResolver>();
                WipWarnings = Substitute.For<IWipWarnings>();
                WipWarnings.AllowWipFor(Arg.Any<int>()).Returns(true);
                WipWarnings.HasDebtorRestriction(Arg.Any<int>()).Returns(false);
                WipWarnings.HasNameRestriction(Arg.Any<int>()).Returns(false);

                ValueTime = Substitute.For<IValueTime>();
                ValueTime.For(Arg.Any<RecordableTime>(), Arg.Any<string>()).Returns(new TimeEntry());

                var m = new Mapper(new MapperConfiguration(cfg =>
                {
                    cfg.AddProfile(new AccountingProfile());
                    cfg.CreateMissingTypeMaps = true;
                }));
                Mapper = m.DefaultContext.Mapper.DefaultContext.Mapper;

                FunctionSecurity = Substitute.For<IFunctionSecurityProvider>();
                FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int?>()).Returns(true);

                DiaryUpdate = Substitute.For<IDiaryUpdate>();
                WipWarningCheck = Substitute.For<IWipWarningCheck>();
                WipWarningCheck.For(Arg.Any<int>(), Arg.Any<int>()).Returns(Task.FromResult(true));
                Bus = Substitute.For<IBus>();

                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                preferredCultureResolver.Resolve().Returns("fr-FR");

                Subject = new TimeRecordingController(db, SecurityContext, preferredCultureResolver, 
                                                      Now, WipCosting, WipDefaulting, BestNarrativeResolver, WipWarnings, Mapper, FunctionSecurity, DiaryUpdate, WipWarningCheck, Bus, ValueTime);

                if (!withEntries) return;
                TestEntry = new DiaryBuilder(db) {StaffId = CurrentUser.NameId, EntryNo = EntryNo}.BuildWithCase();
                new DiaryBuilder(db) {StaffId = CurrentUser.NameId, EntryNo = EntryNo + 1}.BuildWithCase();
            }

            public IValueTime ValueTime { get; set; }
            public IBus Bus { get; set; }
            public int NextEntryNo { get; }
            public int EntryNo { get; }
            public User CurrentUser { get; set; }
            public int CurrentStaffId => CurrentUser.NameId;
            public Diary TestEntry { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public Func<DateTime> Now { get; set; }
            public IWipCosting WipCosting { get; set; }
            public IWipDefaulting WipDefaulting { get; set; }
            public IBestTranslatedNarrativeResolver BestNarrativeResolver { get; set; }
            public IWipWarnings WipWarnings { get; }
            public IMapper Mapper { get; }
            public IFunctionSecurityProvider FunctionSecurity { get; set; }
            public IDiaryUpdate DiaryUpdate { get; set; }
            public IWipWarningCheck WipWarningCheck { get; set; }
            public InMemoryDbContext DbContext { get; }
            public TimeRecordingController Subject { get; }
        }
    }
}