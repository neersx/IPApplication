using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Configuration.Screens;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class InheritanceFacts
    {
        public class GetDescendantsWithoutEvent : FactBase
        {
            [Fact]
            public void DoesNotReturnChildCriteriaWhereParentHasEvent()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = Fixture.Integer();

                var childCriteria1 = new InheritsBuilder(Fixture.Integer(), parentCriteriaNo).Build().In(Db); // return
                var grandChildCriteria1 = new InheritsBuilder(Fixture.Integer(), childCriteria1.CriteriaNo).Build().In(Db); // return

                var childCriteria2 = new InheritsBuilder(Fixture.Integer(), parentCriteriaNo).Build().In(Db); // don't return (has event)
                var grandChildCriteria2 = new InheritsBuilder(Fixture.Integer(), childCriteria2.CriteriaNo).Build().In(Db); // don't return (doesn't have event)

                var validEvent = new ValidEvent(childCriteria2.CriteriaNo, Fixture.Integer());

                childCriteria2.Criteria.ValidEvents.Add(validEvent);

                var result = f.Subject.GetDescendantsWithoutEvent(parentCriteriaNo, validEvent.EventId).ToArray();

                Assert.Contains(result, r => r.Id == childCriteria1.CriteriaNo);
                Assert.Contains(result, r => r.Id == grandChildCriteria1.CriteriaNo);

                Assert.True(result.All(r => r.Id != parentCriteriaNo));

                Assert.True(result.All(r => r.Id != childCriteria2.CriteriaNo));
                Assert.True(result.All(r => r.Id != grandChildCriteria2.CriteriaNo));
            }

            [Fact]
            public void DoesNotReturnItself()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = Fixture.Integer();
                var parentCriteria = new InheritsBuilder(parentCriteriaNo, parentCriteriaNo).Build().In(Db);

                var result = f.Subject.GetDescendantsWithoutEvent(parentCriteria.CriteriaNo, Fixture.Integer()).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void HandlesCircularReferences()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = Fixture.Integer();
                var grandChildCriteriaNo = Fixture.Integer();
                var parentCriteria = new InheritsBuilder(parentCriteriaNo, grandChildCriteriaNo).Build().In(Db);
                var childCriteria = new InheritsBuilder(Fixture.Integer(), parentCriteriaNo).Build().In(Db);
                new InheritsBuilder(grandChildCriteriaNo, childCriteria.CriteriaNo).Build().In(Db);

                var result = f.Subject.GetDescendantsWithoutEvent(parentCriteria.CriteriaNo, Fixture.Integer()).ToArray();

                Assert.Equal(2, result.Length);
                Assert.True(result.All(r => r.Id != parentCriteria.CriteriaNo));
            }

            [Fact]
            public void ReturnsEmptyCollectionWhenNoResults()
            {
                var f = new InheritanceFixture(Db);
                var result = f.Subject.GetDescendantsWithoutEvent(Fixture.Integer(), Fixture.Integer()).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void ReturnsInheritedChildrenNotContainingEvent()
            {
                var f = new InheritanceFixture(Db);

                var parentCriteriaNo = Fixture.Integer();
                var childCriteria = new InheritsBuilder(Fixture.Integer(), parentCriteriaNo).Build().In(Db);
                var grandChildCriteria = new InheritsBuilder(Fixture.Integer(), childCriteria.CriteriaNo).Build().In(Db);

                var notReturnedCriteria = new InheritsBuilder(Fixture.Integer(), childCriteria.CriteriaNo).Build().In(Db);

                var validEvent = new ValidEvent(notReturnedCriteria.CriteriaNo, Fixture.Integer());
                notReturnedCriteria.Criteria.ValidEvents.Add(validEvent);

                var result = f.Subject.GetDescendantsWithoutEvent(parentCriteriaNo, validEvent.EventId).ToArray();

                Assert.Equal(2, result.Count());
                Assert.Contains(result, r => r.Id == childCriteria.CriteriaNo);
                Assert.Contains(result, r => r.Id == grandChildCriteria.CriteriaNo);
                Assert.True(result.All(r => r.Id != parentCriteriaNo));
                Assert.True(result.All(r => r.Id != notReturnedCriteria.CriteriaNo));
            }
        }

        public class GetDescendantsWithInheritedEvent : FactBase
        {
            [Fact]
            public void ShouldNotReturnForDifferentEvent()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 1;
                var childCriteria1 = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);

                new ValidEvent(parentCriteriaNo, 1) {Inherited = 0}.In(Db);
                new ValidEvent(childCriteria1.CriteriaNo, 2) {Inherited = 1}.In(Db);

                var ids = f.Subject.GetDescendantsWithInheritedEvent(parentCriteriaNo, 1).OrderBy(_ => _).ToArray();
                Assert.Empty(ids);
            }

            [Fact]
            public void ShouldNotReturnNonInheritedDescendants()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 1;
                var childCriteria1 = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);

                new ValidEvent(parentCriteriaNo, 1) {Inherited = 0}.In(Db);
                new ValidEvent(childCriteria1.CriteriaNo, 1) {Inherited = 0}.In(Db);

                var ids = f.Subject.GetDescendantsWithInheritedEvent(parentCriteriaNo, 1).OrderBy(_ => _).ToArray();
                Assert.Empty(ids);
            }

            [Fact]
            public void ShouldReturnInheritedDescendants()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 1;
                var childCriteria1 = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);
                var childCriteria2 = new InheritsBuilder(3, parentCriteriaNo).Build().In(Db);

                new ValidEvent(parentCriteriaNo, 1) {Inherited = 0}.In(Db);
                new ValidEvent(childCriteria1.CriteriaNo, 1) {Inherited = 1}.In(Db);
                new ValidEvent(childCriteria2.CriteriaNo, 1) {Inherited = 1}.In(Db);

                var ids = f.Subject.GetDescendantsWithInheritedEvent(parentCriteriaNo, 1).OrderBy(_ => _).ToArray();
                Assert.Equal(new[] {2, 3}, ids);
            }

            [Fact]
            public void TestWithComplexInheritance()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 1;
                var childCriteria1 = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);
                var childCriteria2 = new InheritsBuilder(3, parentCriteriaNo).Build().In(Db);
                var grandChildCriteria1 = new InheritsBuilder(4, childCriteria1.CriteriaNo).Build().In(Db);
                var grandChildCriteria2 = new InheritsBuilder(5, childCriteria1.CriteriaNo).Build().In(Db);
                var grandChildCriteria3 = new InheritsBuilder(6, childCriteria2.CriteriaNo).Build().In(Db);
                var grandChildCriteria4 = new InheritsBuilder(7, childCriteria2.CriteriaNo).Build().In(Db);

                new ValidEvent(parentCriteriaNo, 1) {Inherited = 0}.In(Db);
                new ValidEvent(childCriteria1.CriteriaNo, 1) {Inherited = 0}.In(Db);
                new ValidEvent(childCriteria2.CriteriaNo, 1) {Inherited = 1}.In(Db);
                new ValidEvent(grandChildCriteria1.CriteriaNo, 1) {Inherited = 1}.In(Db);
                new ValidEvent(grandChildCriteria2.CriteriaNo, 1) {Inherited = 1}.In(Db);
                new ValidEvent(grandChildCriteria3.CriteriaNo, 1) {Inherited = 0}.In(Db);
                new ValidEvent(grandChildCriteria4.CriteriaNo, 1) {Inherited = 1}.In(Db);

                var ids = f.Subject.GetDescendantsWithInheritedEvent(parentCriteriaNo, 1).OrderBy(_ => _).ToArray();
                Assert.Equal(new[] {3, 7}, ids);
            }
        }

        public class GetEventRulesWithInheritanceLevel : FactBase
        {
            InheritanceLevel CheckResult(IInheritance subject, int criteriaId)
            {
                var result = subject.GetEventRulesWithInheritanceLevel(criteriaId);
                return result.First().InheritanceLevel;
            }

            [Fact]
            public void ChecksAllRulesForInheritance()
            {
                var f = new InheritanceFixture(Db);

                var @event = new EventBuilder().Build();
                var parentCriteria = new CriteriaBuilder().Build();
                var criteria = new CriteriaBuilder().Build();
                new InheritsBuilder(criteria.Id, parentCriteria.Id) {Criteria = criteria, FromCriteria = parentCriteria}.Build().In(Db);

                var parentValidEvent = new ValidEventBuilder().For(parentCriteria, @event).Build().In(Db);
                var validEvent = new ValidEventBuilder {Inherited = true}.For(criteria, @event).Build().In(Db);
                parentCriteria.ValidEvents.Add(parentValidEvent);
                criteria.ValidEvents.Add(validEvent);
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));

                parentValidEvent.DueDateCalcs.Add(new DueDateCalcBuilder().For(parentValidEvent).Build());
                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));
                validEvent.DueDateCalcs.Add(new DueDateCalcBuilder {Inherited = 1}.For(validEvent).Build());
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));

                parentValidEvent.RelatedEvents.Add(new RelatedEventRuleBuilder().For(parentValidEvent).Build());
                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));
                validEvent.RelatedEvents.Add(new RelatedEventRuleBuilder {Inherited = 1}.For(validEvent).Build());
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));

                parentValidEvent.DatesLogic.Add(new DatesLogicBuilder().For(parentValidEvent).Build());
                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));
                validEvent.DatesLogic.Add(new DatesLogicBuilder {Inherited = 1}.For(validEvent).Build());
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));

                parentValidEvent.Reminders.Add(new ReminderRuleBuilder().AsReminderRule().For(parentValidEvent).Build());
                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));
                validEvent.Reminders.Add(new ReminderRuleBuilder {Inherited = 1}.AsReminderRule().For(validEvent).Build());
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));

                parentValidEvent.NameTypeMaps.Add(new NameTypeMapBuilder().For(parentValidEvent).Build());
                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));
                validEvent.NameTypeMaps.Add(new NameTypeMapBuilder {Inherited = true}.For(validEvent).Build());
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));

                parentValidEvent.RequiredEvents.Add(new RequiredEventRuleBuilder().For(parentValidEvent).Build());
                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));
                validEvent.RequiredEvents.Add(new RequiredEventRuleBuilder {Inherited = true}.For(validEvent).Build());
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));
            }

            [Fact]
            public void ReturnsNoInheritanceIfNoParent()
            {
                var f = new InheritanceFixture(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var validEvent = new ValidEventBuilder {Inherited = true}.For(criteria, new EventBuilder().Build()).Build().In(Db);
                criteria.ValidEvents.Add(validEvent);

                var result = f.Subject.GetEventRulesWithInheritanceLevel(criteria.Id);

                Assert.Equal(InheritanceLevel.None, result.First().InheritanceLevel);
            }

            [Fact]
            public void ReturnsPartialInheritanceWhenInheritedRulesChanged()
            {
                var f = new InheritanceFixture(Db);
                var @event = new EventBuilder().Build();
                var parentCriteria = new CriteriaBuilder().Build();
                var criteria = new CriteriaBuilder().Build();
                new InheritsBuilder(criteria.Id, parentCriteria.Id) {Criteria = criteria, FromCriteria = parentCriteria}.Build().In(Db);

                var parentValidEvent = new ValidEventBuilder().For(parentCriteria, @event).Build().In(Db);
                var validEvent = new ValidEventBuilder {Inherited = true}.For(criteria, @event).Build().In(Db);
                parentCriteria.ValidEvents.Add(parentValidEvent);
                criteria.ValidEvents.Add(validEvent);

                parentValidEvent.DueDateCalcs.Add(new DueDateCalcBuilder().For(parentValidEvent).Build());
                parentValidEvent.RelatedEvents.Add(new RelatedEventRuleBuilder().For(parentValidEvent).Build());
                parentValidEvent.DatesLogic.Add(new DatesLogicBuilder().For(parentValidEvent).Build());
                parentValidEvent.Reminders.Add(new ReminderRuleBuilder().AsReminderRule().AsReminderRule().For(parentValidEvent).Build());
                parentValidEvent.NameTypeMaps.Add(new NameTypeMapBuilder().For(parentValidEvent).Build());
                parentValidEvent.RequiredEvents.Add(new RequiredEventRuleBuilder().For(parentValidEvent).Build());

                validEvent.DueDateCalcs.Add(new DueDateCalcBuilder {Inherited = 0}.For(validEvent).Build());
                validEvent.RelatedEvents.Add(new RelatedEventRuleBuilder {Inherited = 0}.For(validEvent).Build());
                validEvent.DatesLogic.Add(new DatesLogicBuilder {Inherited = 0}.For(validEvent).Build());
                validEvent.Reminders.Add(new ReminderRuleBuilder {Inherited = 0}.For(validEvent).Build());
                validEvent.NameTypeMaps.Add(new NameTypeMapBuilder {Inherited = false}.For(validEvent).Build());
                validEvent.RequiredEvents.Add(new RequiredEventRuleBuilder {Inherited = false}.For(validEvent).Build());

                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));
            }

            [Fact]
            public void ReturnsPartialInheritanceWhenParentHasMoreRules()
            {
                var f = new InheritanceFixture(Db);

                var @event = new EventBuilder().Build();
                var parentCriteria = new CriteriaBuilder().Build();
                var criteria = new CriteriaBuilder().Build();
                new InheritsBuilder(criteria.Id, parentCriteria.Id) {Criteria = criteria, FromCriteria = parentCriteria}.Build().In(Db);

                var parentValidEvent = new ValidEventBuilder().For(parentCriteria, @event).Build().In(Db);
                var validEvent = new ValidEventBuilder {Inherited = true}.For(criteria, @event).Build().In(Db);

                parentCriteria.ValidEvents.Add(parentValidEvent);
                criteria.ValidEvents.Add(validEvent);

                parentValidEvent.DueDateCalcs.AddRange(new[] {new DueDateCalcBuilder().For(parentValidEvent).Build(), new DueDateCalcBuilder().For(parentValidEvent).Build()});
                validEvent.DueDateCalcs.Add(new DueDateCalcBuilder {Inherited = 1}.For(validEvent).Build());

                var result = f.Subject.GetEventRulesWithInheritanceLevel(criteria.Id);

                Assert.Equal(InheritanceLevel.Partial, result.First().InheritanceLevel);
            }
        }

        public class GetDescendantsWithEntry : FactBase
        {
            [Fact]
            public void ShouldNotReturnForDifferentEntry()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 100;
                var childCriteria1 = new InheritsBuilder(1, parentCriteriaNo).Build().In(Db);

                new DataEntryTask(parentCriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);
                new DataEntryTask(childCriteria1.CriteriaNo, 2) {Inherited = 1, Description = "Entry2"}.In(Db);

                var ids = f.Subject.GetDescendantsWithMatchedDescription(parentCriteriaNo, 1).OrderBy(_ => _).ToArray();
                Assert.Empty(ids);
            }

            [Fact]
            public void ShouldReturnDescendants()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 100;
                var childCriteria1 = new InheritsBuilder(1, parentCriteriaNo).Build().In(Db);
                var childCriteria2 = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);

                new DataEntryTask(parentCriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);
                new DataEntryTask(childCriteria1.CriteriaNo, 1) {Inherited = 1, Description = "Entry1"}.In(Db);
                new DataEntryTask(childCriteria2.CriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);

                var ids = f.Subject.GetDescendantsWithMatchedDescription(parentCriteriaNo, 1).OrderBy(_ => _).ToArray();
                Assert.Equal(new[] {1, 2}, ids);
            }

            [Fact]
            public void ShouldReturnDescendantsWithExactMatchForSeparator()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 100;
                var childCriteria1 = new InheritsBuilder(1, parentCriteriaNo).Build().In(Db);
                var childCriteria2 = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);

                new DataEntryTask(parentCriteriaNo, 1) {Inherited = 0, Description = "++A++", IsSeparator = true}.In(Db);
                new DataEntryTask(childCriteria1.CriteriaNo, 1) {Inherited = 1, Description = "++A++", IsSeparator = true}.In(Db);
                new DataEntryTask(childCriteria2.CriteriaNo, 1) {Inherited = 0, Description = "++A++===", IsSeparator = true}.In(Db);

                var ids = f.Subject.GetDescendantsWithMatchedDescription(parentCriteriaNo, 1).OrderBy(_ => _).ToArray();
                Assert.Equal(new[] {1}, ids);
            }

            [Fact]
            public void TestWithComplexInheritance()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 100;
                var childCriteria1 = new InheritsBuilder(1, parentCriteriaNo).Build().In(Db);
                var childCriteria2 = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);
                var grandChildCriteria1 = new InheritsBuilder(11, childCriteria1.CriteriaNo).Build().In(Db);
                var grandChildCriteria2 = new InheritsBuilder(12, childCriteria1.CriteriaNo).Build().In(Db);
                var grandChildCriteria3 = new InheritsBuilder(21, childCriteria2.CriteriaNo).Build().In(Db);
                var grandChildCriteria4 = new InheritsBuilder(22, childCriteria2.CriteriaNo).Build().In(Db);

                new DataEntryTask(parentCriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);
                new DataEntryTask(childCriteria1.CriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);
                new DataEntryTask(childCriteria2.CriteriaNo, 1) {Inherited = 1, Description = "Entry1"}.In(Db);
                new DataEntryTask(grandChildCriteria1.CriteriaNo, 1) {Inherited = 1, Description = "Entry3"}.In(Db);
                new DataEntryTask(grandChildCriteria2.CriteriaNo, 1) {Inherited = 1, Description = "Entry1"}.In(Db);
                new DataEntryTask(grandChildCriteria3.CriteriaNo, 1) {Inherited = 0, Description = "Entry4"}.In(Db);
                new DataEntryTask(grandChildCriteria4.CriteriaNo, 1) {Inherited = 1, Description = "Entry1"}.In(Db);

                var ids = f.Subject.GetDescendantsWithMatchedDescription(parentCriteriaNo, 1).OrderBy(_ => _).ToArray();
                Assert.Equal(new[] {1, 2, 12, 22}, ids);
            }
        }

        public class GetDescendantsWithoutEntry : FactBase
        {
            [Fact]
            public void DoesNotReturnChildCriteriaWhereParentHasEntry()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = Fixture.Integer();

                var childCriteria1 = new InheritsBuilder(Fixture.Integer(), parentCriteriaNo).Build().In(Db); // return
                var grandChildCriteria1 = new InheritsBuilder(Fixture.Integer(), childCriteria1.CriteriaNo).Build().In(Db); // return

                var childCriteria2 = new InheritsBuilder(Fixture.Integer(), parentCriteriaNo).Build().In(Db); // don't return (has event)
                var grandChildCriteria2 = new InheritsBuilder(Fixture.Integer(), childCriteria2.CriteriaNo).Build().In(Db); // don't return (doesn't have event)

                var entryDescription = "Entry test";
                var entry = new DataEntryTask(childCriteria2.CriteriaNo, Fixture.Short())
                {
                    Description = entryDescription
                };

                childCriteria2.Criteria.DataEntryTasks.Add(entry);

                var result = f.Subject.GetDescendantsWithoutEntry(parentCriteriaNo, entry.Description).ToArray();

                Assert.Contains(result, r => r.criteria.Id == childCriteria1.CriteriaNo);
                Assert.Contains(result, r => r.criteria.Id == grandChildCriteria1.CriteriaNo);

                Assert.True(result.All(r => r.criteria.Id != parentCriteriaNo));

                Assert.True(result.All(r => r.criteria.Id != childCriteria2.CriteriaNo));
                Assert.True(result.All(r => r.criteria.Id != grandChildCriteria2.CriteriaNo));
            }

            [Fact]
            public void DoesNotReturnItself()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = Fixture.Integer();
                var parentCriteria = new InheritsBuilder(parentCriteriaNo, parentCriteriaNo).Build().In(Db);

                var result = f.Subject.GetDescendantsWithoutEntry(parentCriteria.CriteriaNo, Fixture.String()).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void HandlesCircularReferences()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = Fixture.Integer();
                var grandChildCriteriaNo = Fixture.Integer();
                var parentCriteria = new InheritsBuilder(parentCriteriaNo, grandChildCriteriaNo).Build().In(Db);
                var childCriteria = new InheritsBuilder(Fixture.Integer(), parentCriteriaNo).Build().In(Db);
                new InheritsBuilder(grandChildCriteriaNo, childCriteria.CriteriaNo).Build().In(Db);

                var result = f.Subject.GetDescendantsWithoutEntry(parentCriteria.CriteriaNo, Fixture.String()).ToArray();

                Assert.Equal(2, result.Length);
                Assert.True(result.All(r => r.criteria.Id != parentCriteria.CriteriaNo));
            }

            [Fact]
            public void ReturnsEmptyCollectionWhenNoResults()
            {
                var f = new InheritanceFixture(Db);
                var result = f.Subject.GetDescendantsWithoutEntry(Fixture.Integer(), Fixture.String()).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void ReturnsInheritedChildrenNotContainingEntry()
            {
                var f = new InheritanceFixture(Db);

                var parentCriteriaNo = Fixture.Integer();
                var childCriteria = new InheritsBuilder(Fixture.Integer(), parentCriteriaNo).Build().In(Db);
                var grandChildCriteria = new InheritsBuilder(Fixture.Integer(), childCriteria.CriteriaNo).Build().In(Db);

                var notReturnedCriteria = new InheritsBuilder(Fixture.Integer(), childCriteria.CriteriaNo).Build().In(Db);

                var entryDescription = "Entry test";
                var entry = new DataEntryTask(notReturnedCriteria.CriteriaNo, Fixture.Short())
                {
                    Description = entryDescription
                };
                notReturnedCriteria.Criteria.DataEntryTasks.Add(entry);

                var result = f.Subject.GetDescendantsWithoutEntry(parentCriteriaNo, entry.Description).ToArray();

                Assert.Equal(2, result.Length);
                Assert.Contains(result, r => r.criteria.Id == childCriteria.CriteriaNo);
                Assert.Contains(result, r => r.criteria.Id == grandChildCriteria.CriteriaNo);
                Assert.True(result.All(r => r.criteria.Id != parentCriteriaNo));
                Assert.True(result.All(r => r.criteria.Id != notReturnedCriteria.CriteriaNo));
            }
        }

        public class GetDescendantsWithAnyOfEntriesInheritedMethod : FactBase
        {
            [Fact]
            public void DoesNotConsiderNonInheritedDescenedents()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 100;
                var childCriteria1 = new InheritsBuilder(1, parentCriteriaNo).Build().In(Db);
                var childCriteria2 = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);

                var parentEntry = new DataEntryTask(parentCriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);
                new DataEntryTask(childCriteria1.CriteriaNo, 1) {Inherited = 1, Description = "Entry1", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry.Id}.In(Db);
                new DataEntryTask(childCriteria2.CriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);

                var ids = f.Subject.GetDescendantsWithAnyInheritedEntriesFrom(parentCriteriaNo, new short[] {1}).OrderBy(_ => _).ToArray();
                Assert.DoesNotContain(childCriteria2.CriteriaNo, ids);
            }

            [Fact]
            public void ReturnEmptyIfNoDescendents()
            {
                var f = new InheritanceFixture(Db);
                const int parentCriteriaNo = 100;
                new DataEntryTask(parentCriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);

                var ids = f.Subject.GetDescendantsWithAnyInheritedEntriesFrom(parentCriteriaNo, new short[] {1}).OrderBy(_ => _).ToArray();
                Assert.Empty(ids);
            }

            [Fact]
            public void ReturnsForMultipleEntryIds()
            {
                const short parentEntry1 = 1989, parentEntry2 = 1991, child1Entry1 = 300;

                var f = new InheritanceFixture(Db);

                const int parentCriteriaNo = 100;

                var child1Rel = new InheritsBuilder(1, parentCriteriaNo).Build().In(Db);
                var child2Rel = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);
                var child3Rel = new InheritsBuilder(3, parentCriteriaNo).Build().In(Db);
                var child4Rel = new InheritsBuilder(4, parentCriteriaNo).Build().In(Db);

                var grandchild11Rel = new InheritsBuilder(11, child1Rel.CriteriaNo).Build().In(Db);

                new DataEntryTask(parentCriteriaNo, parentEntry1) {Inherited = 0, Description = "Entry1"}.In(Db);
                new DataEntryTask(parentCriteriaNo, parentEntry2) {Inherited = 0, Description = "Entry2"}.In(Db);

                new DataEntryTask(child1Rel.Criteria, child1Entry1) {Inherited = 1, Description = "Entry1", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry1}.In(Db);
                new DataEntryTask(child2Rel.Criteria, 6) {Inherited = 1, Description = "Entry2", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry2}.In(Db);
                new DataEntryTask(child3Rel.Criteria, 16) {Inherited = 1, Description = "DifferentEntry"}.In(Db);
                new DataEntryTask(child4Rel.Criteria, 16) {Inherited = 1, Description = "Entry1", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry1}.In(Db);
                new DataEntryTask(child4Rel.Criteria, 16) {Inherited = 1, Description = "Entry2", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry2}.In(Db);

                new DataEntryTask(grandchild11Rel.Criteria, 99) {Inherited = 1, Description = "Entry2", ParentCriteriaId = child1Rel.CriteriaNo, ParentEntryId = child1Entry1}.In(Db);

                var ids = f.Subject.GetDescendantsWithAnyInheritedEntriesFrom(parentCriteriaNo, new[] {parentEntry1, parentEntry2}).OrderBy(_ => _).ToArray();
                Assert.Equal(new[] {child1Rel.CriteriaNo, child2Rel.CriteriaNo, child4Rel.CriteriaNo, grandchild11Rel.CriteriaNo}, ids);
            }

            [Fact]
            public void ReturnsInheritedDescendents()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 100;
                var childCriteria1 = new InheritsBuilder(1, parentCriteriaNo).Build().In(Db);
                var childCriteria2 = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);

                var parentEntry = new DataEntryTask(parentCriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);
                new DataEntryTask(childCriteria1.CriteriaNo, 1) {Inherited = 1, Description = "Entry1", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry.Id}.In(Db);
                new DataEntryTask(childCriteria2.CriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);

                var ids = f.Subject.GetDescendantsWithAnyInheritedEntriesFrom(parentCriteriaNo, new short[] {1}).OrderBy(_ => _).ToArray();
                Assert.Equal(new[] {childCriteria1.CriteriaNo}, ids);
            }

            [Fact]
            public void ReturnsPartiallyInheritedDescendents()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 100;
                var child1Relation = new InheritsBuilder(1, parentCriteriaNo).Build().In(Db);
                var child2Relation = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);

                var parentEntry = new DataEntryTask(parentCriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);
                var child1 = new DataEntryTask(child1Relation.Criteria, 1) {Inherited = 1, Description = "Entry1", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry.Id}.In(Db);
                child1.AvailableEvents.Add(new AvailableEvent(child1, new Event(1).In(Db)) {Inherited = 1}.In(Db));

                var child2 = new DataEntryTask(child2Relation.Criteria, 1) {Inherited = 1, Description = "Entry1", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry.Id}.In(Db);
                child2.DocumentRequirements.Add(new DocumentRequirement {Inherited = 1}.In(Db));
                var ids = f.Subject.GetDescendantsWithAnyInheritedEntriesFrom(parentCriteriaNo, new short[] {1}).OrderBy(_ => _).ToArray();
                Assert.Equal(new[] {child1Relation.CriteriaNo, child2Relation.CriteriaNo}, ids);
            }
        }

        public class GetDescendantsWithAnyInheritedEntriesFromWithEntryIdsMethod : FactBase
        {
            [Fact]
            public void ConsiderInheritanceWhileReturningDescenedents()
            {
                var f = new InheritanceFixture(Db);
                var parentCriteriaNo = 100;
                var childCriteria1 = new InheritsBuilder(1, parentCriteriaNo).Build().In(Db);
                var childCriteria2 = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);

                var parentEntry = new DataEntryTask(parentCriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);
                new DataEntryTask(childCriteria1.CriteriaNo, 1) {Inherited = 1, Description = "Entry1", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry.Id}.In(Db);
                new DataEntryTask(childCriteria2.CriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);

                var ids = f.Subject.GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(parentCriteriaNo, new short[] {1}).OrderBy(_ => _).ToArray();
                Assert.DoesNotContain(ids, _ => _.CriteriaId == childCriteria2.CriteriaNo);
                Assert.Contains(ids, _ => _.CriteriaId == childCriteria1.CriteriaNo);
            }

            [Fact]
            public void ReturnEmptyIfNoDescendents()
            {
                var f = new InheritanceFixture(Db);
                const int parentCriteriaNo = 100;
                new DataEntryTask(parentCriteriaNo, 1) {Inherited = 0, Description = "Entry1"}.In(Db);

                var ids = f.Subject.GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(parentCriteriaNo, new short[] {1}).OrderBy(_ => _).ToArray();
                Assert.Empty(ids);
            }

            [Fact]
            public void ReturnsDirectDescendentsOnly()
            {
                const short parentEntry1 = 1989, parentEntry2 = 1991, child1Entry1 = 300;

                var f = new InheritanceFixture(Db);

                const int parentCriteriaNo = 100;

                var child1Rel = new InheritsBuilder(1, parentCriteriaNo).Build().In(Db);
                var grandchild11Rel = new InheritsBuilder(11, child1Rel.CriteriaNo).Build().In(Db);

                new DataEntryTask(parentCriteriaNo, parentEntry1) {Inherited = 0, Description = "Entry1"}.In(Db);
                new DataEntryTask(parentCriteriaNo, parentEntry2) {Inherited = 0, Description = "Entry2"}.In(Db);

                new DataEntryTask(child1Rel.Criteria, child1Entry1) {Inherited = 1, Description = "Entry1", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry1}.In(Db);
                new DataEntryTask(grandchild11Rel.Criteria, 99) {Inherited = 1, Description = "Entry2", ParentCriteriaId = child1Rel.CriteriaNo, ParentEntryId = child1Entry1}.In(Db);

                var ids = f.Subject.GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(parentCriteriaNo, new[] {parentEntry1, parentEntry2}, true).OrderBy(_ => _).ToArray();
                Assert.Contains(ids, _ => _.CriteriaId == child1Rel.CriteriaNo && _.EntryId == child1Entry1);
                Assert.DoesNotContain(ids, _ => _.CriteriaId == grandchild11Rel.CriteriaNo);
            }

            [Fact]
            public void ReturnsForMultipleEntryIds()
            {
                const short parentEntry1 = 1989, parentEntry2 = 1991, child1Entry1 = 300;

                var f = new InheritanceFixture(Db);

                const int parentCriteriaNo = 100;

                var child1Rel = new InheritsBuilder(1, parentCriteriaNo).Build().In(Db);
                var child2Rel = new InheritsBuilder(2, parentCriteriaNo).Build().In(Db);
                var child3Rel = new InheritsBuilder(3, parentCriteriaNo).Build().In(Db);
                var child4Rel = new InheritsBuilder(4, parentCriteriaNo).Build().In(Db);

                var grandchild11Rel = new InheritsBuilder(11, child1Rel.CriteriaNo).Build().In(Db);

                new DataEntryTask(parentCriteriaNo, parentEntry1) {Inherited = 0, Description = "Entry1"}.In(Db);
                new DataEntryTask(parentCriteriaNo, parentEntry2) {Inherited = 0, Description = "Entry2"}.In(Db);

                new DataEntryTask(child1Rel.Criteria, child1Entry1) {Inherited = 1, Description = "Entry1", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry1}.In(Db);
                new DataEntryTask(child2Rel.Criteria, 6) {Inherited = 1, Description = "Entry2", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry2}.In(Db);
                new DataEntryTask(child3Rel.Criteria, 16) {Inherited = 1, Description = "DifferentEntry"}.In(Db);
                new DataEntryTask(child4Rel.Criteria, 16) {Inherited = 1, Description = "Entry1", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry1}.In(Db);
                new DataEntryTask(child4Rel.Criteria, 16) {Inherited = 1, Description = "Entry2", ParentCriteriaId = parentCriteriaNo, ParentEntryId = parentEntry2}.In(Db);

                new DataEntryTask(grandchild11Rel.Criteria, 99) {Inherited = 1, Description = "Entry2", ParentCriteriaId = child1Rel.CriteriaNo, ParentEntryId = child1Entry1}.In(Db);

                var ids = f.Subject.GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(parentCriteriaNo, new[] {parentEntry1, parentEntry2}).ToArray();
                Assert.Contains(ids, _ => _.CriteriaId == child1Rel.CriteriaNo && _.EntryId == child1Entry1);
                Assert.Contains(ids, _ => _.CriteriaId == child2Rel.CriteriaNo);
                Assert.Contains(ids, _ => _.CriteriaId == child4Rel.CriteriaNo);
                Assert.Contains(ids, _ => _.CriteriaId == grandchild11Rel.CriteriaNo);
            }
        }

        public class GetEntriesWithInheritanceLevel : FactBase
        {
            InheritanceLevel CheckResult(IInheritance subject, int criteriaId)
            {
                var result = subject.GetEntriesWithInheritanceLevel(criteriaId);
                return result.First().InheritanceLevel;
            }

            [Fact]
            public void ChecksAllRulesForInheritance()
            {
                var f = new InheritanceFixture(Db);

                var @event = new EventBuilder().Build();
                var parentCriteria = new CriteriaBuilder().Build();
                var criteria = new CriteriaBuilder().Build();
                new InheritsBuilder(criteria.Id, parentCriteria.Id) {Criteria = criteria, FromCriteria = parentCriteria}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder {Criteria = parentCriteria}.Build().In(Db);
                var entry = new DataEntryTaskBuilder {Criteria = criteria, Description = parentEntry.Description, ParentCriteriaId = parentCriteria.Id}.WithParentInheritance(parentEntry.Id).Build().In(Db);
                parentCriteria.DataEntryTasks.Add(parentEntry);
                criteria.DataEntryTasks.Add(entry);
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));

                parentEntry.AvailableEvents.Add(new AvailableEventBuilder {DataEntryTask = parentEntry, Event = @event}.Build());
                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));
                entry.AvailableEvents.Add(new AvailableEventBuilder {IsInherited = true, DataEntryTask = entry, Event = @event}.Build());
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));

                parentEntry.DocumentRequirements.Add(new DocumentRequirement(parentCriteria, parentEntry, new Document(1, "doc", 0)).In(Db));
                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));
                entry.DocumentRequirements.Add(new DocumentRequirement(criteria, entry, new Document(1, "doc", 0)) {Inherited = 1}.In(Db));
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));

                parentEntry.GroupsAllowed.Add(new GroupControl(parentEntry, "group").In(Db));
                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));
                entry.GroupsAllowed.Add(new GroupControl(entry, "group") {Inherited = 1}.In(Db));
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));

                parentEntry.UsersAllowed.Add(UserControlBuilder.For(parentEntry, "test").Build());
                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));
                var userControl = UserControlBuilder.For(entry, "test");
                userControl.Inherited = 1;
                entry.UsersAllowed.Add(userControl.Build());
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));

                var parentTasks = new WindowControl(parentCriteria, parentEntry.Id).In(Db);
                TopicControlBuilder.For(parentTasks, "step 1").Build().In(Db);
                TopicControlBuilder.For(parentTasks, "step 2").Build().In(Db);
                parentEntry.TaskSteps.Add(parentTasks);

                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));

                var entryTasks = new WindowControl(criteria, entry.Id).In(Db);

                var tc1 = TopicControlBuilder.For(entryTasks, "step 1").Build();
                var tc2 = TopicControlBuilder.For(entryTasks, "step 2").Build();
                tc1.IsInherited = true;
                tc2.IsInherited = true;

                entry.TaskSteps.Add(entryTasks);
                Assert.Equal(InheritanceLevel.Full, CheckResult(f.Subject, criteria.Id));
            }

            [Fact]
            public void ReturnsNoInheritanceIfNoParent()
            {
                var f = new InheritanceFixture(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var entry = new DataEntryTaskBuilder {Inherited = 1, Criteria = criteria}.Build().In(Db);
                criteria.DataEntryTasks.Add(entry);

                var result = f.Subject.GetEntriesWithInheritanceLevel(criteria.Id);

                Assert.Equal(InheritanceLevel.None, result.First().InheritanceLevel);
            }

            [Fact]
            public void ReturnsNoInheritanceWhenInheritanceBroken()
            {
                var f = new InheritanceFixture(Db);
                var @event = new EventBuilder().Build();
                var parentCriteria = new CriteriaBuilder().Build();
                var criteria = new CriteriaBuilder().Build();
                new InheritsBuilder(criteria.Id, parentCriteria.Id) {Criteria = criteria, FromCriteria = parentCriteria}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder {Criteria = parentCriteria}.Build().In(Db);
                var entry = new DataEntryTaskBuilder {Inherited = 0, Criteria = criteria, Description = parentEntry.Description, ParentCriteriaId = parentCriteria.Id}.Build().In(Db);
                parentCriteria.DataEntryTasks.Add(parentEntry);
                criteria.DataEntryTasks.Add(entry);

                parentEntry.AvailableEvents.Add(new AvailableEventBuilder {DataEntryTask = parentEntry, Event = @event}.Build());
                parentEntry.DocumentRequirements.Add(new DocumentRequirement(parentCriteria, parentEntry, new Document(1, "doc", 0)));
                parentEntry.GroupsAllowed.Add(new GroupControl(parentEntry, "group"));
                parentEntry.UsersAllowed.Add(UserControlBuilder.For(parentEntry, "test").Build());
                parentEntry.TaskSteps.Add(new WindowControl(parentCriteria, parentEntry.Id));

                entry.AvailableEvents.Add(new AvailableEventBuilder {IsInherited = false, DataEntryTask = entry, Event = @event}.Build());
                entry.DocumentRequirements.Add(new DocumentRequirement(criteria, entry, new Document(1, "doc", 0)) {Inherited = 0});
                entry.GroupsAllowed.Add(new GroupControl(entry, "group") {Inherited = 0});
                entry.UsersAllowed.Add(UserControlBuilder.For(entry, "test").Build());
                entry.TaskSteps.Add(new WindowControl(criteria, entry.Id) {IsInherited = false});

                Assert.Equal(InheritanceLevel.None, CheckResult(f.Subject, criteria.Id));
            }

            [Fact]
            public void ReturnsPartialInheritanceWhenParentHasMoreRules()
            {
                var f = new InheritanceFixture(Db);

                var @event = new EventBuilder().Build();
                var parentCriteria = new CriteriaBuilder().Build();
                var criteria = new CriteriaBuilder().Build();
                new InheritsBuilder(criteria.Id, parentCriteria.Id) {Criteria = criteria, FromCriteria = parentCriteria}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder {Criteria = parentCriteria}.Build().In(Db);
                var entry = new DataEntryTaskBuilder {Criteria = criteria, Description = parentEntry.Description, ParentCriteriaId = parentCriteria.Id}.WithParentInheritance(parentEntry.Id).Build().In(Db);

                parentCriteria.DataEntryTasks.Add(parentEntry);
                criteria.DataEntryTasks.Add(entry);

                parentEntry.AvailableEvents.AddRange(new[] {new AvailableEventBuilder {DataEntryTask = parentEntry, Event = @event}.Build(), new AvailableEventBuilder {DataEntryTask = parentEntry, Event = new EventBuilder().Build()}.Build()});
                entry.AvailableEvents.Add(new AvailableEventBuilder {DataEntryTask = parentEntry, Event = @event, IsInherited = true}.Build());

                var result = f.Subject.GetEntriesWithInheritanceLevel(criteria.Id);

                Assert.Equal(InheritanceLevel.Partial, result.First().InheritanceLevel);
            }

            [Fact]
            public void ReturnsPartialInheritanceWhenParentHasMoreStepRules()
            {
                var f = new InheritanceFixture(Db);

                new EventBuilder().Build();
                var parentCriteria = new CriteriaBuilder().Build();
                var criteria = new CriteriaBuilder().Build();
                new InheritsBuilder(criteria.Id, parentCriteria.Id) {Criteria = criteria, FromCriteria = parentCriteria}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder {Criteria = parentCriteria}.Build().In(Db);
                var entry = new DataEntryTaskBuilder {Criteria = criteria, Description = parentEntry.Description, ParentCriteriaId = parentCriteria.Id}.WithParentInheritance(parentEntry.Id).Build().In(Db);

                parentCriteria.DataEntryTasks.Add(parentEntry);
                criteria.DataEntryTasks.Add(entry);

                var parentTasks = new WindowControl(parentCriteria, parentEntry.Id).In(Db);
                TopicControlBuilder.For(parentTasks, "step 1").Build().In(Db);
                TopicControlBuilder.For(parentTasks, "step 2").Build().In(Db);
                parentEntry.TaskSteps.Add(parentTasks);

                Assert.Equal(InheritanceLevel.Partial, CheckResult(f.Subject, criteria.Id));

                var entryTasks = new WindowControl(criteria, entry.Id).In(Db);

                var tc1 = TopicControlBuilder.For(entryTasks, "step 1").Build();
                var tc2 = TopicControlBuilder.For(entryTasks, "step 2").Build();
                tc1.IsInherited = true;
                tc2.IsInherited = false;

                entry.TaskSteps.Add(entryTasks);

                var result = f.Subject.GetEntriesWithInheritanceLevel(criteria.Id);

                Assert.Equal(InheritanceLevel.Partial, result.First().InheritanceLevel);
            }
        }

        public class GetInheritanceLevel : FactBase
        {
            [Fact]
            public void ReturnsInheritanceLevel()
            {
                var f = new InheritanceFixture(Db);

                var @event = new EventBuilder().Build();
                var parentCriteria = new CriteriaBuilder().Build();
                var criteria = new CriteriaBuilder().Build();
                new InheritsBuilder(criteria.Id, parentCriteria.Id) {Criteria = criteria, FromCriteria = parentCriteria}.Build().In(Db);
                criteria.ValidEvents = new[] {new ValidEventBuilder().For(criteria, @event).WithParentInheritance().Build()}.In(Db);
                parentCriteria.ValidEvents = new[] {new ValidEventBuilder().For(parentCriteria, @event).Build()}.In(Db);

                var result = f.Subject.GetInheritanceLevel(criteria.Id, @event.Id);

                Assert.Equal(InheritanceLevel.Full, result);
            }
        }

        public class GetParentEntryWithFuzzyMatch : FactBase
        {
            [Fact]
            public void ChecksAllRulesForInheritance()
            {
                var f = new InheritanceFixture(Db);

                var @event = new EventBuilder().Build();
                var parentCriteria = new CriteriaBuilder().Build();
                var criteria = new CriteriaBuilder().Build();
                new InheritsBuilder(criteria.Id, parentCriteria.Id) {Criteria = criteria, FromCriteria = parentCriteria}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder {Criteria = parentCriteria}.Build().In(Db);
                var entry = new DataEntryTaskBuilder {Criteria = criteria, Description = parentEntry.Description, Inherited = 0}.Build().In(Db);
                parentCriteria.DataEntryTasks.Add(parentEntry);
                criteria.DataEntryTasks.Add(entry);

                parentEntry.AvailableEvents.Add(new AvailableEventBuilder {DataEntryTask = parentEntry, Event = @event}.Build());

                Assert.Equal(InheritanceLevel.None, f.Subject.GetEntriesWithInheritanceLevel(criteria.Id).First().InheritanceLevel);

                Assert.True(f.Subject.HasParentEntryWithFuzzyMatch(entry));
                Assert.Equal(parentEntry.Id, f.Subject.GetParentEntryWithFuzzyMatch(entry).Id);
            }
        }

        public class CheckAnyProtectedDescendantsInTreeMethod : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnHasProtectedChildren(bool hasProtected)
            {
                var f = new InheritanceFixture(Db);
                new InheritsBuilder(new CriteriaBuilder {Id = 456, UserDefinedRule = 1}.ForEventsEntriesRule().Build().In(Db),
                                    new CriteriaBuilder {UserDefinedRule = hasProtected ? 0 : 1}.ForEventsEntriesRule().Build().In(Db)).Build().In(Db);

                var r = f.Subject.CheckAnyProtectedDescendantsInTree(456);

                Assert.Equal(hasProtected, r);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnHasProtectedGrandchild(bool hasProtected)
            {
                var f = new InheritanceFixture(Db);
                var parent = new CriteriaBuilder {Id = 456, UserDefinedRule = 1}.ForEventsEntriesRule().Build().In(Db);
                var sibling = new CriteriaBuilder().Build().In(Db);
                var child = new CriteriaBuilder {UserDefinedRule = 1}.ForEventsEntriesRule().Build().In(Db);

                new InheritsBuilder(parent, child).Build().In(Db);
                new InheritsBuilder(parent, sibling).Build().In(Db);
                new InheritsBuilder(child, new CriteriaBuilder {UserDefinedRule = hasProtected ? 0 : 1}.ForEventsEntriesRule().Build()).Build().In(Db);
                new InheritsBuilder(child, new CriteriaBuilder {UserDefinedRule = 1}.ForEventsEntriesRule().Build()).Build().In(Db);

                var r = f.Subject.CheckAnyProtectedDescendantsInTree(456);

                Assert.Equal(hasProtected, r);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnHasProtectedSiblingGrandchild(bool hasProtected)
            {
                var f = new InheritanceFixture(Db);
                var parent = new CriteriaBuilder {Id = 456, UserDefinedRule = 1}.ForEventsEntriesRule().Build().In(Db);
                var child = new CriteriaBuilder {UserDefinedRule = 1}.ForEventsEntriesRule().Build().In(Db);
                var sibling = new CriteriaBuilder().Build().In(Db);

                new InheritsBuilder(parent, child).Build().In(Db);
                new InheritsBuilder(parent, sibling).Build().In(Db);
                new InheritsBuilder(sibling, new CriteriaBuilder {UserDefinedRule = 1}.ForEventsEntriesRule().Build()).Build().In(Db);
                new InheritsBuilder(sibling, new CriteriaBuilder {UserDefinedRule = hasProtected ? 0 : 1}.ForEventsEntriesRule().Build()).Build().In(Db);

                var r = f.Subject.CheckAnyProtectedDescendantsInTree(456);

                Assert.Equal(hasProtected, r);
            }
        }

        internal class InheritanceFixture : IFixture<Inheritance>
        {
            public InheritanceFixture(InMemoryDbContext db)
            {
                Subject = new Inheritance(db);
            }

            public Inheritance Subject { get; set; }
        }
    }
}