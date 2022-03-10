using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using AutoMapper;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Messages;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Accounting.Time
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/accounting/time")]
    public class TimeRecordingController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IBestTranslatedNarrativeResolver _bestNarrativeResolver;
        readonly IFunctionSecurityProvider _functionSecurity;
        readonly IDiaryUpdate _diaryUpdate;
        readonly IWipWarningCheck _wipWarningCheck;
        readonly IBus _bus;
        readonly IValueTime _valueTime;
        readonly IMapper _mapper;
        readonly Func<DateTime> _now;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IWipCosting _wipCosting;
        readonly IWipDefaulting _wipDefaulting;
        readonly IWipWarnings _wipWarnings;
        const string TimerStartedTopic = "time.recording.timerStarted";

        public TimeRecordingController(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver,
                                       Func<DateTime> now, 
                                       IWipCosting wipCosting, IWipDefaulting wipDefaulting, 
                                       IBestTranslatedNarrativeResolver bestNarrativeResolver,
                                       IWipWarnings wipWarnings, 
                                       IMapper mapper, IFunctionSecurityProvider functionSecurity, IDiaryUpdate diaryUpdate, IWipWarningCheck wipWarningCheck, IBus bus, IValueTime valueTime)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _now = now;
            _wipCosting = wipCosting;
            _wipDefaulting = wipDefaulting;
            _bestNarrativeResolver = bestNarrativeResolver;
            _wipWarnings = wipWarnings;
            _mapper = mapper;
            _functionSecurity = functionSecurity;
            _diaryUpdate = diaryUpdate;
            _wipWarningCheck = wipWarningCheck;
            _bus = bus;
            _valueTime = valueTime;
        }

        [HttpPost]
        [RequiresCaseAuthorization(PropertyPath = "timeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeEntry.NameKey")]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        [Route("save")]
        public async Task<dynamic> Save(RecordableTime timeEntry)
        {
            if (timeEntry == null) throw new HttpResponseException(HttpStatusCode.BadRequest);
            if (timeEntry.EntryNo.HasValue) throw new HttpResponseException(HttpStatusCode.BadRequest);

            await _wipWarningCheck.For(timeEntry.CaseKey, timeEntry.NameKey);

            timeEntry.StaffId ??= _securityContext.User.NameId;

            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanInsert, _securityContext.User, timeEntry.StaffId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            var addedEntry = await _diaryUpdate.AddEntry(timeEntry);

            return new
            {
                Response = new {addedEntry.EntryNo, TimeEntry = addedEntry}
            };
        }

        [HttpPut]
        [RequiresCaseAuthorization(PropertyPath = "timeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeEntry.NameKey")]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        [Route("update")]
        public async Task<dynamic> Update(RecordableTime timeEntry)
        {
            if (timeEntry == null) throw new HttpResponseException(HttpStatusCode.BadRequest);
            if (!timeEntry.EntryNo.HasValue) throw new HttpResponseException(HttpStatusCode.BadRequest);

            timeEntry.StaffId ??= _securityContext.User.NameId;

            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanUpdate, _securityContext.User, timeEntry.StaffId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            await _wipWarningCheck.For(timeEntry.CaseKey, timeEntry.NameKey);

            await _diaryUpdate.UpdateEntry(timeEntry);

            return new
            {
                Response = new {timeEntry.EntryNo, TimeEntry = timeEntry}
            };
        }

        [HttpDelete]
        [Route("delete")]
        [Route("delete-from-chain")]
        [RequiresCaseAuthorization(PropertyPath = "timeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeEntry.NameKey")]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<dynamic> DeleteStaffTimeEntry(RecordableTime timeEntry)
        {
            if (timeEntry?.EntryNo == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            timeEntry.StaffId ??= _securityContext.User.NameId;
            
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, _securityContext.User, timeEntry.StaffId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            var deletedDiary = await _diaryUpdate.DeleteEntry(timeEntry);

            if (deletedDiary.IsTimer > 0 && deletedDiary.EmployeeNo == _securityContext.User.NameId)
            {
                var data = TimerStateInfo.StoppedTimer(_mapper.Map<TimeEntry>(deletedDiary));

                _bus.Publish(new BroadcastMessageToClient
                {
                    Topic = TimerStartedTopic + _securityContext.User.Id,
                    Data = data
                });
            }

            return new
            {
                Response = deletedDiary.EntryNo
            };
        }

        [HttpDelete]
        [Route("delete-chain")]
        [RequiresCaseAuthorization(PropertyPath = "timeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeEntry.NameKey")]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<dynamic> DeleteChain(RecordableTime timeEntry)
        {
            if (timeEntry.EntryNo == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            timeEntry.StaffId ??= _securityContext.User.NameId;
            
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, _securityContext.User, timeEntry.StaffId))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }

            await _diaryUpdate.DeleteChainFor(timeEntry);

            return new
            {
                Response = timeEntry.EntryNo
            };
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [Route("activities/{caseKey}")]
        public async Task<dynamic> DefaultWipFromCase(int caseKey)
        {
            var wipTemplateFilter = new WipTemplateFilterCriteria().ForTimesheet(caseKey);
            var wipDefaults = await _wipDefaulting.ForCase(wipTemplateFilter, caseKey);
            return new
            {
                Activity = new
                {
                    Key = wipDefaults.WIPTemplateKey,
                    Value = wipDefaults.WIPTemplateDescription
                },
                Narrative = new
                {
                    Key = wipDefaults.NarrativeKey,
                    Value = wipDefaults.NarrativeTitle,
                    Text = wipDefaults.NarrativeText
                }
            };
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [Route("narrative")]
        public async Task<BestNarrative> DefaultNarrative(string activityKey, int? caseKey = null, int? debtorKey = null, int? staffNameId = null)
        {
            var culture = _preferredCultureResolver.Resolve();
            var effectiveDebtorId = !caseKey.HasValue ? debtorKey : null;

            return await _bestNarrativeResolver.Resolve(culture, activityKey, staffNameId ?? _securityContext.User.NameId, caseKey, effectiveDebtorId);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("checkstatus/{caseKey}")]
        public async Task<bool> CheckStatus(int caseKey)
        {
            return await _wipWarnings.AllowWipFor(caseKey);
        }

        [HttpGet]
        [RequiresCaseAuthorization(PropertyPath = "timeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeEntry.NameKey")]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [Route("evaluateTime")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<TimeEntry> EvaluateTime([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "timeEntry")]
                                                  RecordableTime timeEntry)
        {
            timeEntry.StaffId ??= _securityContext.User.NameId;

            return await _valueTime.For(timeEntry, _preferredCultureResolver.Resolve()); 
        }

        [HttpPut]
        [RequiresCaseAuthorization(PropertyPath = "timeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeEntry.NameKey")]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        [Route("updateDate")]
        public async Task<dynamic> UpdateDate(RecordableTime timeEntry)
        {
            if (timeEntry.EntryNo == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            timeEntry.StaffId ??= _securityContext.User.NameId;
            
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanUpdate, _securityContext.User, timeEntry.StaffId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            await _diaryUpdate.UpdateDate(timeEntry);

            return new
            {
                Response = new {timeEntry.EntryNo}
            };
        }

        [HttpPost]
        [RequiresCaseAuthorization(PropertyPath = "timeCost.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeCost.NameKey")]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [Route("cost-preview")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<TimeCost> CostPreview(WipCost timeCost)
        {
            timeCost.StaffKey ??= _securityContext.User.NameId;
            
            var result = await _wipCosting.For(timeCost);
            
            return _mapper.Map<TimeCost>(result);
        }

        [HttpPut]
        [RequiresCaseAuthorization(PropertyPath = "timeCost.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeCost.NameKey")]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        [Route("adjust-value")]
        public async Task<dynamic> UpdateValue(TimeCost timeCost)
        {
            var staffNameId = timeCost.StaffKey ?? _securityContext.User.NameId;
            
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanAdjustValue, _securityContext.User, staffNameId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            await _wipWarningCheck.For(timeCost.CaseKey, timeCost.NameKey);

            var entry = await _dbContext.Set<Diary>().Include(_=>_.DebtorSplits).SingleOrDefaultAsync(_ => _.EmployeeNo == staffNameId && _.EntryNo == timeCost.EntryNo);

            if (entry == null || entry.DebtorSplits?.Count > 0) throw new HttpResponseException(HttpStatusCode.BadRequest);

            entry.TimeValue = timeCost.LocalValue;
            entry.DiscountValue = timeCost.LocalDiscount;
            entry.ForeignValue = timeCost.ForeignValue;
            entry.ForeignDiscount = timeCost.ForeignDiscount;
            entry.MarginId = timeCost.MarginNo;
            entry.ExchRate = timeCost.ExchangeRate.HasValue ? Math.Round(timeCost.ExchangeRate.Value, 4) : null;

            var newChargeRate = EntryChargeOutRate(timeCost, entry);
            if (newChargeRate.HasValue)
                entry.ChargeOutRate = newChargeRate;

            await _dbContext.SaveChangesAsync();

            return new
            {
                timeCost.EntryNo
            };
        }

        [HttpPost]
        [Route("save-gaps")]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<dynamic> SaveGaps(TimeGap[] timeGaps)
        {
            if (!timeGaps.Any())
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanInsert, _securityContext.User, timeGaps.First().StaffId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            var diaryTable = _dbContext.Set<Diary>();
            var entryNo = diaryTable.GetNewEntryNoFor(timeGaps[0].StaffId);
            
            foreach (var gap in timeGaps)
            {
                var timeEntry = _mapper.Map<RecordableTime>(gap);

                var valuedTime = await _valueTime.For(timeEntry.AdjustDataForWipCalculation(), _preferredCultureResolver.Resolve());
                var newDiary = new Diary();
                _mapper.Map(valuedTime, newDiary);
                _mapper.Map(timeEntry, newDiary);
                
                newDiary.EntryNo = entryNo++;
                newDiary.CreatedOn = _now();
                diaryTable.Add(newDiary);

                gap.EntryNo = newDiary.EntryNo;
            }

            await _dbContext.SaveChangesAsync();

            return new
            {
                Entries = timeGaps.Select(_ => new {_.Id, _.EntryNo})
            };
        }

        [HttpPost]
        [Route("copy")]
        [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<int> Copy(TimeCopyRequest request)
        {
            var staffNameId = request.StaffId;
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanInsert, _securityContext.User, staffNameId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            if (!request.IsValidDateRange)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            var diaryTbl = _dbContext.Set<Diary>();
            var allEntries = diaryTbl.Where(_ => _.EmployeeNo == staffNameId);
            var entry = allEntries.FirstOrDefault(x => x.EntryNo == request.EntryNo);
            if (entry == null)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            var dates = new List<DateTime>();
            for (var day = request.Start.Date; day.Date <= request.End.Date; day = day.AddDays(1)) dates.Add(day);
            var copyToDates = dates.Where(d => request.Days.Contains(d.DayOfWeek)).OrderBy(_ => _);

            return await _diaryUpdate.AddEntries(entry, copyToDates);
        }

        static decimal? EntryChargeOutRate(TimeCost timeCost, Diary entry) =>
            !entry.UnitsPerHour.HasValue || !entry.TotalUnits.HasValue
                ? null
                : Math.Round((!string.IsNullOrEmpty(entry.ForeignCurrency)
                                 ? timeCost.ForeignValue.GetValueOrDefault()
                                 : timeCost.LocalValue.GetValueOrDefault()) /
                             ((decimal) entry.TotalUnits.GetValueOrDefault() / entry.UnitsPerHour.GetValueOrDefault()),
                             2, MidpointRounding.AwayFromZero);

        public class TimeCopyRequest
        {
            public int EntryNo { get; set; }
            public int StaffId { get; set; }
            public DateTime Start { get; set; }
            public DateTime End { get; set; }
            public DayOfWeek[] Days { get; set; }

            public bool IsValidDateRange => Start <= End && Start.Date.AddMonths(3) >= End;
        }
    }
}