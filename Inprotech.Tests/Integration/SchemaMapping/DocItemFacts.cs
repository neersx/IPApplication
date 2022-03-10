using System.Collections.Generic;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class DocItemFacts
    {
        [Fact]
        public void ShouldBuildFixedParametersAndCached()
        {
            var docItem = new DocItem
            {
                Parameters = new[]
                {
                    new FixedParameter
                    {
                        Id = "1",
                        Value = "1"
                    }
                }
            };

            var r = docItem.BuildParameters(null);
            Assert.Equal(r, docItem.CachedParameters);
            Assert.Equal("1", r["1"]);
        }

        [Fact]
        public void ShouldBuildGlobalParameters()
        {
            var docItem = new DocItem
            {
                Parameters = new[]
                {
                    new GlobalParameter
                    {
                        Id = "1"
                    }
                }
            };

            var r = docItem.BuildParameters(new GlobalContext(new Dictionary<string, object> {{"1", "1"}}));
            Assert.Equal("1", r["1"]);
        }
    }
}