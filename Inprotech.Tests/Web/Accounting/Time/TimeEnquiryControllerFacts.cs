using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Storage;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class InitialView : FactBase
    {
        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ReturnsDisplaySecondsAndLocalCurrencyCode(bool displayTimeWithSeconds)
        {
            var currencyCode = Fixture.RandomString(3);
            var f = new TimeEnquiryControllerFixture(Db);
            f.PreferenceManager.GetPreference<bool>(Arg.Any<int>(), KnownSettingIds.DisplayTimeWithSeconds).Returns(displayTimeWithSeconds);
            f.SiteControlReader.Read<string>(SiteControls.CURRENCY).Returns(currencyCode);
            var result = await f.Subject.ViewData();

            f.PreferenceManager.Received(1).GetPreference<bool>(f.CurrentUser.Id, KnownSettingIds.DisplayTimeWithSeconds);
            f.SiteControlReader.Received(1).Read<string>(SiteControls.CURRENCY);
            Assert.Equal(displayTimeWithSeconds, result.Settings.DisplaySeconds);
            Assert.Equal(currencyCode, result.Settings.LocalCurrencyCode);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ReturnsTimeEmptyForNewEntries(bool timeEmptyForNewEntries)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.SiteControlReader.Read<bool>(SiteControls.TimeEmptyForNewEntries).Returns(timeEmptyForNewEntries);
            var result = await f.Subject.ViewData();

            f.SiteControlReader.Received(1).Read<bool>(SiteControls.TimeEmptyForNewEntries);
            Assert.Equal(timeEmptyForNewEntries, result.Settings.TimeEmptyForNewEntries);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ReturnsAddNewEntryOnSave(bool addNewOnSave)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.PreferenceManager.GetPreference<bool>(Arg.Any<int>(), KnownSettingIds.AddEntryOnSave).Returns(addNewOnSave);
            var result = await f.Subject.ViewData();

            f.PreferenceManager.Received(1).GetPreference<bool>(f.CurrentUser.Id, KnownSettingIds.AddEntryOnSave);
            Assert.Equal(addNewOnSave, result.Settings.AddEntryOnSave);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ReturnsTimeFormat12Hours(bool timeFormat12Hours)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.PreferenceManager.GetPreference<bool>(Arg.Any<int>(), KnownSettingIds.TimeFormat12Hours).Returns(timeFormat12Hours);
            var result = await f.Subject.ViewData();

            f.PreferenceManager.Received(1).GetPreference<bool>(f.CurrentUser.Id, KnownSettingIds.TimeFormat12Hours);
            Assert.Equal(timeFormat12Hours, result.Settings.TimeFormat12Hours);
        }

        [Fact]
        public async Task ReturnsTimePickerIntervalSetting()
        {
            var f = new TimeEnquiryControllerFixture(Db);
            var timeInterval = Fixture.Integer();
            f.PreferenceManager.GetPreference<int>(Arg.Any<int>(), KnownSettingIds.TimePickerInterval).Returns(timeInterval);
            var result = await f.Subject.ViewData();

            f.PreferenceManager.Received(1).GetPreference<int>(f.CurrentUser.Id, KnownSettingIds.TimePickerInterval);
            Assert.Equal(timeInterval, result.Settings.TimePickerInterval);
        }

        [Fact]
        public async Task ReturnsDurationPickerIntervalSetting()
        {
            var f = new TimeEnquiryControllerFixture(Db);
            var timeInterval = Fixture.Integer();
            f.PreferenceManager.GetPreference<int>(Arg.Any<int>(), KnownSettingIds.DurationPickerInterval).Returns(timeInterval);
            var result = await f.Subject.ViewData();

            f.PreferenceManager.Received(1).GetPreference<int>(f.CurrentUser.Id, KnownSettingIds.DurationPickerInterval);
            Assert.Equal(timeInterval, result.Settings.DurationPickerInterval);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ChecksAbilityToAdjustUnitsForContinuedEntries(bool contEntryUnitsAdjust)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.SiteControlReader.Read<bool>(SiteControls.ContEntryUnitsAdjmt).Returns(contEntryUnitsAdjust);
            var result = await f.Subject.ViewData();

            f.SiteControlReader.Received(1).Read<bool>(SiteControls.ContEntryUnitsAdjmt);
            Assert.Equal(contEntryUnitsAdjust, result.Settings.EnableUnitsForContinuedTime);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ChecksOnWipSplitMultiDebtorFlag(bool wipSplitMultiDebtor)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.SiteControlReader.Read<bool>(SiteControls.WIPSplitMultiDebtor).Returns(wipSplitMultiDebtor);
            var result = await f.Subject.ViewData();

            f.SiteControlReader.Received(1).Read<bool>(SiteControls.ContEntryUnitsAdjmt);
            Assert.Equal(wipSplitMultiDebtor, result.Settings.WipSplitMultiDebtor);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ReturnsValueOnEdit(bool valueOnEdit)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.PreferenceManager.GetPreference<bool>(Arg.Any<int>(), KnownSettingIds.ValueTimeOnEntry).Returns(valueOnEdit);
            var result = await f.Subject.ViewData();

            f.PreferenceManager.Received(1).GetPreference<bool>(f.CurrentUser.Id, KnownSettingIds.ValueTimeOnEntry);
            Assert.Equal(valueOnEdit, result.Settings.ValueTimeOnEntry);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ReturnsAdjustValueFunctionSecurity(bool effective)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), FunctionSecurityPrivilege.CanAdjustValue, Arg.Any<User>()).Returns(effective);
            var result = await f.Subject.ViewData();

            await f.FunctionSecurityProvider.Received(1).FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanAdjustValue, f.CurrentUser);
            Assert.Equal(effective, result.UserInfo.CanAdjustValues);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ChecksIfUserCanFunctionAsOtherStaff(bool effective)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.FunctionSecurityProvider.ForOthers(Arg.Any<BusinessFunction>(), Arg.Any<User>()).Returns(new[]
            {
                new FunctionPrivilege { CanRead = effective }
            });

            var result = await f.Subject.ViewData();

            await f.FunctionSecurityProvider.Received(1).FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanAdjustValue, f.CurrentUser);
            Assert.Equal(effective, result.UserInfo.CanFunctionAsOtherStaff);
        }

        [Fact]
        public async Task ReturnsUserNameAndId()
        {
            var f = new TimeEnquiryControllerFixture(Db);
            var result = await f.Subject.ViewData();

            Assert.Equal(f.CurrentUser.Name.FormattedWithDefaultStyle(), result.UserInfo.DisplayName);
            Assert.Equal(f.CurrentUser.Name.Id, result.UserInfo.NameId);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ReturnsMaintainPostedTimeTaskSecurity(bool hasAccess)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>(), Arg.Any<ApplicationTaskAccessLevel>()).ReturnsForAnyArgs(hasAccess);
            var result = await f.Subject.ViewData();

            f.TaskSecurityProvider.Received(1).HasAccessTo(Arg.Is<ApplicationTask>(_ => _ == ApplicationTask.MaintainPostedTime), Arg.Is<ApplicationTaskAccessLevel>(l => l == ApplicationTaskAccessLevel.Modify));
            Assert.Equal(hasAccess, result.UserInfo.MaintainPostedTimeEdit);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(true)]
        [InlineData(false)]
        public async Task RetrievesDefaultCaseInfo(bool withCaseParam, bool withExistingCase = false)
        {
            var @case = new CaseBuilder().Build();
            if (withExistingCase)
            {
                @case.In(Db);
            }

            var f = new TimeEnquiryControllerFixture(Db);
            var result = await f.Subject.ViewData(caseId: withCaseParam ? @case.Id : (int?) null);
            Assert.Equal(withExistingCase ? @case.Id : (int?) null, result.DefaultInfo?.CaseId);
            Assert.Equal(withExistingCase ? @case.Irn : null, result.DefaultInfo?.CaseReference);
        }

        [Theory]
        [InlineData(true, true, true)]
        [InlineData(true, false, true)]
        [InlineData(false, true, true)]
        [InlineData(false, false, false)]
        public async Task RetrievesPermissionToViewAttachments(bool attachmentSubjectSecurity, bool dmsTaskSecurity, bool canViewCaseAttachments)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.SubjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments).ReturnsForAnyArgs(attachmentSubjectSecurity);
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.AccessDocumentsfromDms).ReturnsForAnyArgs(dmsTaskSecurity);

            var result = await f.Subject.ViewData();
            Assert.Equal(canViewCaseAttachments, result.CanViewCaseAttachments);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task RetrievesPermissionToPostForAll(bool canPostForAll)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, f.CurrentUser).Returns(canPostForAll);

            var result = await f.Subject.ViewData();
            Assert.Equal(canPostForAll, result.CanPostForAllStaff);
        }
    }

    public class UserPermissions : FactBase
    {
        [Theory]
        [InlineData(true)]
        public async Task ReturnsAllPermissionsForSelf(bool canAdjust)
        {
            var f = new TimeEnquiryControllerFixture(Db);
            f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanAdjustValue, f.CurrentUser).Returns(canAdjust);
            var result = await f.Subject.UserPermissions(f.CurrentUser.NameId);

            Assert.True(result.CanRead);
            Assert.True(result.CanInsert);
            Assert.True(result.CanUpdate);
            Assert.True(result.CanDelete);
            Assert.True(result.CanPost);
            Assert.Equal(canAdjust, result.CanAdjustValue);
        }

        [Fact]
        public async Task ReturnsFalseForNonStaff()
        {
            var value = new FunctionPrivilege
            {
                CanRead = true,
                CanInsert = true,
                CanUpdate = true,
                CanDelete = true,
                CanPost = true,
                CanAdjustValue = true
            };

            var f = new TimeEnquiryControllerFixture(Db, false);
            f.FunctionSecurityProvider.BestFit(BusinessFunction.TimeRecording, f.CurrentUser, Arg.Any<int?>()).Returns(value);
            var result = await f.Subject.UserPermissions(f.CurrentUser.NameId);
            Assert.False(result.CanRead);
            Assert.False(result.CanInsert);
            Assert.False(result.CanUpdate);
            Assert.False(result.CanDelete);
            Assert.False(result.CanPost);
            Assert.False(result.CanAdjustValue);
        }

        [Fact]
        public async Task ReturnsResultsFromTimeRecordingFunctionSecurity()
        {
            var otherStaff = new NameBuilder(Db){UsedAs = NameUsedAs.Individual + NameUsedAs.StaffMember}.Build().In(Db);
            var value = new FunctionPrivilege
            {
                CanRead = true,
                CanInsert = false,
                CanUpdate = true,
                CanDelete = false,
                CanPost = true,
                CanAdjustValue = true
            };

            var f = new TimeEnquiryControllerFixture(Db);
            f.FunctionSecurityProvider.BestFit(BusinessFunction.TimeRecording, f.CurrentUser, Arg.Any<int?>()).Returns(value);

            var result = await f.Subject.UserPermissions(otherStaff.Id);
            Assert.Equal(value.CanRead, result.CanRead);
            Assert.Equal(value.CanInsert, result.CanInsert);
            Assert.Equal(value.CanUpdate, result.CanUpdate);
            Assert.Equal(value.CanDelete, result.CanDelete);
            Assert.Equal(value.CanPost, result.CanPost);
            Assert.Equal(value.CanAdjustValue, result.CanAdjustValue);
        }
    }

    public class ListEntries : FactBase
    {
        [Fact]
        public async Task CallsTheServiceToRetrieveData()
        {
            var selectedDate = Fixture.Today();
            var f = new TimeEnquiryControllerFixture(Db);
            await f.Subject.ListTime(new TimeEnquiryController.TimesheetQuery
            {
                SelectedDate = selectedDate
            }, new CommonQueryParameters {SortBy = "StartTime"});
            await f.TimesheetList.Received(1).For(f.CurrentUser.NameId, selectedDate);
        }

        [Fact]
        public async Task ReturnsListForSpecificStaff()
        {
            var selectedDate = Fixture.Date();
            var staffNameId = Fixture.Integer();
            var f = new TimeEnquiryControllerFixture(Db);
            f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, f.CurrentUser, Arg.Any<int?>()).Returns(true);
            await f.Subject.ListTime(new TimeEnquiryController.TimesheetQuery
            {
                SelectedDate = selectedDate,
                StaffNameId = staffNameId
            }, new CommonQueryParameters {SortBy = "StartTime"});

            await f.TimesheetList.Received(1).For(staffNameId, selectedDate);
        }

        [Fact]
        public async Task ReturnsErrorDueToFunctionSecurity()
        {
            var selectedDate = Fixture.Date();
            var staffNameId = Fixture.Integer();
            var f = new TimeEnquiryControllerFixture(Db);
            f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, Arg.Any<User>(), Arg.Any<int>()).Returns(false);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.ListTime(new TimeEnquiryController.TimesheetQuery
            {
                SelectedDate = selectedDate,
                StaffNameId = staffNameId
            }, CommonQueryParameters.Default));
            Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);

            await f.TimesheetList.DidNotReceive().For(Arg.Any<int>(), Arg.Any<DateTime>());
            f.TimeSummaryProvider.DidNotReceive().Get(Arg.Any<IQueryable<TimeEntry>>()).IgnoreAwaitForNSubstituteAssertion();
        }
    }

    public class GetTimeGaps : FactBase
    {
        [Fact]
        public async Task CallsTheServiceToRetrieveGapsForCurrentStaff()
        {
            var selectedDate = Fixture.Date();
            var f = new TimeEnquiryControllerFixture(Db);
            await f.Subject.GetTimeGaps(new TimeEnquiryController.TimesheetQuery
            {
                SelectedDate = selectedDate
            });
            await f.TimesheetList.Received(1).TimeGapFor(f.CurrentUser.NameId, selectedDate);
        }

        [Fact]
        public async Task ChecksFunctionSecurityWhereRequired()
        {
            var selectedDate = Fixture.Date();
            var staffNameId = Fixture.Integer();
            var f = new TimeEnquiryControllerFixture(Db);
            f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, Arg.Any<User>(), Arg.Any<int>()).Returns(true);
            await f.Subject.GetTimeGaps(new TimeEnquiryController.TimesheetQuery
            {
                SelectedDate = selectedDate,
                StaffNameId = staffNameId
            });
            await f.FunctionSecurityProvider.Received(1).FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, f.CurrentUser, staffNameId);
            await f.TimesheetList.Received(1).TimeGapFor(staffNameId, selectedDate);
        }

        [Fact]
        public async Task ThrowsExceptionDueToFunctionSecurity()
        {
            var selectedDate = Fixture.Date();
            var staffNameId = Fixture.Integer();
            var f = new TimeEnquiryControllerFixture(Db);
            f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, Arg.Any<User>(), Arg.Any<int>()).Returns(false);
            await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetTimeGaps(new TimeEnquiryController.TimesheetQuery
            {
                SelectedDate = selectedDate,
                StaffNameId = staffNameId
            }));

            await f.FunctionSecurityProvider.Received(1).FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, f.CurrentUser, staffNameId);
            await f.TimesheetList.DidNotReceive().TimeGapFor(Arg.Any<int>(), Arg.Any<DateTime>());
        }
    }

    public class TimeEnquiryControllerFixture : IFixture<TimeEnquiryController>
    {
        public TimeEnquiryControllerFixture(InMemoryDbContext db, bool asStaff = true)
        {
            var loginName = new NameBuilder(db) {UsedAs = asStaff ? NameUsedAs.Individual + NameUsedAs.StaffMember : (short?) null}.Build().In(db);
            TimesheetList = Substitute.For<ITimesheetList>();
            SecurityContext = Substitute.For<ISecurityContext>();
            CurrentUser = new UserBuilder(db) {Name = loginName}.Build();
            SecurityContext.User.Returns(CurrentUser);
            PreferenceManager = Substitute.For<IUserPreferenceManager>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            TimeSummaryProvider = Substitute.For<ITimeSummaryProvider>();
            RecentCasesProvider = Substitute.For<IRecentCasesProvider>();
            FunctionSecurityProvider = Substitute.For<IFunctionSecurityProvider>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            Bus = Substitute.For<IBus>();
            ContentHasher = Substitute.For<IContentHasher>();

            TimesheetList.For(Arg.Any<int>(), Arg.Any<DateTime>()).Returns(new List<TimeEntry>
            {
                new TimeEntry {CaseKey = Fixture.Integer(), ActivityKey = Fixture.RandomString(3)}
            });
            TimeSummaryProvider.Get(Arg.Any<IQueryable<TimeEntry>>()).Returns((new TimeSummary(), 0));
            SubjectSecurityProvider = Substitute.For<ISubjectSecurityProvider>();

            Subject = new TimeEnquiryController(TimesheetList, SecurityContext, PreferenceManager, SiteControlReader, TimeSummaryProvider, FunctionSecurityProvider, TaskSecurityProvider, SubjectSecurityProvider, db, Bus, ContentHasher);
        }

        public ITimesheetList TimesheetList { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public IUserPreferenceManager PreferenceManager { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
        public User CurrentUser { get; set; }
        public ITimeSummaryProvider TimeSummaryProvider { get; set; }
        public IRecentCasesProvider RecentCasesProvider { get; set; }
        public IFunctionSecurityProvider FunctionSecurityProvider { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public ISubjectSecurityProvider SubjectSecurityProvider { get; set; }
        public TimeEnquiryController Subject { get; set; }
        public IBus Bus { get; set; }
        public IContentHasher ContentHasher { get; set; }
    }
}