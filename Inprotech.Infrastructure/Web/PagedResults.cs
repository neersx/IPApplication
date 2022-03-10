using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;

// ReSharper disable PossibleMultipleEnumeration

namespace Inprotech.Infrastructure.Web
{
    public class PagedResultsWithRecent
    {
        public bool ResultsContainsRecent = true;

        public PagedResults Results { get; set; }

        public PagedResults RecentResults { get; set; }
    }

    public class PagedResults
    {
        public PagedResults(IEnumerable<object> data, long total)
        {
            Data = data;
            Pagination = new Pagination(total);
        }

        public IEnumerable<object> Data { get; }

        public Pagination Pagination { get; }

        // additional values for all ids from search result set
        public object Ids { get; set; }
    }

    public class PagedResults<T> : PagedResults where T : class
    {
        public PagedResults(IEnumerable<T> data, long total) : base(data, total)
        {
        }

        public new IEnumerable<T> Data => (IEnumerable<T>) base.Data;
    }

    public static class PagedResultsExtension
    {
        public static IEnumerable<T> Items<T>(this PagedResults pr)
        {
            return pr.Data.Cast<T>();
        }
    }

    public static class EnumerableExtensions
    {
        public static PagedResults AsPagedResults(this IEnumerable<object> results, CommonQueryParameters parameters)
        {
            if (!results.Any())
            {
                return new PagedResults(results, 0);
            }

            return new PagedResults(results
                                    .Skip(parameters.Skip ?? 0)
                                    .Take(parameters.Take ?? int.MaxValue), results.Count());
        }

        public static PagedResults<T> AsPagedResults<T>(this IEnumerable<T> results, CommonQueryParameters parameters) where T : class
        {
            if (!results.Any())
            {
                return new PagedResults<T>(results, 0);
            }

            return new PagedResults<T>(results
                                       .Skip(parameters.Skip ?? 0)
                                       .Take(parameters.Take ?? int.MaxValue), results.Count());
        }

        public static PagedResults<T> AsOrderedPagedResults<T>(this IEnumerable<T> results, CommonQueryParameters parameters) where T : class
        {
            if (!results.Any())
            {
                return new PagedResults<T>(results, 0);
            }

            return new PagedResults<T>(results
                                       .OrderByProperty(parameters.SortBy, parameters.SortDir)
                                       .Skip(parameters.Skip ?? 0)
                                       .Take(parameters.Take ?? int.MaxValue), results.Count());
        }
    }

    public static class QueryableExtensions
    {
        public static PagedResults<T> AsPagedResults<T>(this IQueryable<T> results, CommonQueryParameters parameters) where T : class
        {
            var totalCount = results.Count();
            if (totalCount == 0)
            {
                return new PagedResults<T>(results, 0);
            }

            return new PagedResults<T>(results
                                       .Skip(parameters.Skip ?? 0)
                                       .Take(parameters.Take ?? int.MaxValue).ToArray(), totalCount);
        }
    }

    public class Pagination
    {
        public Pagination(long total)
        {
            Total = total;
        }

        public long Total { get; }
    }
}