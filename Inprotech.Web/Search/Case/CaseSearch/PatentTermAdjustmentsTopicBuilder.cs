using System;
using System.Xml.Linq;
using InprotechKaizen.Model;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class PatentTermAdjustmentsTopicBuilder : ITopicBuilder
    {
        public CaseSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new CaseSavedSearch.Topic("patentTermAdjustments");
            var ptTopic = new PatentTermAdjustmentsTopic
            {
                Id = filterCriteria.GetAttributeIntValue("ID"),
                SuppliedPtaOperator = filterCriteria.GetAttributeOperatorValueForXPathElement("PatentTermAdjustments/IPOfficeAdjustment", "Operator", Operators.Between),
                FromSuppliedPta = GetIntPtaValue(filterCriteria, "IPOfficeAdjustment", "FromDays"),
                ToSuppliedPta = GetIntPtaValue(filterCriteria, "IPOfficeAdjustment", "ToDays"),
                DeterminedByUsOperator = filterCriteria.GetAttributeOperatorValueForXPathElement("PatentTermAdjustments/CalculatedAdjustment", "Operator", Operators.Between),
                FromPtaDeterminedByUs = GetIntPtaValue(filterCriteria, "CalculatedAdjustment", "FromDays"),
                ToPtaDeterminedByUs = GetIntPtaValue(filterCriteria, "CalculatedAdjustment", "ToDays"),
                ApplicantDelayOperator = filterCriteria.GetAttributeOperatorValueForXPathElement("PatentTermAdjustments/ApplicantDelay", "Operator", Operators.Between),
                FromApplicantDelay = GetIntPtaValue(filterCriteria, "ApplicantDelay", "FromDays"),
                ToApplicantDelay = GetIntPtaValue(filterCriteria, "ApplicantDelay", "ToDays"),
                IpOfficeDelayOperator = filterCriteria.GetAttributeOperatorValueForXPathElement("PatentTermAdjustments/IPOfficeDelay", "Operator", Operators.Between),
                FromIpOfficeDelay = GetIntPtaValue(filterCriteria, "IPOfficeDelay", "FromDays"),
                ToIpOfficeDelay = GetIntPtaValue(filterCriteria, "IPOfficeDelay", "ToDays"),
                PtaDiscrepancies = filterCriteria.GetXPathBooleanValue("PatentTermAdjustments/HasDiscrepancy")
            };
            topic.FormData = ptTopic;
            return topic;
        }

        int? GetIntPtaValue(XContainer filterCriteria, string type, string name)
        {
            var fieldValue = filterCriteria.Element("PatentTermAdjustments")?.Element(type)?.Element(name)?.Value;

            return !string.IsNullOrEmpty(fieldValue)? Convert.ToInt32(fieldValue) : (int?) null;
        }
    }

    public class PatentTermAdjustmentsTopic
    {
        public int Id { get; set; }

        public string SuppliedPtaOperator { get; set; }
        public int? FromSuppliedPta { get; set; }
        public int? ToSuppliedPta { get; set; }
        public string DeterminedByUsOperator { get; set; }
        public int? FromPtaDeterminedByUs { get; set; }
        public int? ToPtaDeterminedByUs { get; set; }
        public string IpOfficeDelayOperator { get; set; }
        public int? FromIpOfficeDelay { get; set; }
        public int? ToIpOfficeDelay { get; set; }
        public string ApplicantDelayOperator { get; set; }
        public int? FromApplicantDelay { get; set; }
        public int? ToApplicantDelay { get; set; }
        public bool PtaDiscrepancies { get; set; }
    }
}
