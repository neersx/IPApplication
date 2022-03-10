using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Storage;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Analytics;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Accounting.Time
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
    [RoutePrefix("api/accounting/time")]
    public class TimeEnquiryController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IFunctionSecurityProvider _functionSecurity;
        readonly IUserPreferenceManager _preferenceManager;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControl;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ISubjectSecurityProvider _subjectSecurityProvider;
        readonly ITimesheetList _timesheetList;
        readonly ITimeSummaryProvider _timeSummaryProvider;
        readonly IBus _bus;
        readonly IContentHasher _contentHasher;

        public TimeEnquiryController(ITimesheetList timesheetList,
                                     ISecurityContext securityContext,
                                     IUserPreferenceManager preferenceManager,
                                     ISiteControlReader siteControl,
                                     ITimeSummaryProvider timeSummaryProvider,
                                     IFunctionSecurityProvider functionSecurity,
                                     ITaskSecurityProvider taskSecurityProvider,
                                     ISubjectSecurityProvider subjectSecurityProvider,
                                     IDbContext dbContext,
                                     IBus bus,
                                     IContentHasher contentHasher)
        {
            _timesheetList = timesheetList;
            _securityContext = securityContext;
            _preferenceManager = preferenceManager;
            _siteControl = siteControl;
            _timeSummaryProvider = timeSummaryProvider;
            _functionSecurity = functionSecurity;
            _taskSecurityProvider = taskSecurityProvider;
            _subjectSecurityProvider = subjectSecurityProvider;
            _dbContext = dbContext;
            _bus = bus;
            _contentHasher = contentHasher;
        }

        [HttpGet]
        [RequiresCaseAuthorization(PropertyName = "caseId")]
        [Route("view/{caseId?}")]
        public async Task<TimeSheetEnquiryViewData> ViewData(int? caseId = null)
        {
            await TrackTransaction();

            var settings = TimeRecordingSettings();
            var userInfo = await UserInfo(_securityContext.User.Name);
            var caseInfo = caseId == null ? null : _dbContext.Set<Case>().Where(_ => _.Id == caseId).Select(_ => new {_.Id, _.Irn}).FirstOrDefault();
            var canViewCaseAttachments = _subjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments) || _taskSecurityProvider.HasAccessTo(ApplicationTask.AccessDocumentsfromDms);
            var canPostForAllStaff = await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, _securityContext.User);
            return new TimeSheetEnquiryViewData
            {
                Settings = settings,
                CanViewCaseAttachments = canViewCaseAttachments,
                CanPostForAllStaff = canPostForAllStaff,
                UserInfo = userInfo,
                DefaultInfo = caseInfo == null
                    ? null
                    : new DefaultInfo
                    {
                        CaseId = caseInfo.Id,
                        CaseReference = caseInfo.Irn
                    }
            };
        }

        [HttpGet]
        [Route("view/staff/{staffNameId}")]
        public async Task<TimeSheetEnquiryViewData> ViewDataForStaff(int staffNameId)
        {
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, _securityContext.User, staffNameId))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }
            var canPostForAllStaff = await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, _securityContext.User);

            var staffName = _dbContext.Set<Name>().SingleOrDefault(_ => _.Id == staffNameId);
            if (staffName == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var settings = TimeRecordingSettings();
            var userInfo = await UserInfo(staffName, staffNameId);

            return new TimeSheetEnquiryViewData
            {
                CanPostForAllStaff = canPostForAllStaff,
                Settings = settings,
                UserInfo = userInfo
            };
        }

        async Task<UserInfo> UserInfo(Name staffName = null, int? staffNameId = null)
        {
            var accessToOthersTime = await _functionSecurity.ForOthers(BusinessFunction.TimeRecording, _securityContext.User);
            
            var userInfo = new UserInfo
            {
                NameId = staffNameId ?? _securityContext.User.NameId,
                DisplayName = staffName?.FormattedWithDefaultStyle(),
                IsStaff = staffName?.IsStaff ?? true,
                CanAdjustValues = await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanAdjustValue, _securityContext.User, staffNameId),
                CanFunctionAsOtherStaff = staffNameId != null || accessToOthersTime.Any(_ => _.CanRead),
                MaintainPostedTimeEdit = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPostedTime, ApplicationTaskAccessLevel.Modify),
                MaintainPostedTimeDelete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPostedTime, ApplicationTaskAccessLevel.Delete)
            };
            return userInfo;
        }

        TimeRecordingSettings TimeRecordingSettings()
        {
            var settings = new TimeRecordingSettings
            {
                LocalCurrencyCode = _siteControl.Read<string>(SiteControls.CURRENCY),
                TimeEmptyForNewEntries = _siteControl.Read<bool>(SiteControls.TimeEmptyForNewEntries),
                RestrictOnWip = _siteControl.Read<bool>(SiteControls.RestrictOnWIP),
                UnitsPerHour = _siteControl.Read<int>(SiteControls.UnitsPerHour),
                RoundUpUnits = _siteControl.Read<bool>(SiteControls.RoundUp),
                ConsiderSecsInUnitsCalc = _siteControl.Read<bool>(SiteControls.ConsiderSecsInUnitsCalc),
                EnableUnitsForContinuedTime = _siteControl.Read<bool>(SiteControls.ContEntryUnitsAdjmt),
                WipSplitMultiDebtor = _siteControl.Read<bool>(SiteControls.WIPSplitMultiDebtor),
                DisplaySeconds = _preferenceManager.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.DisplayTimeWithSeconds),
                AddEntryOnSave = _preferenceManager.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.AddEntryOnSave),
                TimeFormat12Hours = _preferenceManager.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.TimeFormat12Hours),
                HideContinuedEntries = _preferenceManager.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.HideContinuedEntries),
                ContinueFromCurrentTime = _preferenceManager.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.ContinueFromCurrentTime),
                ValueTimeOnEntry = _preferenceManager.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.ValueTimeOnEntry),
                TimePickerInterval = _preferenceManager.GetPreference<int>(_securityContext.User.Id, KnownSettingIds.TimePickerInterval),
                DurationPickerInterval = _preferenceManager.GetPreference<int>(_securityContext.User.Id, KnownSettingIds.DurationPickerInterval)
            };
            return settings;
        }

        [HttpGet]
        [Route("permissions/{staffNameId}")]
        public async Task<dynamic> UserPermissions(int staffNameId)
        {
            var isStaff = _dbContext.Set<Name>().Any(_ => _.Id == staffNameId && (_.UsedAs & NameUsedAs.StaffMember) == NameUsedAs.StaffMember);
            if (!isStaff)
            {
                return new
                {
                    CanRead = false,
                    CanInsert = false,
                    CanUpdate = false,
                    CanDelete = false,
                    CanPost = false,
                    CanAdjustValue = false
                };
            }

            if (staffNameId == _securityContext.User.NameId)
            {
                return new
                {
                    CanRead = true,
                    CanInsert = true,
                    CanUpdate = true,
                    CanDelete = true,
                    CanPost = true,
                    CanAdjustValue = await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanAdjustValue, _securityContext.User)
                };
            }

            var fs = await _functionSecurity.BestFit(BusinessFunction.TimeRecording, _securityContext.User, staffNameId);

            return new
            {
                fs?.CanRead,
                fs?.CanInsert,
                fs?.CanUpdate,
                fs?.CanDelete,
                fs?.CanPost,
                fs?.CanAdjustValue
            };
        }

        [HttpGet]
        [Route("list")]
        public async Task<dynamic> ListTime([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                            TimesheetQuery q, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                            CommonQueryParameters qp = null)
        {
            if (q.StaffNameId.HasValue && q.StaffNameId.Value == _securityContext.User.NameId)
            {
                q.StaffNameId = null;
            }

            if (q.StaffNameId.HasValue && !await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording,
                                                                                       FunctionSecurityPrivilege.CanRead,
                                                                                       _securityContext.User,
                                                                                       q.StaffNameId))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }

            var queryParameters = new CommonQueryParameters
            {
                Take = null
            }.Extend(qp);

            var data = (await _timesheetList.For(q.StaffNameId ?? _securityContext.User.NameId, q.SelectedDate ?? DateTime.Today)).ToArray();

            var summary = (await _timeSummaryProvider.Get(data.AsQueryable())).summary;
            return new
            {
                Data = data.AsQueryable().OrderByProperty(queryParameters).AsPagedResults(queryParameters),
                Totals = summary
            };
        }

        [HttpGet]
        [Route("gaps")]
        public async Task<IEnumerable<TimeGap>> GetTimeGaps([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                                        TimesheetQuery q)
        {
            if (q.StaffNameId.HasValue &&
                !await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording,
                                                             FunctionSecurityPrivilege.CanRead,
                                                             _securityContext.User,
                                                             q.StaffNameId))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }

            return await _timesheetList.TimeGapFor(q.StaffNameId ?? _securityContext.User.NameId, q.SelectedDate ?? DateTime.Today);
        }

        public class TimesheetQuery
        {
            public DateTime? SelectedDate { get; set; }
            public int? StaffNameId { get; set; }
        }

        async Task TrackTransaction()
        {
            await _bus.PublishAsync(new TransactionalAnalyticsMessage
            {
                EventType = TransactionalEventTypes.TimeRecordingAccessed,
                Value = _contentHasher.ComputeHash(_securityContext.User.Id.ToString())
            });
        }
    }
}