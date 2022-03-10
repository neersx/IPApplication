using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search
{
    public interface ISavedQueries
    {
        IEnumerable<dynamic> Get(string q, QueryContext queryContext, QueryType? queryType);
        IEnumerable<dynamic> GetSavedPresentationQueries(int queryContext);
    }

    public class SavedQueries : ISavedQueries
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public SavedQueries(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IEnumerable<dynamic> GetSavedPresentationQueries(int queryContext)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();
            var results = from a in _dbContext.GetSavedQueries(userId, culture, queryContext)
                           where a.HasPresentation
                          select a;

            return from r in results.ToArray()
                    orderby r.QueryName
                   select new
                   {
                       Key = r.QueryKey,
                       Name = r.QueryName,
                       r.GroupName
                   };
        }

        public IEnumerable<dynamic> Get(string q, QueryContext queryContext, QueryType? queryType)
        {
            q = q ?? string.Empty;

            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            bool PublicQueryFilter(SavedQueryItem a)
            {
                return !queryType.HasValue || queryType == QueryType.All || a.IsPublic == (queryType.Value == QueryType.Public);
            }

            var filters = new[]
            {
                (Func<SavedQueryItem, bool>) PublicQueryFilter,
                a => a.IsRunable,
                a => a.QueryName.IgnoreCaseContains(q)
            };

            var results = from a in _dbContext.GetSavedQueries(userId, culture, (int) queryContext)
                          where filters.All(filter => filter(a))
                          select a;

            return from r in results.ToArray()
                   let isContains = r.QueryName.IgnoreCaseContains(q)
                   let isStartsWith = r.QueryName.IgnoreCaseStartsWith(q)
                   orderby isStartsWith descending, isContains descending, r.QueryName
                   select new
                   {
                       Key = r.QueryKey,
                       Name = r.QueryName,
                       r.Description,
                       r.IsPublic,
                       r.IsMaintainable,
                       r.IsRunable,
                       r.IsReportOnly,
                       r.GroupKey,
                       r.GroupName
                   };
        }
    }
}