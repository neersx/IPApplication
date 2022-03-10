using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.Rules
{
    public class RelatedEventRuleFacts
    {
        public class InheritFromMethod
        {
            [Fact]
            public void CopiesPropertiesAndSetsInheritedFlag()
            {
                var subject = new RelatedEventRule(new ValidEventBuilder().Build(), Fixture.Short());
                var from = new RelatedEventRule(new ValidEventBuilder().Build(), Fixture.Short());

                DataFiller.Fill(from);
                from.IsInherited = false;

                subject.InheritRuleFrom(from);

                Assert.NotEqual(from.CriteriaId, subject.CriteriaId);
                Assert.NotEqual(from.EventId, subject.EventId);
                Assert.NotEqual(from.Sequence, subject.Sequence);
                Assert.NotEqual(from.Inherited, subject.Inherited);
                Assert.True(subject.IsInherited);

                Assert.Equal(subject.RelatedEventId, from.RelatedEventId);
                Assert.Equal(subject.ClearEvent, from.ClearEvent);
                Assert.Equal(subject.ClearDue, from.ClearDue);
                Assert.Equal(subject.SatisfyEvent, from.SatisfyEvent);
                Assert.Equal(subject.UpdateEvent, from.UpdateEvent);
                Assert.Equal(subject.CreateNextCycle, from.CreateNextCycle);
                Assert.Equal(subject.DateAdjustmentId, from.DateAdjustmentId);
                Assert.Equal(subject.RelativeCycleId, from.RelativeCycleId);
                Assert.Equal(subject.ClearEventOnDueChange, from.ClearEventOnDueChange);
                Assert.Equal(subject.ClearDueOnDueChange, from.ClearDueOnDueChange);
            }
        }

        public class CopySatisfyingEventMethod
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void CopiesSatisfyingEventFields(bool isInherited)
            {
                var subject = new RelatedEventRule(new ValidEventBuilder().Build(), Fixture.Short());
                var from = new RelatedEventRule(new ValidEventBuilder().Build(), Fixture.Short());
                DataFiller.Fill(from);

                subject.CopySatisfyingEvent(from, isInherited);

                Assert.Equal(from.RelatedEventId, subject.RelatedEventId);
                Assert.Equal(from.RelativeCycleId, subject.RelativeCycleId);
                Assert.Equal(isInherited, subject.IsInherited);
                Assert.True(subject.IsSatisfyingEvent);
                Assert.Null(subject.ClearEvent);
                Assert.Null(subject.ClearDue);
                Assert.Null(subject.ClearEventOnDueChange);
                Assert.Null(subject.ClearDueOnDueChange);
                Assert.Null(subject.UpdateEvent);
                Assert.Null(subject.DateAdjustmentId);
            }
        }

        public class MultiUseFlags
        {
            [Theory]
            [InlineData(true, false, false, false, false, false)]
            [InlineData(true, true, false, false, false, false)]
            [InlineData(false, false, true, false, false, false)]
            [InlineData(false, false, true, true, false, false)]
            [InlineData(false, false, false, true, false, false)]
            [InlineData(false, false, false, false, true, false)]
            [InlineData(false, false, false, false, false, true)]
            public void DoesNotFlagSingleUseRelatedEvent(bool clearEvent, bool clearDue, bool dueClearEvent, bool dueClearDue, bool isSatisfying, bool updateEvent)
            {
                var subject = new RelatedEventRule(1, 1, 1)
                {
                    ClearEvent = clearEvent ? 1 : 0,
                    ClearDue = clearDue ? 1 : 0,
                    ClearEventOnDueChange = dueClearEvent,
                    ClearDueOnDueChange = dueClearDue,
                    IsSatisfyingEvent = isSatisfying,
                    UpdateEvent = updateEvent ? 1 : 0
                };
                Assert.False(subject.IsMultiuse());
            }

            [Theory]
            [InlineData(true, false, false, false, true, false)]
            [InlineData(false, false, true, false, false, true)]
            [InlineData(true, true, true, true, true, true)]
            [InlineData(false, false, false, false, true, true)]
            [InlineData(true, null, null, null, true, null)]
            [InlineData(null, null, true, null, null, true)]
            public void IndicatesMultiUseRelatedEvent(bool? clearEvent, bool? clearDue, bool? dueClearEvent, bool? dueClearDue, bool? isSatisfying, bool? updateEvent)
            {
                var subject = new RelatedEventRule(1, 1, 1)
                {
                    ClearEvent = clearEvent == null ? (decimal?) null : clearEvent.Value ? 1 : 0,
                    ClearDue = clearDue == null ? (decimal?) null : clearDue.Value ? 1 : 0,
                    ClearEventOnDueChange = dueClearEvent,
                    ClearDueOnDueChange = dueClearDue,
                    SatisfyEvent = isSatisfying == null ? (decimal?) null : isSatisfying.Value ? 1 : 0,
                    UpdateEvent = updateEvent == null ? (decimal?) null : updateEvent.Value ? 1 : 0
                };
                Assert.True(subject.IsMultiuse());
            }
        }

        public class IsDuplicateRelatedRuleMethod
        {
            [Theory]
            [InlineData(1, 1, 1, 1, 1, 1, true, true, true)]
            [InlineData(1, 1, 1, 1, 1, 2, true, true, false)]
            [InlineData(3, 2, 3, 4, 1, 1, true, false, false)]
            [InlineData(9, 9, 9, 9, 9, 9, true, true, false)]
            [InlineData(3, 2, 3, 4, 1, 1, false, true, true)]
            [InlineData(null, null, null, null, null, null, null, null, true)]
            public void FindDuplicateRelatedEvents(int? relatedEventId, int? clearEvent, int? clearDue, int? satisfyingEvent, int? updateEvent, int? relativeCycleId, bool? clearEventOnDueChange, bool? clearDueOnDueChange, bool result)
            {
                var validEvent = new ValidEventBuilder().Build();
                var relatedEvent1 = new RelatedEventRule(validEvent, Fixture.Short())
                {
                    RelatedEventId = 1,
                    ClearEvent = 1,
                    ClearDue = 1,
                    SatisfyEvent = 1,
                    UpdateEvent = 1,
                    RelativeCycleId = 1,
                    ClearEventOnDueChange = true,
                    ClearDueOnDueChange = true
                };
                var relatedEvent2 = new RelatedEventRule(validEvent, Fixture.Short())
                {
                    RelatedEventId = 3,
                    ClearEvent = 2,
                    ClearDue = 3,
                    SatisfyEvent = 4,
                    UpdateEvent = 1,
                    RelativeCycleId = 1,
                    ClearEventOnDueChange = false,
                    ClearDueOnDueChange = true
                };
                var relatedEvent3 = new RelatedEventRule(validEvent, Fixture.Short());
                var subject = new List<RelatedEventRule> {relatedEvent1, relatedEvent2, relatedEvent3};
                var newRule = new RelatedEventRule(validEvent, Fixture.Short())
                {
                    RelatedEventId = relatedEventId,
                    ClearEvent = clearEvent,
                    ClearDue = clearDue,
                    SatisfyEvent = satisfyingEvent,
                    UpdateEvent = updateEvent,
                    RelativeCycleId = (short?)relativeCycleId,
                    ClearEventOnDueChange = clearEventOnDueChange,
                    ClearDueOnDueChange = clearDueOnDueChange
                };

                Assert.Equal(result, subject.IsDuplicateRelatedRule(newRule));
            }
        }

        public class HashKey
        {
            [Fact]
            public void HashKeyDoesNotChangeOnceCalculated()
            {
                // hash key is a singleton because satisfying event/Clear event/Update Event can affect the hash which we use to identify a row
                var subject = new RelatedEventRule(1, 1, 1);
                DataFiller.Fill(subject);
                var initialHashKey = subject.HashKey();
                subject.RelatedEventId = Fixture.Integer();
                subject.RelativeCycleId = Fixture.Short();

                Assert.Equal(initialHashKey, subject.HashKey());
            }
        }

        public class RelatedEventTypeIdentifiers
        {
            [Theory]
            [InlineData(true, false, false, false, true)]
            [InlineData(false, true, false, false, true)]
            [InlineData(false, false, true, false, true)]
            [InlineData(false, false, false, true, true)]
            [InlineData(true, true, true, true, true)]
            [InlineData(false, false, false, false, false)]
            public void IsClearEventRuleIdentifiesClearEvents(bool ece, bool ecd, bool dce, bool dcd, bool expectedResult)
            {
                var subject = new RelatedEventRule(1, 1, 1)
                {
                    IsClearEvent = ece,
                    IsClearDue = ecd,
                    ClearEventOnDueChange = dce,
                    ClearDueOnDueChange = dcd
                };

                Assert.Equal(expectedResult, subject.IsClearEventRule);

                var subject1 = new RelatedEventRule(1, 1, 1);

                var list = new[] {subject1, subject};
                if (expectedResult)
                {
                    Assert.Single(list.WhereEventsToClear());
                }
                else
                {
                    Assert.Empty(list.WhereEventsToClear());
                }
            }

            [Fact]
            public void IsSatisfyingEventIdentifiesSatisfyingEvent()
            {
                var subject = new RelatedEventRule(1, 1, 1) {IsSatisfyingEvent = false};
                Assert.False(subject.IsSatisfyingEvent);

                subject.IsSatisfyingEvent = true;
                Assert.True(subject.IsSatisfyingEvent);

                var subject1 = new RelatedEventRule(1, 1, 1) {IsSatisfyingEvent = false};

                var list = new[] {subject1, subject};
                Assert.True(list.WhereIsSatisfyingEvent().All(_ => _.IsSatisfyingEvent));
            }
        }

        public class WhereFilters
        {
            [Theory]
            [InlineData(true, 1)]
            [InlineData(false, 2)]
            public void WhereSatisfyingEventReturnsSatisfyingEvent(bool inheritedOnly, int expectedCount)
            {
                var subject = new List<RelatedEventRule>();
                subject.Add(new RelatedEventRule(1, 1, 1) {IsSatisfyingEvent = true, IsInherited = false});
                subject.Add(new RelatedEventRule(1, 1, 2) {IsSatisfyingEvent = true, IsInherited = true});
                subject.Add(new RelatedEventRule(1, 1, 3) {IsUpdateEvent = true});
                subject.Add(new RelatedEventRule(1, 1, 4) {IsClearEvent = true});

                var result = subject.WhereIsSatisfyingEvent(inheritedOnly);
                Assert.Equal(expectedCount, result.Count());
            }

            [Theory]
            [InlineData(true, 1)]
            [InlineData(false, 2)]
            public void WhereEventsToUpdateReturnsEventsToUpdate(bool inheritedOnly, int expectedCount)
            {
                var subject = new List<RelatedEventRule>();
                subject.Add(new RelatedEventRule(1, 1, 1) {IsSatisfyingEvent = true});
                subject.Add(new RelatedEventRule(1, 1, 2) {IsUpdateEvent = true, IsInherited = false});
                subject.Add(new RelatedEventRule(1, 1, 3) {IsUpdateEvent = true, IsInherited = true});
                subject.Add(new RelatedEventRule(1, 1, 4) {IsClearEvent = true});

                var result = subject.WhereEventsToUpdate(inheritedOnly);
                Assert.Equal(expectedCount, result.Count());
            }

            [Theory]
            [InlineData(true, 1)]
            [InlineData(false, 2)]
            public void WhereEventToClearReturnsEventsToClear(bool inheritedOnly, int expectedCount)
            {
                var subject = new List<RelatedEventRule>();
                subject.Add(new RelatedEventRule(1, 1, 1) {IsSatisfyingEvent = true});
                subject.Add(new RelatedEventRule(1, 1, 2) {IsUpdateEvent = true});
                subject.Add(new RelatedEventRule(1, 1, 3) {IsClearEvent = true, IsInherited = false});
                subject.Add(new RelatedEventRule(1, 1, 4) {IsClearEvent = true, IsInherited = true});

                var result = subject.WhereEventsToClear(inheritedOnly);
                Assert.Equal(expectedCount, result.Count());
            }
        }
    }
}