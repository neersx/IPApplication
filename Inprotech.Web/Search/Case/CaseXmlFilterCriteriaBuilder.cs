using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.Case
{
    public class CaseXmlFilterCriteriaBuilder : IXmlFilterCriteriaBuilder
    {
        public string Build<T>(T req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap) where T : SearchRequestFilter
        {
            return CaseSearchHelper.ConstructXmlFilterCriteria(req, queryParameters, filterableColumnsMap).OuterXml;
        }

        public string Build<T>(T req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap) where T : SearchRequestFilter
        {
            return CaseSearchHelper.AddXmlFilterCriteriaForFilter(req, xmlFilterCriteria, queryParameters, filterableColumnsMap).OuterXml;
        }
    }
}