using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Portal;
using Inprotech.Web.Search;

namespace Inprotech.Web.SavedSearch
{
    public interface ISavedSearchMenu
    {
        IEnumerable<AppsMenu.AppsMenuItem> Build(QueryContext queryContextKey, string search);
    }

    public class SavedSearchMenu : ISavedSearchMenu
    {
        readonly ISavedQueries _savedQueries;
        string SearchUrl = "#/search-result?queryContext={0}&queryKey={1}";
        const string PublicIcon = "cpa-icon-users";
        const string PrivateIcon = "cpa-icon-lg";

        public SavedSearchMenu(ISavedQueries savedQueries)
        {
            _savedQueries = savedQueries;
        }
        public IEnumerable<AppsMenu.AppsMenuItem> Build(QueryContext queryContextKey, string search)
        {

            var results = _savedQueries.Get(search, queryContextKey, QueryType.All)
                                       .Select(_ => new SavedQueryData
                                       {
                                           Key = _.Key,
                                           Name = _.Name,
                                           Description = _.Description,
                                           IsPublic = _.IsPublic,
                                           IsMaintainable = _.IsMaintainable,
                                           IsRunable = _.IsRunable,
                                           IsReportOnly = _.IsReportOnly,
                                           GroupKey = _.GroupKey,
                                           GroupName = _.GroupName
                                       }).Where(_ => !_.IsReportOnly);

            var queryData = results as SavedQueryData[] ?? results.ToArray();

            var hasPublicSearch = queryData.Any(_ => _.IsPublic);

            var queries = queryData.Where(_ => !_.GroupKey.HasValue)
                                 .OrderBy(_ => _.IsPublic)
                                 .ThenBy(_ => _.Name)
                                 .Select(_ => new AppsMenu.AppsMenuItem(_.Key.ToString())
                                    {
                                      Text = _.Name,
                                      Icon = hasPublicSearch ? _.IsPublic ? PublicIcon : PrivateIcon : null,
                                      Url= string.Format(SearchUrl, Convert.ToInt32(queryContextKey), _.Key),
                                      Description = GetDescription(_),
                                      CanEdit = _.IsMaintainable
                                    });

            var groupQueries = queryData.Where(_ => _.GroupKey.HasValue)
                                 .OrderBy(_ => _.GroupName)
                                 .Select(_ => new AppsMenu.AppsMenuItem(_.GroupKey + "^Group")
                                      {
                                         Text = _.GroupName,
                                         Description = _.GroupName.Length > 24 ? _.GroupName : string.Empty
                                      }).DistinctBy(_ => _.Key).ToArray();

            foreach (var group in groupQueries)
            {
                var itemsInGroup = queryData.Where(_ => _.GroupKey + "^Group" == group.Key).OrderBy(_ => _.IsPublic).ThenBy(_ => _.Name).ToArray();
                var hasPublicSearchInGroup = itemsInGroup.Any(_ => _.IsPublic);
                group.Items = itemsInGroup.Select(_ => new AppsMenu.AppsMenuItem(_.Key.ToString())
                                     {
                                        Text = _.Name,
                                        Icon = hasPublicSearchInGroup ? _.IsPublic ? PublicIcon : PrivateIcon : null,
                                        Url = string.Format(SearchUrl, Convert.ToInt32(queryContextKey), _.Key),
                                        Description = GetDescription(_),
                                        CanEdit = _.IsMaintainable
                                     }).ToList();
            }

            return queries.Union(groupQueries);
        }

        public string GetDescription(SavedQueryData data)
        {
            if(data.Name.Length > 24 || !string.IsNullOrEmpty(data.Description))
                return string.IsNullOrEmpty(data.Description) ? data.Name : data.Name + " : " + data.Description;

            return string.Empty;
        }
    }

    public class SavedQueryData
    {
        public int Key { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public bool IsPublic { get; set; }
        public bool IsMaintainable { get; set; }
        public bool IsRunable { get; set; }
        public bool IsReportOnly { get; set; }
        public int? GroupKey { get; set; }
        public string GroupName { get; set; }
    }
}
