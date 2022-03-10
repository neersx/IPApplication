using System.Linq;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class XmlGenNodeFacts : FactBase
    {
        public XmlGenNodeFacts()
        {
            _mappingEntryLookup = Substitute.For<IMappingEntryLookup>();
            _xmlValueFormatter = Substitute.For<IXmlValueFormatter>();
            _context = Substitute.For<ILocalContext>();

            _xsdRoot = Helpers.BuildXsdTree(Db, @"<?xml version=""1.0"" encoding=""UTF-8"" ?>
<xs:schema xmlns:xs=""http://www.w3.org/2001/XMLSchema"">
	<xs:element name=""root"" type=""t1"">
	</xs:element>

	<xs:complexType name=""t1"">
		<xs:simpleContent>
			<xs:extension base=""xs:string"">
				<xs:attribute name=""id"" type=""xs:string"" use=""required""/>			
			</xs:extension>
		</xs:simpleContent>
	</xs:complexType>
</xs:schema>");
        }

        readonly IMappingEntryLookup _mappingEntryLookup;
        readonly IXmlValueFormatter _xmlValueFormatter;
        readonly XsdNode _xsdRoot;
        readonly ILocalContext _context;

        [Fact]
        public void ShouldBuildNode()
        {
            var xsdNode = _xsdRoot.Children.First();
            _mappingEntryLookup.GetFixedValue(Arg.Any<string>()).ReturnsForAnyArgs(1);

            var node = new XmlGenNode(_mappingEntryLookup, _xmlValueFormatter, null, xsdNode, null);

            Assert.Equal("id", node.Name);
            Assert.True(node.IsAttribute);

            _mappingEntryLookup.Received(1).GetFixedValue(xsdNode.Id);
            _mappingEntryLookup.Received(1).GetDocItemBinding(xsdNode.Id);
        }

        [Fact]
        public void ShouldFormatGetValue()
        {
            var xsdNode = _xsdRoot.Children.First();
            _context.GetDocItemValue(null).ReturnsForAnyArgs("a");

            var node = new XmlGenNode(_mappingEntryLookup, _xmlValueFormatter, null, xsdNode, null)
            {
                Context = _context
            };

            node.GetValue();
            _xmlValueFormatter.Received(1).Format(xsdNode, "a", null);
        }
    }
}