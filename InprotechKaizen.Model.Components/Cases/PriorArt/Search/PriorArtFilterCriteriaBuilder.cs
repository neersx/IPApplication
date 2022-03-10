using System;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Cases.PriorArt.Search
{
    public interface IPriorArtFilterCriteriaBuilder
    {
        XElement Build(SearchRequestFilter req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);

        XElement Build(SearchRequestFilter req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);
    }

    public class PriorArtFilterCriteriaBuilder : IPriorArtFilterCriteriaBuilder
    {
        public XElement Build(SearchRequestFilter searchRequestFilter, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            if (searchRequestFilter == null) throw new ArgumentNullException(nameof(searchRequestFilter));
            if (filterableColumnsMap == null) throw new ArgumentNullException(nameof(filterableColumnsMap));

            return new XElement("pr_ListPriorArt",
                                BuildFromSearchRequest(((PriorArtSearchRequestFilter) searchRequestFilter).SearchRequest.Single())
                               );
        }

        public XElement Build(SearchRequestFilter req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            if (xmlFilterCriteria == null) throw new ArgumentNullException(nameof(xmlFilterCriteria));

            var filterCriteriaElement = XElement.Parse(xmlFilterCriteria);
            if(((PriorArtSearchRequestFilter) req)?.SearchRequest == null) return filterCriteriaElement;
           
            var filter = ((PriorArtSearchRequestFilter) req).SearchRequest.Single();
            if (filter.PriorArtKeys == null || string.IsNullOrEmpty(filter.PriorArtKeys.Value)) return filterCriteriaElement;

            var filterCriteria = filterCriteriaElement.Descendants("FilterCriteria").FirstOrDefault();
            if (filterCriteria == null) return filterCriteriaElement;

            var priorArtKeyElement = new XElement("PriorArtKeys", filter.PriorArtKeys.Value);
            priorArtKeyElement.SetAttributeValue("Operator", filter.PriorArtKeys.Operator);
            filterCriteria.Add(priorArtKeyElement);

            return filterCriteriaElement;
        }

        static void SetPriorArtKeysCriteria(PriorArtSearchRequest filter, XElement filterCriteriaElement)
        {
            var priorArtKeyElement = new XElement("PriorArtKeys", filter.PriorArtKeys.Value);
            priorArtKeyElement.SetAttributeValue("Operator", filter.PriorArtKeys.Operator);
            filterCriteriaElement.Add(priorArtKeyElement);
        }

        static XElement BuildFromSearchRequest(PriorArtSearchRequest filter)
        {
            var filterCriteriaElement = new XElement("FilterCriteria",
                             new XElement("AnySearch", (filter.AnySearch ?? new SearchElement()).Value ?? string.Empty));

            if (filter.PriorArtKeys == null || string.IsNullOrEmpty(filter.PriorArtKeys.Value)) return filterCriteriaElement;
            SetPriorArtKeysCriteria(filter, filterCriteriaElement);

            return filterCriteriaElement;
        }
    }
}