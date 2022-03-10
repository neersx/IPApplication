using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Xml.Linq;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Storage;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Analytics;
using Inprotech.Web.Configuration.TaskPlanner;
using Inprotech.Web.Dates;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.Case;
using Inprotech.Web.Search.Case.CaseSearch;
using Inprotech.Web.Search.TaskPlanner.Reminders;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.Reminders.Search;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.TaskPlanner;

namespace Inprotech.Web.Search.TaskPlanner
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerApplication)]
    [RoutePrefix("api/taskplanner")]
    public class TaskPlannerController : ApiController
    {
        readonly IAdHocDates _adHocDates;
        readonly QueryContext _allowedQueryContext;
        readonly IBus _bus;
        readonly ICaseSearchService _caseSearch;
        readonly IContentHasher _contentHasher;
        readonly IDbContext _dbContext;
        readonly ILastWorkingDayFinder _lastWorkingDayFinder;
        readonly Func<DateTime> _now;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IReminderComments _reminderComments;
        readonly IReminderManager _reminderManager;
        readonly ISearchExportService _searchExportService;
        readonly ISearchService _searchService;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;
        readonly IStaticTranslator _staticTranslator;
        readonly ISubjectSecurityProvider _subjectSecurityProvider;
        readonly ITaskPlannerRowSelectionService _taskPlannerRowSelectionService;
        readonly ITaskPlannerTabResolver _taskPlannerTabResolver;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IUserFilteredTypes _userFilteredTypes;
        readonly IUserPreferenceManager _userPreferences;

        public TaskPlannerController(IDbContext dbContext, 
                                     ISecurityContext securityContext,
                                     ISearchService searchService,
                                     Func<DateTime> now,
                                     IPreferredCultureResolver preferredCultureResolver,
                                     IStaticTranslator staticTranslator, 
                                     ILastWorkingDayFinder lastWorkingDayFinder,
                                     ICaseSearchService caseSearch,
                                     IUserFilteredTypes userFilteredTypes,
                                     ISiteControlReader siteControlReader,
                                     ITaskSecurityProvider taskSecurityProvider,
                                     IReminderComments reminderComments,
                                     ISearchExportService searchExportService,
                                     IReminderManager reminderManager,
                                     IUserPreferenceManager userPreferences,
                                     ITaskPlannerRowSelectionService taskPlannerRowSelectionService,
                                     IAdHocDates adHocDates,
                                     ISubjectSecurityProvider subjectSecurityProvider,
                                     IBus bus,
                                     IContentHasher contentHasher,
                                     ITaskPlannerTabResolver taskPlannerTabResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _searchService = searchService;
            _now = now;
            _allowedQueryContext = QueryContext.TaskPlanner;
            _preferredCultureResolver = preferredCultureResolver;
            _staticTranslator = staticTranslator;
            _lastWorkingDayFinder = lastWorkingDayFinder;
            _caseSearch = caseSearch;
            _userFilteredTypes = userFilteredTypes;
            _siteControlReader = siteControlReader;
            _taskSecurityProvider = taskSecurityProvider;
            _reminderComments = reminderComments;
            _searchExportService = searchExportService;
            _reminderManager = reminderManager;
            _taskPlannerRowSelectionService = taskPlannerRowSelectionService;
            _adHocDates = adHocDates;
            _userPreferences = userPreferences;
            _subjectSecurityProvider = subjectSecurityProvider;
            _bus = bus;
            _contentHasher = contentHasher;
            _taskPlannerTabResolver = taskPlannerTabResolver;
        }

        [Route("viewData")]
        [HttpPost]
        public async Task<dynamic> Get(TaskPlannerViewDataRequest request)
        {
            if (QueryContext.TaskPlanner != request.QueryContext) return BadRequest();

            await TrackTransaction();

            var showReminderComments = _siteControlReader.Read<bool>(SiteControls.ReminderCommentsEnabledInTaskPlanner);
            return new
            {
                isExternal = _securityContext.User.IsExternalUser,
                isPublic = request.QueryKey.HasValue && _dbContext.Set<Query>().FirstOrDefault(_ => _.Id == request.QueryKey.Value)?.IdentityId == null,
                UserNameKey = _securityContext.User.NameId,
                Query = request.QueryKey.HasValue ? GetQueryData(request.QueryKey.Value) : null,
                QueryContext = (int)QueryContext.TaskPlanner,
                TimePeriods = await GetTimePeriodAsync(),
                Criteria = GetSavedCriteria(request),
                MaintainEventNotes = _taskSecurityProvider.HasAccessTo(ApplicationTask.AnnotateDueDates),
                MaintainEventNotesPermissions = new { Insert = _taskSecurityProvider.HasAccessTo(ApplicationTask.AnnotateDueDates, ApplicationTaskAccessLevel.Create), Update = _taskSecurityProvider.HasAccessTo(ApplicationTask.AnnotateDueDates, ApplicationTaskAccessLevel.Modify) },
                ShowReminderComments = showReminderComments,
                MaintainReminderComments = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainReminder),
                ReplaceEventNotes = _taskSecurityProvider.HasAccessTo(ApplicationTask.ReplaceEventNotes),
                ReminderDeleteButton = _siteControlReader.Read<int>(SiteControls.ReminderDeleteButton),
                MaintainTaskPlannerSearch = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaskPlannerSearch),
                MaintainTaskPlannerSearchPermission = new
                {
                    Insert = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaskPlannerSearch, ApplicationTaskAccessLevel.Create),
                    Update = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaskPlannerSearch, ApplicationTaskAccessLevel.Modify),
                    Delete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaskPlannerSearch, ApplicationTaskAccessLevel.Delete)
                },
                MaintainPublicSearch = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch),
                CanFinaliseAdhocDates = _taskSecurityProvider.HasAccessTo(ApplicationTask.FinaliseAdHocDate),
                ResolveReasons = _adHocDates.ResolveReasons(),
                ExportLimit = _siteControlReader.Read<int?>(SiteControls.ExportLimit),
                CanCreateAdhocDate = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainAdHocDate, ApplicationTaskAccessLevel.Create),
                AutoRefreshGrid = _userPreferences.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.AutomaticallyRefreshTaskPlannerResults),
                CanViewAttachments = _subjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments),
                CanAddCaseAttachments = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Create),
                CanMaintainAdhocDate = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainAdHocDate, ApplicationTaskAccessLevel.Modify),
                CanChangeDueDateResponsibility = _taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeDueDateResponsibility, ApplicationTaskAccessLevel.Execute),
                ShowLinksForInprotechWeb = _taskSecurityProvider.HasAccessTo(ApplicationTask.ShowLinkstoWeb, ApplicationTaskAccessLevel.Execute),
                ProvideDueDateInstructions = _taskSecurityProvider.HasAccessTo(ApplicationTask.ProvideDueDateInstructions, ApplicationTaskAccessLevel.Execute)
            };
        }

        [Route("userPreference/viewData")]
        [HttpGet]
        public async Task<dynamic> GetUserPreferenceViewData()
        {
            return new
            {
                MaintainTaskPlannerSearch = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaskPlannerSearch),
                DefaultTabsData = await _taskPlannerTabResolver.ResolveProfileConfiguration(),
                PreferenceData = new TaskPlannerPreferenceModel
                {
                    AutoRefreshGrid = _userPreferences.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.AutomaticallyRefreshTaskPlannerResults),
                    Tabs = await _taskPlannerTabResolver.ResolveUserConfiguration()
                }
            };
        }

        [Route("userPreference/set")]
        [HttpPost]
        public async Task SetUserPreference(TaskPlannerPreferenceModel request)
        {
            _userPreferences.SetPreference(_securityContext.User.Id, KnownSettingIds.AutomaticallyRefreshTaskPlannerResults, request.AutoRefreshGrid);

            if (!_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaskPlannerSearch))
            {
                return;
            }

            var tabs = _dbContext.Set<TaskPlannerTab>()
                                 .Where(_ => _.IdentityId == _securityContext.User.Id)
                                 .Select(x => x);

            _dbContext.RemoveRange(tabs);
            _dbContext.AddRange(request.Tabs.Where(x => !x.IsLocked).Select(x => new TaskPlannerTab(x.SavedSearch.Key, x.TabSequence, _securityContext.User.Id)));
            await _dbContext.SaveChangesAsync();
            await _taskPlannerTabResolver.InvalidateUserConfiguration();
        }

        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [Route("dismissReminders")]
        [HttpPost]
        public async Task<ReminderResult> DismissReminders(DismissReminderRequest request)
        {
            request.TaskPlannerRowKeys = await _taskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(request);
            return await _reminderManager.Dismiss(request);
        }

        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [Route("deferReminders")]
        [HttpPost]
        public async Task<ReminderResult> DeferReminders(DeferReminderRequest request)
        {
            request.TaskPlannerRowKeys = await _taskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(request);
            return await _reminderManager.Defer(request);
        }

        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [Route("readOrUnreadReminders")]
        [HttpPost]
        [RequiresAccessTo(ApplicationTask.MaintainReminder)]
        public async Task<int> MarkReminderAsReadUnread(ReminderReadUnReadRequest request)
        {
            request.TaskPlannerRowKeys = await _taskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(request);
            return await _reminderManager.MarkAsReadOrUnread(request);
        }

        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [Route("changeDueDateResponsibility")]
        [HttpPost]
        [RequiresAccessTo(ApplicationTask.MaintainReminder)]
        public async Task<ReminderResult> ChangeDueDateResponsibility(DueDateResponsibilityRequest request)
        {
            request.TaskPlannerRowKeys = await _taskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(request);
            return await _reminderManager.ChangeDueDateResponsibility(request);
        }
        
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [Route("getDueDateResponsibility/{taskPlannerRowKey}")]
        [HttpGet]
        [RequiresAccessTo(ApplicationTask.MaintainReminder)]
        public async Task<Picklists.Name> GetDueDateResponsibility(string taskPlannerRowKey)
        {
            return await _reminderManager.GetDueDateResponsibility(taskPlannerRowKey);
        }

        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [Route("forwardReminders")]
        [HttpPost]
        [RequiresAccessTo(ApplicationTask.MaintainReminder)]
        public async Task<ReminderResult> ForwardReminders(ForwardReminderRequest request)
        {
            request.TaskPlannerRowKeys = await _taskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(request);
            return await _reminderManager.ForwardReminders(request);
        }

        [Route("getTaskPlannerTabs")]
        [HttpPost]
        public async Task<dynamic> GetTaskPlannerTabs(TaskPlannerViewDataRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            if (QueryContext.TaskPlanner != request.QueryContext) HttpResponseExceptionHelper.RaiseBadRequest(request.QueryContext.ToString());
            
            var userConfiguration = await _taskPlannerTabResolver.ResolveUserConfiguration();
            return userConfiguration.Select(_ => _.SavedSearch).ToArray();
        }

        [HttpGet]
        [Route("comments/{rowKey}")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainReminder)]
        public ReminderCommentsPayload ReminderComments(string rowKey)
        {
            return _reminderComments.Get(rowKey);
        }

        [HttpGet]
        [Route("comments/{rowKey}/count")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainReminder)]
        public int ReminderCommentsCount(string rowKey)
        {
            return _reminderComments.Count(rowKey);
        }

        [HttpPost]
        [AppliesToComponent(KnownComponents.TaskPlanner)]
        [Route("comments/update")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainReminder)]
        public dynamic SaveReminderComments(ReminderCommentsSaveDetails comments)
        {
            return _reminderComments.Update(comments);
        }

        [HttpPost]
        [Route("savedSearchQuery")]
        public dynamic GetSavedSearchQuery(TaskPlannerViewDataRequest request)
        {
            return new
            {
                Query = request.QueryKey.HasValue ? GetQueryData(request.QueryKey.Value) : null,
                Criteria = GetSavedCriteria(request)
            };
        }

        [HttpPost]
        [Route("columns")]
        [NoEnrichment]
        public async Task<IEnumerable<SearchResult.Column>> SearchColumns(ColumnRequestParams columnRequest)
        {
            if (columnRequest == null) throw new ArgumentNullException(nameof(columnRequest));
            if (columnRequest.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);
            return await _searchService.GetSearchColumns(
                                                         columnRequest.QueryContext,
                                                         columnRequest.QueryKey,
                                                         columnRequest.SelectedColumns,
                                                         columnRequest.PresentationType);
        }

        [HttpPost]
        [Route("savedSearch")]
        [NoEnrichment]
        public async Task<SearchResult> RunSavedSearch(SavedSearchRequestParams<TaskPlannerRequestFilter> searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(searchRequestParams));
            if (searchRequestParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await RunSearch(searchRequestParams);
        }

        [HttpPost]
        [Route("filterData")]
        [NoEnrichment]
        public async Task<IEnumerable<CodeDescription>> GetFilterDataForColumn(ColumnFilterParams<TaskPlannerRequestFilter> columnFilterParams)
        {
            if (columnFilterParams == null) throw new ArgumentNullException(nameof(columnFilterParams));
            if (columnFilterParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await _searchService.GetFilterDataForColumn(columnFilterParams);
        }

        [Route("searchBuilder/viewData")]
        [HttpGet]
        public dynamic SearchBuilderViewData()
        {
            var culture = _preferredCultureResolver.Resolve();
            var numberTypes = _userFilteredTypes.NumberTypes()
                                                .Select(_ => new
                                                {
                                                    Key = _.NumberTypeCode,
                                                    Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
                                                });

            var nameTypes = _userFilteredTypes.NameTypes()
                                              .Select(_ => new
                                              {
                                                  Key = _.NameTypeCode,
                                                  Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
                                              });

            var showCeasedNames = _siteControlReader.Read<bool>(SiteControls.DisplayCeasedNames);
            return new
            {
                ImportanceLevels = _caseSearch.GetImportanceLevels(),
                NumberTypes = numberTypes,
                NameTypes = nameTypes,
                ShowCeasedNames = showCeasedNames,
                ShowEventNoteType = !_securityContext.User.IsExternalUser || _dbContext.Set<EventNoteType>().Any(_ => _.IsExternal)
            };
        }

        [HttpPost]
        [Route("export")]
        [NoEnrichment]
        public async Task Export(SearchExportParams<TaskPlannerRequestFilter> searchExportParams)
        {
            if (searchExportParams == null) throw new ArgumentNullException(nameof(searchExportParams));
            if (searchExportParams.QueryContext != _allowedQueryContext) throw new HttpResponseException(HttpStatusCode.BadRequest);

            if (searchExportParams.DeselectedIds != null && searchExportParams.DeselectedIds.Any())
            {
                var taskPlannerRowKeys = new SearchElement
                {
                    Value = string.Join(",", searchExportParams.DeselectedIds),
                    Operator = (short)CollectionExtensions.FilterOperator.NotIn
                };
                var request = searchExportParams.Criteria.SearchRequest ?? new TaskPlannerRequest();

                request.RowKeys = taskPlannerRowKeys;
                searchExportParams.Criteria.SearchRequest = request;
            }

            await _searchExportService.Export(searchExportParams);
        }

        async Task<SearchResult> RunSearch(SavedSearchRequestParams<TaskPlannerRequestFilter> searchRequestParams)
        {
            if (searchRequestParams.QueryKey.HasValue && searchRequestParams.Criteria == null)
            {
                return await _searchService.RunSavedSearch(searchRequestParams);
            }

            if (searchRequestParams.QueryKey.HasValue && searchRequestParams.Criteria != null)
            {
                return await _searchService.RunEditedSavedSearch(searchRequestParams);
            }

            return await _searchService.RunSearch(searchRequestParams);
        }

        [Route("getEmailContent")]
        [HttpPost]
        public async Task<IEnumerable<TaskPlannerEmailContent>> GetEmailContent(ReminderActionRequest request)
        {
            return await _reminderManager.GetEmailContent(await _taskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(request));
        }

        dynamic GetQueryData(int queryKey)
        {
            var query = _dbContext.Set<Query>().FirstOrDefault(_ => _.Id == queryKey && _.ContextId == (int)QueryContext.TaskPlanner);
            if (query == null) return null;

            var culture = _preferredCultureResolver.Resolve();
            return new
            {
                Key = query.Id,
                SearchName = DbFuncs.GetTranslation(query.Name, null, null, culture),
                query.PresentationId,
                Description = DbFuncs.GetTranslation(query.Description, null, null, culture)
            };
        }

        dynamic GetSavedCriteria(TaskPlannerViewDataRequest request)
        {
            var dateOperator = string.Empty;
            DateTime? fromDate = null;
            DateTime? toDate = null;
            var useDueDate = 0;
            var useReminderDate = 0;
            var names = new List<Picklists.Name>();
            var nameGroups = new List<NameGroupPicklistItem>();
            int? timePeriodId = null;
            var sinceLastWorkingDay = 0;
            if (request.QueryKey.HasValue)
            {
                var filterId = _dbContext.Set<Query>().FirstOrDefault(_ => _.Id == request.QueryKey.Value)?.FilterId;
                var xmlCriteria = _dbContext.Set<QueryFilter>().FirstOrDefault(_ => _.Id == filterId)?.XmlFilterCriteria;

                if (!string.IsNullOrWhiteSpace(xmlCriteria))
                {
                    var xDoc = XDocument.Parse(xmlCriteria);
                    var xmlFilterCriteria = xDoc.Descendants("FilterCriteria").FirstOrDefault();
                    var rangeType = xmlFilterCriteria.GetXPathStringValue("Dates/PeriodRange") != null ? 1 : 0;
                    var rangeXpath = rangeType == 0 ? "Dates/DateRange" : "Dates/PeriodRange";
                    var fromPathString = xmlFilterCriteria.GetXPathStringValue(rangeXpath + "/From");
                    var toPathString = xmlFilterCriteria.GetXPathStringValue(rangeXpath + "/To");
                    if (rangeType == 1)
                    {
                        var periodType = xmlFilterCriteria.GetXPathStringValue(rangeXpath + "/Type");
                        var fromPeriod = fromPathString != null ? Convert.ToInt16(fromPathString) : (short?)null;
                        var toPeriod = toPathString != null ? Convert.ToInt16(toPathString) : (short?)null;
                        var dateValue = GetDates(new PeriodRange
                        {
                            Type = periodType,
                            From = fromPeriod,
                            To = toPeriod
                        });
                        fromDate = dateValue.From;
                        toDate = dateValue.To;
                    }
                    else
                    {
                        fromDate = fromPathString != null ? Convert.ToDateTime(fromPathString) : null;
                        toDate = toPathString != null ? Convert.ToDateTime(toPathString) : null;
                    }

                    dateOperator = xmlFilterCriteria.GetAttributeOperatorValueForXPathElement(rangeXpath, "Operator", Operators.Between);
                    useDueDate = Convert.ToInt32(xmlFilterCriteria.GetAttributeOperatorValueForXPathElement("Dates", "UseDueDate", "0"));
                    useReminderDate = Convert.ToInt32(xmlFilterCriteria.GetAttributeOperatorValueForXPathElement("Dates", "UseReminderDate", "0"));

                    var xPath = "BelongsTo/NameKey";
                    var element = xmlFilterCriteria.GetXPathElement(xPath);
                    if (element != null && element.GetAttributeIntValue("IsCurrentUser") == 1)
                    {
                        names.Add(new Picklists.Name
                        {
                            Key = _securityContext.User.Name.Id,
                            Code = _securityContext.User.Name.NameCode,
                            DisplayName = _securityContext.User.Name.Formatted()
                        });
                    }

                    xPath = "BelongsTo/NameKeys";
                    element = xmlFilterCriteria.GetXPathElement(xPath);
                    if (element != null)
                    {
                        var selectedNameKeys = element.Value.Split(',').Select(int.Parse).ToArray();
                        var selectedNames = _dbContext.Set<InprotechKaizen.Model.Names.Name>().Where(_ => selectedNameKeys.Contains(_.Id)).Select(x => x).ToList();
                        names.AddRange(selectedNames.Select(_ => new Picklists.Name
                        {
                            Key = _.Id,
                            Code = _.NameCode,
                            DisplayName = _.Formatted()
                        }));
                    }

                    xPath = "BelongsTo/MemberOfGroupKeys";
                    element = xmlFilterCriteria.GetXPathElement(xPath);
                    if (element != null)
                    {
                        var selectedNameGroups = element.Value.Split(',').Select(int.Parse).ToArray();
                        nameGroups.AddRange(_dbContext.Set<NameFamily>().Where(_ => selectedNameGroups.Contains(_.Id)).Select(_ => new NameGroupPicklistItem
                        {
                            Key = _.Id,
                            Title = _.FamilyTitle,
                            Comments = _.FamilyComments
                        }));
                    }

                    xPath = "BelongsTo/MemberOfGroupKey";
                    element = xmlFilterCriteria.GetXPathElement(xPath);
                    if (element != null && element.GetAttributeIntValue("IsCurrentUser") == 1)
                    {
                        var myGroup = _dbContext.Set<InprotechKaizen.Model.Names.Name>().Single(_ => _.Id == _securityContext.User.Name.Id).NameFamily;
                        if (myGroup != null)
                        {
                            nameGroups.Add(new NameGroupPicklistItem
                            {
                                Key = myGroup.Id,
                                Title = myGroup.FamilyTitle,
                                Comments = myGroup.FamilyComments
                            });
                        }
                    }
                }
            }
            else if (request.FilterCriteria != null)
            {
                var dates = request.FilterCriteria.SearchRequest?.Dates;
                if (dates != null)
                {
                    useDueDate = dates.UseDueDate;
                    useReminderDate = dates.UseReminderDate;
                    dateOperator = dates.DateRange != null ? dates.DateRange.Operator : dates.PeriodRange != null ? dates.PeriodRange.Operator : Operators.Between;

                    if (dates.DateRange != null && (dates.DateRange.From.HasValue || dates.DateRange.To.HasValue))
                    {
                        fromDate = dates.DateRange.From;
                        toDate = dates.DateRange.To;
                    }
                    else if (dates.PeriodRange != null && (dates.PeriodRange.From.HasValue || dates.PeriodRange.To.HasValue))
                    {
                        var periodRange = GetDates(dates.PeriodRange);
                        fromDate = periodRange.From;
                        toDate = periodRange.To;
                    }

                    if (dates.SinceLastWorkingDay == 1)
                    {
                        timePeriodId = 14;
                        sinceLastWorkingDay = 1;
                        fromDate = _lastWorkingDayFinder.GetLastWorkingDayAsync().Result;
                    }
                }

                var belongsTo = request.FilterCriteria.SearchRequest?.BelongsTo;
                if (belongsTo?.NameKeys?.Value != null && !string.IsNullOrWhiteSpace(belongsTo.NameKeys.Value))
                {
                    var selectedNameKeys = belongsTo.NameKeys.Value.Split(',').Select(int.Parse).ToArray();
                    var selectedNames = _dbContext.Set<InprotechKaizen.Model.Names.Name>().Where(_ => selectedNameKeys.Contains(_.Id)).Select(x => x).ToList();
                    names.AddRange(selectedNames.Select(_ => new Picklists.Name
                    {
                        Key = _.Id,
                        Code = _.NameCode,
                        DisplayName = _.Formatted()
                    }));
                }
                else if (belongsTo?.MemberOfGroupKeys?.Value != null && !string.IsNullOrWhiteSpace(belongsTo.MemberOfGroupKeys.Value))
                {
                    var selectedNameGroups = belongsTo.MemberOfGroupKeys.Value.Split(',').Select(int.Parse).ToArray();
                    nameGroups.AddRange(_dbContext.Set<NameFamily>().Where(_ => selectedNameGroups.Contains(_.Id)).Select(_ => new NameGroupPicklistItem
                    {
                        Key = _.Id,
                        Title = _.FamilyTitle,
                        Comments = _.FamilyComments
                    }));
                }
                else if (belongsTo?.NameKey?.IsCurrentUser != null && belongsTo.NameKey.IsCurrentUser == 1)
                {
                    names.Add(new Picklists.Name
                    {
                        Key = _securityContext.User.Name.Id,
                        Code = _securityContext.User.Name.NameCode,
                        DisplayName = _securityContext.User.Name.Formatted()
                    });
                }
                else if (belongsTo?.MemberOfGroupKey?.IsCurrentUser != null && belongsTo.MemberOfGroupKey.IsCurrentUser == 1)
                {
                    var myGroup = _dbContext.Set<InprotechKaizen.Model.Names.Name>().Single(_ => _.Id == _securityContext.User.Name.Id).NameFamily;
                    if (myGroup != null)
                    {
                        nameGroups.Add(new NameGroupPicklistItem
                        {
                            Key = myGroup.Id,
                            Title = myGroup.FamilyTitle,
                            Comments = myGroup.FamilyComments
                        });
                    }
                }
            }

            return new
            {
                HasNameGroup = nameGroups.Count > 0,
                TimePeriodId = timePeriodId,
                BelongsTo = new
                {
                    Names = names,
                    NameGroups = nameGroups
                },
                request.FilterCriteria?.SearchRequest?.ImportanceLevel,
                DateFilter = new
                {
                    UseDueDate = useDueDate,
                    UseReminderDate = useReminderDate,
                    SinceLastWorkingDay = sinceLastWorkingDay,
                    Operator = dateOperator,
                    From = fromDate,
                    To = toDate
                }
            };
        }

        dynamic GetDates(PeriodRange range)
        {
            DateTime? from = null;
            DateTime? to = null;
            var today = _now();

            switch (range.Type)
            {
                case "D":
                    from = range.From.HasValue ? today.AddDays(range.From.Value) : null;
                    to = range.To.HasValue ? today.AddDays(range.To.Value) : null;
                    break;
                case "W":
                    from = range.From.HasValue ? today.AddDays(range.From.Value * 7) : null;
                    to = range.To.HasValue ? today.AddDays(range.To.Value * 7) : null;
                    break;
                case "M":
                    from = range.From.HasValue ? today.AddMonths(range.From.Value) : null;
                    to = range.To.HasValue ? today.AddMonths(range.To.Value) : null;
                    break;
                case "Y":
                    from = range.From.HasValue ? today.AddYears(range.From.Value) : null;
                    to = range.To.HasValue ? today.AddYears(range.To.Value) : null;
                    break;
            }

            return new
            {
                From = from,
                To = to
            };
        }

        async Task<IEnumerable<TimePeriod>> GetTimePeriodAsync()
        {
            var culture = _preferredCultureResolver.ResolveAll().ToList();

            var firstDayOfThisWeek = _now().AddDays(-((int)_now().DayOfWeek - 1));
            var firstDayOfThisMonth = _now().AddDays(-(_now().Day - 1));
            var result = new List<TimePeriod>
            {
                new() { Id = 1, Description = _staticTranslator.Translate("picklist.timePeriod.dateRange", culture), FromDate = _now(), ToDate = _now() },
                new() { Id = 15, Description = _staticTranslator.Translate("taskPlanner.today", culture), FromDate = _now(), ToDate = _now() },
                new() { Id = 2, Description = _staticTranslator.Translate("picklist.timePeriod.thisWeek", culture), FromDate = firstDayOfThisWeek, ToDate = firstDayOfThisWeek.AddDays(6) },
                new() { Id = 3, Description = _staticTranslator.Translate("picklist.timePeriod.thisMonth", culture), FromDate = firstDayOfThisMonth, ToDate = firstDayOfThisMonth.AddMonths(1).AddDays(-1) },
                new() { Id = 4, Description = _staticTranslator.Translate("picklist.timePeriod.nextWeek", culture), FromDate = firstDayOfThisWeek.AddDays(7), ToDate = firstDayOfThisWeek.AddDays(13) },
                new() { Id = 5, Description = _staticTranslator.Translate("picklist.timePeriod.nextMonth", culture), FromDate = firstDayOfThisMonth.AddMonths(1), ToDate = firstDayOfThisMonth.AddMonths(2).AddDays(-1) },
                new() { Id = 6, Description = _staticTranslator.Translate("picklist.timePeriod.overdue", culture), FromDate = null, ToDate = _now().AddDays(-1) },
                new() { Id = 14, Description = _staticTranslator.Translate("picklist.timePeriod.sinceLastWorkDay", culture), FromDate = await _lastWorkingDayFinder.GetLastWorkingDayAsync(), ToDate = null }
            };

            return result;
        }

        async Task TrackTransaction()
        {
            await _bus.PublishAsync(new TransactionalAnalyticsMessage
            {
                EventType = TransactionalEventTypes.TaskPlannerAccessed,
                Value = _contentHasher.ComputeHash(_securityContext.User.Id.ToString())
            });
        }
    }

    public class TimePeriod
    {
        public int Id { get; set; }

        public string Description { get; set; }

        public DateTime? FromDate { get; set; }

        public DateTime? ToDate { get; set; }
    }

    public class TaskPlannerViewDataRequest
    {
        public int? QueryKey { get; set; }
        public QueryContext QueryContext { get; set; }

        public TaskPlannerRequestFilter FilterCriteria { get; set; }
    }

    public class TaskPlannerPreferenceModel
    {
        public bool AutoRefreshGrid { get; set; }
        public TabData[] Tabs { get; set; }
    }

    public class TabData
    {
        public int TabSequence { get; set; }
        public bool IsLocked { get; set; }
        public QueryData SavedSearch { get; set; }
    }
}