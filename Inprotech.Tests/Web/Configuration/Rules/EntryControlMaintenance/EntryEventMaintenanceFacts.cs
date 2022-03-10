using System.Collections.Generic;
using System.Linq;
using AutoMapper;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

#pragma warning disable 618

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance
{
    public class EntryEventMaintenanceFacts
    {
        public class ValidateMethod : FactBase
        {
            [Fact]
            public void ReturnsErrorIfAddedEventAlreadyPresent()
            {
                var f = new EntryEventMaintenanceFixture(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);
                var entryToUpdate = new DataEntryTaskBuilder(criteria, 1) {Description = "A new Entry"}.BuildWithAvailableEvents(Db, 3).In(Db);
                var otherEntry = new DataEntryTaskBuilder(criteria, 2) {Description = "An old Entry"}.Build().In(Db);
                var updatedValues = new WorkflowEntryControlSaveModel {Description = "A new Entry"};
                updatedValues.EntryEventDelta.Added.Add(new EntryEventDelta {EventId = entryToUpdate.AvailableEvents.First().EventId});

                criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate, otherEntry};

                var result = f.Subject.Validate(entryToUpdate, updatedValues).ToArray();
                Assert.NotEmpty(result);
                Assert.Single(result);
                Assert.Equal("details", result.First().Topic);
                Assert.Equal("entryEvents", result.First().Field);
                Assert.Equal(entryToUpdate.AvailableEvents.First().EventId, result.First().Id);
            }

            [Fact]
            public void ReturnsErrorIfUpdatedEventAlreadyPresent()
            {
                var f = new EntryEventMaintenanceFixture(Db);
                var criteria = new CriteriaBuilder().Build();
                var entryToUpdate = new DataEntryTaskBuilder(criteria, 1) {Description = "A new Entry"}.BuildWithAvailableEvents(Db, 3).In(Db);
                var otherEntry = new DataEntryTaskBuilder(criteria, 2) {Description = "An old Entry"}.Build().In(Db);
                var updatedValues = new WorkflowEntryControlSaveModel {Description = "A new Entry"};

                updatedValues.EntryEventDelta.Updated.Add(new EntryEventDelta {EventId = entryToUpdate.AvailableEvents.Last().EventId, PreviousEventId = entryToUpdate.AvailableEvents.First().EventId});

                criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate, otherEntry};

                var result = f.Subject.Validate(entryToUpdate, updatedValues).ToArray();
                Assert.NotEmpty(result);
                Assert.Single(result);
                Assert.Equal("details", result.First().Topic);
                Assert.Equal("entryEvents", result.First().Field);
                Assert.Equal(entryToUpdate.AvailableEvents.Last().EventId, result.First().Id);
            }

            [Fact]
            public void ReturnsWithoutErrorsIfValidUpdates()
            {
                var f = new EntryEventMaintenanceFixture(Db);
                var criteria = new CriteriaBuilder().Build();
                var entryToUpdate = new DataEntryTaskBuilder(criteria, 1) {Description = "A new Entry"}.BuildWithAvailableEvents(Db, 3).In(Db);
                var otherEntry = new DataEntryTaskBuilder(criteria, 2) {Description = "An old Entry"}.Build().In(Db);
                var updatedValues = new WorkflowEntryControlSaveModel {Description = "A new Entry"};

                updatedValues.EntryEventDelta.Added.Add(new EntryEventDelta {EventId = 100});
                updatedValues.EntryEventDelta.Updated.Add(new EntryEventDelta {EventId = 101, PreviousEventId = entryToUpdate.AvailableEvents.First().EventId});

                criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate, otherEntry};

                var result = f.Subject.Validate(entryToUpdate, updatedValues).ToArray();
                Assert.Empty(result);
            }
        }

        public class SetDeltaForUpdateMethod
        {
            public class ForAdd : FactBase
            {
                public ForAdd()
                {
                    _entry = new DataEntryTask(10, 1)
                    {
                        AvailableEvents = new List<AvailableEvent>
                        {
                            new AvailableEvent {EventId = 1, Inherited = 1},
                            new AvailableEvent {EventId = 2, Inherited = 1},
                            new AvailableEvent {EventId = 3}
                        }
                    };

                    _initial = new DataEntryTask(1, 1)
                    {
                        AvailableEvents = new List<AvailableEvent>
                        {
                            new AvailableEvent {EventId = 1, Inherited = 1},
                            new AvailableEvent {EventId = 2, Inherited = 1},
                            new AvailableEvent {EventId = 3}
                        }
                    };
                }

                readonly DataEntryTask _entry;
                readonly DataEntryTask _initial;

                [Fact]
                public void ConsidersAddedEvents()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        EntryEventDelta = new Delta<EntryEventDelta>
                        {
                            Added = new List<EntryEventDelta> {new EntryEventDelta {EventId = 100}}
                        }
                    };

                    var f = new EntryEventMaintenanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.NotEmpty(fieldToUpdates.EntryEventsDelta.Added);
                    Assert.Equal(100, fieldToUpdates.EntryEventsDelta.Added.First());
                }

                [Fact]
                public void IgnoreAlreadyPresentEvents()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        EntryEventDelta = new Delta<EntryEventDelta>
                        {
                            Added = new List<EntryEventDelta> {new EntryEventDelta {EventId = 1}}
                        }
                    };

                    var f = new EntryEventMaintenanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.Empty(fieldToUpdates.EntryEventsDelta.Added);
                }
            }

            public class ForDelete : FactBase
            {
                public ForDelete()
                {
                    _entry = new DataEntryTask(10, 1)
                    {
                        AvailableEvents = new List<AvailableEvent>
                        {
                            new AvailableEvent {EventId = 1, Inherited = 1},
                            new AvailableEvent {EventId = 2, Inherited = 1},
                            new AvailableEvent {EventId = 3}
                        }
                    };

                    _initial = new DataEntryTask(1, 1)
                    {
                        AvailableEvents = new List<AvailableEvent>
                        {
                            new AvailableEvent {EventId = 1, Inherited = 1},
                            new AvailableEvent {EventId = 2, Inherited = 1},
                            new AvailableEvent {EventId = 3}
                        }
                    };
                }

                readonly DataEntryTask _entry;
                readonly DataEntryTask _initial;

                [Fact]
                void ConsidersDeletions()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        EntryEventDelta = new Delta<EntryEventDelta>
                        {
                            Deleted = new List<EntryEventDelta> {new EntryEventDelta {EventId = 1}, new EntryEventDelta {EventId = 2}}
                        }
                    };

                    var f = new EntryEventMaintenanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.NotEmpty(fieldToUpdates.EntryEventsDelta.Deleted);
                    Assert.Equal(1, fieldToUpdates.EntryEventsDelta.Deleted.First());
                    Assert.Equal(2, fieldToUpdates.EntryEventsDelta.Deleted.Last());
                }

                [Fact]
                void IgnoresNonInheritedEvents()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        EntryEventDelta = new Delta<EntryEventDelta>
                        {
                            Deleted = new List<EntryEventDelta> {new EntryEventDelta {EventId = 3}}
                        }
                    };

                    var f = new EntryEventMaintenanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.Empty(fieldToUpdates.EntryEventsDelta.Deleted);
                }
            }

            public class ForUpdate : FactBase
            {
                public ForUpdate()
                {
                    _entry = new DataEntryTask(10, 1)
                    {
                        AvailableEvents = new List<AvailableEvent>
                        {
                            new AvailableEvent {EventId = 1, Inherited = 1},
                            new AvailableEvent {EventId = 2, Inherited = 1},
                            new AvailableEvent {EventId = 3}
                        }
                    };

                    _initial = new DataEntryTask(1, 1)
                    {
                        AvailableEvents = new List<AvailableEvent>
                        {
                            new AvailableEvent {EventId = 1, Inherited = 1},
                            new AvailableEvent {EventId = 2, Inherited = 1},
                            new AvailableEvent {EventId = 3}
                        }
                    };
                }

                readonly DataEntryTask _entry;
                readonly DataEntryTask _initial;

                [Fact]
                public void ConsidersEventUpdates()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        EntryEventDelta = new Delta<EntryEventDelta>
                        {
                            Updated = new List<EntryEventDelta> {new EntryEventDelta {EventId = 100, PreviousEventId = 1}}
                        }
                    };

                    var f = new EntryEventMaintenanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.NotEmpty(fieldToUpdates.EntryEventsDelta.Updated);
                    Assert.Equal(1, fieldToUpdates.EntryEventsDelta.Updated.First());
                    Assert.Empty(fieldToUpdates.EntryEventRemoveInheritanceFor);
                }

                [Fact]
                public void IgnoresEntryEventUpdateIfEventAlreadyPresent()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        EntryEventDelta = new Delta<EntryEventDelta>
                        {
                            Updated = new List<EntryEventDelta> {new EntryEventDelta {EventId = 3, PreviousEventId = 1}}
                        }
                    };

                    var f = new EntryEventMaintenanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.Empty(fieldToUpdates.EntryEventsDelta.Updated);
                }

                [Fact]
                public void IgnoresNonInheritedEvents()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        EntryEventDelta = new Delta<EntryEventDelta>
                        {
                            Updated = new List<EntryEventDelta> {new EntryEventDelta {EventId = 3}}
                        }
                    };

                    var f = new EntryEventMaintenanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.Empty(fieldToUpdates.EntryEventsDelta.Updated);
                }

                [Fact]
                public void SetsIdsForWhichInheritanceShouldBeRemoved()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        EntryEventDelta = new Delta<EntryEventDelta>
                        {
                            Updated = new List<EntryEventDelta> {new EntryEventDelta {EventId = 3, PreviousEventId = 1}}
                        }
                    };

                    var f = new EntryEventMaintenanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.Empty(fieldToUpdates.EntryEventsDelta.Updated);
                    Assert.Equal(1, fieldToUpdates.EntryEventRemoveInheritanceFor.Count);
                    Assert.Equal(1, fieldToUpdates.EntryEventRemoveInheritanceFor.First());
                }
            }
        }

        public class ApplyChanges
        {
            public class Additions : FactBase
            {
                [Fact]
                public void AppliedToCurrentRelativeEventConsidered()
                {
                    var f = new EntryEventMaintenanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry"
                    }.BuildWithAvailableEvents(Db, "apple", "banana", "coconut").In(Db);

                    var apple = entryToUpdate.AvailableEvents.ByName("apple");
                    var banana = entryToUpdate.AvailableEvents.ByName("banana");
                    var coconut = entryToUpdate.AvailableEvents.ByName("coconut");

                    var kiwi = new EventBuilder {Description = "kiwi"}.In(Db).Build();
                    var peach = new EventBuilder {Description = "peach"}.In(Db).Build();
                    var mango = new EventBuilder {Description = "mango"}.In(Db).Build();

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        CriteriaId = criteria.Id,
                        Description = "A new Entry"
                    };
                    updatedValues.EntryEventDelta.Added.Add(new EntryEventDelta {EventId = kiwi.Id, AlsoUpdateEventId = peach.Id, DueAttribute = 3, PeriodAttribute = 1, DueDateResponsibleNameAttribute = 3, OverrideEventAttribute = 1});
                    updatedValues.EntryEventDelta.Added.Add(new EntryEventDelta {EventId = peach.Id, EventAttribute = 2, PolicingAttribute = 0, RelativeEventId = apple.EventId, OverrideDueAttribute = 1});
                    updatedValues.EntryEventDelta.Added.Add(new EntryEventDelta {EventId = mango.Id});

                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToUpdate, updatedValues) {EntryEventsDelta = {Added = new List<int> {kiwi.Id, peach.Id}}};

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, fieldsToupdate);
                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                    var entryEvents = updatedEntry.AvailableEvents.OrderBy(_ => _.DisplaySequence).ToArray();

                    Assert.Equal(5, entryEvents.Length);
                    Assert.Equal(apple.EventId, entryEvents[0].EventId);

                    Assert.Equal(peach.Id, entryEvents[1].EventId);
                    Assert.Null(entryEvents[1].AlsoUpdateEventId);
                    Assert.Equal((short) 2, entryEvents[1].EventAttribute);
                    Assert.Equal((short) 0, entryEvents[1].PolicingAttribute);
                    Assert.Equal((short) 1, entryEvents[1].OverrideDueAttribute);

                    Assert.Equal(banana.EventId, entryEvents[2].EventId);
                    Assert.Equal(coconut.EventId, entryEvents[3].EventId);

                    Assert.Equal(kiwi.Id, entryEvents[4].EventId);
                    Assert.False(entryEvents[4].IsInherited);
                    Assert.Equal(peach.Id, entryEvents[4].AlsoUpdateEventId);
                    Assert.Equal((short) 3, entryEvents[4].DueAttribute);
                    Assert.Equal((short) 1, entryEvents[4].PeriodAttribute);
                    Assert.Equal((short) 3, entryEvents[4].DueDateResponsibleNameAttribute);
                    Assert.Equal((short)1, entryEvents[4].OverrideEventAttribute);
                }

                [Fact]
                public void InheritanceFlagAndDisplaySeqAreSetIfResettingEntry()
                {
                    var f = new EntryEventMaintenanceFixture(Db);

                    var kiwi = new EventBuilder {Description = "kiwi"}.In(Db).Build();

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry"
                    }.Build().In(Db);
                    criteria.DataEntryTasks.Add(entryToUpdate);

                    var saveModel = new WorkflowEntryControlSaveModel
                    {
                        Id = 110,
                        CriteriaId = 10,
                        Description = "A new Entry",
                        ResetInheritance = true
                    };
                    saveModel.EntryEventDelta.Added.Add(new EntryEventDelta {EventId = kiwi.Id, OverrideDisplaySequence = 99});

                    f.Subject.ApplyChanges(entryToUpdate, saveModel, new EntryControlFieldsToUpdate(entryToUpdate, saveModel));

                    Assert.True(entryToUpdate.AvailableEvents.Single().IsInherited);
                    Assert.Equal((short) 99, entryToUpdate.AvailableEvents.Single().DisplaySequence);
                }

                [Fact]
                public void InheritanceFlagIsSetIfUpdatingChildEntries()
                {
                    var f = new EntryEventMaintenanceFixture(Db);

                    var kiwi = new EventBuilder {Description = "kiwi"}.In(Db).Build();

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry"
                    }.BuildWithAvailableEvents(Db, "apple", "banana").In(Db);
                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 110,
                        CriteriaId = 10,
                        Description = "A new Entry"
                    };
                    updatedValues.EntryEventDelta.Added.Add(new EntryEventDelta {EventId = kiwi.Id});

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, new EntryControlFieldsToUpdate(entryToUpdate, updatedValues));
                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                    var entryEvents = updatedEntry.AvailableEvents.OrderBy(_ => _.DisplaySequence).ToArray();

                    Assert.Equal(kiwi.Id, entryEvents[2].EventId);
                    Assert.Equal(1, entryEvents[2].Inherited);
                }

                [Fact]
                public void NotAppliedIfEventExistsAlready()
                {
                    var f = new EntryEventMaintenanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry"
                    }.BuildWithAvailableEvents(Db, "apple", "banana").In(Db);
                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var apple = entryToUpdate.AvailableEvents.ByName("apple");
                    var banana = entryToUpdate.AvailableEvents.ByName("banana");

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        CriteriaId = criteria.Id,
                        Description = "A new Entry"
                    };
                    updatedValues.EntryEventDelta.Added.Add(new EntryEventDelta {EventId = apple.EventId, AlsoUpdateEventId = 11, DueAttribute = 3, PeriodAttribute = 1});

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, new EntryControlFieldsToUpdate(entryToUpdate, updatedValues));
                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                    var entryEvents = updatedEntry.AvailableEvents.OrderBy(_ => _.DisplaySequence).ToArray();

                    Assert.Equal(apple.EventId, entryEvents[0].EventId);
                    Assert.Equal(banana.EventId, entryEvents[1].EventId);
                    Assert.Null(entryEvents[1].AlsoUpdateEventId);
                }
            }

            public class Updations : FactBase
            {
                [Fact]
                public void InheritanceRemovedIfUpdateCanNotApply()
                {
                    var f = new EntryEventMaintenanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithAvailableEvents(Db, "apple", "banana", "coconut").In(Db);

                    var apple = entryToUpdate.AvailableEvents.ElementAt(0);
                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = entryToUpdate.Id,
                        CriteriaId = 100
                    };

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToUpdate, updatedValues)
                    {
                        EntryEventRemoveInheritanceFor = new List<int> {apple.EventId}
                    };

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, fieldsToupdate);

                    var entryEvents = Db.Set<DataEntryTask>()
                                        .Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId)
                                        .AvailableEvents
                                        .OrderBy(_ => _.DisplaySequence).ToArray();

                    Assert.Equal(3, entryEvents.Length);

                    Assert.Equal(apple.EventId, entryEvents[0].EventId);
                    Assert.False(entryEvents[0].IsInherited);
                }

                [Fact]
                public void TurnsOnInheritanceAndSetsDisplaySeqWhenResetting()
                {
                    var f = new EntryEventMaintenanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithAvailableEvents(Db, "apple").In(Db);

                    criteria.DataEntryTasks.Add(entryToUpdate);
                    var apple = entryToUpdate.AvailableEvents.ElementAt(0);
                    apple.IsInherited = false;

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = entryToUpdate.Id,
                        CriteriaId = criteria.Id,
                        ResetInheritance = true
                    };
                    updatedValues.EntryEventDelta.Updated.Add(new EntryEventDelta {OverrideDisplaySequence = 99, EventId = apple.EventId, PreviousEventId = apple.EventId, DueAttribute = Fixture.Short()});

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToUpdate, updatedValues)
                    {
                        EntryEventsDelta = {Updated = new List<int> {apple.EventId}}
                    };

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, fieldsToupdate);

                    Assert.True(apple.IsInherited);
                    Assert.Equal((short) 99, apple.DisplaySequence);
                }

                [Fact]
                public void UpdatesAppliedToCurrentEventIdUpdatesHandled()
                {
                    var f = new EntryEventMaintenanceFixture(Db);
                    var pinkLady = new EventBuilder {Description = "pinklady apple"}.In(Db).Build();
                    var mango = new EventBuilder {Description = "mango"}.In(Db).Build();
                    var kiwi = new EventBuilder {Description = "kiwi"}.In(Db).Build();

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithAvailableEvents(Db, "apple", "banana", "coconut").In(Db);

                    var apple = entryToUpdate.AvailableEvents.ByName("apple");
                    var banana = entryToUpdate.AvailableEvents.ByName("banana");
                    var coconut = entryToUpdate.AvailableEvents.ByName("coconut");

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        CriteriaId = criteria.Id,
                        EntryEventDelta =
                        {
                            Updated = new List<EntryEventDelta>
                            {
                                new EntryEventDelta {EventId = pinkLady.Id, AlsoUpdateEventId = mango.Id, DueAttribute = 3, PeriodAttribute = 1, DueDateResponsibleNameAttribute = 0, PreviousEventId = apple.EventId},
                                new EntryEventDelta {EventId = banana.EventId, EventAttribute = 2, PolicingAttribute = 0, PreviousEventId = banana.EventId, OverrideEventAttribute = 0},
                                new EntryEventDelta {EventId = kiwi.Id, PreviousEventId = coconut.EventId, OverrideDueAttribute = 1}
                            }
                        }
                    };

                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToUpdate, updatedValues)
                    {
                        EntryEventsDelta = {Updated = new List<int> {apple.EventId, banana.EventId}}
                    };

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, fieldsToupdate);

                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                    var entryEvents = updatedEntry.AvailableEvents.OrderBy(_ => _.DisplaySequence).ToArray();

                    Assert.Equal(3, entryEvents.Length);

                    Assert.Equal(pinkLady.Id, entryEvents[0].EventId);
                    Assert.False(entryEvents[0].IsInherited);
                    Assert.Equal(mango.Id, entryEvents[0].AlsoUpdateEventId);
                    Assert.Equal((short) 3, entryEvents[0].DueAttribute);
                    Assert.Equal((short) 1, entryEvents[0].PeriodAttribute);
                    Assert.Equal((short) 0, entryEvents[0].DueDateResponsibleNameAttribute);
                    
                    Assert.Equal(banana.EventId, entryEvents[1].EventId);
                    Assert.False(entryEvents[1].IsInherited);
                    Assert.Null(entryEvents[1].AlsoUpdateEventId);
                    Assert.Equal((short) 2, entryEvents[1].EventAttribute);
                    Assert.Equal((short) 0, entryEvents[1].PolicingAttribute);
                    Assert.Equal((short) 0, entryEvents[1].OverrideEventAttribute);

                    Assert.Equal(coconut.EventId, entryEvents[2].EventId);
                    Assert.True(entryEvents[2].IsInherited);
                }
            }

            public class Deletions : FactBase
            {
                [Fact]
                public void DeletedAppliedToCurrent()
                {
                    var f = new EntryEventMaintenanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToChange = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithAvailableEvents(Db, "apple", "banana", "coconut").In(Db);

                    var apple = entryToChange.AvailableEvents.ByName("apple");
                    var banana = entryToChange.AvailableEvents.ByName("banana");
                    var coconut = entryToChange.AvailableEvents.ByName("coconut");

                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToChange};

                    var deltaValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        CriteriaId = criteria.Id
                    };

                    deltaValues.EntryEventDelta.Deleted.Add(new EntryEventDelta
                    {
                        EventId = banana.EventId,
                        AlsoUpdateEventId = 11,
                        DueAttribute = 3,
                        PeriodAttribute = 1,
                        PreviousEventId = apple.EventId
                    });

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToChange, deltaValues);

                    f.Subject.ApplyChanges(entryToChange, deltaValues, fieldsToupdate);

                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToChange.Id && _.CriteriaId == entryToChange.CriteriaId);
                    var entryEvents = updatedEntry.AvailableEvents.OrderBy(_ => _.DisplaySequence).ToArray();

                    Assert.Equal(2, entryEvents.Length);

                    Assert.Equal(apple.EventId, entryEvents[0].EventId);
                    Assert.True(entryEvents[0].IsInherited);

                    Assert.Equal(coconut.EventId, entryEvents[1].EventId);
                    Assert.True(entryEvents[1].IsInherited);
                }

                [Fact]
                public void InheritanceRemovedForEntryEventIfDeleteNoPropogated()
                {
                    var f = new EntryEventMaintenanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToChange = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithAvailableEvents(Db, "apple", "banana", "coconut").In(Db);

                    var childCritera = new Criteria {ParentCriteriaId = criteria.Id}.In(Db);
                    var childEntry = new DataEntryTaskBuilder(childCritera, 1)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithAvailableEvents(Db, "apple", "banana", "coconut").In(Db);

                    var banana = childEntry.AvailableEvents.ByName("banana");

                    childCritera.DataEntryTasks = new List<DataEntryTask> {childEntry};

                    var deltaValues = new WorkflowEntryControlSaveModel();
                    deltaValues.EntryEventDelta.Deleted.Add(new EntryEventDelta {EventId = banana.EventId});

                    f.Subject.RemoveInheritance(childEntry, new EntryControlFieldsToUpdate(entryToChange, deltaValues));

                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == childEntry.Id && _.CriteriaId == childEntry.CriteriaId);
                    var entryEvents = updatedEntry.AvailableEvents.OrderBy(_ => _.DisplaySequence).ToArray();

                    Assert.Equal(3, entryEvents.Length);

                    Assert.Equal(banana.EventId, entryEvents[1].EventId);
                    Assert.False(entryEvents[1].IsInherited);
                }
            }

            public class ComplexScenarios : FactBase
            {
                [Fact]
                public void UpdatesAreAppliedBeforeAddition()
                {
                    var f = new EntryEventMaintenanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithAvailableEvents(Db, "apple", "banana", "coconut").In(Db);

                    var apple = entryToUpdate.AvailableEvents.ByName("apple");
                    var banana = entryToUpdate.AvailableEvents.ByName("banana");
                    var coconut = entryToUpdate.AvailableEvents.ByName("coconut");

                    var eventAdded = new EventBuilder().Build().In(Db);

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        CriteriaId = criteria.Id
                    };

                    updatedValues.EntryEventDelta.Updated.Add(new EntryEventDelta {EventId = banana.EventId, PreviousEventId = apple.EventId});
                    updatedValues.EntryEventDelta.Added.Add(new EntryEventDelta {EventId = eventAdded.Id, PolicingAttribute = 0, RelativeEventId = banana.EventId});

                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToUpdate, updatedValues)
                    {
                        EntryEventsDelta =
                        {
                            Updated = new List<int> {banana.EventId},
                            Added = new List<int> {eventAdded.Id}
                        }
                    };

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, fieldsToupdate);

                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                    var entryEvents = updatedEntry.AvailableEvents.OrderBy(_ => _.DisplaySequence).ToArray();

                    Assert.Equal(4, entryEvents.Length);

                    Assert.Equal(apple.EventId, entryEvents[0].EventId);
                    Assert.Equal(banana.EventId, entryEvents[1].EventId);
                    Assert.Equal(eventAdded.Id, entryEvents[2].EventId);
                    Assert.Equal(coconut.EventId, entryEvents[3].EventId);
                }
            }
        }

        public class RemoveInheritance : FactBase
        {
            [Fact]
            public void RemovesInheritanceForUpdatedEvents()
            {
                var f = new EntryEventMaintenanceFixture(Db);
                var kiwi = new EventBuilder {Description = "kiwi"}.Build().In(Db);

                var criteria = new Criteria().In(Db);
                var entryToUpdate = new DataEntryTaskBuilder(criteria)
                {
                    Description = "A new Entry",
                    Inherited = 1
                }.BuildWithAvailableEvents(Db, "apple", "banana", "coconut").In(Db);

                var apple = entryToUpdate.AvailableEvents.ByName("apple");
                var banana = entryToUpdate.AvailableEvents.ByName("banana");
                var coconut = entryToUpdate.AvailableEvents.ByName("coconut");

                criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = entryToUpdate.Id,
                    CriteriaId = 100,
                    EntryEventDelta =
                    {
                        Updated = new List<EntryEventDelta>
                        {
                            new EntryEventDelta {EventId = kiwi.Id, PreviousEventId = apple.EventId},
                            new EntryEventDelta {EventId = banana.EventId, PreviousEventId = banana.EventId, PolicingAttribute = 1, DueDateResponsibleNameAttribute = 0}
                        }
                    }
                };

                f.Subject.RemoveInheritance(entryToUpdate, new EntryControlFieldsToUpdate(entryToUpdate, updatedValues));

                var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                var entryEvents = updatedEntry.AvailableEvents.OrderBy(_ => _.DisplaySequence).ToArray();

                Assert.Equal(apple.EventId, entryEvents[0].EventId);
                Assert.False(entryEvents[0].IsInherited);

                Assert.Equal(banana.EventId, entryEvents[1].EventId);
                Assert.False(entryEvents[1].IsInherited);

                Assert.Equal(coconut.EventId, entryEvents[2].EventId);
                Assert.True(entryEvents[2].IsInherited);
            }
        }

        public class UpdateDisplayOrderMethod : FactBase
        {
            Criteria BuildWithEntryEvents(params string[] events)
            {
                var criteria = new Criteria().In(Db);
                var entryToUpdate = new DataEntryTaskBuilder(criteria)
                                    .BuildWithAvailableEvents(Db, events)
                                    .In(Db);
                criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};
                return criteria;
            }

            [Fact]
            public void MovesDown()
            {
                var criteria = BuildWithEntryEvents("apple", "banana", "coconut", "durian", "emuberry");
                var entryToUpdate = criteria.DataEntryTasks.Single();
                var coconut = entryToUpdate.AvailableEvents.ByName("coconut");
                var durian = entryToUpdate.AvailableEvents.ByName("durian");
                var apple = entryToUpdate.AvailableEvents.ByName("apple");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = 110,
                    CriteriaId = 10,
                    EntryEventsMoved = new[]
                    {
                        new EntryEventMovementsBase(coconut.EventId, durian.EventId), /* move coconut to 2nd last */
                        new EntryEventMovementsBase(apple.EventId, durian.EventId) /* move apple following durian */
                    }
                };

                var movements = new EntryControlRecordMovements(entryToUpdate, updatedValues);
                new EntryEventMaintenanceFixture(Db).Subject.UpdateDisplayOrder(entryToUpdate, movements);

                var expected = new[]
                {
                    "banana", "durian", "apple", "coconut", "emuberry"
                };

                var result = entryToUpdate.EventsInDisplayOrder().Names();

                Assert.Equal(expected, result);
            }

            [Fact]
            public void MovesEveryWhichWay()
            {
                var criteria = BuildWithEntryEvents("apple", "banana", "coconut", "durian", "emuberry");
                var entryToUpdate = criteria.DataEntryTasks.Single();
                var banana = entryToUpdate.AvailableEvents.ByName("banana");
                var emuberry = entryToUpdate.AvailableEvents.ByName("emuberry");
                var coconut = entryToUpdate.AvailableEvents.ByName("coconut");
                var durian = entryToUpdate.AvailableEvents.ByName("durian");
                var apple = entryToUpdate.AvailableEvents.ByName("apple");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = 110,
                    CriteriaId = 10,
                    EntryEventsMoved = new[]
                    {
                        new EntryEventMovementsBase(banana.EventId), /* "banana", "apple", "coconut", "durian", "emuberry" */
                        new EntryEventMovementsBase(emuberry.EventId, banana.EventId), /* "banana", "emuberry", "apple", "coconut", "durian" */
                        new EntryEventMovementsBase(apple.EventId, durian.EventId), /* "banana", "emuberry", "coconut", "durian", "apple" */
                        new EntryEventMovementsBase(coconut.EventId) /* "coconut", "banana", "emuberry", "durian", "apple" */
                    }
                };

                var movements = new EntryControlRecordMovements(entryToUpdate, updatedValues);
                new EntryEventMaintenanceFixture(Db).Subject.UpdateDisplayOrder(entryToUpdate, movements);

                var expected = new[]
                {
                    "coconut", "banana", "emuberry", "durian", "apple"
                };

                var result = entryToUpdate.EventsInDisplayOrder().Names();

                Assert.Equal(expected, result);
            }

            [Fact]
            public void MovesUp()
            {
                var criteria = BuildWithEntryEvents("apple", "banana", "coconut", "durian", "emuberry");
                var entryToUpdate = criteria.DataEntryTasks.Single();
                var banana = entryToUpdate.AvailableEvents.ByName("banana");
                var emuberry = entryToUpdate.AvailableEvents.ByName("emuberry");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = 110,
                    CriteriaId = 10,
                    EntryEventsMoved = new[]
                    {
                        new EntryEventMovementsBase(banana.EventId), /* move banana to top of the bunch */
                        new EntryEventMovementsBase(emuberry.EventId, banana.EventId) /* move enumberry following banana */
                    }
                };

                var movements = new EntryControlRecordMovements(entryToUpdate, updatedValues);
                new EntryEventMaintenanceFixture(Db).Subject.UpdateDisplayOrder(entryToUpdate, movements);

                var expected = new[]
                {
                    "banana", "emuberry", "apple", "coconut", "durian"
                };

                var result = entryToUpdate.EventsInDisplayOrder().Names();

                Assert.Equal(expected, result);
            }
        }

        public class PropagateDisplayOrderMethod : FactBase
        {
            public PropagateDisplayOrderMethod()
            {
                _fixture = new EntryEventMaintenanceFixture(Db);
            }

            readonly EntryEventMaintenanceFixture _fixture;

            Criteria BuildWithEntryEvents(params string[] events)
            {
                var criteria = new Criteria().In(Db);
                var entryToUpdate = new DataEntryTaskBuilder(criteria)
                                    .BuildWithAvailableEvents(Db, events)
                                    .In(Db);
                criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};
                return criteria;
            }

            [Theory]
            [InlineData("apple,banana,coconut,durian,emuberry", "apple,banana,coconut,durian,emuberry", "coconut,banana,emuberry,durian,apple")]
            [InlineData("apple,banana,coconut,durian,emuberry", "apple,random,banana,coconut,durian,emuberry", "coconut,banana,emuberry,random,durian,apple")]
            [InlineData("apple,banana,coconut,durian,emuberry", "apple,banana,coconut,random,durian,emuberry", "coconut,banana,emuberry,random,durian,apple")]
            [InlineData("apple,banana,coconut,durian,emuberry", "yuzu,apple,watermelon,banana,coconut,tomato,durian,strawberry,emuberry,rambutan", "coconut,banana,emuberry,yuzu,watermelon,tomato,durian,apple,strawberry,rambutan")]
            [InlineData("apple,banana,coconut,durian,emuberry", "banana,coconut,durian", "coconut,banana,durian")]
            public void PropagatesWhenAllEventsAreInSameOrder(string strSource, string strTarget, string expected)
            {
                var source = BuildWithEntryEvents(strSource.Split(','));
                var target = BuildWithEntryEvents(strTarget.Split(','));

                var entryToUpdate = source.DataEntryTasks.Single();

                var banana = entryToUpdate.AvailableEvents.ByName("banana");
                var emuberry = entryToUpdate.AvailableEvents.ByName("emuberry");
                var coconut = entryToUpdate.AvailableEvents.ByName("coconut");
                var durian = entryToUpdate.AvailableEvents.ByName("durian");
                var apple = entryToUpdate.AvailableEvents.ByName("apple");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = source.DataEntryTasks.Single().Id,
                    CriteriaId = source.Id,
                    EntryEventsMoved = new[]
                    {
                        new EntryEventMovementsBase(banana.EventId),
                        new EntryEventMovementsBase(emuberry.EventId, banana.EventId),
                        new EntryEventMovementsBase(apple.EventId, durian.EventId),
                        new EntryEventMovementsBase(coconut.EventId)
                    }
                };

                var reorderSource = _fixture.Mapper.Map<EntryReorderSouce>(source.DataEntryTasks.Single());

                var movements = new EntryControlRecordMovements(source.DataEntryTasks.First(), updatedValues);
                var result = _fixture.Subject.PropagateDisplayOrder(reorderSource, target.DataEntryTasks.Single(), movements);

                Assert.True(result);
                Assert.Equal(expected.Split(','), target.DataEntryTasks.Single().EventsInDisplayOrder().Names());
            }

            [Fact]
            public void MovesWithFallbackToNextEventIfPrevIsNotAvailable()
            {
                var source = BuildWithEntryEvents("apple", "banana", "missing", "coconut", "durian", "emuberry");
                var target = BuildWithEntryEvents("apple", "banana", "coconut", "durian", "emuberry");

                var entryToUpdate = source.DataEntryTasks.Single();
                var reorderSource = _fixture.Mapper.Map<EntryReorderSouce>(entryToUpdate);

                var banana = entryToUpdate.AvailableEvents.ByName("banana");
                var emuberry = entryToUpdate.AvailableEvents.ByName("emuberry");
                var missing = entryToUpdate.AvailableEvents.ByName("missing");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = entryToUpdate.Id,
                    CriteriaId = source.Id,
                    EntryEventsMoved = new[]
                    {
                        new EntryEventMovementsBase(banana.EventId), /* move banana to top of the bunch */
                        new EntryEventMovementsBase(emuberry.EventId, missing.EventId) /* move enumberry following missing */
                    }
                };

                var movements = new EntryControlRecordMovements(source.DataEntryTasks.First(), updatedValues);
                _fixture.Subject.UpdateDisplayOrder(entryToUpdate, movements);

                var expected = new[]
                {
                    "banana", "apple", "emuberry", "coconut", "durian"
                };

                var result = _fixture.Subject.PropagateDisplayOrder(reorderSource, target.DataEntryTasks.Single(), movements);

                var names = target.DataEntryTasks.Single().EventsInDisplayOrder().Names();

                Assert.True(result);
                Assert.Equal(expected, names);
            }

            [Fact]
            public void ShouldPropagateIfAllCommonalityAreInSameOrder()
            {
                var source = BuildWithEntryEvents("apple", "banana", "coconut", "durian", "emuberry");
                var banana = source.DataEntryTasks.Single().AvailableEvents.ByName("banana");

                var target = BuildWithEntryEvents("apple", "coconut", "banana", "durian", "emuberry");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = source.DataEntryTasks.Single().Id,
                    CriteriaId = source.Id,
                    EntryEventsMoved = new[]
                    {
                        new EntryEventMovementsBase(banana.EventId) /* "banana", "apple", "coconut", "durian", "emuberry" */
                    }
                };

                var reorderSource = _fixture.Mapper.Map<EntryReorderSouce>(source.DataEntryTasks.Single());

                var movements = new EntryControlRecordMovements(source.DataEntryTasks.First(), updatedValues);
                var result = _fixture.Subject.PropagateDisplayOrder(reorderSource, target.DataEntryTasks.Single(), movements);

                Assert.False(result);
            }

            [Fact]
            public void ShouldPropagateIfTargetContainsEvents()
            {
                var source = BuildWithEntryEvents("apple", "banana", "coconut", "durian", "emuberry");
                var banana = source.DataEntryTasks.Single().AvailableEvents.ByName("banana");

                var target = BuildWithEntryEvents();

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = source.DataEntryTasks.Single().Id,
                    CriteriaId = source.Id,
                    EntryEventsMoved = new[]
                    {
                        new EntryEventMovementsBase(banana.EventId) /* "banana", "apple", "coconut", "durian", "emuberry" */
                    }
                };

                var reorderSource = _fixture.Mapper.Map<EntryReorderSouce>(source.DataEntryTasks.Single());

                var movements = new EntryControlRecordMovements(source.DataEntryTasks.First(), updatedValues);
                var result = _fixture.Subject.PropagateDisplayOrder(reorderSource, target.DataEntryTasks.Single(), movements);

                Assert.False(result);
            }

            [Fact]
            public void ShouldPropagateOnlyIfMovementExists()
            {
                var source = BuildWithEntryEvents("apple", "banana", "coconut", "durian", "emuberry");

                var target = BuildWithEntryEvents("apple", "banana", "coconut", "durian", "emuberry");

                var updatedValues = new WorkflowEntryControlSaveModel
                {
                    Id = source.DataEntryTasks.Single().Id,
                    CriteriaId = source.Id,
                    EntryEventsMoved = new EntryEventMovements[0]
                };

                var reorderSource = _fixture.Mapper.Map<EntryReorderSouce>(source.DataEntryTasks.Single());

                var movements = new EntryControlRecordMovements(source.DataEntryTasks.First(), updatedValues);
                var result = _fixture.Subject.PropagateDisplayOrder(reorderSource, target.DataEntryTasks.Single(), movements);

                Assert.False(result);
            }
        }

        public class Reset : FactBase
        {
            bool CompareEventEntry(AvailableEvent e1, EntryEventDelta e2)
            {
                return (e1.EventId + e1.EventAttribute + e1.DueAttribute + e1.PolicingAttribute + e1.PeriodAttribute + e1.AlsoUpdateEventId + e1.DueDateResponsibleNameAttribute + e1.OverrideEventAttribute + e1.OverrideDueAttribute).GetHashCode() ==
                       (e2.EventId + e2.EventAttribute + e2.DueAttribute + e2.PolicingAttribute + e2.PeriodAttribute + e2.AlsoUpdateEventId + e1.DueDateResponsibleNameAttribute + e1.OverrideEventAttribute + e1.OverrideDueAttribute).GetHashCode();
            }

            [Fact]
            public void AddsEventsFromParent()
            {
                var f = new EntryEventMaintenanceFixture(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder(criteria, 1)
                {
                    Description = "Parent Entry"
                }.BuildWithAvailableEvents(Db, 2).In(Db);
                criteria.DataEntryTasks.Add(parentEntry);
                var event1 = parentEntry.AvailableEvents.ElementAt(0);
                var event2 = parentEntry.AvailableEvents.ElementAt(1);
                event1.DisplaySequence = Fixture.Short();
                event2.DisplaySequence = Fixture.Short();

                var childEntry = new DataEntryTaskBuilder(criteriaChild1, 1)
                {
                    Description = "Child Entry",
                    ParentCriteriaId = criteria.Id,
                    ParentEntryId = parentEntry.Id
                }.Build().In(Db);
                criteriaChild1.DataEntryTasks.Add(childEntry);

                var saveModel = new WorkflowEntryControlSaveModel();
                f.Subject.Reset(childEntry, parentEntry, saveModel);

                // Reset should add 2 Events in the parent that weren't in the child
                Assert.Equal(2, saveModel.EntryEventDelta.Added.Count);
                Assert.Empty(saveModel.EntryEventDelta.Updated);
                Assert.Empty(saveModel.EntryEventDelta.Deleted);

                var e1 = saveModel.EntryEventDelta.Added.Single(e => e.EventId == event1.EventId);
                Assert.True(CompareEventEntry(event1, e1));

                var e2 = saveModel.EntryEventDelta.Added.Single(e => e.EventId == event2.EventId);
                Assert.True(CompareEventEntry(event2, e2));

                Assert.Equal(e1.OverrideDisplaySequence, event1.DisplaySequence);
                Assert.Equal(e2.OverrideDisplaySequence, event2.DisplaySequence);
            }

            [Fact]
            public void DeletesEventsNotInParent()
            {
                var f = new EntryEventMaintenanceFixture(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder(criteria, 1)
                {
                    Description = "Parent Entry"
                }.BuildWithAvailableEvents(Db, 1).In(Db);
                criteria.DataEntryTasks.Add(parentEntry);
                var pEvent = parentEntry.AvailableEvents.ElementAt(0);

                var childEntry = new DataEntryTaskBuilder(criteriaChild1, 1)
                {
                    Description = "Child Entry",
                    ParentCriteriaId = criteria.Id,
                    ParentEntryId = parentEntry.Id
                }.BuildWithAvailableEvents(Db, 3).In(Db);
                criteriaChild1.DataEntryTasks.Add(childEntry);

                var cEventToDelete1 = childEntry.AvailableEvents.ElementAt(0);
                var cEventToDelete2 = childEntry.AvailableEvents.ElementAt(1);

                cEventToDelete1.EventId = Fixture.Integer();
                cEventToDelete2.EventId = Fixture.Integer();

                var cEvent = childEntry.AvailableEvents.ElementAt(2);
                cEvent.EventId = pEvent.EventId;

                var saveModel = new WorkflowEntryControlSaveModel();
                f.Subject.Reset(childEntry, parentEntry, saveModel);

                // Reset should delete 2 Events in child not matching in the parent
                Assert.Equal(2, saveModel.EntryEventDelta.Deleted.Count);
                Assert.Equal(1, saveModel.EntryEventDelta.Updated.Count);
                Assert.Empty(saveModel.EntryEventDelta.Added);

                Assert.NotNull(saveModel.EntryEventDelta.Deleted.SingleOrDefault(e => e.EventId == cEventToDelete1.EventId));
                Assert.NotNull(saveModel.EntryEventDelta.Deleted.SingleOrDefault(e => e.EventId == cEventToDelete2.EventId));

                Assert.NotNull(saveModel.EntryEventDelta.Updated.SingleOrDefault(e => e.EventId == pEvent.EventId));
            }

            [Fact]
            public void UpdatesEventsFromParent()
            {
                var f = new EntryEventMaintenanceFixture(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder(criteria, 1)
                {
                    Description = "Parent Entry"
                }.BuildWithAvailableEvents(Db, 1).In(Db);
                criteria.DataEntryTasks.Add(parentEntry);
                var pEvent = parentEntry.AvailableEvents.ElementAt(0);
                pEvent.DisplaySequence = Fixture.Short();

                var childEntry = new DataEntryTaskBuilder(criteriaChild1, 1)
                {
                    Description = "Child Entry",
                    ParentCriteriaId = criteria.Id,
                    ParentEntryId = parentEntry.Id
                }.BuildWithAvailableEvents(Db, 1).In(Db);
                criteriaChild1.DataEntryTasks.Add(childEntry);
                var cEvent = childEntry.AvailableEvents.ElementAt(0);
                cEvent.EventId = pEvent.EventId;
                cEvent.DisplaySequence = Fixture.Short();

                var saveModel = new WorkflowEntryControlSaveModel();
                f.Subject.Reset(childEntry, parentEntry, saveModel);

                // Reset should update 1 Event that matches in the child
                Assert.Equal(1, saveModel.EntryEventDelta.Updated.Count);
                Assert.Empty(saveModel.EntryEventDelta.Added);
                Assert.Empty(saveModel.EntryEventDelta.Deleted);

                var eResult = saveModel.EntryEventDelta.Updated.Single(e => e.EventId == pEvent.EventId);
                Assert.True(CompareEventEntry(pEvent, eResult));
                Assert.Equal(cEvent.EventId, eResult.PreviousEventId);
                Assert.Equal(eResult.OverrideDisplaySequence, pEvent.DisplaySequence);
            }
        }
    }

    public class EntryEventMaintenanceFixture : IFixture<EntryEventMaintenance>
    {
        public EntryEventMaintenanceFixture(InMemoryDbContext db)
        {
            var m = new Mapper(new MapperConfiguration(cfg =>
            {
                cfg.AddProfile(new EntryControlMaintenanceProfile());
                cfg.CreateMissingTypeMaps = true;
            }));

            Mapper = m.DefaultContext.Mapper.DefaultContext.Mapper;

            ChangeTracker = Substitute.For<IChangeTracker>();

            ChangeTracker.HasChanged(null).ReturnsForAnyArgs(true);

            DbContext = db;

            Subject = new EntryEventMaintenance(Mapper, ChangeTracker);
        }

        public IMapper Mapper { get; }

        public IChangeTracker ChangeTracker { get; }

        public IDbContext DbContext { get; }

        public EntryEventMaintenance Subject { get; }
    }

    public static class AvailableEventExt
    {
        public static string[] Names(this IOrderedEnumerable<AvailableEvent> events)
        {
            return events.Select(_ => _.EventName).ToArray();
        }

        public static AvailableEvent ByName(this IEnumerable<AvailableEvent> events, string name)
        {
            return events.Single(_ => _.EventName == name);
        }
    }
}