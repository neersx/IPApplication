using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.Rules
{
    public class NameTypeMapFacts
    {
        public class InheritFromMethod
        {
            [Fact]
            public void CopiesPropertiesAndSetsInheritedFlag()
            {
                var subject = new NameTypeMap(new ValidEventBuilder().Build(), null, null, Fixture.Short());
                var from = new NameTypeMap(new ValidEventBuilder().Build(), null, null, Fixture.Short());

                DataFiller.Fill(from);
                from.Inherited = false;

                subject.InheritRuleFrom(from);

                Assert.NotEqual(from.CriteriaId, subject.CriteriaId);
                Assert.NotEqual(from.EventId, subject.EventId);
                Assert.NotEqual(from.Sequence, subject.Sequence);
                Assert.NotEqual(from.Inherited, subject.Inherited);
                Assert.True(subject.Inherited);

                Assert.Equal(subject.ApplicableNameTypeKey, from.ApplicableNameTypeKey);
                Assert.Equal(subject.SubstituteNameTypeKey, from.SubstituteNameTypeKey);
                Assert.Equal(subject.MustExist, from.MustExist);
            }
        }
    }
}