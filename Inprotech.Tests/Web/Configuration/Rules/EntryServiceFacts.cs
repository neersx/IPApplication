using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Microsoft.CSharp.RuntimeBinder;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class EntryServiceFacts
    {
        public class GetAdjacentEntriesMethod : FactBase
        {
            [Fact]
            public void GetAdjacentEntryIds()
            {
                var f = new EntryServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(criteria.Id, 1) {Description = "Entry 1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(criteria.Id, 2) {Description = "Entry 2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(criteria.Id, 3) {Description = "Entry 3", DisplaySequence = 3}.In(Db);

                f.Subject.GetAdjacentEntries(criteria.Id, 2, out var prev, out var next);
                Assert.NotNull(prev);
                Assert.NotNull(next);
                Assert.Equal(1, prev.Value);
                Assert.Equal(3, next.Value);
            }

            [Fact]
            public void ReturnsNullForNextIfTopEntry()
            {
                var f = new EntryServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(criteria.Id, 1) {Description = "Entry 1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(criteria.Id, 2) {Description = "Entry 2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(criteria.Id, 3) {Description = "Entry 3", DisplaySequence = 3}.In(Db);

                f.Subject.GetAdjacentEntries(criteria.Id, 3, out var prev, out var next);
                Assert.NotNull(prev);
                Assert.Null(next);
                Assert.Equal(2, prev.Value);
            }

            [Fact]
            public void ReturnsNullForPrevIfTopEntry()
            {
                var f = new EntryServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(criteria.Id, 1) {Description = "Entry 1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(criteria.Id, 2) {Description = "Entry 2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(criteria.Id, 3) {Description = "Entry 3", DisplaySequence = 3}.In(Db);

                f.Subject.GetAdjacentEntries(criteria.Id, 1, out var prev, out var next);
                Assert.Null(prev);
                Assert.NotNull(next);
                Assert.Equal(2, next.Value);
            }

            [Fact]
            public void ReturnsNullIfTargetNotFound()
            {
                var f = new EntryServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(criteria.Id, 1) {Description = "Entry 1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(criteria.Id, 2) {Description = "Entry 2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(criteria.Id, 3) {Description = "Entry 3", DisplaySequence = 3}.In(Db);

                f.Subject.GetAdjacentEntries(criteria.Id, 7, out var prev, out var next);
                Assert.Null(prev);
                Assert.Null(next);
            }
        }

        public class ReorderEntriesMethod : FactBase
        {
            [Fact]
            public void DemoteEntry()
            {
                var f = new EntryServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(criteria.Id, 1) {Description = "Entry 1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(criteria.Id, 2) {Description = "Entry 2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(criteria.Id, 3) {Description = "Entry 3", DisplaySequence = 3}.In(Db);

                f.Subject.ReorderEntries(criteria.Id, 1, 2, false);

                var reorderedEntries = Db.Set<DataEntryTask>()
                                         .OrderBy(_ => _.DisplaySequence)
                                         .ToArray();

                Assert.Equal(2, reorderedEntries[0].Id);
                Assert.Equal(1, reorderedEntries[1].Id);
                Assert.Equal(3, reorderedEntries[2].Id);
            }

            [Fact]
            public void DemoteEntryToBottom()
            {
                var f = new EntryServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(criteria.Id, 1) {Description = "Entry 1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(criteria.Id, 2) {Description = "Entry 2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(criteria.Id, 3) {Description = "Entry 3", DisplaySequence = 3}.In(Db);

                f.Subject.ReorderEntries(criteria.Id, 1, 3, false);

                var reorderedEntries = Db.Set<DataEntryTask>()
                                         .OrderBy(_ => _.DisplaySequence)
                                         .ToArray();

                Assert.Equal(2, reorderedEntries[0].Id);
                Assert.Equal(3, reorderedEntries[1].Id);
                Assert.Equal(1, reorderedEntries[2].Id);
            }

            [Fact]
            public void PromoteEntry()
            {
                var f = new EntryServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(criteria.Id, 1) {Description = "Entry 1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(criteria.Id, 2) {Description = "Entry 2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(criteria.Id, 3) {Description = "Entry 3", DisplaySequence = 3}.In(Db);

                f.Subject.ReorderEntries(criteria.Id, 3, 2, true);

                var reorderedEntries = Db.Set<DataEntryTask>()
                                         .OrderBy(_ => _.DisplaySequence)
                                         .ToArray();

                Assert.Equal(1, reorderedEntries[0].Id);
                Assert.Equal(3, reorderedEntries[1].Id);
                Assert.Equal(2, reorderedEntries[2].Id);
            }

            [Fact]
            public void PromoteEntrytoTop()
            {
                var f = new EntryServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(criteria.Id, 1) {Description = "Entry 1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(criteria.Id, 2) {Description = "Entry 2", DisplaySequence = 2}.In(Db);

                f.Subject.ReorderEntries(criteria.Id, 2, 1, true);

                var reorderedEntries = Db.Set<DataEntryTask>()
                                         .OrderBy(_ => _.DisplaySequence)
                                         .ToArray();

                Assert.Equal(2, reorderedEntries[0].Id);
                Assert.Equal(1, reorderedEntries[1].Id);
            }

            [Fact]
            public void ThrowsExceptionIfSourceNotFound()
            {
                var f = new EntryServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(criteria.Id, 1) {Description = "Entry 1", DisplaySequence = 1}.In(Db);

                Assert.Throws<KeyNotFoundException>(() => f.Subject.ReorderEntries(criteria.Id, 4, 1, false));
            }

            [Fact]
            public void ThrowsExceptionIfTargetNotFound()
            {
                var f = new EntryServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(criteria.Id, 1) {Description = "Entry 1", DisplaySequence = 1}.In(Db);

                Assert.Throws<KeyNotFoundException>(() => f.Subject.ReorderEntries(criteria.Id, 1, 4, false));
            }
        }

        public class ReorderDescendantEntriesMethod : FactBase
        {
            [Fact]
            public void DemoteEntryTargetAbsentUseNextTarget()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(parentCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(parentCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 3}.In(Db);
                new DataEntryTask(parentCriteria.Id, 4) {Description = "Entry4", DisplaySequence = 4}.In(Db);

                var childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(childCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 2}.In(Db);
                new DataEntryTask(childCriteria.Id, 4) {Description = "Entry4", DisplaySequence = 1}.In(Db);

                f.Inheritance.GetDescendantsWithMatchedDescription(parentCriteria.Id, Arg.Any<short>()).Returns(new[] {childCriteria.Id});

                f.Subject.ReorderDescendantEntries(parentCriteria.Id, 1, 3, 2, 4, false);

                var reorderedEntries = Db.Set<DataEntryTask>()
                                         .Where(_ => _.CriteriaId == childCriteria.Id)
                                         .OrderBy(_ => _.DisplaySequence)
                                         .ToArray();

                Assert.Equal(1, reorderedEntries[0].Id);
                Assert.Equal(4, reorderedEntries[1].Id);
            }

            [Fact]
            public void DemoteEntryTargetPresent()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(parentCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(parentCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 3}.In(Db);

                var childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(childCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 2}.In(Db);
                new DataEntryTask(childCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 3}.In(Db);
                new DataEntryTask(childCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 1}.In(Db);

                f.Inheritance.GetDescendantsWithMatchedDescription(parentCriteria.Id, Arg.Any<short>()).Returns(new[] {childCriteria.Id});

                f.Subject.ReorderDescendantEntries(parentCriteria.Id, 1, 2, 1, 3, false);

                var reorderedEntries = Db.Set<DataEntryTask>()
                                         .Where(_ => _.CriteriaId == childCriteria.Id)
                                         .OrderBy(_ => _.DisplaySequence)
                                         .ToArray();

                Assert.Equal(3, reorderedEntries[0].Id);
                Assert.Equal(2, reorderedEntries[1].Id);
                Assert.Equal(1, reorderedEntries[2].Id);
            }

            [Fact]
            public void DemoteEntryToBottomTargetAbsentUsePrevTarget()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(parentCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(parentCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 3}.In(Db);
                new DataEntryTask(parentCriteria.Id, 4) {Description = "Entry4", DisplaySequence = 4}.In(Db);

                var childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(childCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(childCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 2}.In(Db);

                f.Inheritance.GetDescendantsWithMatchedDescription(parentCriteria.Id, Arg.Any<short>()).Returns(new[] {childCriteria.Id});

                f.Subject.ReorderDescendantEntries(parentCriteria.Id, 1, 4, 3, null, false);

                var reorderedEntries = Db.Set<DataEntryTask>()
                                         .Where(_ => _.CriteriaId == childCriteria.Id)
                                         .OrderBy(_ => _.DisplaySequence)
                                         .ToArray();

                Assert.Equal(3, reorderedEntries[0].Id);
                Assert.Equal(1, reorderedEntries[1].Id);
            }

            [Fact]
            public void DoNothingIfTargetNotDetermined()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(parentCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(parentCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 3}.In(Db);

                var childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(childCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(childCriteria.Id, 7) {Description = "Entry7", DisplaySequence = 2}.In(Db);

                f.Inheritance.GetDescendantsWithMatchedDescription(parentCriteria.Id, Arg.Any<short>()).Returns(new[] {childCriteria.Id});

                f.Subject.ReorderDescendantEntries(parentCriteria.Id, 1, 2, 1, 3, false);

                var reorderedEntries = Db.Set<DataEntryTask>()
                                         .Where(_ => _.CriteriaId == childCriteria.Id)
                                         .OrderBy(_ => _.DisplaySequence)
                                         .ToArray();

                Assert.Equal(1, reorderedEntries[0].Id);
                Assert.Equal(7, reorderedEntries[1].Id);
            }

            [Fact]
            public void MultipleDescendantsEntriesAreReordered()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(parentCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(parentCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 3}.In(Db);
                new DataEntryTask(parentCriteria.Id, 4) {Description = "Entry4", DisplaySequence = 4}.In(Db);

                var childCriteria1 = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(childCriteria1.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(childCriteria1.Id, 3) {Description = "Entry3", DisplaySequence = 2}.In(Db);

                var childCriteria2 = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(childCriteria2.Id, 1) {Description = "Entry1", DisplaySequence = 2}.In(Db);
                new DataEntryTask(childCriteria2.Id, 4) {Description = "Entry4", DisplaySequence = 1}.In(Db);

                f.Inheritance.GetDescendantsWithMatchedDescription(parentCriteria.Id, Arg.Any<short>()).Returns(new[] {childCriteria1.Id, childCriteria2.Id});

                f.Subject.ReorderDescendantEntries(parentCriteria.Id, 1, 3, 2, 4, false);

                var reorderedEntries1 = Db.Set<DataEntryTask>()
                                          .Where(_ => _.CriteriaId == childCriteria1.Id)
                                          .OrderBy(_ => _.DisplaySequence)
                                          .ToArray();

                Assert.Equal(3, reorderedEntries1[0].Id);
                Assert.Equal(1, reorderedEntries1[1].Id);

                var reorderedEntries2 = Db.Set<DataEntryTask>()
                                          .Where(_ => _.CriteriaId == childCriteria2.Id)
                                          .OrderBy(_ => _.DisplaySequence)
                                          .ToArray();

                Assert.Equal(1, reorderedEntries2[0].Id);
                Assert.Equal(4, reorderedEntries2[1].Id);
            }

            [Fact]
            public void PromoteEntryTargetAbsentUsePrevTarget()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(parentCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(parentCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 3}.In(Db);

                var childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(childCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 2}.In(Db);
                new DataEntryTask(childCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 1}.In(Db);

                f.Inheritance.GetDescendantsWithMatchedDescription(parentCriteria.Id, Arg.Any<short>()).Returns(new[] {childCriteria.Id});

                f.Subject.ReorderDescendantEntries(parentCriteria.Id, 3, 2, 1, 3, true);

                var reorderedEntries = Db.Set<DataEntryTask>()
                                         .Where(_ => _.CriteriaId == childCriteria.Id)
                                         .OrderBy(_ => _.DisplaySequence)
                                         .ToArray();

                Assert.Equal(1, reorderedEntries[0].Id);
                Assert.Equal(3, reorderedEntries[1].Id);
            }

            [Fact]
            public void PromoteEntryTargetPresent()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(parentCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(parentCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 3}.In(Db);

                var childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(childCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 2}.In(Db);
                new DataEntryTask(childCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 3}.In(Db);
                new DataEntryTask(childCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 1}.In(Db);

                f.Inheritance.GetDescendantsWithMatchedDescription(parentCriteria.Id, Arg.Any<short>()).Returns(new[] {childCriteria.Id});

                f.Subject.ReorderDescendantEntries(parentCriteria.Id, 3, 2, 1, 3, true);

                var reorderedEntries = Db.Set<DataEntryTask>()
                                         .Where(_ => _.CriteriaId == childCriteria.Id)
                                         .OrderBy(_ => _.DisplaySequence)
                                         .ToArray();

                Assert.Equal(1, reorderedEntries[0].Id);
                Assert.Equal(3, reorderedEntries[1].Id);
                Assert.Equal(2, reorderedEntries[2].Id);
            }

            [Fact]
            public void PromoteEntryToTopTargetAbsentUseNextTarget()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db);
                new DataEntryTask(parentCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 2}.In(Db);
                new DataEntryTask(parentCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 3}.In(Db);

                var childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(childCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 1}.In(Db);
                new DataEntryTask(childCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 2}.In(Db);

                f.Inheritance.GetDescendantsWithMatchedDescription(parentCriteria.Id, Arg.Any<short>()).Returns(new[] {childCriteria.Id});

                f.Subject.ReorderDescendantEntries(parentCriteria.Id, 3, 1, null, 2, true);

                var reorderedEntries = Db.Set<DataEntryTask>()
                                         .Where(_ => _.CriteriaId == childCriteria.Id)
                                         .OrderBy(_ => _.DisplaySequence)
                                         .ToArray();

                Assert.Equal(3, reorderedEntries[0].Id);
                Assert.Equal(2, reorderedEntries[1].Id);
            }
        }

        public class ReorderDescendantEntriesMethodConsidersSeparators : FactBase
        {
            readonly Criteria _childCriteria;
            readonly EntryServiceFixture _f;
            readonly Criteria _parentCriteria;

            public ReorderDescendantEntriesMethodConsidersSeparators()
            {
                _f = new EntryServiceFixture(Db);

                _parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                _parentCriteria.DataEntryTasks = new[]
                {
                    new DataEntryTask(_parentCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 1}.In(Db),
                    new DataEntryTask(_parentCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 2}.In(Db),
                    new DataEntryTask(_parentCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 3}.In(Db)
                };

                _childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                _childCriteria.DataEntryTasks = new List<DataEntryTask>
                {
                    new DataEntryTask(_childCriteria.Id, 3) {Description = "Entry3", DisplaySequence = 1}.In(Db),
                    new DataEntryTask(_childCriteria.Id, 1) {Description = "Entry1", DisplaySequence = 2}.In(Db),
                    new DataEntryTask(_childCriteria.Id, 2) {Description = "Entry2", DisplaySequence = 3}.In(Db)
                };

                _f.Inheritance.GetDescendantsWithMatchedDescription(_parentCriteria.Id, Arg.Any<short>()).Returns(new[] {_childCriteria.Id});
            }

            void SetParentSeparatorTestData(int id, string parentDesc)
            {
                var task = _parentCriteria.DataEntryTasks.Single(_ => _.Id == id);
                task.IsSeparator = true;
                task.Description = parentDesc;
                Db.SaveChanges();
            }

            void SetChildSeparatorTestData(int id, string childDesc)
            {
                var task = _childCriteria.DataEntryTasks.Single(_ => _.Id == id);
                task.IsSeparator = true;
                task.Description = childDesc;
                Db.SaveChanges();
            }

            void RemoveFrom(Criteria criteria, int id)
            {
                var task = criteria.DataEntryTasks.Single(_ => _.Id == id);
                criteria.DataEntryTasks.Remove(task);

                Db.Set<DataEntryTask>().Remove(task);
            }

            [Theory]
            [InlineData(1, "Entry1", "Entry 1", false)]
            [InlineData(1, "Entry1", "Entry1", true)]
            [InlineData(2, "Entry2", "Entry 2", false)]
            [InlineData(2, "Entry2", "Entry2", true)]
            public void SourceOrTargetAsSeparator(int sourceId, string parentDesc, string childDesc, bool result)
            {
                SetParentSeparatorTestData(sourceId, parentDesc);
                SetChildSeparatorTestData(sourceId, childDesc);

                _f.Subject.ReorderDescendantEntries(_parentCriteria.Id, 1, 2, 1, 3, false);

                var reorderedEntries = _childCriteria.DataEntryTasks
                                                     .OrderBy(_ => _.DisplaySequence)
                                                     .Select(_ => (int) _.Id)
                                                     .ToArray();

                Assert.Equal(result, reorderedEntries.SequenceEqual(new[] {3, 2, 1}));
            }

            [Theory]
            [InlineData(1, "Entry1", "Entry 1", false)]
            [InlineData(1, "Entry1", "Entry1", true)]
            public void NextTargetAsSeparator(int sourceId, string parentDesc, string childDesc, bool result)
            {
                RemoveFrom(_childCriteria, 3);

                SetParentSeparatorTestData(sourceId, parentDesc);
                SetChildSeparatorTestData(sourceId, childDesc);

                _f.Subject.ReorderDescendantEntries(_parentCriteria.Id, 2, 3, null, 1, true);

                var reorderedEntries = _childCriteria.DataEntryTasks
                                                     .OrderBy(_ => _.DisplaySequence)
                                                     .Select(_ => (int) _.Id)
                                                     .ToArray();

                Assert.Equal(result, reorderedEntries.SequenceEqual(new[] {2, 1}));
            }

            [Theory]
            [InlineData(1, "Entry1", "Entry 1", false)]
            [InlineData(1, "Entry1", "Entry1", true)]
            public void PrevTargetAsSeparator(int sourceId, string parentDesc, string childDesc, bool result)
            {
                RemoveFrom(_childCriteria, 2);

                SetParentSeparatorTestData(sourceId, parentDesc);
                SetChildSeparatorTestData(sourceId, childDesc);

                _f.Subject.ReorderDescendantEntries(_parentCriteria.Id, 3, 2, 1, null, false);

                var reorderedEntries = _childCriteria.DataEntryTasks
                                                     .OrderBy(_ => _.DisplaySequence)
                                                     .Select(_ => (int) _.Id)
                                                     .ToArray();

                Assert.Equal(result, reorderedEntries.SequenceEqual(new[] {1, 3}));
            }
        }

        public class AddEntryMethod : FactBase
        {
            [Fact]
            public void ShouldApplyInheritance()
            {
                var entryDescription = "entry Test";
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                parentCriteria.DataEntryTasks.Add(
                                                  new DataEntryTask(parentCriteria.Id, 34)
                                                  {
                                                      Description = Fixture.String(),
                                                      DisplaySequence = 1
                                                  }.In(Db));
                parentCriteria.DataEntryTasks.Add(
                                                  new DataEntryTask(parentCriteria.Id, 35)
                                                  {
                                                      Description = Fixture.String(),
                                                      DisplaySequence = 2
                                                  }.In(Db));

                var childCriteria = new CriteriaBuilder
                    {
                        ParentCriteriaId = parentCriteria.Id
                    }.ForEventsEntriesRule()
                     .Build()
                     .In(Db);

                childCriteria.DataEntryTasks.Add(
                                                 new DataEntryTask(childCriteria.Id, 34)
                                                 {
                                                     Description = parentCriteria.DataEntryTasks.First().Description,
                                                     DisplaySequence = 1
                                                 }.In(Db));
                childCriteria.DataEntryTasks.Add(
                                                 new DataEntryTask(childCriteria.Id, 35)
                                                 {
                                                     Description = Fixture.String(),
                                                     DisplaySequence = 2
                                                 }.In(Db));

                var f = new EntryServiceFixture(Db).WithDescriptionValidityAs();
                f.Inheritance.GetDescendantsWithoutEntry(Arg.Any<int>(), Arg.Any<string>()).ReturnsForAnyArgs(new[] {(childCriteria, parentCriteria.Id)});

                var r = f.Subject.AddEntry(parentCriteria.Id, entryDescription, 34, true);

                var newEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == parentCriteria.Id && _.Description == entryDescription);
                var movedEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == parentCriteria.Id && _.Id == 35);

                Assert.Equal(newEntry.Id, r.Id);
                Assert.Equal(newEntry.DisplaySequence, r.DisplaySequence);
                Assert.Throws<RuntimeBinderException>(() => r.Error);
                Assert.Equal(2, newEntry.DisplaySequence);
                Assert.Equal(2, r.DisplaySequence);
                Assert.Equal(3, movedEntry.DisplaySequence);

                var newChildEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == childCriteria.Id && _.Description == entryDescription);
                var movedChildEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == childCriteria.Id && _.Id == 35);

                Assert.Equal(36, newChildEntry.Id);
                Assert.Equal(2, newChildEntry.DisplaySequence);
                Assert.Equal(parentCriteria.Id, newChildEntry.ParentCriteriaId);
                Assert.Equal(newEntry.Id, newChildEntry.Id);
                Assert.Throws<RuntimeBinderException>(() => r.Error);
                Assert.Equal(3, movedChildEntry.DisplaySequence);
            }

            [Fact]
            public void ShouldNotReturnErrorIfDuplicateNotUnderSameCriteria()
            {
                var entryDescription = "entry Test";
                var criteria1 = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var criteria2 = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                new DataEntryTask(criteria1.Id, 34)
                {
                    Description = entryDescription
                }.In(Db);

                var f = new EntryServiceFixture(Db);

                f.Subject.AddEntry(criteria2.Id, entryDescription, null, false);
            }

            [Fact]
            public void ShouldReturnErrorIfDuplicateEntry()
            {
                var entryDescription = "entry Test";
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                criteria.DataEntryTasks.Add(
                                            new DataEntryTask(criteria.Id, 34)
                                            {
                                                Description = entryDescription
                                            }.In(Db));

                var f = new EntryServiceFixture(Db);

                var r = f.Subject.AddEntry(criteria.Id, entryDescription, null, false);

                Assert.Equal("entryDescription", r.Error.Field);
                Assert.Equal("notunique", r.Error.Message);
            }

            [Fact]
            public void ShouldReturnNewEntry()
            {
                var entryDescription = "entry Test";
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var f = new EntryServiceFixture(Db).WithDescriptionValidityAs();

                var r = f.Subject.AddEntry(criteria.Id, entryDescription, null, false);

                var newEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == criteria.Id && _.Description == entryDescription);

                Assert.Equal(newEntry.Id, r.Id);
                Assert.Equal(newEntry.DisplaySequence, r.DisplaySequence);
            }

            [Fact]
            public void ShouldReturnNewEntryWithCorrectDisplayOrder()
            {
                var entryDescription = "entry Test";
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                criteria.DataEntryTasks.Add(
                                            new DataEntryTask(criteria.Id, 34)
                                            {
                                                Description = Fixture.String(),
                                                DisplaySequence = 1
                                            }.In(Db));

                criteria.DataEntryTasks.Add(
                                            new DataEntryTask(criteria.Id, 35)
                                            {
                                                Description = Fixture.String(),
                                                DisplaySequence = 2
                                            }.In(Db));

                var f = new EntryServiceFixture(Db).WithDescriptionValidityAs();

                var r = f.Subject.AddEntry(criteria.Id, entryDescription, 34, false);

                var newEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == criteria.Id && _.Description == entryDescription);
                var movedEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == criteria.Id && _.Id == 35);

                Assert.Equal(newEntry.Id, r.Id);
                Assert.Equal(newEntry.DisplaySequence, r.DisplaySequence);
                Assert.Throws<RuntimeBinderException>(() => r.Error);
                Assert.Equal(2, newEntry.DisplaySequence);
                Assert.Equal(2, r.DisplaySequence);
                Assert.Equal(3, movedEntry.DisplaySequence);
            }

            [Fact]
            public void ShouldSetTheEntryAsASeparator()
            {
                var entryDescription = "entry Test";
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var f = new EntryServiceFixture(Db).WithDescriptionValidityAs();

                var r = f.Subject.AddEntry(criteria.Id, entryDescription, null, false, true);

                var newEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == criteria.Id && _.Description == entryDescription);

                Assert.Equal(newEntry.Id, r.Id);
                Assert.Equal(newEntry.DisplaySequence, r.DisplaySequence);
                Assert.True(r.IsSeparator);
            }
        }

        public class AddEventsEntryMethod : FactBase
        {
            [Theory]
            [InlineData(34)]
            [InlineData(24)]
            public void ShouldApplyInheritance(int parentEventId)
            {
                var entryDescription = "entry Test";
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var @event = new Event(parentEventId).In(Db);

                var entry1 = new DataEntryTaskBuilder(parentCriteria, 1) {Description = Fixture.String(), DisplaySequence = 1}.Build().In(Db);
                var entry2 = new DataEntryTaskBuilder(parentCriteria, 2) {Description = Fixture.String(), DisplaySequence = 2}.Build().In(Db);
                var entry3 = new DataEntryTaskBuilder(parentCriteria, 3) {Description = Fixture.String(), DisplaySequence = 3}.Build().In(Db);

                parentCriteria.DataEntryTasks = new List<DataEntryTask> {entry1, entry2, entry3};

                parentCriteria.ValidEvents.Add(new ValidEvent(parentCriteria, @event) {Event = @event});

                var childCriteria = new CriteriaBuilder {ParentCriteriaId = parentCriteria.Id}.ForEventsEntriesRule().Build().In(Db);

                var childEntry1 = new DataEntryTaskBuilder(childCriteria, 3) {Description = entry1.Description, DisplaySequence = 1}.WithParentInheritance(entry1.Id).Build().In(Db);
                var childEntry2 = new DataEntryTaskBuilder(childCriteria, 4) {Description = entry1.Description, DisplaySequence = 2}.WithParentInheritance(entry2.Id).Build().In(Db);

                childCriteria.DataEntryTasks = new List<DataEntryTask> {childEntry1, childEntry2};

                var f = new EntryServiceFixture(Db).WithDescriptionValidityAs();
                f.Inheritance.GetDescendantsWithoutEntry(Arg.Any<int>(), Arg.Any<string>()).ReturnsForAnyArgs(new[] {(childCriteria, parentCriteria.Id)});

                var r = f.Subject.AddEntryWithEvents(parentCriteria.Id, entryDescription, new[] {parentEventId}, true);

                var newEntry = f.DbContext.Set<DataEntryTask>()
                                .Include(_ => _.AvailableEvents)
                                .Single(_ => _.CriteriaId == parentCriteria.Id && _.Description == entryDescription);
                var unMovedEntry = f.DbContext.Set<DataEntryTask>()
                                    .Single(_ => _.CriteriaId == parentCriteria.Id && _.Id == 3);

                Assert.Equal(newEntry.Id, r.Id);
                Assert.Equal(newEntry.DisplaySequence, r.DisplaySequence);
                Assert.Throws<RuntimeBinderException>(() => r.Error);
                Assert.Equal(4, newEntry.DisplaySequence);
                Assert.Equal(4, r.DisplaySequence);
                Assert.Equal(3, unMovedEntry.DisplaySequence);
                Assert.Single(newEntry.AvailableEvents);
                Assert.Equal(newEntry.AvailableEvents.Single().EventId, parentEventId);

                var newChildEntry = f.DbContext.Set<DataEntryTask>()
                                     .Include(_ => _.AvailableEvents)
                                     .Single(_ => _.CriteriaId == childCriteria.Id && _.Description == entryDescription);
                var unMovedChildEntry = f.DbContext.Set<DataEntryTask>()
                                         .Single(_ => _.CriteriaId == childCriteria.Id && _.Id == 4);

                Assert.Equal(newChildEntry.Id, childCriteria.DataEntryTasks.Last().Id + 1);
                Assert.Equal(3, newChildEntry.DisplaySequence);
                Assert.Throws<RuntimeBinderException>(() => r.Error);
                Assert.Equal(2, unMovedChildEntry.DisplaySequence);
                Assert.Single(newChildEntry.AvailableEvents);
                Assert.Equal(newChildEntry.AvailableEvents.Single().EventId, parentEventId);
            }

            [Fact]
            public void ShouldNotReturnErrorIfDuplicateNotUnderSameCriteria()
            {
                var entryDescription = "entry Test";
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var @event = new Event(2).In(Db);

                new DataEntryTask(criteria, 34)
                {
                    Description = entryDescription
                }.In(Db);

                var f = new EntryServiceFixture(Db).WithDescriptionValidityAs();
                f.Subject.AddEntryWithEvents(criteria.Id, entryDescription, new[] {@event.Id}, false);
            }

            [Fact]
            public void ShouldReturnEntryWithEventsInCorrectOrder()
            {
                var entryDescription = "entry Test";

                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var event1 = new Event(Fixture.Integer()).In(Db);

                var event2 = new Event(Fixture.Integer()).In(Db);

                criteria.DataEntryTasks.Add(
                                            new DataEntryTask(criteria.Id, 34)
                                            {
                                                Description = Fixture.String(),
                                                DisplaySequence = 1
                                            }.In(Db));

                criteria.DataEntryTasks.Add(
                                            new DataEntryTask(criteria.Id, 35)
                                            {
                                                Description = Fixture.String(),
                                                DisplaySequence = 2
                                            }.In(Db));

                criteria.ValidEvents.Add(new ValidEvent(criteria, event1)
                {
                    Event = event1,
                    DisplaySequence = 2
                });

                criteria.ValidEvents.Add(new ValidEvent(criteria, event2)
                {
                    Event = event2,
                    DisplaySequence = 1
                });

                var f = new EntryServiceFixture(Db).WithDescriptionValidityAs();
                f.Subject.AddEntryWithEvents(criteria.Id, entryDescription, new[] {event1.Id, event2.Id}, false);
                var newEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == criteria.Id && _.Description == entryDescription);
                Assert.Equal(event2.Id, newEntry.AvailableEvents.First().EventId);

                Assert.Equal(event1.Id, newEntry.AvailableEvents.Last().EventId);
            }

            [Fact]
            public void ShouldReturnErrorIfDuplicateEntry()
            {
                var entryDescription = "entry Test";
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                criteria.DataEntryTasks.Add(
                                            new DataEntryTask(criteria.Id, 34)
                                            {
                                                Description = entryDescription
                                            }.In(Db));

                var f = new EntryServiceFixture(Db);
                var r = f.Subject.AddEntryWithEvents(criteria.Id, entryDescription, new[] {1}, false);
                Assert.Equal("entryDescription", r.Error.Field);
                Assert.Equal("notunique", r.Error.Message);
            }

            [Fact]
            public void ShouldReturnNewEntry()
            {
                var entryDescription = "entry Test";
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var @event = new Event(2).In(Db);

                var f = new EntryServiceFixture(Db).WithDescriptionValidityAs();
                var r = f.Subject.AddEntryWithEvents(criteria.Id, entryDescription, new[] {@event.Id}, false);

                var newEntry = f.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == criteria.Id && _.Description == entryDescription);
                Assert.Equal(newEntry.Id, r.Id);
                Assert.Equal(newEntry.DisplaySequence, r.DisplaySequence);
                Assert.Throws<RuntimeBinderException>(() => r.Error);
            }
        }

        public class DeleteEntriesMethod : FactBase
        {
            [Fact]
            public void DeletesEntriesFromChildIfDeleteAppliedToDescendents()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria.Id, 1) {Description = "Entry1"}.In(Db);
                var parentEntry2 = new DataEntryTask(parentCriteria.Id, 2) {Description = "Entry2"}.In(Db);
                var parentEntry3 = new DataEntryTask(parentCriteria.Id, 3) {Description = "Entry3"}.In(Db);

                var childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTaskBuilder(childCriteria, 11) {Description = "Entry1"}.Build().In(Db);
                new DataEntryTaskBuilder(childCriteria, 22) {Description = "Entry2", ParentCriteriaId = parentCriteria.Id}.WithParentInheritance(parentEntry2.Id).Build().In(Db);
                var entry3 = new DataEntryTaskBuilder(childCriteria, 33) {Description = "Entry2", ParentCriteriaId = parentCriteria.Id}.WithParentInheritance(parentEntry3.Id).Build().In(Db);
                entry3.DocumentRequirements.Add(new DocumentRequirement {Inherited = 1}.In(Db));

                f.Inheritance.GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(parentCriteria.Id, Arg.Any<short[]>(), Arg.Any<bool>())
                 .Returns(new[] {new CriteriaEntryIds(childCriteria.Id, 33)});

                f.Subject.DeleteEntries(parentCriteria.Id, new short[] {1, 3}, true);

                var parentEntries = Db.Set<DataEntryTask>()
                                      .Where(_ => _.CriteriaId == parentCriteria.Id)
                                      .OrderBy(_ => _.Id)
                                      .Select(_ => _.Id)
                                      .ToArray();

                var childEntries = Db.Set<DataEntryTask>()
                                     .Where(_ => _.CriteriaId == childCriteria.Id)
                                     .OrderBy(_ => _.Id)
                                     .Select(_ => _.Id)
                                     .ToArray();
                var documentRequirement = Db.Set<DocumentRequirement>()
                                            .Where(_ => _.CriteriaId == childCriteria.Id && _.DataEntryTaskId == entry3.Inherited.Value);

                Assert.Equal(new short[] {2}, parentEntries);
                Assert.Equal(new short[] {11, 22}, childEntries);
                Assert.Empty(documentRequirement);
            }

            [Fact]
            public void DeletesEntryFromParent()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria.Id, 1) {Description = "Entry1"}.In(Db);
                new DataEntryTask(parentCriteria.Id, 2) {Description = "Entry2"}.In(Db);
                new DataEntryTask(parentCriteria.Id, 3) {Description = "Entry3"}.In(Db);

                f.Inheritance.GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(parentCriteria.Id, Arg.Any<short[]>(), Arg.Any<bool>())
                 .Returns(new CriteriaEntryIds[] { });
                f.Subject.DeleteEntries(parentCriteria.Id, new short[] {1, 3}, true);

                var parentEntries = Db.Set<DataEntryTask>()
                                      .Where(_ => _.CriteriaId == parentCriteria.Id)
                                      .OrderBy(_ => _.Id)
                                      .Select(_ => _.Id)
                                      .ToArray();

                Assert.Equal(new short[] {2}, parentEntries);
            }

            [Fact]
            public void IgnoreDeletesForEntriesWhichCouldNotBeDeterminedInChild()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria.Id, 1) {Description = "Entry1"}.In(Db);
                new DataEntryTask(parentCriteria.Id, 2) {Description = "Entry2"}.In(Db);
                new DataEntryTask(parentCriteria.Id, 3) {Description = "Entry3"}.In(Db);

                var childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(childCriteria.Id, 11) {Description = "Entry1", Inherited = 1}.In(Db);
                new DataEntryTask(childCriteria.Id, 22) {Description = "Entry1", Inherited = 1}.In(Db);
                new DataEntryTask(childCriteria.Id, 33) {Description = "Entry3", Inherited = 1}.In(Db);

                f.Inheritance.GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(parentCriteria.Id, Arg.Any<short[]>(), Arg.Any<bool>())
                 .Returns(new[] {new CriteriaEntryIds(childCriteria.Id, 33)});
                f.Subject.DeleteEntries(parentCriteria.Id, new short[] {1, 3}, true);

                var parentEntries = Db.Set<DataEntryTask>()
                                      .Where(_ => _.CriteriaId == parentCriteria.Id)
                                      .OrderBy(_ => _.Id)
                                      .Select(_ => _.Id)
                                      .ToArray();

                var childEntries = Db.Set<DataEntryTask>()
                                     .Where(_ => _.CriteriaId == childCriteria.Id)
                                     .OrderBy(_ => _.Id)
                                     .Select(_ => _.Id)
                                     .ToArray();

                Assert.Equal(new short[] {2}, parentEntries);
                Assert.Equal(new short[] {11, 22}, childEntries);
            }

            [Fact]
            public void RemovesInheritanceFromChidIfDeleteNotAppliedToChildren()
            {
                var f = new EntryServiceFixture(Db);
                var parentCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(parentCriteria, 1) {Description = "Entry1"}.In(Db);
                new DataEntryTask(parentCriteria, 2) {Description = "Entry2"}.In(Db);
                new DataEntryTask(parentCriteria, 3) {Description = "Entry3"}.In(Db);

                var childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new DataEntryTask(childCriteria, 11) {Description = "Entry1", Inherited = 1}.In(Db);
                var entry22 = new DataEntryTask(childCriteria, 22) {Description = "Entry2", Inherited = 1}.In(Db);
                entry22.AvailableEvents.Add(new AvailableEvent(entry22, new Event(1).In(Db)) {Inherited = 1}.In(Db));
                var entry33 = new DataEntryTask(childCriteria, 33) {Description = "Entry3", Inherited = 1}.In(Db);
                entry33.DocumentRequirements.Add(new DocumentRequirement {Inherited = 1}.In(Db));

                var grandChildCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var entry222 = new DataEntryTask(grandChildCriteria, 222) {Description = "Entry2", Inherited = 1}.In(Db);
                entry222.AvailableEvents.Add(new AvailableEvent(entry222, new Event(1).In(Db)) {Inherited = 1}.In(Db));
                entry222.GroupsAllowed.Add(new GroupControl(entry222, string.Empty) {Inherited = 1}.In(Db));
                entry222.UsersAllowed.Add(new UserControl("User", entry222.CriteriaId, entry222.Id) {Inherited = 1}.In(Db));
                entry222.TaskSteps.Add(new WindowControl(entry222.CriteriaId, entry222.Id)
                {
                    IsInherited = true
                }.In(Db));

                f.Inheritance.GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(parentCriteria.Id, Arg.Any<short[]>(), Arg.Any<bool>())
                 .Returns(new[]
                 {
                     new CriteriaEntryIds(childCriteria.Id, entry22.Id),
                     new CriteriaEntryIds(childCriteria.Id, entry33.Id),
                     new CriteriaEntryIds(grandChildCriteria.Id, entry222.Id)
                 });

                f.Subject.DeleteEntries(parentCriteria.Id, new short[] {2, 3}, false);

                var parentEntries = Db.Set<DataEntryTask>()
                                      .Where(_ => _.CriteriaId == parentCriteria.Id)
                                      .OrderBy(_ => _.Id)
                                      .Select(_ => _.Id)
                                      .ToArray();
                Assert.Equal(new short[] {1}, parentEntries);

                var childEntries = Db.Set<DataEntryTask>()
                                     .Include(_ => _.AvailableEvents)
                                     .Include(_ => _.DocumentRequirements)
                                     .Where(_ => _.CriteriaId == childCriteria.Id)
                                     .OrderBy(_ => _.Id)
                                     .ToArray();

                Assert.Equal(11, childEntries[0].Id);
                Assert.True(childEntries[0].IsInherited);

                Assert.Equal(22, childEntries[1].Id);
                Assert.True(childEntries[1].AvailableEvents.All(_ => !_.IsInherited));
                Assert.True(childEntries[1].DocumentRequirements.All(_ => !_.IsInherited));

                Assert.Equal(33, childEntries[2].Id);
                Assert.True(childEntries[2].AvailableEvents.All(_ => !_.IsInherited));
                Assert.True(childEntries[2].DocumentRequirements.All(_ => !_.IsInherited));

                var grandChildEntries = Db.Set<DataEntryTask>()
                                          .Where(_ => _.CriteriaId == grandChildCriteria.Id)
                                          .OrderBy(_ => _.Id)
                                          .ToArray();

                Assert.Equal(222, grandChildEntries[0].Id);
                Assert.False(grandChildEntries[0].IsInherited);
                Assert.True(grandChildEntries[0].AvailableEvents.All(_ => !_.IsInherited));
                Assert.True(grandChildEntries[0].UsersAllowed.All(_ => !_.IsInherited));
                Assert.True(grandChildEntries[0].GroupsAllowed.All(_ => !_.IsInherited));
                Assert.True(grandChildEntries[0].WorkflowWizard.TopicControls.All(_ => !_.IsInherited));
            }
        }
    }

    public class EntryServiceFixture : IFixture<EntryService>
    {
        public EntryServiceFixture(InMemoryDbContext db)
        {
            DbContext = db;
            Inheritance = Substitute.For<IInheritance>();
            DescriptionValidator = Substitute.For<IDescriptionValidator>();
            Subject = new EntryService(DbContext, Inheritance, DescriptionValidator);
        }

        public IDbContext DbContext { get; }
        public IInheritance Inheritance { get; }

        public IDescriptionValidator DescriptionValidator { get; }

        public EntryService Subject { get; }

        public EntryServiceFixture WithDescriptionValidityAs(bool validity = true)
        {
            DescriptionValidator.IsDescriptionUniqueIn(Arg.Any<DataEntryTask[]>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(validity);

            return this;
        }
    }
}