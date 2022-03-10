using System;
using System.Xml;
using System.Xml.XPath;

namespace Inprotech.IntegrationServer.PtoAccess.Utilities
{
    public static class XmlTools
    {
        public static DateTime? ParseDate(string value)
        {
            DateTime? dateTime = null;
            if (!string.IsNullOrWhiteSpace(value))
            {
                if (value.Length > 10)
                    value = value.Substring(0, 10);

                dateTime = DateTime.ParseExact(value, "yyyy-MM-dd", null);
            }
            return dateTime;
        }

        public static string GetXmlNodeValue(XPathNavigator navigator, string xpathExpression,
            IXmlNamespaceResolver resolver)
        {
            var node = navigator.SelectSingleNode(xpathExpression, resolver);
            if (node != null && !string.IsNullOrEmpty(node.Value))
                return node.Value.Trim();
            return null;
        }

        public static DateTime? GetXmlNodeDateValue(XPathNavigator navigator, string xpathExpression,
            IXmlNamespaceResolver resolver)
        {
            return ParseDate(GetXmlNodeValue(navigator, xpathExpression, resolver));

        }
    }
}
