using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;

namespace InprotechKaizen.Model.Components.Cases
{
    public static class CasePicklistSearchFilter
    {
        public static XElement ConstructSearchFilter(XElement caseFilterXml, CaseSearchFilter searchFilter)
        {
            if (searchFilter == null) return caseFilterXml;

            if (searchFilter.NameKeys != null && searchFilter.NameKeys.Any())
            {
                var nameKeys = string.Join(",", searchFilter.NameKeys);
                if (searchFilter.NameType == KnownNameTypes.Instructor)
                {
                    caseFilterXml.Descendants("NameKeys").First().Value = nameKeys;
                }
                else
                {
                    var caseNameNode = new XElement("CaseName");
                    caseNameNode.SetAttributeValue("Operator", 0);
                    if (!string.IsNullOrEmpty(searchFilter.NameType))
                    {
                        caseNameNode.SetElementValue("TypeKey", searchFilter.NameType);
                    }
                    AddElementWithoutAttr(caseNameNode, "NameKeys", nameKeys);
                    caseFilterXml.Descendants("CaseNameGroup").First().Add(caseNameNode);
                }
            }

            var filterCriteria = caseFilterXml.Descendants("FilterCriteria").First();
            if (searchFilter.CaseOffices != null && searchFilter.CaseOffices.Any())
            {
                AddElement(filterCriteria, "OfficeKeys", string.Join(",", searchFilter.CaseOffices));
            }
            if (searchFilter.CaseTypes != null && searchFilter.CaseTypes.Any())
            {
                AddElement(filterCriteria, "CaseTypeKeys", string.Join(",", searchFilter.CaseTypes));
            }
            if (searchFilter.PropertyTypes != null && searchFilter.PropertyTypes.Any())
            {
                AddElement(filterCriteria, "PropertyTypeKeys", null);
                var ptsNodes = caseFilterXml.Descendants("PropertyTypeKeys").First();
                foreach (var pt in searchFilter.PropertyTypes)
                {
                    AddElementWithoutAttr(ptsNodes, "PropertyTypeKey", pt);
                }
            }
            if (searchFilter.CountryCodes != null && searchFilter.CountryCodes.Any())
            {
                AddElement(filterCriteria, "CountryCodes", string.Join(",", searchFilter.CountryCodes));
            }

            if (!searchFilter.IsRegistered && !searchFilter.IsDead && !searchFilter.IsPending)
            {
                return caseFilterXml;
            }

            AddElementWithoutAttr(filterCriteria, "StatusFlags", null);
            var sNodes = caseFilterXml.Descendants("StatusFlags").First();
            sNodes.SetAttributeValue("CheckDeadCaseRestriction", 1);
            AddElementWithoutAttr(sNodes, "IsDead", searchFilter.IsDead ? "1" : "0");
            AddElementWithoutAttr(sNodes, "IsPending", searchFilter.IsPending ? "1" : "0");
            AddElementWithoutAttr(sNodes, "IsRegistered", searchFilter.IsRegistered ? "1" : "0");

            return caseFilterXml;
        }
        static void AddElement(XElement filterCriteria, string name, string value)
        {
            var node = new XElement(name);
            node.SetAttributeValue("Operator", 0);
            if (!string.IsNullOrWhiteSpace(value))
            {
                node.Value = value;
            }
            filterCriteria.Add(node);
        }

        static void AddElementWithoutAttr(XElement filterCriteria, string name, string value)
        {
            var node = new XElement(name);
            if (!string.IsNullOrWhiteSpace(value))
            {
                node.Value = value;
            }
            filterCriteria.Add(node);
        }
    }

    public class CaseSearchFilter
    {
        public IEnumerable<int> NameKeys { get; set; }
        public string NameType { get; set; }
        public IEnumerable<int> CaseOffices { get; set; }
        public IEnumerable<string> CaseTypes { get; set; }
        public IEnumerable<string> CountryCodes { get; set; }
        public IEnumerable<string> PropertyTypes { get; set; }
        public bool IsPending { get; set; }
        public bool IsRegistered { get; set; }
        public bool IsDead { get; set; }
    }
}
