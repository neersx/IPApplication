using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Notifications.Validation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Accounting.Time.Search;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using ServiceStack;
using PostTimeResult = InprotechKaizen.Model.Components.Accounting.Time.PostTimeResult;

namespace Inprotech.Web.Accounting.Time
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
    [RoutePrefix("api/accounting/time-posting")]
    public class TimePostingController : ApiController
    {
        readonly IEntities _entities;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControls;
        readonly IPostTimeCommand _postTimeCommand;
        readonly IDiaryDatesReader _datesReader;
        readonly Func<DateTime> _systemClock;
        readonly IFunctionSecurityProvider _functionSecurity;
        readonly ITimeSearchService _timeSearchService;
        readonly IValidatePostDates _validatePostDates;
        readonly IBus _bus;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        static readonly CommonQueryParameters DefaultQueryParameters = new CommonQueryParameters
        {
            SortBy = "date",
            SortDir = "desc",
            Take = 10
        };

        public TimePostingController(IEntities entities,
                                     ISecurityContext securityContext,
                                     ISiteControlReader siteControls,
                                     IPostTimeCommand postTimeCommand,
                                     IDiaryDatesReader datesReader,
                                     Func<DateTime> systemClock,
                                     IFunctionSecurityProvider functionSecurity,
                                     ITimeSearchService timeSearchService,
                                     IValidatePostDates validatePostDates,
                                     IBus bus,
                                     IPreferredCultureResolver preferredCultureResolver)
        {
            _entities = entities;
            _securityContext = securityContext;
            _postTimeCommand = postTimeCommand;
            _datesReader = datesReader;
            _systemClock = systemClock;
            _functionSecurity = functionSecurity;
            _timeSearchService = timeSearchService;
            _validatePostDates = validatePostDates;
            _bus = bus;
            _preferredCultureResolver = preferredCultureResolver;
            _siteControls = siteControls;
        }

        [HttpGet]
        [Route("view")]
        public async Task<dynamic> ViewData()
        {
            var canPostToCaseOfficeEntity = _siteControls.ReadMany<bool>(SiteControls.EntityDefaultsFromCaseOffice, SiteControls.RowSecurityUsesCaseOffice);
            var postToCaseOfficeEntity = canPostToCaseOfficeEntity.Count == 2 && canPostToCaseOfficeEntity.All(_ => _.Value);

            return new
            {
                Entities = postToCaseOfficeEntity ? null : await _entities.Get(_securityContext.User.NameId),
                HasFixedEntity = _siteControls.Read<bool>(SiteControls.AutomaticWIPEntity),
                PostToCaseOfficeEntity = postToCaseOfficeEntity
            };
        }

        [HttpGet]
        [Route("getDates/{staffNameId:int?}")]
        public async Task<PagedResults<PostableDate>> GetDateDetails([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters qp,
                                                                     [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "dates")] PostDateRange dates,
                                                                     int? staffNameId = null)
        {
            if (dates.From.HasValue && !dates.To.HasValue || dates.To.HasValue && !dates.From.HasValue)
            {
                throw new ArgumentException("Both From and To dates must be specified.");
            }

            var queryParameters = DefaultQueryParameters.Extend(qp);

            var tomorrow = _systemClock().Date.AddDays(1);

            var result = dates.From.HasValue ?
                await _datesReader.GetDiaryDatesFor(dates.From.Value, dates.To?.Date.AddDays(1)) :
                await _datesReader.GetDiaryDatesFor(staffNameId ?? _securityContext.User.NameId, tomorrow);

            return result.AsOrderedPagedResults(queryParameters);
        }

        [HttpPost]
        [Route("post")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<dynamic> PostTimeEntries(PostTimeRequest request)
        {
            var staffNameId = request.StaffNameId ?? _securityContext.User.NameId;
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, _securityContext.User, staffNameId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            var result = request.WarningAccepted
                ? (isValid: true, isWarningOnly: false, code: string.Empty)
                : await _validatePostDates.For(await GetPostDate());

            if (result.isValid)
            {
                var postTimeArgs = new PostTimeArgs
                {
                    UserIdentityId = _securityContext.User.Id,
                    EntityKey = request.EntityKey,
                    StaffNameNo = staffNameId,
                    SelectedDates = request.SelectedDates,
                    Culture = _preferredCultureResolver.Resolve()
                };

                if (request.SelectedDates is { Count: <= 7 })
                    return await _postTimeCommand.PostTime(postTimeArgs);

                await _bus.PublishAsync(postTimeArgs);

                return new { Result = "success", IsBackground = true };
            }

            var hasError = result.code != KnownErrors.ItemPostedToDifferentPeriod;
            return new PostTimeResult(0, 0, false, hasError)
            {
                HasWarning = !hasError,
                Error = new ApplicationAlert {AlertID = result.code}
            };

            async Task<DateTime> GetPostDate()
            {
                if (request.SelectedDates != null) 
                    return request.SelectedDates.Max();

                var postableDates = await _datesReader.GetDiaryDatesFor(staffNameId, _systemClock().Date);
                var dates = postableDates as PostableDate[] ?? postableDates.ToArray();
                return !dates.Any() ? _systemClock().Date : dates.Select(_ => _.Date).Max();
            }
        }

        [HttpPost]
        [Route("postEntry")]
        [RequiresNameAuthorization(PropertyPath = "request.PostingParams.SearchParams.NameId")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<dynamic> PostSelectedEntries(PostEntry request)
        {
            var staffNameId = request.StaffNameId ?? _securityContext.User.NameId;
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, _securityContext.User, staffNameId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);

            if (request.EntryNo == null && request.EntryNumbers == null && !request.IsSelectAll)
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            int[] entryNumbersForPosting;
            if (request.IsSelectAll)
            {
                var queryParameters = request.PostingParams.QueryParams;
                var dataQuery = _timeSearchService.Search(request.PostingParams.SearchParams, queryParameters.Filters);
                var searchResults = await dataQuery.Select(_ => _.EntryNo.Value).ToListAsync();
                entryNumbersForPosting = request.ExceptEntryNumbers == null ? searchResults.ToArray() : searchResults.Except(request.ExceptEntryNumbers.ToArray()).ToArray();
            }
            else
            {
                entryNumbersForPosting = request.EntryNo.HasValue ? new[] {request.EntryNo.Value} : request.EntryNumbers;
            }

            var postableDates = request.WarningAccepted ? new[] {_systemClock().Date} : await _datesReader.GetDiaryDatesFor(staffNameId, entryNumbersForPosting);
            var postableDiaryDates = postableDates as DateTime[] ?? postableDates.ToArray();
            if (postableDiaryDates.Any() == false)
            {
                return new PostTimeResult(0, null);
            }

            var result = request.WarningAccepted
                ? (isValid: true, isWarningOnly: false, code: string.Empty)
                : await _validatePostDates.For(postableDiaryDates.Max());

            if (result.isValid)
            {
                var postTimeArgs = new PostTimeArgs
                {
                    UserIdentityId = _securityContext.User.Id,
                    EntityKey = request.EntityKey,
                    StaffNameNo = staffNameId,
                    SelectedEntryNos = entryNumbersForPosting,
                    Culture = _preferredCultureResolver.Resolve()
                };
                if (entryNumbersForPosting is not { Length: > 50 })
                    return await _postTimeCommand.PostTime(postTimeArgs);

                await _bus.PublishAsync(postTimeArgs);
                return new { Result = "success", IsBackground = true };
            }

            var hasError = result.code != KnownErrors.ItemPostedToDifferentPeriod;
            return new PostTimeResult(0, 0, false, hasError)
            {
                HasWarning = !hasError,
                Error = new ApplicationAlert {AlertID = result.code}
            };
        }

        [HttpPost]
        [Route("postForAllStaff")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        public async Task<dynamic> PostForAllStaff(PostForAllStaff request)
        {
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, _securityContext.User))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }
            var result = request.WarningAccepted
                ? (isValid: true, isWarningOnly: false, code: string.Empty)
                : await _validatePostDates.For(await GetPostDate());
            if (result.isValid)
            {
                var postTimeArgs = new PostTimeArgs
                {
                    UserIdentityId = _securityContext.User.Id,
                    EntityKey = request.EntityKey,
                    SelectedStaffDates = request.SelectedDates,
                    PostForAllStaff = request.SelectedDates == null,
                    Culture = _preferredCultureResolver.Resolve()
                };
                await _bus.PublishAsync(postTimeArgs);
                return new { Result = "success", IsBackground = true };
            }
            var hasError = result.code != KnownErrors.ItemPostedToDifferentPeriod;
            return new PostTimeResult(0, 0, false, hasError)
            {
                HasWarning = !hasError,
                Error = new ApplicationAlert {AlertID = result.code}
            };

            async Task<DateTime> GetPostDate()
            {
                if (request.SelectedDates != null) 
                    return request.SelectedDates.Select(v => v.Date).Max();

                var postableDates = await _datesReader.GetDiaryDatesFor(null, _systemClock().Date);
                var dates = postableDates as PostableDate[] ?? postableDates.ToArray();
                return !dates.Any() ? _systemClock().Date : dates.Select(_ => _.Date).Max();
            }
        }
    }

    public class PostTimeRequest
    {
        public int? EntityKey { get; set; }
        public List<DateTime> SelectedDates { get; set; }
        public int? StaffNameId { get; set; }
        public bool WarningAccepted { get; set; }
    }

    public class PostForAllStaff
    {
        public int? EntityKey { get; set; }
        public List<PostableDate> SelectedDates { get; set; }
        public bool WarningAccepted { get; set; }
        public TimeSearchParams SearchParams { get; set; }
    }
    
    public class PostEntry
    {
        public int? EntryNo { get; set; }
        public int? EntityKey { get; set; }
        public int? StaffNameId { get; set; }
        public int[] EntryNumbers { get; set; }
        public int[] ExceptEntryNumbers { get; set; }
        public bool IsSelectAll { get; set; }
        public bool WarningAccepted { get; set; }
        public TimePostingParams PostingParams { get; set; }
    }

    public class TimePostingParams
    {
        public TimeSearchParams SearchParams { get; set; }
        public CommonQueryParameters QueryParams { get; set; }
    }

    public class PostDateRange
    {
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
    }
}