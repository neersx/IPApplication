using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;
using InprotechKaizen.Model;

namespace Inprotech.Web.Search.TaskPlanner.SavedSearch
{
    public static class TaskPlannerSavedSearchHelper
    {
        public static string GetStringValue(this XElement element, string name)
        {
            return element?.Element(name)?.Value;
        }

        public static IEnumerable<XElement> GetElements(this XElement element, string name, string childName)
        {
            var _element = element?.Element(name);
            return _element != null && _element.HasElements ? _element.Elements().Where(e => e.Name.ToString().Equals(childName)) : new XElement[0];
        }

        public static string GetStringValue(this XElement element)
        {
            return element.Value;
        }

        public static string GetXPathStringValue(this XElement element, string xpath)
        {
            var xPathElement = element.XPathSelectElement(xpath);
            return xPathElement?.Value;
        }

        public static int? GetIntegerNullableValue(this XElement element)
        {
            return !string.IsNullOrEmpty(element.Value) ? Convert.ToInt32(element.Value) : (int?) null;
        }

        public static int? GetXPathNullableIntegerValue(this XElement element, string xPath)
        {
            var xPathElement = element.XPathSelectElement(xPath);
            if (xPathElement == null || string.IsNullOrEmpty(xPathElement.Value))
            {
                return null;
            }

            return Convert.ToInt32(xPathElement.Value);
        }

        public static XElement GetXPathElement(this XElement element, string xPath)
        {
            return element.XPathSelectElement(xPath);
        }

        public static bool GetBooleanValue(this XElement element, string name)
        {
            return Convert.ToBoolean(element?.Element(name)?.Value);
        }

        public static bool GetXPathBooleanValue(this XElement element, string xpath)
        {
            var xPathElement = element.XPathSelectElement(xpath);
            if (xPathElement == null)
            {
                return false;
            }

            return Convert.ToInt16(xPathElement.Value) == 1;
        }

        public static int GetIntegerValue(this XElement element, string name)
        {
            return Convert.ToInt32(element?.Element(name)?.Value);
        }

        public static int? GetIntegerNullableValue(this XElement element, string name)
        {
            return element?.Element(name) != null ? Convert.ToInt32(element.Element(name)?.Value) : (int?) null;
        }

        public static bool GetAttributeBooleanValue(this XElement element, string name)
        {
            return Convert.ToBoolean(element?.Attribute(name)?.Value);
        }

        public static int GetAttributeIntValue(this XElement element, string name)
        {
            return Convert.ToInt32(element?.Attribute(name)?.Value);
        }

        public static string GetAttributeStringValue(this XElement element, string attributeName)
        {
            return element.Attribute(attributeName)?.Value;
        }

        public static string GetAttributeOperatorValue(this XElement element, string attributeName)
        {
            return element.Attribute(attributeName) != null ? Convert.ToInt32(element.Attribute(attributeName)?.Value).ToString() : Operators.EqualTo;
        }

        public static string GetAttributeOperatorValue(this XElement element, string elementName, string attributeName, string defaultValue)
        {
            return element.Element(elementName)?.Attribute(attributeName) != null ? Convert.ToInt32(element.Element(elementName)?.Attribute(attributeName)?.Value).ToString() : defaultValue;
        }

        public static string GetAttributeOperatorValue(this XElement element, string elementName, string attributeName)
        {
            return element.Element(elementName)?.Attribute(attributeName) != null ? Convert.ToInt32(element.Element(elementName)?.Attribute(attributeName)?.Value).ToString() : Operators.EqualTo;
        }

        public static string GetAttributeOperatorExactValue(this XElement element, string elementName, string attributeName)
        {
            return element.Element(elementName)?.Attribute(attributeName) != null ? Convert.ToInt32(element.Element(elementName)?.Attribute(attributeName)?.Value).ToString() : string.Empty;
        }

        public static string GetAttributeOperatorValueForXPathElement(this XElement element, string xpath, string attributeName, string defaultValue)
        {
            var xPathElement = element.XPathSelectElement(xpath);
            if (xPathElement == null)
            {
                return defaultValue;
            }

            return xPathElement.Attribute(attributeName) != null ? xPathElement.Attribute(attributeName)?.Value : defaultValue;
        }

        public static string GetAttributeStringValueForElement(this XElement element, string elementName, string attributeName)
        {
            return element.Element(elementName)?.Attribute(attributeName)?.Value;
        }
    }
}