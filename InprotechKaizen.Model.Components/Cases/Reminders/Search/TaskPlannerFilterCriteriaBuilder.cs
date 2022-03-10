using System;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using System.Xml.Serialization;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Cases.Reminders.Search
{
    public interface ITaskPlannerFilterCriteriaBuilder
    {
        XElement Build(SearchRequestFilter req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);

        XElement Build(SearchRequestFilter req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);
    }

    public class TaskPlannerFilterCriteriaBuilder : ITaskPlannerFilterCriteriaBuilder
    {
        public XElement Build(SearchRequestFilter searchRequestFilter, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            if (searchRequestFilter == null) throw new ArgumentNullException(nameof(searchRequestFilter));
            if (filterableColumnsMap == null) throw new ArgumentNullException(nameof(filterableColumnsMap));

            return BuildFromSearchRequest(((TaskPlannerRequestFilter)searchRequestFilter).SearchRequest, queryParameters, filterableColumnsMap);
        }

        public XElement Build(SearchRequestFilter req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            if (xmlFilterCriteria == null) throw new ArgumentNullException(nameof(xmlFilterCriteria));

            var requestFilter = (TaskPlannerRequestFilter)req;
            var xmlCriteria = XElement.Parse(xmlFilterCriteria);
            var filterCriteria = xmlCriteria.DescendantsAndSelf("FilterCriteria").SingleOrDefault();

            foreach (var filter in queryParameters.Filters.Where(f => !string.IsNullOrWhiteSpace(f.Field)))
            {
                var element = new XElement(filterableColumnsMap.XmlCriteriaFields[filter.Field], new XAttribute("Operator", filter.Operator.GetOperatorMapping()), filter.Value);

                filterCriteria?.Add(element);
            }

            if (requestFilter?.SearchRequest?.Dates != null)
            {
                filterCriteria?.DescendantsAndSelf("Dates").SingleOrDefault()?.Remove();
                if (requestFilter.SearchRequest.Dates.DateRange != null)
                {
                    requestFilter.SearchRequest.Dates.DateRange.From = requestFilter.SearchRequest.Dates.DateRange.From?.Date;
                    requestFilter.SearchRequest.Dates.DateRange.To = requestFilter.SearchRequest.Dates.DateRange.To?.Date;
                }

                if (requestFilter.SearchRequest?.Dates.PeriodRange != null)
                {
                    requestFilter.SearchRequest.Dates.PeriodRange = null;
                }

                var dateRange = XElement.Parse(Serialize(requestFilter.SearchRequest.Dates));
                filterCriteria?.Add(dateRange);
            }

            var belongsTo = filterCriteria?.DescendantsAndSelf("BelongsTo").SingleOrDefault();
            if (belongsTo == null)
            {
                belongsTo = new XElement("BelongsTo");
                filterCriteria?.Add(belongsTo);
            }

            if (requestFilter?.SearchRequest?.BelongsTo?.NameKey == null)
            {
                belongsTo.DescendantsAndSelf("NameKey").SingleOrDefault()?.Remove();
            }
            else
            {
                belongsTo.Add(new XElement("NameKey", new XAttribute("Operator", requestFilter.SearchRequest.BelongsTo.NameKey.Operator), new XAttribute("IsCurrentUser", requestFilter.SearchRequest.BelongsTo.NameKey.IsCurrentUser)));
            }
            if (requestFilter?.SearchRequest?.BelongsTo?.MemberOfGroupKey == null)
            {
                belongsTo.DescendantsAndSelf("MemberOfGroupKey").SingleOrDefault()?.Remove();
            }
            else
            {
                belongsTo.Add(new XElement("MemberOfGroupKey", new XAttribute("Operator", requestFilter.SearchRequest.BelongsTo.MemberOfGroupKey.Operator), new XAttribute("IsCurrentUser", requestFilter.SearchRequest.BelongsTo.MemberOfGroupKey.IsCurrentUser)));
            }
            if (requestFilter?.SearchRequest?.BelongsTo?.NameKeys != null && requestFilter.SearchRequest.BelongsTo.NameKeys.Value.Split(',').Any())
            {
                RemoveBelongsToSection(belongsTo);
                var element = new XElement("NameKeys", new XAttribute("Operator", requestFilter.SearchRequest.BelongsTo.NameKeys.Operator), requestFilter.SearchRequest.BelongsTo.NameKeys.Value);
                belongsTo.Add(element);
            }

            if (requestFilter?.SearchRequest?.BelongsTo?.MemberOfGroupKeys != null && requestFilter.SearchRequest.BelongsTo.MemberOfGroupKeys.Value.Split(',').Any())
            {
                RemoveBelongsToSection(belongsTo);
                var element = new XElement("MemberOfGroupKeys", new XAttribute("Operator", requestFilter.SearchRequest.BelongsTo.MemberOfGroupKeys.Operator), requestFilter.SearchRequest.BelongsTo.MemberOfGroupKeys.Value);
                belongsTo.Add(element);
            }

            if (requestFilter?.SearchRequest?.RowKeys != null)
            {
                var element = new XElement("RowKeys", new XAttribute("Operator", requestFilter.SearchRequest.RowKeys.Operator), requestFilter.SearchRequest.RowKeys.Value);
                filterCriteria?.Add(element);
            }

            xmlFilterCriteria = xmlCriteria.ToString();
            return XElement.Parse(xmlFilterCriteria);
        }

        void RemoveBelongsToSection(XElement belongsTo)
        {
            if (belongsTo == null) return;
            belongsTo.DescendantsAndSelf("NameKey").SingleOrDefault()?.Remove();
            belongsTo.DescendantsAndSelf("MemberOfGroupKey").SingleOrDefault()?.Remove();
            belongsTo.DescendantsAndSelf("MemberOfGroupKeys").SingleOrDefault()?.Remove();
            belongsTo.DescendantsAndSelf("NameKeys").SingleOrDefault()?.Remove();
        }

        static XElement BuildFromSearchRequest(TaskPlannerRequest filterRequest, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            var criteria = new XElement("Search", new XElement("Filtering", new XElement("ipw_TaskPlanner", XElement.Parse(Serialize(filterRequest)))));
            var filterCriteria = criteria.DescendantsAndSelf("FilterCriteria").SingleOrDefault();

            foreach (var filter in queryParameters.Filters.Where(f => !string.IsNullOrWhiteSpace(f.Field)))
            {
                var element = new XElement(filterableColumnsMap.XmlCriteriaFields[filter.Field], new XAttribute("Operator", filter.Operator.GetOperatorMapping()), filter.Value);

                filterCriteria?.Add(element);
            }
            return criteria;
        }

        static string Serialize(object dataToSerialize)
        {
            if (dataToSerialize == null) return null;

            using (var stringWriter = new StringWriter())
            {
                var xmlNamespaces = new XmlSerializerNamespaces();
                xmlNamespaces.Add(string.Empty, string.Empty);

                var serializer = new XmlSerializer(dataToSerialize.GetType());
                serializer.Serialize(stringWriter, dataToSerialize, xmlNamespaces);
                return stringWriter.ToString();
            }
        }
    }
}
