using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Search.Export;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Accounting.Time.Search
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
    [RoutePrefix("api/accounting/time/search")]
    public class TimeSearchController : ApiController
    {
        const string Start = "ENTRYDATE";
        const string CaseReference = "CASEREFERENCE";
        const string Name = "NAME";
        const string Activity = "ACTIVITY";

        static readonly CommonQueryParameters DefaultQueryParameters = new CommonQueryParameters
        {
            SortBy = "entryDate",
            SortDir = "desc"
        };

        readonly IBus _bus;

        readonly IDbContext _dbContext;
        readonly IDisplayFormattedName _displayFormattedName;
        readonly IExportSettings _exportSettings;
        readonly ITimeSearchService _timeSearchService;
        readonly IFunctionSecurityProvider _functionSecurity;
        readonly IUserPreferenceManager _preferenceManager;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControls;
        readonly IStaticTranslator _staticTranslator;
        readonly ITimesheetList _timesheetList;
        readonly ITimeSummaryProvider _timeSummaryProvider;

        public TimeSearchController(ITimesheetList timesheetList,
                                    IFunctionSecurityProvider functionSecurity,
                                    ISecurityContext securityContext,
                                    ISiteControlReader siteControls,
                                    IDbContext dbContext,
                                    ITimeSummaryProvider timeSummaryProvider,
                                    IDisplayFormattedName displayFormattedName,
                                    IUserPreferenceManager preferenceManager,
                                    IPreferredCultureResolver preferredCultureResolver,
                                    IStaticTranslator staticTranslator,
                                    IBus bus,
                                    IExportSettings exportSettings,
                                    ITimeSearchService timeSearchService)
        {
            _timesheetList = timesheetList;
            _functionSecurity = functionSecurity;
            _securityContext = securityContext;
            _siteControls = siteControls;
            _dbContext = dbContext;
            _displayFormattedName = displayFormattedName;
            _preferenceManager = preferenceManager;
            _preferredCultureResolver = preferredCultureResolver;
            _staticTranslator = staticTranslator;
            _bus = bus;
            _exportSettings = exportSettings;
            _timeSearchService = timeSearchService;
            _timeSummaryProvider = timeSummaryProvider;
        }

        [HttpGet]
        [Route("view")]
        public async Task<dynamic> ViewData()
        {
            var settings = new TimeRecordingSettings
            {
                DisplaySeconds = _preferenceManager.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.DisplayTimeWithSeconds)
            };

            var userInfo = new UserInfo
            {
                NameId = _securityContext.User.Name.Id,
                DisplayName = _securityContext.User.Name.FormattedWithDefaultStyle()
            };
            return new
            {
                Settings = settings,
                UserInfo = userInfo,
                Entities = await GetEntityNames()
            };
        }

        async Task<IEnumerable<EntityName>> GetEntityNames()
        {
            var automaticWipEntity = _siteControls.Read<bool>(SiteControls.AutomaticWIPEntity);
            if (automaticWipEntity)
            {
                var homeNameNo = _siteControls.Read<int>(SiteControls.HomeNameNo);
                return new List<EntityName>
                {
                    new EntityName
                    {
                        Id = homeNameNo,
                        DisplayName = await _displayFormattedName.For(homeNameNo)
                    }
                };
            }

            var candidates = _dbContext.Set<SpecialName>()
                                       .Where(e => e.IsEntity.HasValue && e.IsEntity == 1)
                                       .Select(e => new EntityName
                                       {
                                           Id = e.Id
                                       }).ToArray();

            var formattedNames = await _displayFormattedName.For(candidates.Select(_ => _.Id).Distinct().ToArray());
            if (formattedNames.Any())
            {
                foreach (var entity in candidates)
                {
                    entity.DisplayName = formattedNames[entity.Id]?.Name;
                }
            }

            var orderedEntities = new List<EntityName>(candidates.OrderBy(_ => _.DisplayName));
            return orderedEntities;
        }

        public class EntityName
        {
            public int Id { get; set; }
            public string DisplayName { get; set; }
        }

        [HttpGet]
        [Route("")]
        [Route("recent-entries")]
        [RequiresNameAuthorization(PropertyPath = "q.NameId")]
        [RequiresCaseAuthorization(PropertyPath = "q.CaseIds")]
        public async Task<dynamic> Search(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
            TimeSearchParams q,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
            CommonQueryParameters queryParameters)
        {
            if (q == null) throw new ArgumentNullException(nameof(q));
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, _securityContext.User, q.StaffId))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }

            var dataQuery = _timeSearchService.Search(q, queryParameters.Filters);
            List<TimeEntry> pagedData;

            if (queryParameters.SortBy != "name")
            {
                pagedData = queryParameters.SortBy == "totalDuration"
                    ? ApplyOrderAndPaging((await dataQuery.ToListAsync()).AsQueryable(),
                                          queryParameters).ToList()
                    : await ApplyOrderAndPaging(dataQuery, queryParameters).ToListAsync();
                await _timesheetList.FormatNamesForDisplay(pagedData);
            }
            else
            {
                var data = await dataQuery.ToListAsync();
                await _timesheetList.FormatNamesForDisplay(data);
                pagedData = ApplyOrderAndPaging(data.AsQueryable(), queryParameters).ToList();
            }

            var (summary, count) = queryParameters.Skip == 0 ? await _timeSummaryProvider.Get(dataQuery) : (null, 0);

            return new
            {
                Data = new PagedResults(pagedData, count),
                Summary = summary
            };
        }

        IQueryable<TimeEntry> ApplyOrderAndPaging(IQueryable<TimeEntry> query, CommonQueryParameters queryParameters)
        {
            var mapCol = new Dictionary<string, string> {{"entryDate", "startTime"}};
            if (!string.IsNullOrWhiteSpace(queryParameters.SortBy) && mapCol.ContainsKey(queryParameters.SortBy))
            {
                queryParameters.SortBy = mapCol[queryParameters.SortBy];
            }

            return query.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                        .Skip(queryParameters.Skip.GetValueOrDefault())
                        .Take(queryParameters.Take.GetValueOrDefault());
        }

        [HttpGet]
        [Route("filterData/{field}")]
        [RequiresNameAuthorization(PropertyPath = "q.NameId")]
        [RequiresCaseAuthorization(PropertyPath = "q.CaseIds")]
        public async Task<IEnumerable<dynamic>> GetFilterDataForColumn(string field,
                                                                       [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                                                       TimeSearchParams q,
                                                                       [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                       CommonQueryParameters queryParameters)
        {
            if (q == null) throw new ArgumentNullException(nameof(q));
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var results = _timeSearchService.Search(q, queryParameters.Filters.Where(f => !f.Field.IgnoreCaseEquals(field)));

            switch (field.ToUpper())
            {
                case Start:
                    var dates = (await results.Select(_ => DbFuncs.TruncateTime(_.StartTime))
                                              .Distinct()
                                              .OrderBy(_ => _)
                                              .ToArrayAsync())
                        .Select(_ => new {Description = _?.Date});
                    return dates;

                case CaseReference:
                    var cases = await results.Select(_ => new {_.CaseKey, _.CaseReference})
                                             .OrderBy(_ => _.CaseReference)
                                             .Distinct()
                                             .ToArrayAsync();
                    return RearrangeEmpty(cases.Select(_ => new CodeDescription {Code = _.CaseKey?.ToString(), Description = _.CaseReference}).ToList());

                case Name:
                    var nameKeys = await results.Select(_ => _.InstructorName != null ? _.InstructorName.Id : _.DebtorName != null ? _.DebtorName.Id : (int?) null).Distinct().ToArrayAsync();
                    var names = (await _displayFormattedName.For(nameKeys.Where(_ => _.HasValue).Select(_ => _.Value).ToArray()))
                                .Select(d => new CodeDescription {Code = d.Key.ToString(), Description = d.Value.Name})
                                .OrderBy(_ => _.Description);
                    return nameKeys.Contains(null) ? new[] {new CodeDescription()}.Concat(names) : names;

                case Activity:
                    var activities = await results.Select(_ => new CodeDescription {Code = _.ActivityKey, Description = _.Activity})
                                                  .OrderBy(_ => _.Description)
                                                  .Distinct()
                                                  .ToArrayAsync();
                    return RearrangeEmpty(activities);
            }

            return Enumerable.Empty<dynamic>();

            IEnumerable<CodeDescription> RearrangeEmpty(IReadOnlyCollection<CodeDescription> list)
            {
                var containsEmpty = list.SingleOrDefault(_ => string.IsNullOrWhiteSpace(_.Code));

                return containsEmpty != null ? new[] {new CodeDescription()}.Concat(list.Except(new[] {containsEmpty})) : list;
            }
        }

        [HttpPost]
        [Route("export")]
        [RequiresNameAuthorization(PropertyPath = "exportParams.SearchParams.NameId")]
        [RequiresCaseAuthorization(PropertyPath = "exportParams.SearchParams.CaseIds")]
        public async Task Export(TimeSearchExportParams exportParams)
        {
            if (exportParams == null) throw new ArgumentNullException(nameof(exportParams));

            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, _securityContext.User, exportParams.SearchParams.StaffId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            
            var culture = _preferredCultureResolver.ResolveAll().ToArray();
            var queryParameters = exportParams.QueryParams;
            var dataQuery = _timeSearchService.Search(exportParams.SearchParams, queryParameters.Filters);
            List<TimeEntry> searchResults;

            if (queryParameters.SortBy != "name")
            {
                searchResults = queryParameters.SortBy == "totalDuration"
                    ? ApplySorting((await dataQuery.ToListAsync()).AsQueryable())
                        .ToList()
                    : await ApplySorting(dataQuery)
                        .ToListAsync();
                await _timesheetList.FormatNamesForDisplay(searchResults);
            }
            else
            {
                var data = await dataQuery.ToListAsync();
                await _timesheetList.FormatNamesForDisplay(data);
                searchResults = ApplySorting(data.AsQueryable()).ToList();
            }

            IQueryable<TimeEntry> ApplySorting(IQueryable<TimeEntry> query)
            {
                var mapCol = new Dictionary<string, string> {{"entryDate", "startTime"}};
                if (!string.IsNullOrWhiteSpace(queryParameters.SortBy) && mapCol.ContainsKey(queryParameters.SortBy))
                    queryParameters.SortBy = mapCol[queryParameters.SortBy];

                return query.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
            }

            var exportData = searchResults.Select(_ => JToken.FromObject(_).Value<JObject>().Properties().ToDictionary(k => k.Name, v => v.Value.ToObject<object>())).ToList();

            var exportRequest = new ExportRequest
            {
                ExportFormat = exportParams.ExportFormat,
                Columns = PrepareForExport(exportParams.Columns, culture),
                Rows = exportData,
                SearchPresentation = null,
                SearchExportContentId = exportParams.ContentId,
                RunBy = _securityContext.User.Id
            };

            var settings = _exportSettings.Load(_staticTranslator.TranslateWithDefault("accounting.time.query.reportTitle", culture), QueryContext.TimeEntrySearch);
            settings.LocalCurrencyCode = _siteControls.Read<string>(SiteControls.CURRENCY);

            var args = new ExportExecutionJobArgs
            {
                ExportRequest = exportRequest,
                Settings = settings
            };

            await _bus.PublishAsync(args);
        }

        IEnumerable<Column> PrepareForExport(IEnumerable<Column> columns, string[] culture)
        {
            var displaySeconds = _preferenceManager.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.DisplayTimeWithSeconds);
            const string resourcePrefix = "accounting.time.fields.";
            var data = new List<Column>();
            if (columns != null)
                data = columns.ToList();

            foreach (var column in data)
            {
                switch (column.Name)
                {
                    case nameof(TimeEntry.Start):
                    case nameof(TimeEntry.EntryDate):
                        column.Format = ColumnFormats.Date;
                        column.Title = _staticTranslator.TranslateWithDefault($"{resourcePrefix}date", culture);
                        break;
                    case nameof(TimeEntry.TotalDuration):
                    case nameof(TimeEntry.ElapsedTimeInSeconds):
                        column.Format = displaySeconds ? ColumnFormats.HoursWithSeconds : ColumnFormats.HoursWithMinutes;
                        column.Title = _staticTranslator.TranslateWithDefault($"{resourcePrefix}time", culture);
                        break;
                    case nameof(TimeEntry.NarrativeText):
                        column.Format = ColumnFormats.Text;
                        column.Title = _staticTranslator.TranslateWithDefault($"{resourcePrefix}narrativeText", culture);
                        break;
                    case nameof(TimeEntry.Notes):
                        column.Format = ColumnFormats.Text;
                        column.Title = _staticTranslator.TranslateWithDefault($"{resourcePrefix}notes", culture);
                        break;
                    case nameof(TimeEntry.LocalValue):
                        column.Title = _staticTranslator.TranslateWithDefault($"{resourcePrefix}localValue", culture);
                        column.Format = ColumnFormats.LocalCurrency;
                        break;
                    case nameof(TimeEntry.LocalDiscount):
                        column.Title = _staticTranslator.TranslateWithDefault($"{resourcePrefix}localDiscount", culture);
                        column.Format = ColumnFormats.LocalCurrency;
                        break;
                    case nameof(TimeEntry.ForeignValue):
                        column.Title = _staticTranslator.TranslateWithDefault($"{resourcePrefix}foreignValue", culture);
                        column.Format = ColumnFormats.Currency;
                        column.CurrencyCodeColumnName = nameof(TimeEntry.ForeignCurrency);
                        break;
                    case nameof(TimeEntry.ForeignDiscount):
                        column.Title = _staticTranslator.TranslateWithDefault($"{resourcePrefix}foreignDiscount", culture);
                        column.Format = ColumnFormats.Currency;
                        column.CurrencyCodeColumnName = nameof(TimeEntry.ForeignCurrency);
                        break;
                    case nameof(TimeEntry.ChargeOutRate):
                        column.Title = _staticTranslator.TranslateWithDefault($"{resourcePrefix}chargeOutRate", culture);
                        column.Format = ColumnFormats.Currency;
                        column.CurrencyCodeColumnName = nameof(TimeEntry.ForeignCurrency);
                        break;
                    case nameof(TimeEntry.TotalUnits):
                        column.Title = _staticTranslator.TranslateWithDefault($"{resourcePrefix}units", culture);
                        column.Format = ColumnFormats.Integer;
                        break;
                }
            }

            return data;
        }

        public class TimeSearchExportParams
        {
            public TimeSearchParams SearchParams { get; set; }
            public CommonQueryParameters QueryParams { get; set; }
            public ReportExportFormat ExportFormat { get; set; }
            public IEnumerable<Column> Columns { get; set; }
            public int ContentId { get; set; }
        }
    }
}