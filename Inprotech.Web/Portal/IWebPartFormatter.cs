using System.Xml.Linq;

namespace Inprotech.Web.Portal
{
    public interface IWebPartFormatter
    {
        object Load(XElement xml);
    }
}