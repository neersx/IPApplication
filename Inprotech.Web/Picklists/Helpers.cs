using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Picklists
{
    public static class Helpers
    {
        public static readonly CommonQueryParameters DefaultQueryParameters = new CommonQueryParameters
                                                                              {
                                                                                  SortDir = "asc",
                                                                                  Skip = 0,
                                                                                  Take = 50
                                                                              };

        public static PagedResults<T> GetPagedResults<T>(IEnumerable<T> data,
                                                         CommonQueryParameters queryParameters,
                                                         Expression<Func<T, string>> key,
                                                         Expression<Func<T, string>> desc,
                                                         string search) where T : class
        {
            return GetPagedResults(data.AsQueryable(), queryParameters, key, desc, search);
        }

        public static PagedResults<T> GetPagedResults<T>(IQueryable<T> data,
                                                          CommonQueryParameters queryParameters,
                                                          Expression<Func<T, string>> key,
                                                          Expression<Func<T, string>> desc,
                                                          string search) where T : class
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var total = data.Count();

            var ordered = data.OrderBy(x => 0);

            if (queryParameters != null && !string.IsNullOrEmpty(queryParameters.SortBy))
                ordered = ordered.ThenByProperty(queryParameters.SortBy, queryParameters.SortDir);

            ordered = ordered.OrderForPicklist(key, desc, search);

            return new PagedResults<T>(ordered.Skip(queryParameters.Skip.Value)
                                              .Take(queryParameters.Take.Value)
                                              .ToArray(), total);
        }
    }
}