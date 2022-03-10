using System.Xml.Linq;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders
{
    internal static class Helper
    {
        public static XElement AddElement(XElement parent, XName childName)
        {
            var newElement = new XElement(childName);
            parent.Add(newElement);
            return newElement;
        }

        public static XElement AddElement(XElement parent, XName childName, string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return null;
            }

            var newElement = new XElement(childName, value);
            parent.Add(newElement);
            return newElement;
        }

        public static void AddAttribute(XElement element, string name, string value)
        {
            if (!string.IsNullOrEmpty(value))
            {
                element.Add(new XAttribute(name, value));
            }
        }
    }
}