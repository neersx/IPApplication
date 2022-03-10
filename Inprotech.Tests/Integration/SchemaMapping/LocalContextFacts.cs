using System;
using System.Data;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.XmlGen;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class LocalContextFacts
    {
        [Fact]
        public void ShouldGetDocItemValue()
        {
            var table = new DataTable();
            table.Columns.Add("a", typeof(string));
            table.Columns.Add("b", typeof(string));
            var row = table.NewRow();
            row["a"] = "1";
            row["b"] = DBNull.Value;

            var ctx = new LocalContext(null, "1", row);
            var r1 = ctx.GetDocItemValue(new DocItemBinding {NodeId = "1", ColumnId = 0});
            Assert.Equal("1", r1);
            var r2 = ctx.GetDocItemValue(new DocItemBinding {NodeId = "1", ColumnId = 1});
            Assert.Null(r2);
        }

        [Fact]
        public void ShouldPassOverToParentContextIfBindingNotMatching()
        {
            var parent = Substitute.For<ILocalContext>();

            var ctx = new LocalContext(parent, "1", null);

            var binding = new DocItemBinding();
            ctx.GetDocItemValue(binding);

            parent.Received(1).GetDocItemValue(binding);
        }

        [Fact]
        public void ShouldRaiseExceptionIfUnableToResolveBinding()
        {
            var e = Record.Exception(() =>
            {
                var ctx = new LocalContext(null, "1", null);

                ctx.GetDocItemValue(new DocItemBinding());
            });

            Assert.IsType<XmlGenException>(e);
        }
    }
}