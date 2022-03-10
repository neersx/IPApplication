using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search
{
    public interface ISearchPresentationService
    {
        Task<SearchPresentation> GetSearchPresentation(QueryContext queryContext, int? queryKey = null, IEnumerable<SelectedColumn> selectedColumns = null, string presentationType = null);

        string GetMatchingColumnCode(QueryContext queryContext, string name);

        void UpdatePresentationForColumnSort(SearchPresentation presentation, string sortBy, string sortDirection);

        void UpdatePresentationForColumnFilterData(SearchPresentation presentation, string column, string codeKey);
    }

    public class SearchPresentationService : ISearchPresentationService
    {
        readonly IDbContext _dbContext;
        readonly IFilterableColumnsMapResolver _filterableColumnsMapResolver;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        IFilterableColumnsMap _filterableColumnsMap;

        public SearchPresentationService(ISecurityContext securityContext,
                                         IDbContext dbContext,
                                         IPreferredCultureResolver preferredCultureResolver,
                                         IFilterableColumnsMapResolver filterableColumnsMapResolver)
        {
            _securityContext = securityContext;
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _filterableColumnsMapResolver = filterableColumnsMapResolver;
        }

        public async Task<SearchPresentation> GetSearchPresentation(QueryContext queryContext, int? queryKey = null, IEnumerable<SelectedColumn> selectedColumns = null, string presentationType = null)
        {
            return await GetPresentation(queryContext, queryKey, selectedColumns, presentationType);
        }

        public string GetMatchingColumnCode(QueryContext queryContext, string name)
        {
            var columnMap = GetFilterableColumnMap(queryContext);
            return columnMap.Columns.ContainsKey(name) ? columnMap.Columns[name] : string.Empty;
        }

        public void UpdatePresentationForColumnSort(SearchPresentation presentation, string sortBy, string sortDirection)
        {
            // overwrite presentation configuration on Column sort
            if (string.IsNullOrWhiteSpace(sortBy) || string.IsNullOrWhiteSpace(sortDirection)) return;
            //if column exists in presentation
            if (!presentation.OutputRequests.Any(r => r.PublishName.Equals(sortBy, StringComparison.CurrentCultureIgnoreCase))) return;

            foreach (var r in presentation.OutputRequests)
            {
                if (r.PublishName.Equals(sortBy, StringComparison.CurrentCultureIgnoreCase))
                {
                    r.SortOrder = 1;
                    r.SortDirection = GetOrderDirValue(sortDirection);
                }
                else
                {
                    r.SortOrder = null;
                    r.SortDirection = null;
                }
            }
        }

        public void UpdatePresentationForColumnFilterData(SearchPresentation presentation, string column, string codeKey)
        {
            if (presentation.OutputRequests.Any(r => r.PublishName.Equals(column, StringComparison.CurrentCultureIgnoreCase)) &&
                presentation.OutputRequests.Any(r => r.PublishName.Equals(codeKey, StringComparison.CurrentCultureIgnoreCase)))
            {
                presentation.OutputRequests.RemoveAll(r => !(r.PublishName.Equals(column, StringComparison.CurrentCultureIgnoreCase)
                                                             || r.PublishName.Equals(codeKey, StringComparison.CurrentCultureIgnoreCase)));
            }
        }

        async Task<SearchPresentation> GetPresentation(QueryContext queryContext, int? queryKey, IEnumerable<SelectedColumn> selectedColumns = null, string presentationType = null)
        {
            var requirements = await _dbContext.ListSearchRequirements(_securityContext.User.Id,
                                                                       _preferredCultureResolver.Resolve(),
                                                                       (int) queryContext,
                                                                       queryKey,
                                                                       selectedColumns.ToXml(),
                                                                       null,
                                                                       presentationType,
                                                                       _securityContext.User.IsExternalUser);

            requirements.QueryContextKey = queryContext;
            requirements.UserId = _securityContext.User.Id;
            requirements.Culture = _preferredCultureResolver.Resolve();

            if (requirements.ColumnFormats.Any() && requirements.OutputRequests.Any())
            {
                foreach (var columnFormat in requirements.ColumnFormats)
                {
                    var outputColumn = requirements.OutputRequests?.Where(r => r.PublishName.Equals(columnFormat.Id)).FirstOrDefault();
                    var columnId = outputColumn?.Id;

                    if (string.IsNullOrWhiteSpace(columnId)) continue;

                    var columnMap = GetFilterableColumnMap(queryContext);

                    columnFormat.Filterable = requirements.OutputRequests.Any(r => columnMap.Columns.ContainsKey(columnId) && r.Id.Equals(columnMap.Columns[columnId]));
                    columnFormat.IsColumnFreezed = requirements.OutputRequests.Any(r => r.IsFreezeColumnIndex && r.Id == columnId);
                    columnFormat.GroupBySortDirection = outputColumn?.GroupBySortDirection;
                    columnFormat.GroupBySortOrder = outputColumn?.GroupBySortOrder;
                    columnFormat.ColumnItemId = columnId;
                }
            }

            var freezeColumnIndex = requirements.ColumnFormats.FindIndex(col => col.IsColumnFreezed);
            if (freezeColumnIndex > 0) requirements.ColumnFormats.GetRange(0, freezeColumnIndex).ForEach(x => x.IsColumnFreezed = true);

            return requirements;
        }

        static SortDirectionType GetOrderDirValue(string val)
        {
            if (string.IsNullOrWhiteSpace(val)) return SortDirectionType.Ascending;

            return val.Equals("asc", StringComparison.CurrentCultureIgnoreCase) || val.Equals("a", StringComparison.CurrentCultureIgnoreCase) ? SortDirectionType.Ascending : SortDirectionType.Descending;
        }

        IFilterableColumnsMap GetFilterableColumnMap(QueryContext queryContext)
        {
            return _filterableColumnsMap ?? (_filterableColumnsMap = _filterableColumnsMapResolver.Resolve(queryContext));
        }
    }

    public static class SelectedColumnsExtension
    {
        public static string ToXml(this IEnumerable<SelectedColumn> selectedColumns)
        {
            var sc = selectedColumns?.ToArray() ?? new SelectedColumn[0];
            if (!sc.Any()) return null;

            return new XElement("SelectedColumns",
                                sc.Select(_ => new XElement("Column",
                                                            new XElement("ColumnKey", _.ColumnKey),
                                                            new XElement("DisplaySequence", _.DisplaySequence),
                                                            new XElement("SortDirection", _.SortDirection),
                                                            new XElement("SortOrder", _.SortOrder),
                                                            new XElement("GroupBySortDirection", _.GroupBySortDirection),
                                                            new XElement("GroupBySortOrder", _.GroupBySortOrder),
                                                            new XElement("IsFreezeColumnIndex", _.IsFreezeColumnIndex)
                                                           ))
                               ).ToString();
        }
    }
}