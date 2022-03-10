using System.IO;
using System.Linq;
using System.Xml;
using System.Xml.Linq;
using System.Xml.Serialization;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Cases.Search
{
    public static class CaseSearchHelper
    {
        public static int[] DeSelectedIds { get; set; }
        public static string ConstructGlobalCaseChangeCriteria(int globalProcessKey)
        {
            return "<Search><Filtering>" +
                   "<csw_ListCase><FilterCriteriaGroup><FilterCriteria><GlobalProcessKey>" + globalProcessKey +
                   "</GlobalProcessKey></FilterCriteria></FilterCriteriaGroup></csw_ListCase>" +
                   "</Filtering></Search>";
        }

        public static XmlDocument ConstructXmlFilterCriteria(SearchRequestFilter requestFilter, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            var request = (CaseSearchRequestFilter) requestFilter;
            var xmlFilterCriteria = new XmlDocument {XmlResolver = null};
            xmlFilterCriteria.LoadXml("<csw_ListCase><FilterCriteriaGroup></FilterCriteriaGroup></csw_ListCase>");
            var stepId = 1;
            foreach (var req in request.SearchRequest)
            {
                var doc = new XmlDocument {XmlResolver = null};

                var filterCriteria = $"<FilterCriteria ID='{stepId}' BooleanOperator='{req.Operator}'><IsAdvancedFilter>true</IsAdvancedFilter><StatusFlags CheckDeadCaseRestriction='1'></StatusFlags></FilterCriteria>";

                doc.LoadXml(filterCriteria);

                if (doc.DocumentElement != null)
                {
                    var currentNode = xmlFilterCriteria.ImportNode(doc.DocumentElement, true);
                    var selectSingleNode = xmlFilterCriteria.SelectSingleNode("csw_ListCase/FilterCriteriaGroup");
                    selectSingleNode?.AppendChild(currentNode);
                }

                var xml = new XmlDocument {XmlResolver = null};
                xml.LoadXml(Serialize(req));

                var xmlNodeList = xml.SelectNodes("//CaseSearchRequest/child::*");
                if (xmlNodeList != null)
                {
                    foreach (XmlNode element in xmlNodeList)
                    {
                        var node = xmlFilterCriteria.ImportNode(element, true);
                        var singleNode = xmlFilterCriteria.SelectSingleNode("csw_ListCase/FilterCriteriaGroup/FilterCriteria[@ID='" + stepId + "']");
                        singleNode?.AppendChild(node);
                    }
                }

                stepId++;
            }

            if (request.DueDateFilter != null)
            {
                AppendDueDateFilter(request.DueDateFilter, xmlFilterCriteria);
            }

            return AddXmlFilter(queryParameters, xmlFilterCriteria, filterableColumnsMap);
        }

        public static XmlDocument AddXmlFilterCriteriaForFilter(string filterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            var xmlFilterCriteria = new XmlDocument {XmlResolver = null};
            xmlFilterCriteria.LoadXml(filterCriteria);
            return AddXmlFilter(queryParameters, xmlFilterCriteria, filterableColumnsMap);
        }

        public static XmlDocument AddXmlFilterCriteriaForFilter(SearchRequestFilter req, string filterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            var requestFilter = (CaseSearchRequestFilter) req;
            if (requestFilter?.SearchRequest != null && requestFilter.SearchRequest.Any(_ => _.CaseKeys != null && !string.IsNullOrEmpty(_.CaseKeys.Value)))
            {
                var searchRequest = requestFilter.SearchRequest.SingleOrDefault(_ => !string.IsNullOrEmpty(_.CaseKeys.Value));
                var xmlCriteria = XElement.Parse(filterCriteria);
                foreach (var step in xmlCriteria.DescendantsAndSelf("FilterCriteria"))
                {
                    var existingCaseKeys = step.DescendantsAndSelf("CaseKeys").SingleOrDefault();
                    if (existingCaseKeys != null)
                    {
                        if (DeSelectedIds != null && DeSelectedIds.Any())
                        {
                            var selectedCaseIds = existingCaseKeys.Value.Split(',').Select(int.Parse).ToList();
                            existingCaseKeys.Value = string.Join(",", selectedCaseIds.Except(DeSelectedIds));
                        } 
                        else if(searchRequest != null && !string.IsNullOrEmpty(searchRequest.CaseKeys.Value))
                        {
                            existingCaseKeys.Value = searchRequest.CaseKeys.Value;
                        }
                    }
                    else if(searchRequest != null)
                    {
                        step.Add(new XElement("CaseKeys", searchRequest.CaseKeys.Value, new XAttribute("Operator", searchRequest.CaseKeys.Operator)));
                    }
                }

                filterCriteria = xmlCriteria.ToString();
            }

            var xmlFilterCriteria = new XmlDocument {XmlResolver = null};

            var replaceDueDateFilter = requestFilter != null && (requestFilter.SearchRequest == null
                                                                 && requestFilter.DueDateFilter != null);
            if(replaceDueDateFilter)
                filterCriteria = AddReplaceDueDateFilter(filterCriteria, requestFilter.DueDateFilter);

            xmlFilterCriteria.LoadXml(filterCriteria);
           
            return AddXmlFilter(queryParameters, xmlFilterCriteria, filterableColumnsMap);
        }

        static XmlDocument AddXmlFilter(CommonQueryParameters queryParameters, XmlDocument xmlFilterCriteria, IFilterableColumnsMap filterableColumnsMap)
        {
            if (queryParameters.Filters == null || !queryParameters.Filters.Any()) return xmlFilterCriteria;

            var xmlColumnFilter = xmlFilterCriteria.CreateElement("FilterCriteria");
            xmlColumnFilter.SetAttribute("BooleanOperator", "AND");
            xmlColumnFilter.SetAttribute("ID", "UserColumnFilter");
            xmlFilterCriteria.SelectSingleNode("//FilterCriteriaGroup")?.AppendChild(xmlColumnFilter);

            foreach (var filter in queryParameters.Filters.Where(f => !string.IsNullOrWhiteSpace(f.Field)))
            {
                if (!filterableColumnsMap.XmlCriteriaFields.TryGetValue(filter.Field, out _))
                    continue;

                var filterNode = xmlFilterCriteria.CreateElement(filterableColumnsMap.XmlCriteriaFields[filter.Field]);
                filterNode.InnerText = filter.Value;
                filterNode.SetAttribute("Operator", filter.Operator.GetOperatorMapping());

                xmlFilterCriteria.SelectSingleNode("//FilterCriteria[@ID='UserColumnFilter']")?.AppendChild(filterNode);
            }

            return xmlFilterCriteria;
        }

        public static void AppendDueDateFilter(DueDateFilter dueDateFilter, XmlDocument xmlFilterCriteria)
        {
            var dueDateFilterCriteria = new XmlDocument {XmlResolver = null};
            dueDateFilterCriteria.LoadXml("<ColumnFilterCriteria></ColumnFilterCriteria>");

            var xml = new XmlDocument {XmlResolver = null};
            xml.LoadXml(Serialize(dueDateFilter));

            var xmlNodeList = xml.SelectNodes("//DueDateFilter/child::*");
            if (xmlNodeList != null)
            {
                foreach (XmlNode element in xmlNodeList)
                {
                    var node = dueDateFilterCriteria.ImportNode(element, true);
                    var singleNode = dueDateFilterCriteria.SelectSingleNode("ColumnFilterCriteria");
                    singleNode?.AppendChild(node);
                }
            }

            if (dueDateFilterCriteria.DocumentElement != null)
            {
                var currentNode = xmlFilterCriteria.ImportNode(dueDateFilterCriteria.DocumentElement, true);
                var selectSingleNode = xmlFilterCriteria.SelectSingleNode("csw_ListCase");
                selectSingleNode?.AppendChild(currentNode);
            }
        }

        public static string Serialize(object dataToSerialize)
        {
            if (dataToSerialize == null) return null;

            using (var stringwriter = new StringWriter())
            {
                var serializer = new XmlSerializer(dataToSerialize.GetType(), string.Empty);
                serializer.Serialize(stringwriter, dataToSerialize);
                return stringwriter.ToString();
            }
        }

        public static string AddReplaceDueDateFilter(string filterCriteria, object dueDateFilter)
        {
            if (dueDateFilter == null) return filterCriteria;

            var xmlCriteria = XElement.Parse(filterCriteria);

            var columnFilterCriteria = xmlCriteria.DescendantsAndSelf("ColumnFilterCriteria").FirstOrDefault();

            var dueDateToReplace = XElement.Parse(Serialize(dueDateFilter)).DescendantsAndSelf("DueDates").First();

            if (columnFilterCriteria?.Descendants("DueDates").FirstOrDefault() != null)
            {
                columnFilterCriteria.ReplaceAll(dueDateToReplace);
                return xmlCriteria.ToString();
            }

            var criteria = xmlCriteria.DescendantsAndSelf("csw_ListCase").First();

            if (columnFilterCriteria == null)
            {
                criteria.Add(new XElement("ColumnFilterCriteria"));
            }

            xmlCriteria.DescendantsAndSelf("ColumnFilterCriteria").First().Add(dueDateToReplace);

            return xmlCriteria.ToString();
        }

        public static string AddStepToFilterCases(int[] deselectedIds, string xmlFilterCriteria)
        {
            if (deselectedIds == null || deselectedIds.Length <= 0) return xmlFilterCriteria;

            var xmlCriteria = XElement.Parse(xmlFilterCriteria);

            var filterCriteriaGroup = xmlCriteria.DescendantsAndSelf("FilterCriteriaGroup").First();

            var stepCount = xmlCriteria.DescendantsAndSelf("FilterCriteria").Count();

            var newStep = new XElement("FilterCriteria", new XAttribute("ID", (++stepCount).ToString()), new XAttribute("BooleanOperator", "AND"),
                                       new XElement("CaseKeys", string.Join(",", deselectedIds), new XAttribute("Operator", "1")));

            filterCriteriaGroup.Add(newStep);
            xmlFilterCriteria = xmlCriteria.ToString();

            return xmlFilterCriteria;
        }
    }
}