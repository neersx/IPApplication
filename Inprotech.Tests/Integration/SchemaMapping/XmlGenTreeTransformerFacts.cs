using System.Data;
using System.Linq;
using Inprotech.Contracts.DocItems;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class XmlGenTreeTransformerFacts : FactBase
    {
        public XmlGenTreeTransformerFacts()
        {
            _globalContext = Substitute.For<IGlobalContext>();
            _docItemRunner = Substitute.For<IDocItemRunner>();
            _mappingEntryLookup = Substitute.For<IMappingEntryLookup>();
            _xmlValueFormatter = Substitute.For<IXmlValueFormatter>();

            _xsdRoot = Helpers.BuildXsdTree(Db, @"<?xml version=""1.0"" encoding=""UTF-8"" ?>
<xs:schema xmlns:xs=""http://www.w3.org/2001/XMLSchema"">
	<xs:complexType name=""usertype"">
		<xs:sequence>
		  <xs:element name=""name"" type=""xs:string"" />
		</xs:sequence>
	</xs:complexType>

	<xs:element name=""user"" type=""usertype"" />
</xs:schema>");
        }

        readonly IDocItemRunner _docItemRunner;
        readonly IGlobalContext _globalContext;
        readonly IMappingEntryLookup _mappingEntryLookup;
        readonly XsdNode _xsdRoot;
        readonly IXmlValueFormatter _xmlValueFormatter;

        XmlGenNode Build()
        {
            return new XmlGenTreeTransformer(_docItemRunner, _xmlValueFormatter).Transform(_globalContext, _xsdRoot, _mappingEntryLookup);
        }

        static DataSet BuildDataRows(params string[] values)
        {
            var table = new DataTable();
            table.Columns.Add(new DataColumn("c1", typeof(string)));

            foreach (var v in values)
            {
                var row = table.NewRow();
                row["c1"] = v;
                table.Rows.Add(row);
            }

            var dataSet = new DataSet();
            dataSet.Tables.Add(table);

            return dataSet;
        }

        [Fact]
        public void ShouldBuildNodesWithoutDocItemBinding()
        {
            var n = Build();

            Assert.Equal("user", n.Name);
            Assert.Equal("name", n.Children.Single().Name);
        }

        [Fact]
        public void ShouldNotRenderElementIfDocItemDoesNotReturnAnyRows()
        {
            _mappingEntryLookup.GetDocItem(_xsdRoot.Children.Single().Id).Returns(new DocItem());

            _docItemRunner.Run(0, null).ReturnsForAnyArgs(BuildDataRows());

            var n = Build();

            Assert.Empty(n.Children);
        }

        [Fact]
        public void ShuldBuildNodesWithDocItemBinding()
        {
            _mappingEntryLookup.GetDocItem(_xsdRoot.Children.Single().Id).Returns(new DocItem());

            _docItemRunner.Run(0, null).ReturnsForAnyArgs(BuildDataRows("a", "b"));

            var n = Build();

            Assert.Equal(2, n.Children.Count);
        }
    }
}