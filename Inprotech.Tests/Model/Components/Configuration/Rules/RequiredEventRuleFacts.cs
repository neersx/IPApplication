using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.Rules
{
    public class RequiredEventRuleFacts
    {
        public class InheritFromMethod
        {
            [Fact]
            public void CopiesPropertiesAndSetsInheritedFlag()
            {
                var subject = new RequiredEventRule(new ValidEventBuilder().Build());
                var from = new RequiredEventRule(new ValidEventBuilder().Build());

                DataFiller.Fill(from);
                from.Inherited = false;

                subject.InheritRuleFrom(from);

                Assert.NotEqual(from.CriteriaId, subject.CriteriaId);
                Assert.NotEqual(from.EventId, subject.EventId);
                Assert.NotEqual(from.Inherited, subject.Inherited);
                Assert.True(subject.Inherited);

                Assert.Equal(subject.RequiredEventId, from.RequiredEventId);
            }
        }
    }
}