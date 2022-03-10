using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Accounting.Wip.Overview.Search;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.WipOverview
{
    public class WipOverviewXmlFilterCriteriaBuilder : IXmlFilterCriteriaBuilder
    {
        readonly IWipOverviewFilterCriteriaBuilder _builder;

        public WipOverviewXmlFilterCriteriaBuilder(IWipOverviewFilterCriteriaBuilder builder)
        {
            _builder = builder;
        }

        public string Build<T>(T req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap) where T : SearchRequestFilter
        {
            return _builder.Build(req, queryParameters, filterableColumnsMap).ToString(SaveOptions.DisableFormatting);
        }

        public string Build<T>(T req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap) where T : SearchRequestFilter
        {
            return _builder.Build(req, xmlFilterCriteria, queryParameters, filterableColumnsMap).ToString(SaveOptions.DisableFormatting);
        }
    }
}