using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;

namespace Inprotech.Infrastructure.Web
{
    public interface ICommonQueryService
    {
        IEnumerable<TEntity> Filter<TEntity>(IEnumerable<TEntity> source, CommonQueryParameters queryParameters) where TEntity : class;

        IEnumerable<TEntity> GetSortedPage<TEntity>(IEnumerable<TEntity> source, CommonQueryParameters queryParameters) where TEntity : class;

        CodeDescription BuildCodeDescriptionObject(string code, string description);
    }

    class CommonQueryService : ICommonQueryService
    {
        public IEnumerable<TEntity> Filter<TEntity>(IEnumerable<TEntity> source, CommonQueryParameters queryParameters) where TEntity : class
        {
            var result = source;

            foreach (var f in queryParameters.Filters)
            {
                switch (f.Type)
                {
                    case "date":
                        result = result.FilterByProperty(f.Field, f.Operator, f.DateTimeValue);
                        break;

                    default:
                        var fields = f.Field.Split('-');
                        foreach (var field in fields)
                        {
                            result = result.FilterByProperty(field, f.Operator, f.Value, queryParameters.FilterEmpty);
                        }
                        break;
                }
            }

            return result;
        }
        
        public IEnumerable<TEntity> GetSortedPage<TEntity>(IEnumerable<TEntity> source, CommonQueryParameters queryParameters) where TEntity : class
        {
            return source.OrderByProperty(queryParameters.SortBy,
                queryParameters.SortDir)
                .Skip(queryParameters.Skip.GetValueOrDefault(CommonQueryParameters.DefaultSkip))
                .Take(queryParameters.Take.GetValueOrDefault(CommonQueryParameters.DefaultTake));
        }

        public CodeDescription BuildCodeDescriptionObject(string code, string description)
        {
            if (string.IsNullOrEmpty(description))
                return new CodeDescription { }; // Filter template requires object

            return new CodeDescription
            {
                Code = code,
                Description = description
            };
        }
    }
}
