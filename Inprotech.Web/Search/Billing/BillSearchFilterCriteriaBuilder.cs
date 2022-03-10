using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Accounting.Billing.Search;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.Billing
{   
    public class BillSearchFilterCriteriaBuilder : IXmlFilterCriteriaBuilder
    {
        readonly IBillSearchFilterCriteriaBuilder _builder;

        public BillSearchFilterCriteriaBuilder(IBillSearchFilterCriteriaBuilder builder)
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
