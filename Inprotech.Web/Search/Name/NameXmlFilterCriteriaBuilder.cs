using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Names.Search;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.Name
{
    public class NameXmlFilterCriteriaBuilder : IXmlFilterCriteriaBuilder
    {
        readonly INameFilterCriteriaBuilder _builder;

        public NameXmlFilterCriteriaBuilder(INameFilterCriteriaBuilder builder)
        {
            _builder = builder;
        }

        public string Build<T>(T req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap) where T : SearchRequestFilter
        {
            return _builder.Build(req, queryParameters, filterableColumnsMap).ToString(SaveOptions.DisableFormatting);
        }

        public string Build<T>(T req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap) where T : SearchRequestFilter
        {
            return _builder.Build(xmlFilterCriteria, queryParameters, filterableColumnsMap).ToString(SaveOptions.DisableFormatting);
        }
    }
}