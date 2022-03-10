using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Documents;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;
using static Inprotech.Web.Configuration.Rules.Workflow.WorkflowEntryInheritanceService;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEntryInheritanceServiceFacts
    {
        public class InheritNewEntriesMethod : FactBase
        {
            [Theory]
            [InlineData("Aaa##", "aaA$$", true)]
            [InlineData("Aaa##", "aaAb$$", false)]
            public void ThrowExceptionIfDuplicateEntryInChild(string desc1, string desc2, bool result)
            {
                var criteria = new CriteriaBuilder().Build();
                criteria.DataEntryTasks = new[]
                {
                    new DataEntryTask {Description = desc1},
                    new DataEntryTask {Description = desc2},
                    new DataEntryTask {Description = "bbb"}
                };

                var f = new WorkflowEntryInheritanceServiceFixture(Db);

                if (result)
                {
                    Assert.Throws<DuplicateEntryDescriptionException>(() => f.Subject.InheritNewEntries(criteria, new DataEntryTask[0], true));
                }
                else
                {
                    var exception = Record.Exception(() => f.Subject.InheritNewEntries(criteria, new DataEntryTask[0], true));
                    Assert.Null(exception);
                }
            }

            [Theory]
            [InlineData("Aaa##", "aaA$$", false)]
            [InlineData("Aaa##", "Aaa##", true)]
            public void ThrowExceptionIfDuplicateSeparatorEntryInChild(string desc1, string desc2, bool result)
            {
                var criteria = new CriteriaBuilder().Build();
                criteria.DataEntryTasks = new[]
                {
                    new DataEntryTask {Description = desc1, IsSeparator = true},
                    new DataEntryTask {Description = desc2, IsSeparator = true},
                    new DataEntryTask {Description = "bbb"}
                };

                var f = new WorkflowEntryInheritanceServiceFixture(Db);

                if (result)
                {
                    Assert.Throws<DuplicateEntryDescriptionException>(() => f.Subject.InheritNewEntries(criteria, new DataEntryTask[0], true));
                }
                else
                {
                    var exception = Record.Exception(() => f.Subject.InheritNewEntries(criteria, new DataEntryTask[0], true));
                    Assert.Null(exception);
                }
            }

            [Theory]
            [InlineData("Aaa##", "aaA$$", true)]
            [InlineData("Aaa##", "Aaa##b", false)]
            public void ThrowExceptionIfDuplicateEntryInParent(string desc1, string desc2, bool result)
            {
                var criteria = new CriteriaBuilder().Build();
                var parentCriteriaEntries = new[]
                {
                    new DataEntryTask {Description = desc1},
                    new DataEntryTask {Description = desc2},
                    new DataEntryTask {Description = "bbb"}
                };

                var f = new WorkflowEntryInheritanceServiceFixture(Db);

                if (result)
                {
                    Assert.Throws<DuplicateEntryDescriptionException>(() => f.Subject.InheritNewEntries(criteria, parentCriteriaEntries, true));
                }
                else
                {
                    var exception = Record.Exception(() => f.Subject.InheritNewEntries(criteria, parentCriteriaEntries, true));
                    Assert.Null(exception);
                }
            }

            [Theory]
            [InlineData("Aaa##", "aaA$$", false)]
            [InlineData("Aaa##", "Aaa##", true)]
            public void ThrowExceptionIfDuplicateSeparatorEntryInParent(string desc1, string desc2, bool result)
            {
                var criteria = new CriteriaBuilder().Build();
                var parentCriteriaEntries = new[]
                {
                    new DataEntryTask {Description = desc1, IsSeparator = true},
                    new DataEntryTask {Description = desc2, IsSeparator = true},
                    new DataEntryTask {Description = "bbb"}
                };

                var f = new WorkflowEntryInheritanceServiceFixture(Db);

                if (result)
                {
                    Assert.Throws<DuplicateEntryDescriptionException>(() => f.Subject.InheritNewEntries(criteria, parentCriteriaEntries, true));
                }
                else
                {
                    var exception = Record.Exception(() => f.Subject.InheritNewEntries(criteria, parentCriteriaEntries, true));
                    Assert.Null(exception);
                }
            }

            [Fact]
            public void AddsMatchingEntriesToCriteriaWhenReplace()
            {
                var c = new CriteriaBuilder().Build();
                var replacedEntry = DataEntryTaskBuilder.ForCriteria(c).Build().In(Db).WithStep(Db, Fixture.String());
                replacedEntry.Description = Fixture.String("Replace");
                c.DataEntryTasks = new[] {replacedEntry};

                var parentDataEntryTaskBuilder = new DataEntryTaskBuilder();

                var parentTasks = new[] {parentDataEntryTaskBuilder.Build().In(Db), parentDataEntryTaskBuilder.Build().In(Db)};

                var f = new WorkflowEntryInheritanceServiceFixture(Db);
                var subject = Substitute.ForPartsOf<WorkflowEntryInheritanceService>(f.DbContext);

                var returnMatches = new[] {new EntryMatch(parentTasks[0], c.DataEntryTasks.First()), new EntryMatch(parentTasks[1], null)};
                subject.SplitMatchingAndNonMatching(Arg.Any<DataEntryTask[]>(), Arg.Any<DataEntryTask[]>())
                       .ReturnsForAnyArgs(returnMatches);

                var fakeEntry = new DataEntryTaskBuilder {Description = Fixture.String("Task1")}.Build();
                subject.InheritDataEntryTask(Arg.Any<Criteria>(), Arg.Any<DataEntryTask>(), Arg.Any<short>(), 1)
                       .Returns(fakeEntry);

                var result = subject.InheritNewEntries(c, parentTasks, true);
                Db.SaveChanges();

                Assert.Empty(f.DbContext.Set<DataEntryTask>().Where(_ => _.CriteriaId == c.Id && _.Id == replacedEntry.Id && _.Description == replacedEntry.Description));
                Assert.Empty(f.DbContext.Set<WindowControl>().Where(_ => _.CriteriaId == c.Id && _.EntryNumber == replacedEntry.Id));

                Assert.Equal(parentTasks.Length, result.Count());
                subject.Received(1).SplitMatchingAndNonMatching(Arg.Is<DataEntryTask[]>(_ => _.SequenceEqual(c.DataEntryTasks)), parentTasks);
            }

            [Fact]
            public void AddsNewEntriesAtTheEndInParentDisplaySequenceOrder()
            {
                var c = new CriteriaBuilder().Build();
                var existingDisplaySequence = Fixture.Short();
                var existingEntryId = Fixture.Short();
                c.DataEntryTasks = new[] {new DataEntryTaskBuilder {EntryNumber = existingEntryId, DisplaySequence = existingDisplaySequence}.Build().In(Db)};

                var parentTasks = new[] {new DataEntryTaskBuilder {DisplaySequence = 9}.Build().In(Db), new DataEntryTaskBuilder {DisplaySequence = 1}.Build().In(Db), new DataEntryTaskBuilder {DisplaySequence = 5}.Build().In(Db)};

                var f = new WorkflowEntryInheritanceServiceFixture(Db);
                var subject = Substitute.ForPartsOf<WorkflowEntryInheritanceService>(f.DbContext);

                var returnMatches = new[] {new EntryMatch(parentTasks[0], null), new EntryMatch(parentTasks[1], null), new EntryMatch(parentTasks[2], null)};
                subject.SplitMatchingAndNonMatching(Arg.Any<DataEntryTask[]>(), Arg.Any<DataEntryTask[]>()).ReturnsForAnyArgs(returnMatches);

                subject.InheritNewEntries(c, parentTasks, false);

                subject.Received(1).InheritDataEntryTask(c, parentTasks[1], (short) (existingEntryId + 1), (short) (existingDisplaySequence + 1));
                subject.Received(1).InheritDataEntryTask(c, parentTasks[2], (short) (existingEntryId + 2), (short) (existingDisplaySequence + 2));
                subject.Received(1).InheritDataEntryTask(c, parentTasks[0], (short) (existingEntryId + 3), (short) (existingDisplaySequence + 3));
            }

            [Fact]
            public void AddsNonMatchingEntriesToCriteriaInTheSamePosition()
            {
                var c = new CriteriaBuilder().Build();
                var existingDisplaySeq = Fixture.Short();
                var existingEntryNumber = Fixture.Short();
                c.DataEntryTasks = new[] {new DataEntryTaskBuilder {EntryNumber = existingEntryNumber, DisplaySequence = existingDisplaySeq}.Build().In(Db)};

                var parentTasks = new[]
                {
                    new DataEntryTaskBuilder {DisplaySequence = 1}.Build().In(Db),
                    new DataEntryTaskBuilder {DisplaySequence = 2}.Build().In(Db), new DataEntryTaskBuilder {Description = "DoNotAdd"}.Build().In(Db)
                };

                var f = new WorkflowEntryInheritanceServiceFixture(Db);
                var subject = Substitute.ForPartsOf<WorkflowEntryInheritanceService>(f.DbContext);

                var returnMatches = new[] {new EntryMatch(parentTasks[0], null), new EntryMatch(parentTasks[1], c.DataEntryTasks.First())};
                subject.SplitMatchingAndNonMatching(Arg.Any<DataEntryTask[]>(), Arg.Any<DataEntryTask[]>())
                       .ReturnsForAnyArgs(returnMatches);

                var entryToAdd = new DataEntryTaskBuilder {EntryNumber = Fixture.Short(), Description = Fixture.String("Task1")}.Build();
                subject.InheritDataEntryTask(Arg.Any<Criteria>(), parentTasks[0], Arg.Any<short>(), Arg.Any<short>())
                       .Returns(entryToAdd);

                subject.InheritNewEntries(c, parentTasks, false);

                subject.Received(1).InheritDataEntryTask(c, parentTasks[0], (short) (existingEntryNumber + 1), (short) (existingDisplaySeq + 1));
                Assert.NotNull(f.DbContext.Set<DataEntryTask>().SingleOrDefault(_ => _.CriteriaId == entryToAdd.CriteriaId && _.Id == entryToAdd.Id && _.Description == entryToAdd.Description));

                subject.DidNotReceive().InheritDataEntryTask(c, parentTasks[1], Arg.Any<short>(), Arg.Any<short>());
                subject.Received(1).SplitMatchingAndNonMatching(Arg.Is<DataEntryTask[]>(_ => _.SequenceEqual(c.DataEntryTasks)), parentTasks);
            }

            [Fact]
            public void ReplacesExistingEntriesForSameDisplaySequence()
            {
                var c = new CriteriaBuilder().Build();
                var existingDisplaySequence = Fixture.Short();
                var existingEntryNumber = Fixture.Short();
                c.DataEntryTasks = new[] {new DataEntryTaskBuilder {EntryNumber = existingEntryNumber, DisplaySequence = existingDisplaySequence}.Build().In(Db)};

                var parentTasks = new[] {new DataEntryTaskBuilder {DisplaySequence = 1}.Build().In(Db)};

                var f = new WorkflowEntryInheritanceServiceFixture(Db);
                var subject = Substitute.ForPartsOf<WorkflowEntryInheritanceService>(f.DbContext);

                var returnMatches = new[] {new EntryMatch(parentTasks[0], c.DataEntryTasks.First())};
                subject.SplitMatchingAndNonMatching(Arg.Any<DataEntryTask[]>(), Arg.Any<DataEntryTask[]>()).ReturnsForAnyArgs(returnMatches);

                subject.InheritNewEntries(c, parentTasks, true);

                subject.Received(1).InheritDataEntryTask(c, parentTasks[0], existingEntryNumber, existingDisplaySequence);
            }

            [Fact]
            public void InheritDataEntryTaskCopiesRequiredRcordsToChildCriteria()
            {
                var c = new CriteriaBuilder().Build();
                var existingDisplaySequence = Fixture.Short();
                var existingEntryNumber = Fixture.Short();
                c.DataEntryTasks = new[] {new DataEntryTaskBuilder {EntryNumber = existingEntryNumber, DisplaySequence = existingDisplaySequence}.Build().In(Db)};

                var parentTask = new DataEntryTaskBuilder {DisplaySequence = 1}.Build().In(Db);
                parentTask.AvailableEvents.Add(new AvailableEvent{EventId = 1, CriteriaId = c.Id, Event = new Event{Id = 1}.In(Db)}.In(Db));
                parentTask.DocumentRequirements.Add(new DocumentRequirement(c, c.DataEntryTasks.First(), new Document().In(Db)).In(Db));
                parentTask.GroupsAllowed.Add(new GroupControl(c.DataEntryTasks.First(), "SecurityGroup").In(Db));
                parentTask.UsersAllowed.Add(new UserControl{UserId = "A", CriteriaNo = c.Id, DataEntryTaskId = existingEntryNumber}.In(Db));
                parentTask.RolesAllowed.Add(new RolesControl{RoleId = 1, CriteriaId = c.Id, DataEntryTaskId = existingEntryNumber}.In(Db));

                var f = new WorkflowEntryInheritanceServiceFixture(Db);
                var newEntry = f.Subject.InheritDataEntryTask(c, parentTask, 1, 1);

                Assert.Equal(1, newEntry.Id);
                Assert.Equal(1, newEntry.DisplaySequence);
                Assert.Equal(1, newEntry.AvailableEvents.Count);
                Assert.Equal(1, newEntry.AvailableEvents.Count(_=>_.IsInherited));

                Assert.Equal(1, newEntry.DocumentRequirements.Count);
                Assert.Equal(1, newEntry.DocumentRequirements.Count(_=>_.IsInherited));

                Assert.Equal(1, newEntry.GroupsAllowed.Count);
                Assert.Equal(1, newEntry.GroupsAllowed.Count(_=>_.IsInherited));

                Assert.Equal(1, newEntry.UsersAllowed.Count);
                Assert.Equal(1, newEntry.UsersAllowed.Count(_=>_.IsInherited));

                Assert.Equal(1, newEntry.RolesAllowed.Count);
                Assert.Equal(1, newEntry.RolesAllowed.Count(_=>_.Inherited == true));
            }
        }

        public class SplitMatchingAndNonMatchingMethod : FactBase
        {
            [Fact]
            public void SpiltPerformsExactMatchForSeparators()
            {
                var parentEntries = new[]
                {
                    new DataEntryTaskBuilder
                    {
                        EntryNumber = 1,
                        Description = "e1"
                    }.Build(),
                    new DataEntryTaskBuilder
                    {
                        EntryNumber = 2,
                        Description = "e%2A x"
                    }.AsSeparator().Build(),
                    new DataEntryTaskBuilder
                    {
                        EntryNumber = 3,
                        Description = "----"
                    }.AsSeparator().Build()
                };

                var childrenEntries = new[]
                {
                    new DataEntryTaskBuilder
                    {
                        EntryNumber = 3,
                        Description = "e#2ax"
                    }.AsSeparator().Build(),
                    new DataEntryTaskBuilder
                    {
                        EntryNumber = 4,
                        Description = "e3"
                    }.Build(),
                    new DataEntryTaskBuilder
                    {
                        EntryNumber = 6,
                        Description = "----"
                    }.AsSeparator().Build()
                };

                var f = new WorkflowEntryInheritanceServiceFixture(Db);
                var result = f.Subject.SplitMatchingAndNonMatching(childrenEntries, parentEntries).ToArray();

                Assert.Equal(3, result.Length);
                Assert.Equal("e1", result[0].ParentEntry.Description);
                Assert.Null(result[0].ChildEntry);

                Assert.Equal("e%2A x", result[1].ParentEntry.Description);
                Assert.Null(result[1].ChildEntry);

                Assert.Equal("----", result[2].ParentEntry.Description);
                Assert.Equal(3, result[2].ParentEntry.Id);
                Assert.Equal(6, result[2].ChildEntry.Id);
            }

            [Fact]
            public void SplitsMatchingAndNonMatchingEntries()
            {
                var parentEntries = new[]
                {
                    new DataEntryTaskBuilder
                    {
                        EntryNumber = 1,
                        Description = "e1"
                    }.Build(),
                    new DataEntryTaskBuilder
                    {
                        EntryNumber = 2,
                        Description = "e%2A x"
                    }.Build()
                };
                var childrenEntries = new[]
                {
                    new DataEntryTaskBuilder
                    {
                        EntryNumber = 3,
                        Description = "e#2a        x"
                    }.Build(),
                    new DataEntryTaskBuilder
                    {
                        EntryNumber = 4,
                        Description = "e3"
                    }.Build()
                };

                var f = new WorkflowEntryInheritanceServiceFixture(Db);
                var result = f.Subject.SplitMatchingAndNonMatching(childrenEntries, parentEntries).ToArray();

                Assert.Equal(2, result.Length);
                Assert.Equal("e1", result[0].ParentEntry.Description);
                Assert.Null(result[0].ChildEntry);
                Assert.Equal(2, result[1].ParentEntry.Id);
                Assert.Equal(3, result[1].ChildEntry.Id);
            }
        }

        public class InheritDataEntryTaskMethod : FactBase
        {
            [Fact]
            public void ReturnsNewDataEntryTask()
            {
                var criteria = new CriteriaBuilder().Build();
                var parentDataEntryTask = new DataEntryTaskBuilder().Build();
                criteria.DataEntryTasks = new[] {parentDataEntryTask};

                DataFiller.Fill(parentDataEntryTask);
                parentDataEntryTask.IsInherited = false;

                var availableEventBuilder = AvailableEventBuilder.For(parentDataEntryTask);
                parentDataEntryTask.AvailableEvents = new[] {availableEventBuilder.Build(), availableEventBuilder.Build()};

                var documentRequirementBuilder = new DocumentRequirementBuilder {DataEntryTask = parentDataEntryTask};
                parentDataEntryTask.DocumentRequirements = new[] {documentRequirementBuilder.Build(), documentRequirementBuilder.Build()};

                parentDataEntryTask.GroupsAllowed = new[] {new GroupControl(parentDataEntryTask, "securityGroup"), new GroupControl(parentDataEntryTask, "securityGroup1")};

                var userControlBuilder = UserControlBuilder.For(parentDataEntryTask, "userId");
                parentDataEntryTask.UsersAllowed = new[] {userControlBuilder.Build(), userControlBuilder.Build()};

                new DataEntryTaskStepBuilder {Criteria = parentDataEntryTask.Criteria, DataEntryTask = parentDataEntryTask}.Build().In(Db);

                var f = new WorkflowEntryInheritanceServiceFixture(Db);
                var entryId = Fixture.Short();
                var displaySeq = Fixture.Short();
                var result = f.Subject.InheritDataEntryTask(criteria, parentDataEntryTask, entryId, displaySeq);

                Assert.Equal(criteria.Id, result.CriteriaId);
                Assert.True(result.IsInherited);

                Assert.Equal(entryId, result.Id);
                Assert.Equal(displaySeq, result.DisplaySequence);

                Assert.Equal(2, result.AvailableEvents.Count);
                Assert.Equal(parentDataEntryTask.AvailableEvents.First().EventId, result.AvailableEvents.First().EventId);

                Assert.Equal(2, result.DocumentRequirements.Count);
                Assert.Equal(parentDataEntryTask.DocumentRequirements.First().DocumentId, result.DocumentRequirements.First().DocumentId);

                Assert.Equal(2, result.GroupsAllowed.Count);
                Assert.Equal(parentDataEntryTask.GroupsAllowed.First().SecurityGroup, result.GroupsAllowed.First().SecurityGroup);

                Assert.Equal(2, result.UsersAllowed.Count);
                Assert.Equal(parentDataEntryTask.UsersAllowed.First().UserId, result.UsersAllowed.First().UserId);
            }
        }

        public class InheritDataEntryTaskStepsMethod : FactBase
        {
            [Fact]
            public void HandlesDuplicateExistingStepsUnderOtherEntries()
            {
                var parentCriteria = new CriteriaBuilder().Build();
                var parentDataEntryTask = new DataEntryTaskBuilder(parentCriteria).In(Db).Build().WithStep(Db, "frmScreenName")
                                                                                  .WithStep(Db, "frmScreenName");

                var childCriteria = new CriteriaBuilder().Build();
                new DataEntryTaskBuilder(childCriteria).In(Db).Build().WithStep(Db, "frmScreenName");
                new DataEntryTaskBuilder(childCriteria).In(Db).Build().WithStep(Db, "frmScreenName");

                var newInheritedEntry = DataEntryTaskBuilder.ForCriteria(childCriteria).Build();
                newInheritedEntry.ParentCriteriaId = parentDataEntryTask.CriteriaId;
                newInheritedEntry.ParentEntryId = parentDataEntryTask.Id;

                var f = new WorkflowEntryInheritanceServiceFixture(Db);
                f.Subject.InheritDataEntryTaskSteps(new[] {newInheritedEntry});

                var inheritedSteps = newInheritedEntry.WorkflowWizard?.TopicControls.Where(_ => _.Name == "frmScreenName").ToArray();
                Assert.NotNull(inheritedSteps);
                Assert.Equal(2, inheritedSteps.Length);
            }

            [Fact]
            public void InheritsDataEntryTaskSteps()
            {
                var parentDataEntryTask = new DataEntryTaskBuilder().In(Db).Build().WithStep(Db, "frmScreenName", null);

                var parentDataEntryTask1 = DataEntryTaskBuilder.ForCriteria(parentDataEntryTask.Criteria).In(Db).Build()
                                                               .WithStep(Db, "frmScreenName")
                                                               .WithStep(Db, "frmDifferentScreen");
                var childCriteria = new CriteriaBuilder().Build();
                var newInheritedEntry = DataEntryTaskBuilder.ForCriteria(childCriteria).Build();
                newInheritedEntry.ParentCriteriaId = parentDataEntryTask.CriteriaId;
                newInheritedEntry.ParentEntryId = parentDataEntryTask.Id;

                var newInheritedEntry1 = DataEntryTaskBuilder.ForCriteria(childCriteria).Build();
                newInheritedEntry1.ParentCriteriaId = parentDataEntryTask1.CriteriaId;
                newInheritedEntry1.ParentEntryId = parentDataEntryTask1.Id;
                var f = new WorkflowEntryInheritanceServiceFixture(Db);
                f.Subject.InheritDataEntryTaskSteps(new[] {newInheritedEntry, newInheritedEntry1});

                Assert.NotNull(newInheritedEntry.WorkflowWizard?.TopicControls.Where(_ => _.Name == "frmScreenName"));
                Assert.NotNull(newInheritedEntry1.WorkflowWizard?.TopicControls.Where(_ => _.Name == "frmScreenName"));
                Assert.NotNull(newInheritedEntry1.WorkflowWizard?.TopicControls.Where(_ => _.Name == "frmDifferentScreen"));
            }
        }
    }

    public class WorkflowEntryInheritanceServiceFixture : IFixture<WorkflowEntryInheritanceService>
    {
        public WorkflowEntryInheritanceServiceFixture(InMemoryDbContext db)
        {
            DbContext = db;
            Subject = new WorkflowEntryInheritanceService(DbContext);
        }

        public IDbContext DbContext { get; set; }
        public WorkflowEntryInheritanceService Subject { get; set; }
    }
}