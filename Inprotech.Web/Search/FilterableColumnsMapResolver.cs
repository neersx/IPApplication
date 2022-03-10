using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search
{
    public class FilterableColumnsMapResolver : IFilterableColumnsMapResolver
    {
        readonly IIndex<QueryContext, IFilterableColumnsMap> _map;

        public FilterableColumnsMapResolver(IIndex<QueryContext, IFilterableColumnsMap> map)
        {
            _map = map;
        }

        public IFilterableColumnsMap Resolve(QueryContext queryContext)
        {
            return _map.TryGetValue(queryContext, out var columnsMap)
                ? columnsMap
                : new DefaultFilterableColumnMap();
        }

        internal class DefaultFilterableColumnMap : IFilterableColumnsMap
        {
            public DefaultFilterableColumnMap()
            {
                Columns = new ReadOnlyDictionary<string, string>(new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase));

                XmlCriteriaFields = new ReadOnlyDictionary<string, string>(new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase));
            }

            public IReadOnlyDictionary<string, string> Columns { get; }
            public IReadOnlyDictionary<string, string> XmlCriteriaFields { get; }
        }
    }
}