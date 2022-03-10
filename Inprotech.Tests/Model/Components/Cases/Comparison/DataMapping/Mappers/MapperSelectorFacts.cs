using System.Collections.Generic;
using Autofac.Features.Metadata;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class MapperSelectorFacts
    {
        [Fact]
        public void ReturnsMapperByComparisonType()
        {
            var a = Substitute.For<IComparisonScenarioMapper>();

            var mappers = new[]
            {
                new Meta<IComparisonScenarioMapper>(a,
                                                    new Dictionary<string, object> {{"ComparisonType", ComparisonType.OfficialNumbers}})
            };

            var subject = new MapperSelector(mappers);

            Assert.Equal(a, subject[ComparisonType.OfficialNumbers]);
        }
    }
}