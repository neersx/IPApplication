using System.Linq;
using System.Xml.Schema;
using Inprotech.Contracts;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Integration.SchemaMapping.Xsd;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class XsdTreeBuilderFacts : FactBase
    {
        public XsdTreeBuilderFacts()
        {
            XsdTreeBuilderFixture = new XsdTreeBuilderFixture(Db);
        }

        XsdTreeBuilderFixture XsdTreeBuilderFixture { get; }

        [Fact]
        public void ShouldParseAnonymousType()
        {
            var tree = XsdTreeBuilderFixture.Parse(XsdTreeBuilderFixture.XsdAnonymous);
            var types = tree.Types.ToArray();

            Assert.Equal("String", types[0].Name);
            Assert.NotNull(types[1].Name);
        }

        [Fact]
        public void ShouldParseAttribute()
        {
            var root = XsdTreeBuilderFixture.ParseAndGetRoot(XsdTreeBuilderFixture.XsdAttribute);

            Assert.Equal("root", root.Name);
            Assert.Equal("a1", root.Children.First().Name);
            Assert.Equal("attribute", root.Children.First().NodeType);
            Assert.Equal("Required", root.Children.First().AsAttribute().Use);
            Assert.Equal("a2", root.Children.Last().Name);
            Assert.Equal("attribute", root.Children.Last().NodeType);
            Assert.Equal("Optional", root.Children.Last().AsAttribute().Use);
        }

        [Fact]
        public void ShouldParseComplexType()
        {
            var root = XsdTreeBuilderFixture.ParseAndGetRoot(XsdTreeBuilderFixture.XsdComplexType);

            Assert.Equal("root", root.Name);
            Assert.Equal("c1", root.Children.Single().Name);
            Assert.Equal("element", root.Children.Single().NodeType);
            Assert.Equal("2", root.Children.Single().AsElement().MinOccurs);
            Assert.Equal("2", root.Children.Single().AsElement().MaxOccurs);
        }

        [Fact]
        public void ShouldParseEnumeration()
        {
            var tree = XsdTreeBuilderFixture.Parse(XsdTreeBuilderFixture.XsdEnumeration);
            var types = tree.Types;
            var root = tree.Structure;

            var type = types.Single(_ => _.Name == root.AsElement().TypeName);
            Assert.Equal("e1", type.Restrictions.Enumerations.Single());
        }

        [Fact]
        public void ShouldParseSimpleType()
        {
            var tree = XsdTreeBuilderFixture.Parse(XsdTreeBuilderFixture.XsdSimpleType);
            var types = tree.Types.ToArray();
            var t1 = types.Single(_ => _.Name == "t1");
            var t2 = types.Single(_ => _.Name == "t2");

            Assert.Equal("Integer", t1.DataType);
            Assert.Equal("10", t1.Restrictions.MaxInclusive);
            Assert.Equal(".", t2.Restrictions.Pattern);
            Assert.Equal("String", t2.DataType);
        }

        [Fact]
        public void ShouldParseUnionType()
        {
            var tree = XsdTreeBuilderFixture.Parse(XsdTreeBuilderFixture.XsdUnion);
            var types = tree.Types.ToArray();
            var u1 = (Union) types.Single(_ => _.Name == "u1");

            Assert.Equal("t1", u1.UnionTypes.First());
            Assert.Equal("t2", u1.UnionTypes.Last());
        }

        [Fact]
        public void ShouldSetParentIdForChildNode()
        {
            var root = XsdTreeBuilderFixture.ParseAndGetRoot(XsdTreeBuilderFixture.XsdComplexType);

            Assert.Equal(root.Id, root.Children.Single().ParentId);
        }

        [Fact]
        public void ShouldShowChoiceWithequenceInTree()
        {
            var root = XsdTreeBuilderFixture.ParseAndGetRoot(XsdTreeBuilderFixture.XsdChoiceWithSequence);
            var childern = root.Children.ToArray();
            var choice = childern[0];
            Assert.Equal("pageTitle", root.Name);
            Assert.Equal("Choice", choice.Name);
            Assert.Equal(2, choice.Children.Count());
            Assert.Equal("Sequence", choice.Children.First().NodeType);
            Assert.Equal("element", choice.Children.Last().NodeType);
        }

        [Fact]
        public void ShouldShowNestedSequenceInTree()
        {
            var root = XsdTreeBuilderFixture.ParseAndGetRoot(XsdTreeBuilderFixture.XsdNestedSequence);
            var childern = root.Children.ToArray();
            Assert.Equal("employee", root.Name);
            Assert.Equal("Sequence", childern[0].Name);
            Assert.Equal("Sequence", childern[0].NodeType);
            Assert.Equal("1", childern[0].AsSequence().MinOccurs);
            Assert.Equal("2", childern[0].AsSequence().MaxOccurs);
        }

        [Fact]
        public void ShoulParseMixedContentAsText()
        {
            var resp = XsdTreeBuilderFixture.Parse(XsdTreeBuilderFixture.XsdMixedContent);
            var root = resp.Structure.AsElement();
            Assert.Equal("pageTitle", root.Name);
            Assert.Equal("String", resp.Types.First(_ => _.Name == root.TypeName).DataType);
        }

        [Fact]
        public void ShoulRemoveChildernOfMixedContent()
        {
            var root = XsdTreeBuilderFixture.ParseAndGetRoot(XsdTreeBuilderFixture.XsdMixedContent);

            Assert.Equal("pageTitle", root.Name);
            Assert.False(root.Children.Any());
        }
    }

    public class XsdTreeBuilderFixture
    {
        readonly InMemoryDbContext _db;

        readonly IXsdParser _xsdParser;
        XmlSchema _schema;

        public XsdTreeBuilderFixture(InMemoryDbContext db)
        {
            _db = db;
            _xsdParser = new XsdParser(db, Substitute.For<IDtdReader>(), Substitute.For<IBackgroundProcessLogger<XsdParser>>());
            Subject = new XsdTreeBuilder();
        }

        XsdTreeBuilder Subject { get; }

        public XsdTree Parse(string xsdStr)
        {
            Helpers.DefaultSchemaAndFile(_db, xsdStr);
            _schema = _xsdParser.ParseAndCompile(1).SchemaSet.RootNodeSchema();
            return Subject.Build(_schema, Fixture.String());
        }

        public XsdNode ParseAndGetRoot(string xsdStr)
        {
            return Parse(xsdStr).Structure;
        }

        #region xsd samples

        const string XmlHeaderSchema = @"<?xml version=""1.0"" encoding=""UTF-8"" ?><xs:schema xmlns:xs=""http://www.w3.org/2001/XMLSchema"">";
        const string SchemaEnd = @"</xs:schema>";

        public string XsdComplexType => XmlHeaderSchema + @"<xs:element name=""root"" type=""t1"" />	
    <xs:complexType name=""t1"">
		<xs:sequence>
		  <xs:element name=""c1"" type=""xs:string"" minOccurs=""2"" maxOccurs=""2"" />
		</xs:sequence>
	</xs:complexType>" + SchemaEnd;

        public string XsdAttribute => XmlHeaderSchema + @"<xs:element name=""root"" type=""t1""></xs:element>
	<xs:complexType name=""t1"">
		<xs:simpleContent>
			<xs:extension base=""xs:string"">
				<xs:attribute name=""a1"" type=""xs:string"" use=""required""/>
				<xs:attribute name=""a2"" type=""xs:string"" use=""optional""/>
			</xs:extension>
		</xs:simpleContent>
	</xs:complexType>" + SchemaEnd;

        public string XsdEnumeration => XmlHeaderSchema + @"<xs:element name=""root"" type=""t1""/>
	<xs:simpleType name=""t1"">
		<xs:restriction base=""xs:string"">
			<xs:enumeration value=""e1""/>
		</xs:restriction>
	</xs:simpleType>" + SchemaEnd;

        public string XsdSimpleType => XmlHeaderSchema + @"	<xs:element name=""root"">
		<xs:complexType>
			<xs:sequence>
				<xs:element name=""c1"" type=""t1""/>
				<xs:element name=""c2"" type=""t2""/>				
			</xs:sequence>
		</xs:complexType>
	</xs:element>

	<xs:simpleType name=""t1"">
		<xs:restriction base=""xs:integer"">
			<xs:maxInclusive value=""10""/>
		</xs:restriction>
	</xs:simpleType>

	<xs:simpleType name=""t2"">
		<xs:restriction base=""xs:string"">
			<xs:pattern value="".""/>
			<xs:length value=""2""/>
		</xs:restriction>
	</xs:simpleType>" + SchemaEnd;

        public string XsdUnion => XmlHeaderSchema + @"<xs:element name=""root"" type=""u1"">		
	</xs:element>

	<xs:simpleType name=""u1"">
		<xs:union memberTypes=""t1 t2"">			
		</xs:union>
	</xs:simpleType>	
	
	<xs:simpleType name=""t1"">
		<xs:restriction base=""xs:string"">
			<xs:enumeration value=""1""/>
		</xs:restriction>
	</xs:simpleType>
	
	<xs:simpleType name=""t2"">
		<xs:restriction base=""xs:string"">
			<xs:enumeration value=""2""/>
		</xs:restriction>
	</xs:simpleType>" + SchemaEnd;

        public string XsdAnonymous => XmlHeaderSchema + @"
	<xs:element name=""root"">
		<xs:simpleType>
			<xs:restriction base=""xs:string"">
				<xs:length value=""2"" />
			</xs:restriction>
		</xs:simpleType>
	</xs:element>" + SchemaEnd;

        const string RandomElemnets = @"<xs:element name=""firstName"" type=""xs:string""/>
    <xs:element name=""lastName"" type=""xs:string""/>";

        public string XsdNestedSequence => XmlHeaderSchema + @"<xs:element name=""employee"" type=""personinfo""/>
<xs:complexType name=""personinfo"">
  <xs:sequence>
    <xs:sequence minOccurs=""1"" maxOccurs=""2"">
      <xs:element name=""CurrentPositons"" type=""xs:string"" />      
    </xs:sequence>" + RandomElemnets + @"
  </xs:sequence>
</xs:complexType>" + SchemaEnd;

        public string XsdMixedContent => XmlHeaderSchema + @"<xs:element name=""pageTitle"" type=""titleInfo""/>
<xs:complexType name=""titleInfo"" mixed=""true"">
  <xs:sequence>   
        <xs:element name=""italic"" type=""xs:string"" />
        <xs:element name=""bold"" type=""xs:string"" />
  </xs:sequence>
</xs:complexType>" + SchemaEnd;

        public string XsdChoiceWithSequence => XmlHeaderSchema + @"<xs:element name=""pageTitle"" type=""titleInfo""/>
<xs:complexType name=""titleInfo"">
<xs:choice>
  <xs:sequence>   
        <xs:element name=""contentLeft"" type=""xs:string"" />
        <xs:element name=""contentRight"" type=""xs:string"" />
  </xs:sequence>
<xs:element name=""contentAll"" type=""xs:string"" />
</xs:choice>
</xs:complexType>" + SchemaEnd;

        #endregion
    }
}