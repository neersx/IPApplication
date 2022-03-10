using System.Xml.Linq;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders
{
    internal static class ElementNames
    {
        public static XName Registerdoc = Ns.Reg + "register-document";
        public static XName BibliographicData = Ns.Reg + "bibliographic-data";

        public static XName Parties = Ns.Reg + "parties";
        public static XName ApplicationRef = Ns.Reg + "application-reference";
        public static XName PublicationRef = Ns.Reg + "publication-reference";
        public static XName DocumentId = Ns.Reg + "document-id";
        public static XName Country = Ns.Reg + "country";
        public static XName DocNumber = Ns.Reg + "doc-number";
        public static XName Kind = Ns.Reg + "kind";
        public static XName Date = Ns.Reg + "date";

        public static XName Applicants = Ns.Reg + "applicants";
        public static XName Applicant = Ns.Reg + "applicant";
        public static XName Inventors = Ns.Reg + "inventors";
        public static XName Inventor = Ns.Reg + "inventor";
        public static XName AddressBook = Ns.Reg + "addressbook";
        public static XName Address = Ns.Reg + "address";
        public static XName Address1 = Ns.Reg + "address-1";
        public static XName Address2 = Ns.Reg + "address-2";
        public static XName Name = Ns.Reg + "name";

        public static XName PriorityClaims = Ns.Reg + "priority-claims";
        public static XName PriorityClaim = Ns.Reg + "priority-claim";

        public static XName InventionTitle = Ns.Reg + "invention-title";
        public static XName ProceduralData = Ns.Reg + "procedural-data";
        public static XName ProceduralStep = Ns.Reg + "procedural-step";
        public static XName ProceduralStepCode = Ns.Reg + "procedural-step-code";
        public static XName ProceduralStepText = Ns.Reg + "procedural-step-text";
    }
}