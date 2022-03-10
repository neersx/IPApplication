using System.Linq;
using Inprotech.Integration.SchemaMapping.Data;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class MappingInfoParserFacts
    {
        [Fact]
        public void ShouldHandleEmpty()
        {
            const string jsonStr = @"";

            var r = new MappingEntryLookup(jsonStr);

            Assert.Null(r.GetMappingInfo("1"));
        }

        [Fact]
        public void ShouldHandleEmptySet()
        {
            const string jsonStr = @"{}";

            var r = new MappingEntryLookup(jsonStr);

            Assert.Null(r.GetMappingInfo("1"));
        }

        [Fact]
        public void ShouldParse()
        {
            const string jsonStr = @"
{
    ""mappingEntries"": {
        ""1"": {
            ""docItemBinding"": {
                ""nodeId"": ""1"",
                ""columnId"": 0
            },
            ""docItem"": {
                ""id"": 0,
                ""parameters"": [{
                    ""type"": ""global"",
                    ""id"": ""gstrEntryPoint""
                }, {
                    ""type"": ""fixed"",
                    ""id"": ""p1"",
                    ""value"": ""1""
                }]
            }
        },
        ""4"": {
            ""fixedValue"": ""123"",
            ""docItemBinding"": {
                ""nodeId"": ""1"",
                ""columnId"": 1
            }
        }
    }
}";
            var r = new MappingEntryLookup(jsonStr);

            Assert.Equal("gstrEntryPoint", r.GetDocItem("1").Parameters.First().Id);
            Assert.Equal("global", r.GetDocItem("1").Parameters.First().Type);
            Assert.Equal("p1", r.GetDocItem("1").Parameters.Last().Id);
            Assert.Equal("1", ((FixedParameter) r.GetDocItem("1").Parameters.Last()).Value);
            Assert.Equal("123", r.GetFixedValue("4"));
            Assert.Equal("1", r.GetDocItemBinding("4").NodeId);
            Assert.Equal(1, r.GetDocItemBinding("4").ColumnId);
        }
    }
}