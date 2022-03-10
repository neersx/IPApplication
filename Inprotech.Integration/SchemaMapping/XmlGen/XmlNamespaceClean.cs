using System.Linq;
using System.Xml.Linq;

namespace Inprotech.Integration.SchemaMapping.XmlGen
{
    public interface IXmlNameSpaceCleaner
    {
        XDocument Clean(XDocument xdoc);
    }
    public class XmlNamespaceClean : IXmlNameSpaceCleaner
    {
        public XDocument Clean(XDocument xdoc)
        {
            if (xdoc.Root == null || xdoc.Root.Name.Namespace != Constants.TempNameSpace)
                return xdoc;

            foreach (var e in xdoc.Root.DescendantsAndSelf())
            {
                if (e.Name.Namespace != XNamespace.None && e.Name.Namespace == Constants.TempNameSpace)
                {
                    e.Name = XNamespace.None.GetName(e.Name.LocalName);
                }

                if (e.Attributes().Any(a => a.IsNamespaceDeclaration || a.Name.Namespace != XNamespace.None))
                {
                    e.ReplaceAttributes(e.Attributes().Select(a => a.IsNamespaceDeclaration && a.Value == Constants.TempNameSpace ? null : a.Name.Namespace != XNamespace.None ? new XAttribute(XNamespace.None.GetName(a.Name.LocalName), a.Value) : a));
                }
            }

            return xdoc;
        }
    }
}