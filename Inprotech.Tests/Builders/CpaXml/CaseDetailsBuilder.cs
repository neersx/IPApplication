using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.Builders.CpaXml
{
    public class CaseDetailsBuilder : IBuilder<XElement>
    {
        public CaseDetailsBuilder(XNamespace ns)
        {
            Ns = ns;
        }

        public XNamespace Ns { get; set; }

        public string CountryCode { get; set; }

        public string PropertyType { get; set; }

        public List<XElement> DescriptionDetails { get; set; }

        public XElement Build()
        {
            return new XElement(
                                Ns + "CaseDetails",
                                new XElement(Ns + "CaseCountryCode", CountryCode ?? "US"),
                                new XElement(Ns + "CasePropertyTypeCode", PropertyType ?? "Trademark"),
                                BuildDescriptionDetails()
                               );
        }

        IEnumerable<XElement> BuildDescriptionDetails()
        {
            return DescriptionDetails ?? Enumerable.Empty<XElement>();
        }

        public CaseDetailsBuilder WithDescription(string code, string text)
        {
            if (DescriptionDetails == null)
            {
                DescriptionDetails = new List<XElement>();
            }

            DescriptionDetails.Add(new DescriptionDetailsBuilder
            {
                Code = code,
                Text = text,
                Ns = Ns
            }.Build());

            return this;
        }
    }
}