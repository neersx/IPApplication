using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.Builders.CpaXml
{
    public class DescriptionDetailsBuilder : IBuilder<XElement>
    {
        public XNamespace Ns { get; set; }

        public string Text { get; set; }

        public string Code { get; set; }

        public XElement Build()
        {
            return new XElement(
                                Ns + "DescriptionDetails",
                                new XElement(Ns + "DescriptionCode", Code ?? Fixture.String()),
                                new XElement(Ns + "DescriptionText", Text ?? Fixture.String())
                               );
        }
    }
}