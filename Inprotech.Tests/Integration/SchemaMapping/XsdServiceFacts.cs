using System.Linq;
using Inprotech.Contracts;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Integration.SchemaMapping.Xsd;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class XsdServiceFacts
    {
        public class InspectMethod : FactBase
        {
            [Fact]
            public void ShouldcallXmlParser()
            {
                var f = new XsdServiceFixture(Db);
                Helpers.DefaultSchemaAndFile(Db, f.Xsd);
                var schemaInfo = f.Subject.Inspect(1);

                Assert.Equal(SchemaSetError.MissingDependencies, schemaInfo.SchemaError);
                Assert.Equal("child.xsd", schemaInfo.MissingDependencies.Single());
            }
        }

        public class GetPossibleRootNodesMethod : FactBase
        {
            [Fact]
            public void MultipleRootNodeShouldBeIdentified()
            {
                var f = new XsdServiceFixture(Db).WithMultipleRoot();
                var r = f.Subject.GetPossibleRootNodes(1).ToList();
                Assert.Equal(2, r.Count());
                Assert.Equal("root", r.First().QualifiedName.Name);
                Assert.Equal("root2", r.Last().QualifiedName.Name);
            }

            [Fact]
            public void MultipleRootNodeWithOneComplexNode()
            {
                var f = new XsdServiceFixture(Db).WithComplexTypeMultipleRoot();
                var r = f.Subject.GetPossibleRootNodes(1).ToList();
                Assert.Single(r);
                Assert.Equal("employee", r.First().QualifiedName.Name);
            }

            [Fact]
            public void SingleRootNodeShouldBeIdentified()
            {
                var f = new XsdServiceFixture(Db).WithNoDependency();
                var r = f.Subject.GetPossibleRootNodes(1).ToList();
                Assert.Single(r);
                Assert.Equal("root", r.First().QualifiedName.Name);
            }
        }

        public class XsdServiceFixture
        {
            const string Xml = @"<?xml version=""1.0"" encoding=""UTF-8""?>";
            const string SchemaStart = @"<xs:schema xmlns:xs=""http://www.w3.org/2001/XMLSchema"" xmlns=""http://mycompany.com"" targetNamespace=""http://mycompany.com"" version=""1.0"">";
            const string Element = @"<xs:element name=""root"" type=""xs:string""/>";
            const string SchemaEnd = @"</xs:schema>";

            readonly InMemoryDbContext _db;
            string _include = @"<xs:include schemaLocation=""child.xsd""/>";

            public XsdServiceFixture(InMemoryDbContext db)
            {
                _db = db;
                var treeBuilder = Substitute.For<IXsdTreeBuilder>();
                IXsdParser parser = new XsdParser(db, Substitute.For<IDtdReader>(), Substitute.For<IBackgroundProcessLogger<XsdParser>>());
                Subject = new XsdService(parser, treeBuilder, db);
            }

            public string Xsd => Xml + SchemaStart + _include + Element + SchemaEnd;

            internal XsdService Subject { get; }

            public XsdServiceFixture WithNoDependency()
            {
                _include = string.Empty;
                Helpers.DefaultSchemaAndFile(_db, Xsd);
                return this;
            }

            public XsdServiceFixture WithMultipleRoot()
            {
                _include = string.Empty;
                var root2 = @"<xs:element name=""root2"" type=""xs:string""/>";
                var xsd = Xml + SchemaStart + _include + Element + root2 + SchemaEnd;
                Helpers.DefaultSchemaAndFile(_db, xsd);
                return this;
            }

            public XsdServiceFixture WithComplexTypeMultipleRoot()
            {
                _include = string.Empty;
                var section = @"<xs:element name=""employee"" type=""personinfo""/>
<xs:complexType name=""personinfo"">
  <xs:sequence>
    <xs:sequence minOccurs=""1"" maxOccurs=""2"">
      <xs:element name=""CurrentPositons"" type=""xs:string"" maxOccurs=""2"" />      
    </xs:sequence>
    <xs:element name=""firstname"" type=""xs:string""/>
    <xs:element name=""lastname"" type=""xs:string""/>	  
  </xs:sequence>
</xs:complexType>";
                var xsd = Xml + SchemaStart + _include + Element + section + SchemaEnd;
                Helpers.DefaultSchemaAndFile(_db, xsd);
                return this;
            }
        }
    }
}