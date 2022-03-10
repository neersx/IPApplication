using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search.Case;
using Inprotech.Web.Search.Columns;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Search
{
    [Authorize]
    [RoutePrefix("api/search")]
    public class SearchPresentationController : ApiController
    {
        readonly ICaseSearchService _caseSearch;
        readonly IDbContext _dbContext;
        readonly IPresentationColumnsResolver _presentationColumnsResolver;
        readonly ISavedQueries _savedQueries;
        readonly ISearchMaintainabilityResolver _searchMaintainabilityResolver;
        readonly ISecurityContext _securityContext;
        readonly ISavedSearchService _savedSearchService;
        readonly ISearchColumnMaintainabilityResolver _searchColumnMaintainabilityResolver;

        public SearchPresentationController(IPresentationColumnsResolver presentationColumnsResolver,
                                            ISavedQueries savedQueries,
                                            ISecurityContext securityContext,
                                            ICaseSearchService caseSearch,
                                            ISearchMaintainabilityResolver searchMaintainabilityResolver,
                                            IDbContext dbContext,
                                            ISavedSearchService savedSearchService,
                                            ISearchColumnMaintainabilityResolver searchColumnMaintainabilityResolver)
        {
            _presentationColumnsResolver = presentationColumnsResolver;
            _savedQueries = savedQueries;
            _securityContext = securityContext;
            _caseSearch = caseSearch;
            _searchMaintainabilityResolver = searchMaintainabilityResolver;
            _dbContext = dbContext;
            _savedSearchService = savedSearchService;
            _searchColumnMaintainabilityResolver = searchColumnMaintainabilityResolver;
        }

        [HttpGet]
        [Route("view/{queryContextKey}")]
        [NoEnrichment]
        public dynamic ViewData(QueryContext queryContextKey)
        {
            var userHasDefaultPresentation = _dbContext.Set<QueryPresentation>()
                                                       .Any(_ => _.ContextId == (int)queryContextKey
                                                                 && _.IsDefault
                                                                 && _.IdentityId == _securityContext.User.Id);

            var maintainability = _searchMaintainabilityResolver.Resolve(queryContextKey);
            var searchColumnMaintainability = _searchColumnMaintainabilityResolver.Resolve(queryContextKey);
            var canMaintainColumns = searchColumnMaintainability.CanCreateColumnSearch
                                     || searchColumnMaintainability.CanUpdateColumnSearch
                                     || searchColumnMaintainability.CanDeleteColumnSearch;

            return new
            {
                IsExternal = _securityContext.User.IsExternalUser,
                SavedQueries = _savedQueries.GetSavedPresentationQueries((int)queryContextKey),
                ImportanceOptions = _caseSearch.GetImportanceLevels(), // TODO: This should be in a different service
                maintainability.CanMaintainPublicSearch,
                maintainability.CanCreateSavedSearch,
                maintainability.CanUpdateSavedSearch,
                maintainability.CanDeleteSavedSearch,
                userHasDefaultPresentation,
                canMaintainColumns
            };
        }

        [HttpGet]
        [Route("presentation/available/{queryContextKey}")]
        [NoEnrichment]
        public IEnumerable<PresentationColumnView> AvailableColumns(QueryContext queryContextKey)
        {
            var columnGroups = _presentationColumnsResolver.AvailableColumnGroups(queryContextKey)
                                                           .Select(_ => new PresentationColumnView
                                                           {
                                                               Id = $"{_.GroupKey}_G",
                                                               GroupKey = _.GroupKey,
                                                               GroupDescription = _.GroupName,
                                                               DisplayName = _.GroupName,
                                                               IsGroup = true
                                                           });

            var availableColumns = _presentationColumnsResolver.AvailableColumns(queryContextKey)
                                                               .Select(_ => new PresentationColumnView
                                                               {
                                                                   Id = $"{_.ColumnKey}_C",
                                                                   GroupKey = _.GroupKey,
                                                                   ParentId = _.GroupKey.HasValue ? $"{_.GroupKey}_G" : null,
                                                                   ColumnKey = _.ColumnKey,
                                                                   ColumnDescription = _.Description,
                                                                   DisplayName = _.ColumnLabel,
                                                                   IsGroup = false,
                                                                   ProcedureItemId = _.ProcedureItemId,
                                                                   IsMandatory=_.IsMandatory
                                                               });

            return columnGroups.Union(availableColumns);
        }

        [HttpGet]
        [Route("presentation/selected/{queryContextKey}/{queryKey}")]
        [NoEnrichment]
        public IEnumerable<PresentationColumnView> SelectedColumns(QueryContext queryContextKey, int? queryKey)
        {
            var result = _presentationColumnsResolver.Resolve(queryKey, queryContextKey).ToList();

            if (result.Count == 0 && queryKey.HasValue)
            {
                result = _presentationColumnsResolver.Resolve(null, queryContextKey).ToList();
            }

            var freezeColumnDisplaySeq = result.FirstOrDefault(col => col.IsFreezeColumnIndex)?.DisplaySequence;

            return from _ in result
                   let isColumnFrozen = _.DisplaySequence.HasValue && freezeColumnDisplaySeq.HasValue && _.DisplaySequence <= freezeColumnDisplaySeq
                   orderby _.DisplaySequence.HasValue descending, _.DisplaySequence, _.ColumnLabel
                   select new PresentationColumnView
                   {
                       Id = $"{_.ColumnKey}_C",
                       ParentId = _.GroupKey.HasValue ? $"{_.GroupKey}_G" : null,
                       ColumnKey = _.ColumnKey,
                       ColumnDescription = _.Description,
                       DisplayName = _.ColumnLabel,
                       DisplaySequence = _.DisplaySequence,
                       Hidden = !_.DisplaySequence.HasValue,
                       SortDirection = _.SortDirection,
                       SortOrder = _.SortOrder,
                       IsGroup = false,
                       IsDefault = _.IsDefault,
                       GroupKey = _.GroupKey,
                       ProcedureItemId = _.ProcedureItemId,
                       FreezeColumn = isColumnFrozen,
                       GroupBySortDirection = _.GroupBySortDirection,
                       GroupBySortOrder = _.GroupBySortOrder,
                       IsMandatory=_.IsMandatory
                   };
        }

        [HttpPut]
        [Route("presentation/revertToDefault/{queryContextKey}")]
        [NoEnrichment]
        public bool RevertToDefault(QueryContext queryContextKey)
        {
            CheckAccess(queryContextKey);

            return _savedSearchService.RevertToDefault(queryContextKey);
        }

        [HttpPut]
        [Route("presentation/makeMyDefaultPresentation")]
        [NoEnrichment]
        public bool MakeMyDefaultPresentation(SavedSearch savedSearch)
        {
            if (savedSearch == null) throw new ArgumentNullException(nameof(savedSearch));

            CheckAccess(savedSearch.QueryContext);

            return _savedSearchService.MakeMyDefaultPresentation(savedSearch);
        }

        void CheckAccess(QueryContext queryContext)
        {
            var maintainability = _searchMaintainabilityResolver.Resolve(queryContext);
            if (!maintainability.CanUpdateSavedSearch) throw new UnauthorizedAccessException();
        }
    }

    public class PresentationColumnView
    {
        public string Id { get; set; }
        public string ParentId { get; set; }
        public int ColumnKey { get; set; }
        public string ColumnDescription { get; set; }
        public int? GroupKey { get; set; }
        public string GroupDescription { get; set; }
        public string DisplayName { get; set; }
        public bool IsGroup { get; set; }
        public int? DisplaySequence { get; set; }
        public int? SortOrder { get; set; }
        public string SortDirection { get; set; }
        public bool Hidden { get; set; }
        public bool FreezeColumn { get; set; }
        public bool IsDefault { get; set; }
        public string ProcedureItemId { get; set; }
        public int? GroupBySortOrder { get; set; }
        public string GroupBySortDirection { get; set; }
        public bool IsMandatory { get; set; }
    }
}