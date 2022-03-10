using System.Xml.Schema;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Inprotech.Integration.SchemaMapping.XmlGen.Formatters;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class XmlValueFormatterFacts
    {
        [Fact]
        public void ShouldUseSupportedFormatterForAttribute()
        {
            var date = Fixture.Today();
            var node = new Attribute(new XmlSchemaAttribute());

            var formatter1 = Substitute.For<IXmlSchemaTypeFormatter>();
            var formatter2 = Substitute.For<IXmlSchemaTypeFormatter>();
            formatter2.Supports(null, date).Returns(true);

            var xmlValueFormatter = new XmlValueFormatter(new[]
            {
                formatter1,
                formatter2
            });
            xmlValueFormatter.Format(node, date, null);

            formatter1.DidNotReceiveWithAnyArgs().Format(date);
            formatter2.Received(1).Format(date);
        }

        [Fact]
        public void ShouldUseSupportedFormatterForElement()
        {
            var date = Fixture.Today();
            var node = new Element(new XmlSchemaElement());

            var formatter1 = Substitute.For<IXmlSchemaTypeFormatter>();
            var formatter2 = Substitute.For<IXmlSchemaTypeFormatter>();
            formatter2.Supports(null, date).Returns(true);

            var xmlValueFormatter = new XmlValueFormatter(new[]
            {
                formatter1,
                formatter2
            });
            xmlValueFormatter.Format(node, date, null);

            formatter1.DidNotReceiveWithAnyArgs().Format(date);
            formatter2.Received(1).Format(date);
        }
    }
}