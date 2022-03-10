using System;
using System.Linq;
using System.Xml.Linq;

namespace Inprotech.Web.Search
{
    public static class SearchFilterFinder
    {
        static string _xmlFilter;
        static XDocument _filterDocument;
        
        public static DateTime? GetFromDate(string xmlFilter, string nodeName)
        {
            LoadXml(xmlFilter);

            var dateFilter = _filterDocument.Descendants(nodeName).FirstOrDefault();
            if (dateFilter == null) return null;

            var dateRange = dateFilter.Element("DateRange");
            if (dateRange != null)
                return dateRange.Element("From") != null ? (DateTime?) dateRange.Element("From") : null;

            var datePeriod = dateFilter.Element("PeriodRange");
            if (datePeriod != null)
                return datePeriod.Element("To") != null ? GetDateFromPeriodRange(DateTime.Today, nodeName, "To") : null;

            return null;
        }

        public static DateTime? GetToDate(string xmlFilter, string nodeName)
        {
            LoadXml(xmlFilter);
            
            var dateFilter = _filterDocument.Descendants(nodeName).FirstOrDefault();
            if (dateFilter == null) return null;

            var dateRange = dateFilter.Element("DateRange");
            if (dateRange != null)
                return dateRange.Element("To") != null ? (DateTime?) dateRange.Element("To") : null;

            var datePeriod = dateFilter.Element("PeriodRange");
            if (datePeriod != null)
                return datePeriod.Element("From") != null
                    ? GetDateFromPeriodRange(DateTime.Today, nodeName, "From") : null;

            return null;
        }

        static DateTime? GetDateFromPeriodRange(DateTime dateRange, string nodeName, string elementDateType )
        {
            var periodRangeFilter = _filterDocument.Descendants(nodeName).First().Element("PeriodRange");
            if (periodRangeFilter == null) return dateRange;
            var periodType = (string)periodRangeFilter.Element("Type");
            var periodCount = (int)periodRangeFilter.Element(elementDateType) * -1;
            switch (periodType)
            {
                case "D":
                    return dateRange.AddDays(periodCount);
                case "W":
                    return dateRange.AddDays(periodCount * 7);
                case "M":
                    return dateRange.AddMonths(periodCount);
                case "Y":
                    return dateRange.AddYears(periodCount);
            }
            return null;
        }

        public static bool? GetBoolean(string xmlFilter, string rootNodeName, string valueNodeName)
        {
            LoadXml(xmlFilter);
            var rootNode = _filterDocument.Descendants(rootNodeName).FirstOrDefault();
            if (rootNode == null) return null;
            if (valueNodeName.Contains("@") && rootNode.Attribute(valueNodeName.Replace("@",string.Empty)) != null)
                return (bool) rootNode.Attribute(valueNodeName.Replace("@",string.Empty));
            if (rootNode.Element(valueNodeName) != null)
                return (bool)rootNode.Element(valueNodeName);
            
            return null;
        }

        static void LoadXml(string xmlFilter)
        {
            if (xmlFilter == null) throw new ArgumentNullException(nameof(xmlFilter));
            _xmlFilter = xmlFilter;
            _filterDocument = XDocument.Parse(_xmlFilter);
        }
    }
}