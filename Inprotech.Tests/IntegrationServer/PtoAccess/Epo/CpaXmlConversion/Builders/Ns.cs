using System.Xml.Linq;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders
{
    internal static class Ns
    {
        public static XNamespace Ops => XNamespace.Get("http://ops.epo.org");

        public static XNamespace Reg => XNamespace.Get("http://www.epo.org/register");

        public static XNamespace XLink => XNamespace.Get("http://www.w3.org/1999/xlink");

        public static XNamespace Cpc => XNamespace.Get("http://www.epo.org/cpcexport");

        public static XNamespace CpcDef => XNamespace.Get("http://www.epo.org/cpcdefinition");
    }
}