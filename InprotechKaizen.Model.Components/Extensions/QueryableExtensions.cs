using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;

namespace InprotechKaizen.Model.Components.Extensions
{
    public static class QueryableExtensions
    {
        public static async Task<PagedResults<T>> AsPagedResultsAsync<T>(this IQueryable<T> results, CommonQueryParameters parameters) where T : class
        {
            var totalCount = await results.CountAsync();
            if (totalCount == 0)
            {
                return new PagedResults<T>(results, 0);
            }

            return new PagedResults<T>(await results
                                             .Skip(parameters.Skip ?? 0)
                                             .Take(parameters.Take ?? int.MaxValue).ToArrayAsync(), totalCount);
        }
    }
}