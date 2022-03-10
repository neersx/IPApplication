using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Documents;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EntryControlMaintenance
{
    public class EntryDocumentMaintainanceFacts
    {
        public class ValidateMethod : FactBase
        {
            [Fact]
            public void ReturnsErrorIfAddedDocumentAlreadyPresent()
            {
                var f = new EntryDocumentMaintainanceFixture(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);
                var entryToUpdate = new DataEntryTaskBuilder(criteria, 1) {Description = "A new Entry"}.BuildWithDocuments(Db, 3).In(Db);
                var otherEntry = new DataEntryTaskBuilder(criteria, 2) {Description = "An old Entry"}.Build().In(Db);
                var updatedValues = new WorkflowEntryControlSaveModel {Description = "A new Entry"};
                updatedValues.DocumentsDelta.Added.Add(new EntryDocumentDelta {DocumentId = entryToUpdate.DocumentRequirements.First().DocumentId});

                criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate, otherEntry};

                var result = f.Subject.Validate(entryToUpdate, updatedValues).ToArray();
                Assert.NotEmpty(result);
                Assert.Single(result);
                Assert.Equal("documents", result.First().Topic);
                Assert.Equal("entryDocuments", result.First().Field);
                Assert.Equal(entryToUpdate.DocumentRequirements.First().DocumentId, result.First().Id);
            }

            [Fact]
            public void ReturnsErrorIfUpdatedDocumentAlreadyPresent()
            {
                var f = new EntryDocumentMaintainanceFixture(Db);
                var criteria = new CriteriaBuilder().Build();
                var entryToUpdate = new DataEntryTaskBuilder(criteria, 1) {Description = "A new Entry"}.BuildWithDocuments(Db, 3).In(Db);
                var otherEntry = new DataEntryTaskBuilder(criteria, 2) {Description = "An old Entry"}.Build().In(Db);
                var updatedValues = new WorkflowEntryControlSaveModel {Description = "A new Entry"};

                updatedValues.DocumentsDelta.Updated.Add(new EntryDocumentDelta {DocumentId = entryToUpdate.DocumentRequirements.Last().DocumentId, PreviousDocumentId = entryToUpdate.DocumentRequirements.First().DocumentId});

                criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate, otherEntry};

                var result = f.Subject.Validate(entryToUpdate, updatedValues).ToArray();
                Assert.NotEmpty(result);
                Assert.Single(result);
                Assert.Equal("documents", result.First().Topic);
                Assert.Equal("entryDocuments", result.First().Field);
                Assert.Equal(entryToUpdate.DocumentRequirements.Last().DocumentId, result.First().Id);
            }

            [Fact]
            public void ReturnsWithoutErrorsIfValidUpdates()
            {
                var f = new EntryDocumentMaintainanceFixture(Db);
                var criteria = new CriteriaBuilder().Build();
                var entryToUpdate = new DataEntryTaskBuilder(criteria, 1) {Description = "A new Entry"}.BuildWithDocuments(Db, 3).In(Db);
                var otherEntry = new DataEntryTaskBuilder(criteria, 2) {Description = "An old Entry"}.Build().In(Db);
                var updatedValues = new WorkflowEntryControlSaveModel {Description = "A new Entry"};

                updatedValues.DocumentsDelta.Added.Add(new EntryDocumentDelta {DocumentId = 100});
                updatedValues.DocumentsDelta.Updated.Add(new EntryDocumentDelta {DocumentId = 101, PreviousDocumentId = entryToUpdate.DocumentRequirements.First().DocumentId});

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
                        DocumentRequirements = new List<DocumentRequirement>
                        {
                            new DocumentRequirement {DocumentId = 1, Inherited = 1},
                            new DocumentRequirement {DocumentId = 2, Inherited = 1},
                            new DocumentRequirement {DocumentId = 3}
                        }
                    };

                    _initial = new DataEntryTask(1, 1)
                    {
                        DocumentRequirements = new List<DocumentRequirement>
                        {
                            new DocumentRequirement {DocumentId = 1, Inherited = 1},
                            new DocumentRequirement {DocumentId = 2, Inherited = 1},
                            new DocumentRequirement {DocumentId = 3}
                        }
                    };
                }

                readonly DataEntryTask _entry;
                readonly DataEntryTask _initial;

                [Fact]
                public void ConsidersAddedDocuments()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        DocumentsDelta = new Delta<EntryDocumentDelta>
                        {
                            Added = new List<EntryDocumentDelta> {new EntryDocumentDelta {DocumentId = 100}}
                        }
                    };

                    var f = new EntryDocumentMaintainanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.NotEmpty(fieldToUpdates.DocumentsDelta.Added);
                    Assert.Equal(100, fieldToUpdates.DocumentsDelta.Added.First());
                }

                [Fact]
                public void IgnoreAlreadyPresentDocuments()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        DocumentsDelta = new Delta<EntryDocumentDelta>
                        {
                            Added = new List<EntryDocumentDelta> {new EntryDocumentDelta {DocumentId = 1}}
                        }
                    };

                    var f = new EntryDocumentMaintainanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.Empty(fieldToUpdates.DocumentsDelta.Added);
                }
            }

            public class ForDelete : FactBase
            {
                public ForDelete()
                {
                    _entry = new DataEntryTask(10, 1)
                    {
                        DocumentRequirements = new List<DocumentRequirement>
                        {
                            new DocumentRequirement {DocumentId = 1, Inherited = 1},
                            new DocumentRequirement {DocumentId = 2, Inherited = 1},
                            new DocumentRequirement {DocumentId = 3}
                        }
                    };

                    _initial = new DataEntryTask(1, 1)
                    {
                        DocumentRequirements = new List<DocumentRequirement>
                        {
                            new DocumentRequirement {DocumentId = 1, Inherited = 1},
                            new DocumentRequirement {DocumentId = 2, Inherited = 1},
                            new DocumentRequirement {DocumentId = 3}
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
                        DocumentsDelta = new Delta<EntryDocumentDelta>
                        {
                            Deleted = new List<EntryDocumentDelta> {new EntryDocumentDelta {DocumentId = 1}, new EntryDocumentDelta {DocumentId = 2}}
                        }
                    };

                    var f = new EntryDocumentMaintainanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.NotEmpty(fieldToUpdates.DocumentsDelta.Deleted);
                    Assert.Equal(1, fieldToUpdates.DocumentsDelta.Deleted.First());
                    Assert.Equal(2, fieldToUpdates.DocumentsDelta.Deleted.Last());
                }

                [Fact]
                void IgnoresNonInheritedDocuments()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        DocumentsDelta = new Delta<EntryDocumentDelta>
                        {
                            Deleted = new List<EntryDocumentDelta> {new EntryDocumentDelta {DocumentId = 3}}
                        }
                    };

                    var f = new EntryDocumentMaintainanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.Empty(fieldToUpdates.DocumentsDelta.Deleted);
                }
            }

            public class ForUpdate : FactBase
            {
                public ForUpdate()
                {
                    _entry = new DataEntryTask(10, 1)
                    {
                        DocumentRequirements = new List<DocumentRequirement>
                        {
                            new DocumentRequirement {DocumentId = 1, Inherited = 1},
                            new DocumentRequirement {DocumentId = 2, Inherited = 1},
                            new DocumentRequirement {DocumentId = 3}
                        }
                    };

                    _initial = new DataEntryTask(1, 1)
                    {
                        DocumentRequirements = new List<DocumentRequirement>
                        {
                            new DocumentRequirement {DocumentId = 1, Inherited = 1},
                            new DocumentRequirement {DocumentId = 2, Inherited = 1},
                            new DocumentRequirement {DocumentId = 3}
                        }
                    };
                }

                readonly DataEntryTask _entry;
                readonly DataEntryTask _initial;

                [Fact]
                public void ConsidersDocumentUpdates()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        DocumentsDelta = new Delta<EntryDocumentDelta>
                        {
                            Updated = new List<EntryDocumentDelta> {new EntryDocumentDelta {DocumentId = 100, PreviousDocumentId = 1}}
                        }
                    };

                    var f = new EntryDocumentMaintainanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.NotEmpty(fieldToUpdates.DocumentsDelta.Updated);
                    Assert.Equal(1, fieldToUpdates.DocumentsDelta.Updated.First());
                    Assert.Equal(0, fieldToUpdates.DocumentsRemoveInheritanceFor.Count);
                }

                [Fact]
                public void IgnoresEntryDocumentUpdateIfDocumentAlreadyPresent()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        DocumentsDelta = new Delta<EntryDocumentDelta>
                        {
                            Updated = new List<EntryDocumentDelta> {new EntryDocumentDelta {DocumentId = 3, PreviousDocumentId = 1}}
                        }
                    };

                    var f = new EntryDocumentMaintainanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.Empty(fieldToUpdates.DocumentsDelta.Updated);
                }

                [Fact]
                public void IgnoresNonInheritedDocuments()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        DocumentsDelta = new Delta<EntryDocumentDelta>
                        {
                            Updated = new List<EntryDocumentDelta> {new EntryDocumentDelta {DocumentId = 3}}
                        }
                    };

                    var f = new EntryDocumentMaintainanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.Empty(fieldToUpdates.DocumentsDelta.Updated);
                }

                [Fact]
                public void SetsIdsForWhichInheritanceShouldBeRemoved()
                {
                    var updates = new WorkflowEntryControlSaveModel
                    {
                        DocumentsDelta = new Delta<EntryDocumentDelta>
                        {
                            Updated = new List<EntryDocumentDelta> {new EntryDocumentDelta {DocumentId = 3, PreviousDocumentId = 1}}
                        }
                    };

                    var f = new EntryDocumentMaintainanceFixture(Db);
                    var fieldToUpdates = new EntryControlFieldsToUpdate(_initial, updates);
                    f.Subject.SetDeltaForUpdate(_entry, updates, fieldToUpdates);

                    Assert.Empty(fieldToUpdates.DocumentsDelta.Updated);
                    Assert.Equal(1, fieldToUpdates.DocumentsRemoveInheritanceFor.Count);
                    Assert.Equal(1, fieldToUpdates.DocumentsRemoveInheritanceFor.First());
                }
            }
        }

        public class ApplyChanges
        {
            public class Additions : FactBase
            {
                [Fact]
                public void AppliedToCurrent()
                {
                    var f = new EntryDocumentMaintainanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry"
                    }.BuildWithDocuments(Db, 2).In(Db);

                    var doc1 = entryToUpdate.DocumentRequirements.First();
                    var doc2 = entryToUpdate.DocumentRequirements.Last();

                    var newDoc3 = new Document(100, "new Doc 3", 0).In(Db);
                    var newDoc4 = new Document(101, "new Doc 4", 0).In(Db);

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        CriteriaId = criteria.Id,
                        Description = "A new Entry"
                    };
                    updatedValues.DocumentsDelta.Added.Add(new EntryDocumentDelta {DocumentId = newDoc3.Id, MustProduce = true});
                    updatedValues.DocumentsDelta.Added.Add(new EntryDocumentDelta {DocumentId = newDoc4.Id});

                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToUpdate, updatedValues) {DocumentsDelta = {Added = new List<short> {newDoc3.Id, newDoc4.Id}}};

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, fieldsToupdate);
                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                    var entryDocuments = updatedEntry.DocumentRequirements.OrderBy(_ => _.DocumentId).ToArray();

                    Assert.Equal(4, entryDocuments.Length);
                    Assert.Equal(doc1.DocumentId, entryDocuments[0].DocumentId);

                    Assert.Equal(doc2.DocumentId, entryDocuments[1].DocumentId);

                    Assert.Equal(newDoc3.Id, entryDocuments[2].DocumentId);
                    Assert.False(entryDocuments[2].IsInherited);
                    Assert.True(entryDocuments[2].IsMandatory);

                    Assert.Equal(newDoc4.Id, entryDocuments[3].DocumentId);
                    Assert.False(entryDocuments[3].IsInherited);
                    Assert.False(entryDocuments[3].IsMandatory);
                }

                [Fact]
                public void InheritanceFlagIsSetIfResettingEntry()
                {
                    var f = new EntryDocumentMaintainanceFixture(Db);

                    var newDoc = new Document(100, "new Doc", 0).In(Db);

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
                    saveModel.DocumentsDelta.Added.Add(new EntryDocumentDelta {DocumentId = newDoc.Id, MustProduce = true});

                    f.Subject.ApplyChanges(entryToUpdate, saveModel, new EntryControlFieldsToUpdate(entryToUpdate, saveModel));

                    Assert.True(entryToUpdate.DocumentRequirements.Single().IsInherited);
                }

                [Fact]
                public void InheritanceFlagIsSetIfUpdatingChildEntries()
                {
                    var f = new EntryDocumentMaintainanceFixture(Db);

                    var newDoc = new Document(100, "new Doc", 0).In(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry"
                    }.BuildWithDocuments(Db, 2).In(Db);
                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 110,
                        CriteriaId = 10,
                        Description = "A new Entry"
                    };
                    updatedValues.DocumentsDelta.Added.Add(new EntryDocumentDelta {DocumentId = newDoc.Id, MustProduce = true});

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, new EntryControlFieldsToUpdate(entryToUpdate, updatedValues));
                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                    var entryEvents = updatedEntry.DocumentRequirements.OrderBy(_ => _.DocumentId).ToArray();

                    Assert.Equal(newDoc.Id, entryEvents[2].DocumentId);
                    Assert.True(entryEvents[2].IsMandatory);
                    Assert.Equal(1, entryEvents[2].Inherited);
                }

                [Fact]
                public void NotAppliedIfDocumentExistsAlready()
                {
                    var f = new EntryDocumentMaintainanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry"
                    }.BuildWithDocuments(Db, 2).In(Db);
                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var doc1 = entryToUpdate.DocumentRequirements.First();
                    var doc2 = entryToUpdate.DocumentRequirements.Last();

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        CriteriaId = criteria.Id,
                        Description = "A new Entry"
                    };
                    updatedValues.DocumentsDelta.Added.Add(new EntryDocumentDelta {DocumentId = doc1.DocumentId, MustProduce = true});

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, new EntryControlFieldsToUpdate(entryToUpdate, updatedValues));
                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                    var entryDocuments = updatedEntry.DocumentRequirements.OrderBy(_ => _.DocumentId).ToArray();

                    Assert.Equal(doc1.DocumentId, entryDocuments[0].DocumentId);
                    Assert.Equal(doc1.IsMandatory, entryDocuments[0].IsMandatory);
                    Assert.Equal(doc2.DocumentId, entryDocuments[1].DocumentId);
                }
            }

            public class Updations : FactBase
            {
                [Fact]
                public void InheritanceRemovedIfUpdateCanNotApply()
                {
                    var f = new EntryDocumentMaintainanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithDocuments(Db, 3).In(Db);

                    var doc1 = entryToUpdate.DocumentRequirements.ElementAt(0);
                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = entryToUpdate.Id,
                        CriteriaId = 100
                    };

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToUpdate, updatedValues)
                    {
                        DocumentsRemoveInheritanceFor = new List<short> {doc1.DocumentId}
                    };

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, fieldsToupdate);

                    var entryDocuments = Db.Set<DataEntryTask>()
                                           .Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId)
                                           .DocumentRequirements
                                           .OrderBy(_ => _.DocumentId).ToArray();

                    Assert.Equal(3, entryDocuments.Length);

                    Assert.Equal(doc1.DocumentId, entryDocuments[0].DocumentId);
                    Assert.False(entryDocuments[0].IsInherited);
                }

                [Fact]
                public void TurnsOnInheritanceWhenResetting()
                {
                    var f = new EntryDocumentMaintainanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "An Entry",
                        Inherited = 1
                    }.BuildWithDocuments(Db, 2).In(Db);
                    var doc1 = entryToUpdate.DocumentRequirements.ElementAt(0);
                    var doc2 = entryToUpdate.DocumentRequirements.ElementAt(0);
                    doc1.Inherited = 0;
                    doc2.Inherited = 0;

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        CriteriaId = criteria.Id,
                        ResetInheritance = true,
                        DocumentsDelta =
                        {
                            Updated = new List<EntryDocumentDelta>
                            {
                                new EntryDocumentDelta {DocumentId = doc1.DocumentId, PreviousDocumentId = doc1.DocumentId},
                                new EntryDocumentDelta {DocumentId = doc2.DocumentId, PreviousDocumentId = doc1.DocumentId}
                            }
                        }
                    };

                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToUpdate, updatedValues)
                    {
                        DocumentsDelta = {Updated = new List<short> {doc1.DocumentId, doc2.DocumentId}}
                    };

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, fieldsToupdate);

                    Assert.True(doc1.IsInherited);
                    Assert.True(doc2.IsInherited);
                }

                [Fact]
                public void UpdatesAppliedToCurrent()
                {
                    var f = new EntryDocumentMaintainanceFixture(Db);
                    var newDoc3 = new Document(100, "new Doc 3", 0).In(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithDocuments(Db, 3).In(Db);

                    var doc1 = entryToUpdate.DocumentRequirements.ElementAt(0);
                    var doc2 = entryToUpdate.DocumentRequirements.ElementAt(1);

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        CriteriaId = criteria.Id,
                        DocumentsDelta =
                        {
                            Updated = new List<EntryDocumentDelta>
                            {
                                new EntryDocumentDelta {DocumentId = newDoc3.Id, PreviousDocumentId = doc1.DocumentId},
                                new EntryDocumentDelta {DocumentId = doc2.DocumentId, MustProduce = true, PreviousDocumentId = doc2.DocumentId}
                            }
                        }
                    };

                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToUpdate, updatedValues)
                    {
                        DocumentsDelta = {Updated = new List<short> {doc1.DocumentId, doc2.DocumentId}}
                    };

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, fieldsToupdate);

                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                    var entryDocuments = updatedEntry.DocumentRequirements.OrderBy(_ => _.DocumentId).ToArray();

                    Assert.Equal(3, entryDocuments.Length);

                    var doc = entryDocuments.Single(_ => _.DocumentId == newDoc3.Id);
                    Assert.False(doc.IsInherited);
                    Assert.False(doc.IsMandatory);

                    doc = entryDocuments.Single(_ => _.DocumentId == doc2.DocumentId);
                    Assert.False(doc.IsInherited);
                    Assert.True(doc.IsMandatory);

                    Assert.Null(entryDocuments.FirstOrDefault(_ => _.DocumentId == doc1.DocumentId));
                }
            }

            public class Deletions : FactBase
            {
                [Fact]
                public void DeletedAppliedToCurrent()
                {
                    var f = new EntryDocumentMaintainanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToChange = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithDocuments(Db, 3).In(Db);

                    var doc1 = entryToChange.DocumentRequirements.ElementAt(0);
                    var docToDelete = entryToChange.DocumentRequirements.ElementAt(1);
                    var doc2 = entryToChange.DocumentRequirements.ElementAt(2);

                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToChange};

                    var deltaValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        CriteriaId = criteria.Id
                    };

                    deltaValues.DocumentsDelta.Deleted.Add(new EntryDocumentDelta
                    {
                        DocumentId = docToDelete.DocumentId
                    });

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToChange, deltaValues);

                    f.Subject.ApplyChanges(entryToChange, deltaValues, fieldsToupdate);

                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToChange.Id && _.CriteriaId == entryToChange.CriteriaId);
                    var entryDocuments = updatedEntry.DocumentRequirements.OrderBy(_ => _.DocumentId).ToArray();

                    Assert.Equal(2, entryDocuments.Length);

                    Assert.Equal(doc1.DocumentId, entryDocuments[0].DocumentId);
                    Assert.True(entryDocuments[0].IsInherited);

                    Assert.Equal(doc2.DocumentId, entryDocuments[1].DocumentId);
                    Assert.True(entryDocuments[1].IsInherited);
                }

                [Fact]
                public void InheritanceRemovedForEntryEventIfDeleteNoPropogated()
                {
                    var f = new EntryDocumentMaintainanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToChange = new DataEntryTaskBuilder(criteria, 1)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithDocuments(Db, 3).In(Db);

                    var childCritera = new Criteria {ParentCriteriaId = criteria.Id}.In(Db);
                    var childEntry = new DataEntryTaskBuilder(childCritera, 1)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.Build().In(Db);
                    childEntry.DocumentRequirements.Add(new DocumentRequirementBuilder
                    {
                        Criteria = childEntry.Criteria,
                        DataEntryTask = childEntry,
                        Inherited = childEntry.Inherited,
                        Document = entryToChange.DocumentRequirements.ElementAt(0).Document
                    }.Build().In(Db));
                    childEntry.DocumentRequirements.Add(new DocumentRequirementBuilder
                    {
                        Criteria = childEntry.Criteria,
                        DataEntryTask = childEntry,
                        Inherited = childEntry.Inherited,
                        Document = entryToChange.DocumentRequirements.ElementAt(1).Document
                    }.Build().In(Db));
                    childEntry.DocumentRequirements.Add(new DocumentRequirementBuilder
                    {
                        Criteria = childEntry.Criteria,
                        DataEntryTask = childEntry,
                        Inherited = childEntry.Inherited,
                        Document = entryToChange.DocumentRequirements.ElementAt(2).Document
                    }.Build().In(Db));

                    var doc1 = childEntry.DocumentRequirements.ElementAt(0);
                    var doc2 = childEntry.DocumentRequirements.ElementAt(1);

                    childCritera.DataEntryTasks = new List<DataEntryTask> {childEntry};

                    var deltaValues = new WorkflowEntryControlSaveModel();
                    deltaValues.DocumentsDelta.Deleted.Add(new EntryDocumentDelta {DocumentId = doc2.DocumentId});

                    f.Subject.RemoveInheritance(childEntry, new EntryControlFieldsToUpdate(entryToChange, deltaValues));

                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == childEntry.Id && _.CriteriaId == childEntry.CriteriaId);
                    var entryDocuments = updatedEntry.DocumentRequirements.OrderBy(_ => _.DocumentId).ToArray();

                    Assert.Equal(3, entryDocuments.Length);

                    Assert.Equal(doc2.DocumentId, entryDocuments[1].DocumentId);
                    Assert.False(entryDocuments[1].IsInherited);
                }
            }

            public class ComplexScenarios : FactBase
            {
                [Fact]
                public void UpdatesAreAppliedBeforeAddition()
                {
                    var f = new EntryDocumentMaintainanceFixture(Db);

                    var criteria = new Criteria().In(Db);
                    var entryToUpdate = new DataEntryTaskBuilder(criteria)
                    {
                        Description = "A new Entry",
                        Inherited = 1
                    }.BuildWithDocuments(Db, 3).In(Db);

                    var doc1 = entryToUpdate.DocumentRequirements.ElementAt(0);
                    var doc2 = entryToUpdate.DocumentRequirements.ElementAt(1);
                    var doc3 = entryToUpdate.DocumentRequirements.ElementAt(2);

                    var documentAdded = new Document(100, "new Doc 3", 0).In(Db);

                    var updatedValues = new WorkflowEntryControlSaveModel
                    {
                        Id = 1,
                        CriteriaId = criteria.Id
                    };

                    updatedValues.DocumentsDelta.Updated.Add(new EntryDocumentDelta {DocumentId = doc2.DocumentId, PreviousDocumentId = doc1.DocumentId});
                    updatedValues.DocumentsDelta.Added.Add(new EntryDocumentDelta {DocumentId = documentAdded.Id, MustProduce = true});

                    criteria.DataEntryTasks = new List<DataEntryTask> {entryToUpdate};

                    var fieldsToupdate = new EntryControlFieldsToUpdate(entryToUpdate, updatedValues)
                    {
                        DocumentsDelta =
                        {
                            Updated = new List<short> {doc2.DocumentId},
                            Added = new List<short> {documentAdded.Id}
                        }
                    };

                    f.Subject.ApplyChanges(entryToUpdate, updatedValues, fieldsToupdate);

                    var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                    var entryEvents = updatedEntry.DocumentRequirements.OrderBy(_ => _.DocumentId).ToArray();

                    Assert.Equal(4, entryEvents.Length);

                    Assert.Equal(doc1.DocumentId, entryEvents[0].DocumentId);
                    Assert.Equal(doc2.DocumentId, entryEvents[1].DocumentId);
                    Assert.Equal(doc3.DocumentId, entryEvents[2].DocumentId);
                    Assert.Equal(documentAdded.Id, entryEvents[3].DocumentId);
                    Assert.True(entryEvents[3].IsMandatory);
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
                    CriteriaId = 100
                };

                updatedValues.EntryEventDelta.Updated = new List<EntryEventDelta>
                {
                    new EntryEventDelta {EventId = kiwi.Id, PreviousEventId = apple.EventId},
                    new EntryEventDelta {EventId = banana.EventId, PreviousEventId = banana.EventId, PolicingAttribute = 1}
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

        public class Reset : FactBase
        {
            [Fact]
            public void AddsDocumentsFromParent()
            {
                var f = new EntryDocumentMaintainanceFixture(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder(criteria, 1)
                {
                    Description = "Parent Entry"
                }.BuildWithDocuments(Db, 2).In(Db);
                criteria.DataEntryTasks.Add(parentEntry);
                var doc1 = parentEntry.DocumentRequirements.ElementAt(0);
                var doc2 = parentEntry.DocumentRequirements.ElementAt(1);

                var childEntry = new DataEntryTaskBuilder(criteriaChild1, 1)
                {
                    Description = "Child Entry",
                    ParentCriteriaId = criteria.Id,
                    ParentEntryId = parentEntry.Id
                }.Build().In(Db);
                criteriaChild1.DataEntryTasks.Add(childEntry);

                var saveModel = new WorkflowEntryControlSaveModel();
                f.Subject.Reset(childEntry, parentEntry, saveModel);

                // Reset should add 2 documents in the parent that weren't in the child
                Assert.Equal(2, saveModel.DocumentsDelta.Added.Count);
                Assert.Empty(saveModel.DocumentsDelta.Updated);
                Assert.Empty(saveModel.DocumentsDelta.Deleted);

                var doc1Model = saveModel.DocumentsDelta.Added.SingleOrDefault(d => d.DocumentId == doc1.DocumentId);
                var doc2Model = saveModel.DocumentsDelta.Added.SingleOrDefault(d => d.DocumentId == doc2.DocumentId);
                Assert.NotNull(doc1Model);
                Assert.NotNull(doc2Model);
                Assert.Equal(doc1.IsMandatory, doc1Model.MustProduce);
                Assert.Equal(doc2.IsMandatory, doc2Model.MustProduce);
            }

            [Fact]
            public void DeletesDocumentsNotInParent()
            {
                var f = new EntryDocumentMaintainanceFixture(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder(criteria, 1)
                {
                    Description = "Parent Entry"
                }.BuildWithDocuments(Db, 1).In(Db);
                criteria.DataEntryTasks.Add(parentEntry);

                var childEntry = new DataEntryTaskBuilder(criteriaChild1, 1)
                {
                    Description = "Child Entry",
                    ParentCriteriaId = criteria.Id,
                    ParentEntryId = parentEntry.Id
                }.BuildWithDocuments(Db, 4).In(Db);
                criteriaChild1.DataEntryTasks.Add(childEntry);
                var docId1 = childEntry.DocumentRequirements.ElementAt(0).DocumentId;
                var docId2 = childEntry.DocumentRequirements.ElementAt(1).DocumentId;
                var docId3 = childEntry.DocumentRequirements.ElementAt(2).DocumentId;
                var updateDoc = childEntry.DocumentRequirements.ElementAt(3);
                updateDoc.DocumentId = parentEntry.DocumentRequirements.First().DocumentId;

                var saveModel = new WorkflowEntryControlSaveModel();
                f.Subject.Reset(childEntry, parentEntry, saveModel);

                // Reset should delete 3 documents in child not matching in the parent
                Assert.Equal(3, saveModel.DocumentsDelta.Deleted.Count);
                Assert.Empty(saveModel.DocumentsDelta.Added);
                Assert.Equal(1, saveModel.DocumentsDelta.Updated.Count);

                Assert.NotNull(saveModel.DocumentsDelta.Deleted.SingleOrDefault(d => d.DocumentId == docId1));
                Assert.NotNull(saveModel.DocumentsDelta.Deleted.SingleOrDefault(d => d.DocumentId == docId2));
                Assert.NotNull(saveModel.DocumentsDelta.Deleted.SingleOrDefault(d => d.DocumentId == docId3));

                Assert.NotNull(saveModel.DocumentsDelta.Updated.SingleOrDefault(d => d.DocumentId == updateDoc.DocumentId));
            }

            [Fact]
            public void UpdatesDocumentsFromParentWithSameDocumentId()
            {
                var f = new EntryDocumentMaintainanceFixture(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder(criteria, 1)
                {
                    Description = "Parent Entry"
                }.BuildWithDocuments(Db, 2).In(Db);
                criteria.DataEntryTasks.Add(parentEntry);
                var doc1 = parentEntry.DocumentRequirements.ElementAt(0);

                var childEntry = new DataEntryTaskBuilder(criteriaChild1, 1)
                {
                    Description = "Child Entry",
                    ParentCriteriaId = criteria.Id,
                    ParentEntryId = parentEntry.Id
                }.BuildWithDocuments(Db, 1).In(Db);
                criteriaChild1.DataEntryTasks.Add(childEntry);
                childEntry.DocumentRequirements.First().DocumentId = doc1.DocumentId;
                childEntry.DocumentRequirements.First().InternalMandatoryFlag = doc1.IsMandatory ? 0 : 1;

                var saveModel = new WorkflowEntryControlSaveModel();
                f.Subject.Reset(childEntry, parentEntry, saveModel);

                // Reset should add 1 document in the parent that weren't in the child
                Assert.Equal(1, saveModel.DocumentsDelta.Added.Count);
                Assert.Empty(saveModel.DocumentsDelta.Deleted);

                // Reset should update 1 document that matches in the child
                var docModel = saveModel.DocumentsDelta.Updated.SingleOrDefault(d => d.DocumentId == doc1.DocumentId);
                Assert.NotNull(docModel);
                Assert.Equal(doc1.IsMandatory, docModel.MustProduce);
                Assert.Equal(doc1.DocumentId, docModel.PreviousDocumentId);
            }
        }
    }

    public class EntryDocumentMaintainanceFixture : IFixture<EntryDocumentMaintainance>
    {
        public EntryDocumentMaintainanceFixture(InMemoryDbContext db)
        {
            DbContext = db;

            Subject = new EntryDocumentMaintainance(DbContext);
        }

        public IDbContext DbContext { get; }

        public EntryDocumentMaintainance Subject { get; }
    }
}