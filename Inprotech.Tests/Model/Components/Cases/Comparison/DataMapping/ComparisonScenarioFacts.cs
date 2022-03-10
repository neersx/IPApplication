using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping
{
    public class ComparisonScenarioFacts
    {
        public class Fixture
        {
            public string StringProp { get; set; }

            public int IntProp { get; set; }

            public bool? NullableBool { get; set; }
        }

        [Fact]
        public void MakesCopyOfTFromSource()
        {
            var f = new Fixture
            {
                StringProp = Tests.Fixture.String(),
                IntProp = Tests.Fixture.Integer(),
                NullableBool = null
            };

            var subject = new ComparisonScenario<Fixture>(f, ComparisonType.OfficialNumbers);

            Assert.NotEqual(f, subject.Mapped);
            Assert.NotEqual(subject.Mapped, subject.ComparisonSource);
            Assert.Equal(subject.Mapped.StringProp, subject.ComparisonSource.StringProp);
            Assert.Equal(subject.Mapped.IntProp, subject.ComparisonSource.IntProp);
            Assert.Equal(subject.Mapped.NullableBool, subject.ComparisonSource.NullableBool);
        }
    }
}