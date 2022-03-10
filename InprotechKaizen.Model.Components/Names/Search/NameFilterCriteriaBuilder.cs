using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Names.Search
{
    public interface INameFilterCriteriaBuilder
    {
        XElement Build(SearchRequestFilter req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);

        XElement Build(string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);
    }

    public class NameFilterCriteriaBuilder : INameFilterCriteriaBuilder
    {
        public XElement Build(SearchRequestFilter searchRequestFilter, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            if (searchRequestFilter == null) throw new ArgumentNullException(nameof(searchRequestFilter));
            if (filterableColumnsMap == null) throw new ArgumentNullException(nameof(filterableColumnsMap));

            var root = new XElement("naw_ListName",
                                    new XElement("FilterCriteriaGroup",
                                                 BuildFromSearchRequest(GetRequests(searchRequestFilter).ToArray())
                                                )
                                   );

            AddXmlFilter(queryParameters, root.Descendants("FilterCriteriaGroup").Single(), filterableColumnsMap);

            return root;
        }

        public XElement Build(string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            if (xmlFilterCriteria == null) throw new ArgumentNullException(nameof(xmlFilterCriteria));

            var root = XElement.Parse(xmlFilterCriteria);

            AddXmlFilter(queryParameters, root.Descendants("FilterCriteriaGroup").First(), filterableColumnsMap);

            return root;
        }
        protected virtual IEnumerable<NameSearchRequestBase> GetRequests(SearchRequestFilter searchRequestFilter)
        {
            return ((NameSearchRequestFilter<NameSearchRequest>)searchRequestFilter).SearchRequest;
        }
        
        static IEnumerable<XElement> BuildFromSearchRequest(NameSearchRequestBase[] filters)
        {
            for (var i = 0; i < filters.Length; i++)
                yield return BuildFromSearchRequest(filters[i], i);
        }

        static XElement BuildFromSearchRequest(NameSearchRequestBase filter, int stepId)
        {
            var e = new XElement("FilterCriteria",
                                 new XAttribute("ID", stepId),
                                 new XAttribute("BooleanOperator", filter.Operator ?? string.Empty),
                                 BuildFilterCriteria()
                                );

            IEnumerable<XElement> BuildFilterCriteria()
            {
                yield return new XElement("AnySearch", (filter.AnySearch ?? new SearchElement()).Value ?? string.Empty);
                yield return new XElement("NameKeys", new XAttribute("Operator", filter.NameKeys == null ? 0 : filter.NameKeys.Operator), (filter.NameKeysArr ?? Enumerable.Empty<string>()).Select(_ => new XElement("NameKey", _)));
                yield return new XElement("IsCurrent", BooleanToInt(filter.IsCurrent));
                yield return new XElement("IsCeased", BooleanToInt(filter.IsCeased));

                if (filter.IsLead.HasValue) yield return new XElement("IsLead", BooleanToInt(filter.IsLead));
            }

            return e;
        }

        static int BooleanToInt(bool? boolValue)
        {
            return boolValue.GetValueOrDefault() ? 1 : 0;
        }

        protected static void AddXmlFilter(CommonQueryParameters queryParameters, XElement filterCriteriaGroup, IFilterableColumnsMap filterableColumnsMap)
        {
            if (queryParameters == null || !queryParameters.Filters.Any()) return;

            filterCriteriaGroup.Add(new XElement("FilterCriteria",
                                                 new XAttribute("ID", "UserColumnFilter"),
                                                 new XAttribute("BooleanOperator", "AND"),
                                                 queryParameters.Filters.Where(f => !string.IsNullOrWhiteSpace(f.Field) && filterableColumnsMap.XmlCriteriaFields.ContainsKey(f.Field))
                                                                .Select(f => new XElement(filterableColumnsMap.XmlCriteriaFields[f.Field],
                                                                                          new XAttribute("Operator", f.Operator.GetOperatorMapping())))
                                                ));
        }
    }
}