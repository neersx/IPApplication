using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Accounting.Wip.Overview.Search
{
    public interface IWipOverviewFilterCriteriaBuilder
    {
        XElement Build(SearchRequestFilter req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);

        XElement Build(SearchRequestFilter req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);
    }

    public class WipOverviewFilterCriteriaBuilder : IWipOverviewFilterCriteriaBuilder
    {
        public XElement Build(SearchRequestFilter searchRequestFilter, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            if (searchRequestFilter == null) throw new ArgumentNullException(nameof(searchRequestFilter));
            if (filterableColumnsMap == null) throw new ArgumentNullException(nameof(filterableColumnsMap));

            var searchRequest = ((WipOverviewSearchRequestFilter)searchRequestFilter).SearchRequest?.ToArray();

            return new XElement("wp_ListWorkInProgress",
                                new XElement("FilterCriteria",
                                BuildFromSearchRequest(searchRequest))
                               );
        }

        public XElement Build(SearchRequestFilter req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            if (xmlFilterCriteria == null) throw new ArgumentNullException(nameof(xmlFilterCriteria));

            var requestFilter = (WipOverviewSearchRequestFilter)req;
            var xmlCriteria = XElement.Parse(xmlFilterCriteria);
            var filterCriteria = xmlCriteria.DescendantsAndSelf("FilterCriteria").FirstOrDefault();
            filterCriteria?.Add(BuildFromSearchRequest(requestFilter?.SearchRequest));

            xmlFilterCriteria = xmlCriteria.ToString();

            return XElement.Parse(xmlFilterCriteria);
        }

        XElement BuildFromSearchRequest(IEnumerable<WipOverviewSearchRequest> searchRequest)
        {
            var rowKeys = searchRequest?.ToArray().SingleOrDefault(_ => _.RowKeys != null && !string.IsNullOrEmpty(_.RowKeys.Value))?.RowKeys;

            if (rowKeys != null)
            {
                return new XElement("RowKeys", new XAttribute("Operator", rowKeys.Operator), rowKeys.Value);
            }

            return null;
        }

    }
}