using System.Data;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class XmlGenContextFacts
    {
        static DataRow BuildDataRow(string value)
        {
            var table = new DataTable();
            table.Columns.Add(new DataColumn("c1", typeof(string)));

            var row = table.NewRow();
            row[0] = value;
            return row;
        }

        [Fact]
        public void ShouldGetDocItemValueFromCurrentNode()
        {
            var ctx = new LocalContext(null, "n1", BuildDataRow("a"));
            var r = ctx.GetDocItemValue(new DocItemBinding {NodeId = "n1", ColumnId = 0});

            Assert.Equal("a", r);
        }

        [Fact]
        public void ShouldGetDocItemValueFromParentNode()
        {
            var ctx = new LocalContext(new LocalContext(null, "n1", BuildDataRow("a")), null, null);
            var r = ctx.GetDocItemValue(new DocItemBinding {NodeId = "n1", ColumnId = 0});

            Assert.Equal("a", r);
        }
    }
}