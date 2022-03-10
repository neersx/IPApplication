using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Accounting.Time.Search;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Accounting.Time
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
    [RoutePrefix("api/accounting/time/batch")]
    public class TimeRecordingBatchController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IFunctionSecurityProvider _functionSecurity;
        readonly ITimesheetList _timesheetList;
        readonly ITimeSearchService _searchService;
        readonly IDiaryUpdate _diaryUpdate;

        public TimeRecordingBatchController(ISecurityContext securityContext, IFunctionSecurityProvider functionSecurity, ITimesheetList timesheetList, ITimeSearchService searchService, IDiaryUpdate diaryUpdate)
        {
            _securityContext = securityContext;
            _functionSecurity = functionSecurity;
            _timesheetList = timesheetList;
            _searchService = searchService;
            _diaryUpdate = diaryUpdate;
        }

        [HttpDelete]
        [Route("delete")]
        [RequiresCaseAuthorization(PropertyPath = "selectionDetails.ReverseSelection.SearchParams.CaseIds")]
        [RequiresNameAuthorization(PropertyPath = "selectionDetails.ReverseSelection.SearchParams.NameId")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task Delete(BatchSelectionDetails selectionDetails)
        {
            var staffNameId = selectionDetails.StaffNameId ?? _securityContext.User.NameId;
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, _securityContext.User, staffNameId))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }

            await DeleteSelected(staffNameId, GetQuery(selectionDetails).Where(_ => _.TransNo == null));
        }

        public class NewNarrative
        {
            public short? NarrativeNo { get; set; }
            public string NarrativeText { get; set; }
        }
        public class BatchNarrativeRequest
        {
            public BatchSelectionDetails SelectionDetails { get; set; }
            public NewNarrative NewNarrative { get; set; }
        }

        [HttpPut]
        [Route("update-narrative")]
        [RequiresCaseAuthorization(PropertyPath = "narrativeRequest.SelectionDetails.ReverseSelection.SearchParams.CaseIds")]
        [RequiresNameAuthorization(PropertyPath = "narrativeRequest.SelectionDetails.ReverseSelection.SearchParams.NameId")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task UpdateNarrative([FromBody()] BatchNarrativeRequest narrativeRequest)
        {
            var staffNameId = narrativeRequest.SelectionDetails.StaffNameId ?? _securityContext.User.NameId;
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanUpdate, _securityContext.User, staffNameId))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }
            await UpdateNarratives(staffNameId, GetQuery(narrativeRequest.SelectionDetails).Where(_ => _.TransNo == null), narrativeRequest.NewNarrative.NarrativeText, narrativeRequest.NewNarrative.NarrativeNo);
        }

        IQueryable<TimeEntry> GetQuery(BatchSelectionDetails details)
        {
            if (details.EntryNumbers?.Any() == true)
            {
                return _timesheetList.SearchFor(details.StaffNameId ?? _securityContext.User.NameId, details.EntryNumbers);
            }

            var searchQuery = _searchService.Search(details.ReverseSelection.SearchParams, details.ReverseSelection.QueryParams.Filters);
            var exceptEntryNos = details.ReverseSelection.ExceptEntryNumbers ?? new int[]{};

            return from d in searchQuery
                   where d.EntryNo.HasValue && !exceptEntryNos.Contains(d.EntryNo.Value)
                   select d;
        }

        IEnumerable<Diary> GetTimeEntry(int staffNameId, IQueryable<TimeEntry> query)
        {
            var data = query.Where(_ => _.EntryNo.HasValue && _.StartTime.HasValue)
                            .Select(_ => new {entryNo = _.EntryNo.Value, date = DbFuncs.TruncateTime(_.StartTime).Value})
                            .ToList();

            var dates = data.GroupBy(_ => _.date, _ => _.entryNo);

            foreach (var date in dates)
            {
                var entriesForTheDay = _timesheetList.DiaryFor(staffNameId, date.Key).ToArray();

                foreach (var entryNo in date)
                {
                    var continuedChain = entriesForTheDay.GetDownwardChainFor(entryNo).ToList();
                    foreach (var entry in continuedChain)
                    {
                        yield return entry;
                    }
                }
            }
        }

        async Task DeleteSelected(int staffNameId, IQueryable<TimeEntry> query)
        {
            var entriesToBeDeleted = GetTimeEntry(staffNameId, query).Select(diary => diary.EntryNo).ToArray();
            await _diaryUpdate.BatchDelete(staffNameId, entriesToBeDeleted);
        }

        async Task UpdateNarratives(int staffNameId, IQueryable<TimeEntry> query, string narrativeText, short? narrativeNo = null)
        {
            var entriesToBeUpdated = GetTimeEntry(staffNameId, query).Select(diary => diary.EntryNo).ToArray();
            await _diaryUpdate.BatchUpdateNarratives(staffNameId, entriesToBeUpdated, narrativeText, narrativeNo);
        }
    }
}

public class BatchSelectionDetails
{
    public int? StaffNameId { get; set; }

    public int[] EntryNumbers { get; set; }

    public ReverseSelection ReverseSelection { get; set; }
}

public class ReverseSelection
{
    public int[] ExceptEntryNumbers { get; set; }
    public TimeSearchParams SearchParams { get; set; }
    public CommonQueryParameters QueryParams { get; set; }
}