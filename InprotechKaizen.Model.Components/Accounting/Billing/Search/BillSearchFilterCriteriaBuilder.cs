using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Search
{
    public interface IBillSearchFilterCriteriaBuilder
    {
        XElement Build(SearchRequestFilter req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);

        XElement Build(SearchRequestFilter req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);
    }

    public class BillSearchFilterCriteriaBuilder : IBillSearchFilterCriteriaBuilder
    {
        public XElement Build(SearchRequestFilter req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            if (req == null) throw new ArgumentNullException(nameof(req));
            if (filterableColumnsMap == null) throw new ArgumentNullException(nameof(filterableColumnsMap));

            var searchRequest = ((BillSearchRequestFilter)req).SearchRequest.ToArray();

            return new XElement("biw_ListBillSummary",
                                new XElement("FilterCriteria",
                                             new XElement("OpenItem",
                                                          BuildFromSearchRequest(searchRequest)
                                                          )
                                             )
                               );
        }

        XElement BuildFromSearchRequest(IEnumerable<BillSearchRequest> searchRequest)
        {
            var rowKeys = searchRequest?.ToArray().SingleOrDefault(_ => _.RowKeys != null && !string.IsNullOrEmpty(_.RowKeys.Value))?.RowKeys;

            if (rowKeys != null)
            {
                return new XElement("RowKeys", new XAttribute("Operator", rowKeys.Operator), rowKeys.Value);
            }

            return null;
        }

        public XElement Build(SearchRequestFilter req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            if (xmlFilterCriteria == null) throw new ArgumentNullException(nameof(xmlFilterCriteria));

            var requestFilter = (BillSearchRequestFilter)req;
            var xmlCriteria = XElement.Parse(xmlFilterCriteria);
            var filterCriteria = xmlCriteria.DescendantsAndSelf("FilterCriteria").FirstOrDefault();

            var openItem = filterCriteria?.DescendantsAndSelf("OpenItem").FirstOrDefault();
            openItem?.Add(BuildFromSearchRequest(requestFilter?.SearchRequest));

            xmlFilterCriteria = xmlCriteria.ToString();

            return XElement.Parse(xmlFilterCriteria);
        }
    }
}
