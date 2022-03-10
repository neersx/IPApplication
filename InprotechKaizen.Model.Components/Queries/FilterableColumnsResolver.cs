using System.Collections.Generic;
using Inprotech.Infrastructure.Web;

namespace InprotechKaizen.Model.Components.Queries
{
    public interface IFilterableColumnsMapResolver
    {
        IFilterableColumnsMap Resolve(QueryContext queryContext);
    }

    public interface IFilterableColumnsMap
    {
        IReadOnlyDictionary<string, string> Columns { get; }
        IReadOnlyDictionary<string, string> XmlCriteriaFields { get; }
    }
}