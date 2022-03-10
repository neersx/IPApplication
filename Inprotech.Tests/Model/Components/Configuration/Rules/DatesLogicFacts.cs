using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.Rules
{
    public class DatesLogicFacts
    {
        public class HashKeyMethod
        {
            [Fact]
            public void GeneratesHashKey()
            {
                var d = new DatesLogic(new ValidEventBuilder().Build(), Fixture.Short());
                DataFiller.Fill(d);
                d.IsInherited = false;

                var c = new DatesLogic().InheritRuleFrom(d);

                Assert.Equal(c.HashKey(), d.HashKey());
            }
        }

        public class InheritFromMethod
        {
            [Fact]
            public void CopiesPropertiesAndSetsInheritedFlag()
            {
                var subject = new DatesLogic(new ValidEventBuilder().Build(), Fixture.Short());
                var from = new DatesLogic(new ValidEventBuilder().Build(), Fixture.Short());

                DataFiller.Fill(from);
                from.IsInherited = false;

                subject.InheritRuleFrom(from);

                Assert.NotEqual(from.CriteriaId, subject.CriteriaId);
                Assert.NotEqual(from.EventId, subject.EventId);
                Assert.NotEqual(from.Sequence, subject.Sequence);
                Assert.NotEqual(from.Inherited, subject.Inherited);
                Assert.True(subject.IsInherited);

                Assert.Equal(subject.DateTypeId, from.DateTypeId);
                Assert.Equal(subject.Operator, from.Operator);
                Assert.Equal(subject.CompareEventId, from.CompareEventId);
                Assert.Equal(subject.MustExist, from.MustExist);
                Assert.Equal(subject.RelativeCycle, from.RelativeCycle);
                Assert.Equal(subject.CompareDateTypeId, from.CompareDateTypeId);
                Assert.Equal(subject.CaseRelationshipId, from.CaseRelationshipId);
                Assert.Equal(subject.DisplayErrorFlag, from.DisplayErrorFlag);
                Assert.Equal(subject.ErrorMessage, from.ErrorMessage);
            }
        }
    }
}