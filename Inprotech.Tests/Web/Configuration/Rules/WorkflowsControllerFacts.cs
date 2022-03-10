using System;
using System.Collections.Generic;
using System.Linq;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;
using ICharacteristicsValidator = Inprotech.Web.Configuration.Rules.ICharacteristicsValidator;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowsControllerFacts
    {
        public class GetWorkflowMethod : FactBase
        {
            [Fact]
            public void ReturnHasOfficesFalse()
            {
                new CriteriaBuilder {Id = 123}.ForEventsEntriesRule().Build().In(Db);
                var f = new WorkflowsControllerFixture(Db);

                var r = f.Subject.GetWorkflow(123);
                Assert.False(r.HasOffices);
            }

            [Fact]
            public void ReturnHasOfficesTrue()
            {
                new Office().In(Db);
                new CriteriaBuilder {Id = 123}.ForEventsEntriesRule().Build().In(Db);

                var f = new WorkflowsControllerFixture(Db);

                var r = f.Subject.GetWorkflow(123);
                Assert.True(r.HasOffices);
            }

            [Fact]
            public void ReturnsCriteriaDetails()
            {
                var criteria = new CriteriaBuilder {Id = 123, Description = "abc"}.ForEventsEntriesRule().Build().In(Db);
                new InheritsBuilder(new CriteriaBuilder().Build(), criteria).Build().In(Db);

                var f = new WorkflowsControllerFixture(Db);
                f.PermissionHelper.CanEdit(criteria).Returns(true);
                f.PermissionHelper.CanEditProtected().Returns(true);

                var r = f.Subject.GetWorkflow(123);

                Assert.Equal(123, r.CriteriaId);
                Assert.Equal("abc", r.CriteriaName);
                Assert.Equal(false, r.IsProtected);
                Assert.Equal(true, r.IsInherited);
                Assert.True(r.CanEdit);
                Assert.True(r.CanEditProtected);
            }

            [Fact]
            public void ReturnsCriteriaWhichIsHighestParent()
            {
                var criteria = new CriteriaBuilder {Id = 123, Description = "abc"}.ForEventsEntriesRule().Build().In(Db);
                new InheritsBuilder(criteria, new CriteriaBuilder().Build()).Build().In(Db);

                var f = new WorkflowsControllerFixture(Db);
                var r = f.Subject.GetWorkflow(123);

                Assert.True(r.IsHighestParent);
            }

            [Fact]
            public void ReturnsCriteriaWhichIsNotHighestParent()
            {
                var childCriteria = new CriteriaBuilder {Id = 123, Description = "abc"}.ForEventsEntriesRule().Build().In(Db);
                var criteria = new CriteriaBuilder {Id = 456, Description = "def"}.ForEventsEntriesRule().Build().In(Db);
                var parentCriteria = new CriteriaBuilder {Id = 789, Description = "hij"}.ForEventsEntriesRule().Build().In(Db);
                new InheritsBuilder(criteria, childCriteria).Build().In(Db);
                new InheritsBuilder(parentCriteria, criteria).Build().In(Db);

                var f = new WorkflowsControllerFixture(Db);

                var r = f.Subject.GetWorkflow(789);
                Assert.True(r.IsHighestParent);
            }

            [Fact]
            public void ReturnsPermissionRestrictionInformation()
            {
                var criteria = new CriteriaBuilder {Id = 123, Description = "abc"}.ForEventsEntriesRule().Build().In(Db);
                new InheritsBuilder(new CriteriaBuilder().Build(), criteria).Build().In(Db);

                var f = new WorkflowsControllerFixture(Db);

                bool isEditBlockedByDescendants;
                f.PermissionHelper.CanEdit(criteria, out isEditBlockedByDescendants)
                 .ReturnsForAnyArgs(_ =>
                 {
                     _[1] = true;
                     return false;
                 });

                var r = f.Subject.GetWorkflow(123);

                Assert.False(r.CanEdit);
                Assert.True(r.EditBlockedByDescendants);
            }
        }

        public class UpdateWorkflowMethod : FactBase
        {
            [Fact]
            public void ChecksMandatoryFields()
            {
                var f = new WorkflowsControllerFixture(Db);

                var c = new CriteriaBuilder().Build().In(Db);
                f.CharacteristicsValidator.Validate(null).ReturnsForAnyArgs(new ValidatedCharacteristics());

                var e = Record.Exception(() => f.Subject.UpdateWorkflow(c.Id, new WorkflowSaveModel {CriteriaName = " "}));
                Assert.NotNull(e);
            }

            [Fact]
            public void ChecksValidCombination()
            {
                var f = new WorkflowsControllerFixture(Db);

                var c = new CriteriaBuilder().Build().In(Db);
                f.CharacteristicsValidator.Validate(null)
                 .ReturnsForAnyArgs(new ValidatedCharacteristics
                 {
                     CaseType = new ValidatedCharacteristic(isValid: false)
                 });

                var e = Record.Exception(() => f.Subject.UpdateWorkflow(c.Id, new WorkflowSaveModel()));
                Assert.NotNull(e);
            }

            [Fact]
            public void CreateCriteria()
            {
                var f = new WorkflowsControllerFixture(Db);
                f.CharacteristicsValidator.Validate(null).ReturnsForAnyArgs(new ValidatedCharacteristics());

                var office = new OfficeBuilder().Build().In(Db).Id;
                var caseType = new CaseTypeBuilder().Build().In(Db).Code;
                var jurisdiction = new CountryBuilder().Build().In(Db).Id;
                var propertyType = new PropertyTypeBuilder().Build().In(Db).Code;
                var caseCategory = new CaseCategoryBuilder().Build().In(Db).CaseCategoryId;
                var subType = new SubTypeBuilder().Build().In(Db).Code;
                var basis = new ApplicationBasisBuilder().Build().In(Db).Code;
                var action = new ActionBuilder().Build().In(Db).Code;
                var dateOfLaw = new DateOfLawBuilder().Build().In(Db).Date;

                var formData = new WorkflowSaveModel
                {
                    CriteriaName = "ABC",
                    IsProtected = true,
                    IsLocalClient = true,
                    Office = office,
                    CaseType = caseType,
                    Jurisdiction = jurisdiction,
                    PropertyType = propertyType,
                    CaseCategory = caseCategory,
                    SubType = subType,
                    Basis = basis,
                    Action = action,
                    DateOfLaw = dateOfLaw.ToString("yyyy-MM-dd")
                };

                f.Subject.CreateWorkflow(formData);

                f.WorkflowMaintenanceService.Received(1).CreateWorkflow(formData);
            }

            [Fact]
            public void UpdatesCriteria()
            {
                var f = new WorkflowsControllerFixture(Db);

                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                f.CharacteristicsValidator.Validate(null).ReturnsForAnyArgs(new ValidatedCharacteristics());

                var office = new OfficeBuilder().Build().In(Db).Id;
                var caseType = new CaseTypeBuilder().Build().In(Db).Code;
                var jurisdiction = new CountryBuilder().Build().In(Db).Id;
                var propertyType = new PropertyTypeBuilder().Build().In(Db).Code;
                var caseCategory = new CaseCategoryBuilder().Build().In(Db).CaseCategoryId;
                var subType = new SubTypeBuilder().Build().In(Db).Code;
                var basis = new ApplicationBasisBuilder().Build().In(Db).Code;
                var action = new ActionBuilder().Build().In(Db).Code;
                var dateOfLaw = new DateOfLawBuilder().Build().In(Db).Date;

                var formData = new WorkflowSaveModel
                {
                    Id = c.Id,
                    CriteriaName = "ABC",
                    IsProtected = true,
                    IsLocalClient = true,
                    Office = office,
                    CaseType = caseType,
                    Jurisdiction = jurisdiction,
                    PropertyType = propertyType,
                    CaseCategory = caseCategory,
                    SubType = subType,
                    Basis = basis,
                    Action = action,
                    DateOfLaw = dateOfLaw.ToString("yyyy-MM-dd")
                };

                f.Subject.UpdateWorkflow(c.Id, formData);

                f.PermissionHelper.Received(1).EnsureEditPermission(c.Id);
                f.WorkflowMaintenanceService.Received(1).UpdateWorkflow(c.Id, formData);
            }
        }

        public class GetEventsMethod : FactBase
        {
            [Fact]
            public void ReturnEventControlDataFilterByImportanceLevel()
            {
                var f = new WorkflowsControllerFixture(Db);

                var criteria = new Criteria {Id = -123}.In(Db);
                var ve =
                    new ValidEventBuilder {Criteria = criteria, Description = Fixture.String(), DisplaySequence = 0, ImportanceLevel = "1"}
                        .Build().In(Db);
                var ve2 =
                    new ValidEventBuilder {Criteria = criteria, Description = Fixture.String() + "Important", DisplaySequence = 0, ImportanceLevel = "9"}
                        .Build().In(Db);

                f.Inheritance.GetEventRulesWithInheritanceLevel(criteria.Id).Returns(new[] {ve, ve2});

                var result = f.Subject.GetEvents(criteria.Id, new CommonQueryParameters
                {
                    Skip = 0,
                    Take = 10,
                    Filters = new[] {new CommonQueryParameters.FilterValue {Field = "importanceLevel", Operator = "in", Type = null, Value = "9"}}
                });
                var r = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.True(r.Length == 1, "Expect one return result after the filtering");
                Assert.Equal(r[0].EventNo, ve2.EventId);
                Assert.Equal(r[0].ImportanceLevel, ve2.ImportanceLevel);
            }

            [Fact]
            public void ReturnsEventControlData()
            {
                var f = new WorkflowsControllerFixture(Db);

                var criteria = new Criteria {Id = -123}.In(Db);
                var ve =
                    new ValidEventBuilder {Criteria = criteria, Description = Fixture.String(), DisplaySequence = 0}
                        .Build().In(Db);

                f.Inheritance.GetEventRulesWithInheritanceLevel(criteria.Id).Returns(new[] {ve});

                var result = f.Subject.GetEvents(criteria.Id, new CommonQueryParameters {Skip = 0, Take = 10});
                var r = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(r[0].EventNo, ve.EventId);
                Assert.Equal(r[0].Description, ve.Description);
                Assert.Equal(r[0].EventCode, ve.Event.Code);
                Assert.Equal(r[0].DisplaySequence, ve.DisplaySequence);
                Assert.Equal(r[0].Importance, ve.Importance.Description);
                Assert.Equal(r[0].ImportanceLevel, ve.ImportanceLevel);
                Assert.Equal(r[0].MaxCycles, ve.NumberOfCyclesAllowed);
            }

            [Fact]
            public void ReturnsEventsOrderedByDisplaySequence()
            {
                var f = new WorkflowsControllerFixture(Db);

                var criteria = new Criteria {Id = -123, UserDefinedRule = 0}.In(Db);

                var ve1 = new ValidEventBuilder {Criteria = criteria, DisplaySequence = 1}.Build().In(Db);
                var ve2 = new ValidEventBuilder {Criteria = criteria, DisplaySequence = 3}.Build().In(Db);
                var ve3 = new ValidEventBuilder {Criteria = criteria, DisplaySequence = 0}.Build().In(Db);

                f.Inheritance.GetEventRulesWithInheritanceLevel(criteria.Id).Returns(new[] {ve1, ve2, ve3});

                var result = f.Subject.GetEvents(criteria.Id, new CommonQueryParameters {Skip = 0, Take = 10});
                var r = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.NotEqual(ve1.EventId, ve2.EventId);
                Assert.NotEqual(ve1.EventId, ve3.EventId);
                Assert.Equal(r[0].EventNo, ve3.EventId);
                Assert.Equal(r[1].EventNo, ve1.EventId);
                Assert.Equal(r[2].EventNo, ve2.EventId);
            }

            [Fact]
            public void SkipsAndTakesAndReturnsTotal()
            {
                var f = new WorkflowsControllerFixture(Db);
                var criteria = new Criteria {Id = -123, UserDefinedRule = 0}.In(Db);

                var validEvents = new List<ValidEvent>();
                for (var i = 0; i <= 15; i++) validEvents.Add(new ValidEventBuilder {DisplaySequence = (short) i}.For(criteria, new Event(i)).Build());

                f.Inheritance.GetEventRulesWithInheritanceLevel(criteria.Id).Returns(validEvents);

                var result = f.Subject.GetEvents(criteria.Id, new CommonQueryParameters {Skip = 5, Take = 10});
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(10, results.Count());
                Assert.Equal(5, results[0].DisplaySequence);

                Assert.Equal(16, result.Pagination.Total);
            }
        }

        public class GetEntriesMethod : FactBase
        {
            [Fact]
            public void ReturnsDetailControlData()
            {
                var f = new WorkflowsControllerFixture(Db);

                var criteria = new Criteria {Id = -123}.In(Db);
                var det =
                    new DataEntryTaskBuilder {Criteria = criteria, Description = Fixture.String(), DisplaySequence = 0}
                        .Build().In(Db);

                f.Inheritance.GetEntriesWithInheritanceLevel(criteria.Id).Returns(new[] {det});

                var result = f.Subject.GetEntries(criteria.Id, null);
                var r = ((IEnumerable<dynamic>) result).ToArray();

                Assert.Equal(r[0].EntryNo, det.Id);
                Assert.Equal(r[0].Description, det.Description);
                Assert.Equal(r[0].DisplaySequence, det.DisplaySequence);
                Assert.False(r[0].IsSeparator);
            }

            [Fact]
            public void ReturnsEntriesOrderedByDisplaySequence()
            {
                var f = new WorkflowsControllerFixture(Db);

                var criteria = new Criteria {Id = -123, UserDefinedRule = 0}.In(Db);

                var det1 = new DataEntryTaskBuilder {Criteria = criteria, EntryNumber = Fixture.Short(), DisplaySequence = 1}.Build().In(Db);
                var det2 = new DataEntryTaskBuilder {Criteria = criteria, EntryNumber = Fixture.Short(), DisplaySequence = 3}.Build().In(Db);
                var det3 = new DataEntryTaskBuilder {Criteria = criteria, EntryNumber = Fixture.Short(), DisplaySequence = 0}.Build().In(Db);

                f.Inheritance.GetEntriesWithInheritanceLevel(criteria.Id).Returns(new[] {det1, det2, det3});
                var result = f.Subject.GetEntries(criteria.Id, null);
                var r = ((IEnumerable<dynamic>) result).ToArray();

                Assert.NotEqual(det1.Id, det2.Id);
                Assert.NotEqual(det1.Id, det3.Id);
                Assert.Equal(r[0].EntryNo, det3.Id);
                Assert.Equal(r[1].EntryNo, det1.Id);
                Assert.Equal(r[2].EntryNo, det2.Id);
            }
        }

        public class GetFilterDataForColumnMethod : FactBase
        {
            [Fact]
            public void ReturnsDistinctImportanceLevelsInDescendingOrder()
            {
                var f = new WorkflowsControllerFixture(Db);

                var criteria = new Criteria {Id = -123, UserDefinedRule = 0}.In(Db);
                var duplicateImportance = new ImportanceBuilder {ImportanceLevel = "8"}.Build().In(Db);
                var ve1 =
                    new ValidEventBuilder
                    {
                        Criteria = criteria,
                        DisplaySequence = 1,
                        Importance = new ImportanceBuilder {ImportanceLevel = "9"}.Build()
                    }.Build().In(Db);
                var ve2 =
                    new ValidEventBuilder
                    {
                        Criteria = criteria,
                        DisplaySequence = 3,
                        Importance = duplicateImportance
                    }.Build().In(Db);
                var ve3 =
                    new ValidEventBuilder
                    {
                        Criteria = criteria,
                        DisplaySequence = 0,
                        Importance = new ImportanceBuilder {ImportanceLevel = "7"}.Build()
                    }.Build().In(Db);
                new ValidEventBuilder
                {
                    Criteria = criteria,
                    DisplaySequence = 4,
                    Importance = duplicateImportance
                }.Build().In(Db);

                f.Inheritance.GetEventRulesWithInheritanceLevel(criteria.Id).Returns(new[] {ve1, ve2, ve3});

                var result = f.Subject.GetFilterDataForColumn(criteria.Id, "importance");
                var r = ((IEnumerable<dynamic>) result).ToArray();

                Assert.Equal(3, r.Count());
                Assert.Equal(r[0].Code, ve1.Importance.Level);
                Assert.Equal(r[0].Description, ve1.Importance.Description);
                Assert.Equal(r[1].Code, ve2.Importance.Level);
                Assert.Equal(r[1].Description, ve2.Importance.Description);
                Assert.Equal(r[2].Code, ve3.Importance.Level);
                Assert.Equal(r[2].Description, ve3.Importance.Description);
            }
        }

        public class SearchForEventsReferencedInMethod : FactBase
        {
            [Fact]
            public void CallsSearchWithCorrectParameters()
            {
                var criteriaId = Fixture.Integer();
                var eventId = Fixture.Integer();

                var f = new WorkflowsControllerFixture(Db);

                f.Subject.SearchForEventsReferencedIn(criteriaId, eventId);

                f.WorkflowSearch.Received(1).SearchForEventReferencedInCriteria(criteriaId, eventId);
            }
        }

        public class SearchForEntryEventsReferencedInMethod : FactBase
        {
            [Fact]
            public void ReturnsEntriesReferencedByEntryOrUpdateEvent()
            {
                var criteria = new CriteriaBuilder().Build();
                var referencedEventId = Fixture.Integer();
                var dataEntryTask1 = DataEntryTaskBuilder.ForCriteria(criteria).Build();
                dataEntryTask1.DisplayEventNo = referencedEventId;
                dataEntryTask1.In(Db);

                var dataEntryTask2 = DataEntryTaskBuilder.ForCriteria(criteria).Build();
                var availableEvent = new AvailableEvent(dataEntryTask2, new EventBuilder().Build().WithKnownId(referencedEventId));
                dataEntryTask2.AvailableEvents.Add(availableEvent);
                dataEntryTask2.In(Db);

                var f = new WorkflowsControllerFixture(Db);

                var result = f.Subject.SearchForEntryEventsReferencedIn(dataEntryTask2.Criteria.Id, referencedEventId).ToArray();
                Assert.NotEqual(dataEntryTask1.Id, dataEntryTask2.Id);
                Assert.Contains(dataEntryTask1.Id, result);
                Assert.Contains(dataEntryTask2.Id, result);
            }

            [Fact]
            public void ReturnsEntriesReferencedByUpdateEvent()
            {
                var dataEntryTask = new DataEntryTaskBuilder().Build();
                var availableEvent = new AvailableEvent(dataEntryTask, new EventBuilder().Build(), new EventBuilder().Build());
                dataEntryTask.AvailableEvents.Add(availableEvent);
                dataEntryTask.In(Db);

                var f = new WorkflowsControllerFixture(Db);

                var result = f.Subject.SearchForEntryEventsReferencedIn(dataEntryTask.Criteria.Id, availableEvent.EventId);
                Assert.Equal(result.First(), dataEntryTask.Id);

                result = f.Subject.SearchForEntryEventsReferencedIn(dataEntryTask.Criteria.Id, availableEvent.AlsoUpdateEventId.GetValueOrDefault());
                Assert.Equal(result.First(), dataEntryTask.Id);
            }

            [Fact]
            public void ReturnsEntriesReferencingEvent()
            {
                var dataEntryTask = new DataEntryTaskBuilder().Build();
                dataEntryTask.DisplayEventNo = Fixture.Integer();
                dataEntryTask.DimEventNo = Fixture.Integer();
                dataEntryTask.HideEventNo = Fixture.Integer();
                dataEntryTask.In(Db);

                var f = new WorkflowsControllerFixture(Db);

                var result = f.Subject.SearchForEntryEventsReferencedIn(dataEntryTask.Criteria.Id, dataEntryTask.DisplayEventNo.GetValueOrDefault());
                Assert.Equal(result.First(), dataEntryTask.Id);

                result = f.Subject.SearchForEntryEventsReferencedIn(dataEntryTask.Criteria.Id, dataEntryTask.DimEventNo.GetValueOrDefault());
                Assert.Equal(result.First(), dataEntryTask.Id);

                result = f.Subject.SearchForEntryEventsReferencedIn(dataEntryTask.Criteria.Id, dataEntryTask.HideEventNo.GetValueOrDefault());
                Assert.Equal(result.First(), dataEntryTask.Id);
            }
        }

        public class AddEventMethod : FactBase
        {
            [Fact]
            public void ShouldReturnNewEvent()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var eventId = 2;
                var applyToChildren = true;

                var newEvent = new ValidEvent(criteria.Id, eventId, "a")
                {
                    DisplaySequence = 4,
                    Importance = new Importance {Description = "c"},
                    ImportanceLevel = "high",
                    NumberOfCyclesAllowed = 9,
                    Event = new Event {Code = "c"}
                };

                var f = new WorkflowsControllerFixture(Db);
                f.ValidEventService.AddEvent(criteria.Id, eventId, null, applyToChildren).Returns(newEvent);

                var r = f.Subject.AddEvent(criteria.Id, eventId, null, applyToChildren);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);

                Assert.Equal(newEvent.EventId, r.EventNo);
                Assert.Equal(newEvent.Description, r.Description);
                Assert.Equal(newEvent.Event.Code, r.EventCode);
                Assert.Equal(newEvent.DisplaySequence, r.DisplaySequence);
                Assert.Equal(newEvent.Importance.Description, r.Importance);
                Assert.Equal(newEvent.ImportanceLevel, r.ImportanceLevel);
                Assert.Equal(newEvent.NumberOfCyclesAllowed, r.MaxCycles);
            }
        }

        public class GetEventsUsedByCases : FactBase
        {
            [Fact]
            public void ShouldReturnOrderedEventsIfAreUsedByAnyCases()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaId = criteria.Id;
                var eventId = 2;
                var desc = "a";
                var events = new[] {eventId};

                var f = new WorkflowsControllerFixture(Db);
                f.ValidEventService.GetEventsUsedByCases(criteriaId, events).Returns(new[] {new ValidEvent(criteriaId, eventId) {Description = desc}});
                var results = f.Subject.GetEventsUsedByCases(criteriaId, events).ToArray();

                Assert.Equal(eventId, results.Single().EventId);
                Assert.Equal(desc, results.Single().Description);
            }
        }

        public class GetDescendantEventsMethod : FactBase
        {
            [Fact]
            public void ReturnsCriteriaIdsWithInheritedEvents()
            {
                var f = new WorkflowsControllerFixture(Db);
                var criteriaId = 1;
                var eventIds = new[] {1, 2};

                f.Inheritance.GetDescendantsWithInheritedEvent(criteriaId, eventIds[0]).Returns(new[] {1});
                f.Inheritance.GetDescendantsWithInheritedEvent(criteriaId, eventIds[1]).Returns(new[] {1});

                new CriteriaBuilder {Id = 1, Description = "1"}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.GetDescendants(criteriaId, eventIds, true);
                var descendants = (dynamic[]) result.Descendants;

                Assert.Null(result.Parent);
                Assert.Equal(1, descendants.Single().Id);
                Assert.Equal("1", descendants.Single().Description);
            }

            [Fact]
            public void ReturnsInheritedOnlyIfRequested()
            {
                var f = new WorkflowsControllerFixture(Db);
                var criteriaId = 1;

                f.Inheritance.GetDescendantsWithInheritedEvent(criteriaId, 1).Returns(new[] {1});
                f.Inheritance.GetDescendantsWithEvent(criteriaId, 1).Returns(new[] {2});

                new CriteriaBuilder {Id = 1, Description = "1"}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.GetDescendants(criteriaId, new[] {1}, true);
                var descendants = (dynamic[]) result.Descendants;

                Assert.Null(result.Parent);
                Assert.Equal(1, descendants.Single().Id);
                Assert.Equal("1", descendants.Single().Description);
            }

            [Fact]
            public void ReturnsNonInheritedDescendantWithEventIfRequested()
            {
                var f = new WorkflowsControllerFixture(Db);
                var criteriaId = 2;

                f.Inheritance.GetDescendantsWithInheritedEvent(criteriaId, 1).Returns(new[] {1});
                f.Inheritance.GetDescendantsWithEvent(criteriaId, 1).Returns(new[] {2});

                new CriteriaBuilder {Id = 2, Description = "2"}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.GetDescendants(criteriaId, new[] {1}, false);
                var descendants = (dynamic[]) result.Descendants;

                Assert.Null(result.Parent);
                Assert.Equal(2, descendants.Single().Id);
                Assert.Equal("2", descendants.Single().Description);
            }

            [Fact]
            public void ReturnsParentCriteriaDetails()
            {
                var f = new WorkflowsControllerFixture(Db);
                var criteriaId = 1;
                var eventIds = new[] {1};

                var inherits = new Inherits(criteriaId, Fixture.Integer()).In(Db);
                inherits.FromCriteria = new CriteriaBuilder().Build();

                new CriteriaBuilder {Id = 1, Description = "1"}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.GetDescendants(criteriaId, eventIds, true).Parent;

                Assert.Equal(inherits.FromCriteria.Id, result.Id);
                Assert.Equal(inherits.FromCriteria.Description, result.Description);
            }
        }

        public class DeleteEventsMethod : FactBase
        {
            [Fact]
            public void ShouldForwardParameters()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var eventIds = new[] {1};
                var appliesToDescendants = true;
                var f = new WorkflowsControllerFixture(Db);

                f.Subject.DeleteEvents(criteria.Id, eventIds, appliesToDescendants);
                f.ValidEventService.Received(1).DeleteEvents(criteria.Id, eventIds, appliesToDescendants);
            }
        }

        public class ReorderEventMethod : FactBase
        {
            [Fact]
            public void ShouldForwardParameters()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var request = new WorkflowsController.EventReorderRequest
                {
                    InsertBefore = false,
                    NextTargetId = 1,
                    PrevTargetId = 2,
                    SourceId = 3,
                    TargetId = 4
                };

                var f = new WorkflowsControllerFixture(Db);
                f.Subject.ReorderEvent(criteria.Id, request);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);

                int? prevTargetId, nextTargetId;

                f.ValidEventService.Received(1).GetAdjacentEvents(criteria.Id, request.TargetId, out prevTargetId, out nextTargetId);

                f.ValidEventService.Received(1).ReorderEvents(criteria.Id, request.SourceId, request.TargetId, request.InsertBefore);
            }
        }

        public class ReorderDescendantEventsMethod : FactBase
        {
            [Fact]
            public void ShouldForwardParameters()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var request = new WorkflowsController.EventReorderRequest
                {
                    InsertBefore = false,
                    NextTargetId = 1,
                    PrevTargetId = 2,
                    SourceId = 3,
                    TargetId = 4
                };

                var f = new WorkflowsControllerFixture(Db);
                f.Subject.ReorderDescendantEvents(criteria.Id, request);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);
                f.ValidEventService.Received(1).ReorderDescendantEvents(criteria.Id, request.SourceId, request.TargetId, request.PrevTargetId, request.NextTargetId, request.InsertBefore);
            }
        }

        public class IsWorkflowUsedByCaseMethod : FactBase
        {
            [Fact]
            public void ReturnsFalseIfNotUsedByCase()
            {
                var fixture = new WorkflowsControllerFixture(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);

                var result = fixture.Subject.IsWorkflowUsedByCase(criteria.Id);

                Assert.False(result);
            }

            [Fact]
            public void ReturnsTrueIfUsedByCaseChecklist()
            {
                var fixture = new WorkflowsControllerFixture(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);

                new CaseChecklist {CriteriaId = criteria.Id}.In(Db);

                var result = fixture.Subject.IsWorkflowUsedByCase(criteria.Id);

                Assert.True(result);
            }

            [Fact]
            public void ReturnsTrueIfUsedByCaseEvent()
            {
                var fixture = new WorkflowsControllerFixture(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);

                new CaseEvent {CreatedByCriteriaKey = criteria.Id}.In(Db);

                var result = fixture.Subject.IsWorkflowUsedByCase(criteria.Id);

                Assert.True(result);
            }

            [Fact]
            public void ReturnsTrueIfUsedByOpenAction()
            {
                var fixture = new WorkflowsControllerFixture(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);

                new OpenAction {CriteriaId = criteria.Id}.In(Db);

                var result = fixture.Subject.IsWorkflowUsedByCase(criteria.Id);

                Assert.True(result);
            }
        }

        public class DeleteWorkflowMethod : FactBase
        {
            [Fact]
            public void ChecksDeletePermission()
            {
                var fixture = new WorkflowsControllerFixture(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);

                fixture.Subject.DeleteWorkflow(criteria.Id);
                fixture.PermissionHelper.Received(1).EnsureDeletePermission(criteria);
            }

            [Fact]
            public void DeletesCriteriaAndBreaksInheritanceForChildren()
            {
                var fixture = new WorkflowsControllerFixture(Db);
                var parent = new CriteriaBuilder().Build().In(Db);
                var child1 = new CriteriaBuilder().Build().In(Db);
                var child2 = new CriteriaBuilder().Build().In(Db);

                new InheritsBuilder(parent, child1).Build().In(Db);
                new InheritsBuilder(parent, child2).Build().In(Db);

                fixture.Subject.DeleteWorkflow(parent.Id);

                fixture.InheritanceService.Received(1).BreakInheritance(child1.Id);
                fixture.InheritanceService.Received(1).BreakInheritance(child2.Id);
                fixture.DbContext.Received(1).SaveChanges();
                fixture.DbContext.TransactionScope.Received(1).Complete();
                fixture.DbContext.TransactionScope.Received(1).Dispose();

                Assert.False(fixture.DbContext.Set<Criteria>().Any(_ => _.Id == parent.Id));
            }

            [Fact]
            public void UnableToDeleteCriteriaIfUsedByOpenAction()
            {
                var fixture = new WorkflowsControllerFixture(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);

                new OpenAction {CriteriaId = criteria.Id}.In(Db);

                Assert.Throws<Exception>(() => fixture.Subject.DeleteWorkflow(criteria.Id));
            }
        }

        public class ResetWorkflowMethod : FactBase
        {
            [Fact]
            public void CallsResetAndReturnsResult()
            {
                var fixture = new WorkflowsControllerFixture(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);

                var applyToDescendants = Fixture.Boolean();
                var updateRespNameOnCases = Fixture.Boolean();

                var usedByCases = Fixture.Boolean();

                fixture.WorkflowMaintenanceService.ResetWorkflow(null, true, null).ReturnsForAnyArgs("success");
                fixture.WorkflowMaintenanceService.CheckCriteriaUsedByLiveCases(criteria.Id).ReturnsForAnyArgs(usedByCases);

                var result = fixture.Subject.ResetWorkflow(criteria.Id, applyToDescendants, updateRespNameOnCases);

                fixture.WorkflowMaintenanceService.Received(1).ResetWorkflow(criteria, applyToDescendants, updateRespNameOnCases);

                Assert.Equal(usedByCases, result.UsedByCase);
                Assert.Equal("success", result.Status);
            }

            [Fact]
            public void ChecksEditPermission()
            {
                var fixture = new WorkflowsControllerFixture(Db);
                var criteria = new CriteriaBuilder().Build().In(Db);
                fixture.WorkflowMaintenanceService.ResetWorkflow(null, true, null).ReturnsForAnyArgs("success");

                fixture.Subject.ResetWorkflow(criteria.Id, true, true);
                fixture.PermissionHelper.Received(1).EnsureEditPermission(criteria);
            }
        }

        public class ReorderEntryMethod : FactBase
        {
            [Fact]
            public void ShouldForwardParameters()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var request = new WorkflowsController.EntryReorderRequest
                {
                    InsertBefore = false,
                    SourceId = 3,
                    TargetId = 4
                };

                var f = new WorkflowsControllerFixture(Db);
                f.Subject.ReorderEntry(criteria.Id, request);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);

                short? prevTargetId, nextTargetId;

                f.EntryService.Received(1).GetAdjacentEntries(criteria.Id, request.TargetId, out prevTargetId, out nextTargetId);

                f.EntryService.Received(1).ReorderEntries(criteria.Id, request.SourceId, request.TargetId, request.InsertBefore);

                f.Inheritance.Received(1).GetDescendantsWithMatchedDescription(criteria.Id, request.SourceId);
            }

            [Fact]
            public void ShouldReturnDescendentsWithEntry()
            {
                var criteria = new CriteriaBuilder {Id = 1}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = 2, Description = "Criteria2"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = 3, Description = "Criteria3"}.ForEventsEntriesRule().Build().In(Db);
                var request = new WorkflowsController.EntryReorderRequest
                {
                    InsertBefore = false,
                    SourceId = 3,
                    TargetId = 4
                };

                var f = new WorkflowsControllerFixture(Db);
                f.Inheritance.GetDescendantsWithMatchedDescription(criteria.Id, 3).Returns(new[] {2, 3});

                var result = f.Subject.ReorderEntry(criteria.Id, request);
                Assert.NotNull(result.Descendents);
                Assert.Equal(2, result.Descendents.Length);
                Assert.Equal("Criteria2", result.Descendents[0].Description);
                Assert.Equal("Criteria3", result.Descendents[1].Description);
            }
        }

        public class ReorderDescendantEntriesMethod : FactBase
        {
            [Fact]
            public void ShouldForwardParameters()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var request = new WorkflowsController.EntryReorderRequest
                {
                    InsertBefore = false,
                    NextTargetId = 1,
                    PrevTargetId = 2,
                    SourceId = 3,
                    TargetId = 4
                };

                var f = new WorkflowsControllerFixture(Db);
                f.Subject.ReorderDescendantEntries(criteria.Id, request);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);
                f.EntryService.Received(1).ReorderDescendantEntries(criteria.Id, request.SourceId, request.TargetId, request.PrevTargetId, request.NextTargetId, request.InsertBefore);
            }
        }

        public class AddEntryMethod : FactBase
        {
            [Fact]
            public void ShouldCallEntryEventsService()
            {
                const string entryDescription = "entry Test";
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var f = new WorkflowsControllerFixture(Db).WithAddEventsEntryReturns();
                int[] eventNo = {1, 2};

                var r = f.Subject.AddEventsEntry(criteria.Id, entryDescription, eventNo);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);

                f.EntryService.Received(1).AddEntryWithEvents(criteria.Id, entryDescription, eventNo, false);

                Assert.Equal(100, r.EntryNo);
                Assert.Equal("entry Test", r.Description);
                Assert.Equal(5, r.DisplaySequence);
            }

            [Fact]
            public void ShouldCallEntryService()
            {
                const string entryDescription = "entry Test";
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var f = new WorkflowsControllerFixture(Db).WithAddEntryReturns();

                var r = f.Subject.AddEntry(criteria.Id, new WorkflowsController.AddEntryParams
                {
                    EntryDescription = entryDescription,
                    ApplyToChildren = false,
                    InsertAfterEntryId = -11,
                    IsSeparator = true
                });

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);

                f.EntryService.Received(1).AddEntry(criteria.Id, entryDescription, -11, false, true);

                Assert.Equal(100, r.EntryNo);
                Assert.Equal("entry Test", r.Description);
                Assert.Equal(5, r.DisplaySequence);
            }
        }

        public class GetDescendantsWithInheritedEntryMethod : FactBase
        {
            [Fact]
            public void ShouldForwardParameters()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);

                var f = new WorkflowsControllerFixture(Db);
                var entryIds = new short[] {3};
                f.Subject.GetDescendantsWithInheritedEntry(criteria.Id, entryIds);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);
                f.Inheritance.Received(1).GetDescendantsWithAnyInheritedEntriesFrom(criteria.Id, entryIds);
            }

            [Fact]
            public void ShouldReturnDescendentsWithInheritedEntry()
            {
                var criteria = new CriteriaBuilder {Id = 1}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = 2, Description = "Criteria2"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = 3, Description = "Criteria3"}.ForEventsEntriesRule().Build().In(Db);

                var entryIds = new short[] {3};

                var f = new WorkflowsControllerFixture(Db);
                f.Inheritance.GetDescendantsWithAnyInheritedEntriesFrom(criteria.Id, Arg.Any<short[]>()).Returns(new[] {2, 3});
                var result = f.Subject.GetDescendantsWithInheritedEntry(criteria.Id, entryIds).ToArray();

                Assert.NotNull(result);
                Assert.Equal(2, result.Length);
                Assert.Equal("Criteria2", result[0].Description);
                Assert.Equal("Criteria3", result[1].Description);
            }
        }

        public class DeleteEntriesMethod : FactBase
        {
            [Theory]
            [InlineData(new short[] {1, 2}, true)]
            [InlineData(new short[] {10, 12}, false)]
            public void VerifiesPermissionAndCallsEntryService(short[] entryIds, bool appliesToDescendents)
            {
                var criteria = new CriteriaBuilder().Build().In(Db);

                var f = new WorkflowsControllerFixture(Db);
                f.Subject.DeleteEntries(criteria.Id, entryIds, appliesToDescendents);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);
                f.EntryService.Received(1).DeleteEntries(criteria.Id, entryIds, appliesToDescendents);
            }
        }

        public class WorkflowsControllerFixture : IFixture<WorkflowsController>
        {
            public WorkflowsControllerFixture(InMemoryDbContext db)
            {
                CommonQueryService = new CommonQueryService();
                CharacteristicsValidator = Substitute.For<ICharacteristicsValidator>();
                CharacteristicsValidatorIndex = Substitute.For<IIndex<string, ICharacteristicsValidator>>();
                CharacteristicsValidatorIndex[CriteriaPurposeCodes.EventsAndEntries].Returns(CharacteristicsValidator);
                WorkflowSearch = Substitute.For<IWorkflowSearch>();
                Inheritance = Substitute.For<IInheritance>();
                DbContext = db;
                ValidEventService = Substitute.For<IValidEventService>();
                EntryService = Substitute.For<IEntryService>();
                PermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
                InheritanceService = Substitute.For<IWorkflowInheritanceService>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                PreferredCultureResolver.Resolve().Returns("en");

                bool editBlockedByDescendants;
                PermissionHelper.CanEdit(Arg.Any<Criteria>(), out editBlockedByDescendants).ReturnsForAnyArgs(true);
                WorkflowMaintenanceService = Substitute.For<IWorkflowMaintenanceService>();

                Subject = new WorkflowsController(DbContext, CommonQueryService, CharacteristicsValidatorIndex, WorkflowSearch, Inheritance, ValidEventService, PermissionHelper, InheritanceService, EntryService, PreferredCultureResolver, WorkflowMaintenanceService);
            }

            public IIndex<string, ICharacteristicsValidator> CharacteristicsValidatorIndex { get; set; }

            public ICommonQueryService CommonQueryService { get; set; }

            public ICharacteristicsValidator CharacteristicsValidator { get; set; }

            public IWorkflowSearch WorkflowSearch { get; set; }

            public IInheritance Inheritance { get; set; }

            public InMemoryDbContext DbContext { get; set; }

            public IValidEventService ValidEventService { get; set; }

            public IWorkflowPermissionHelper PermissionHelper { get; set; }

            public IWorkflowMaintenanceService WorkflowMaintenanceService { get; set; }

            public IWorkflowInheritanceService InheritanceService { get; set; }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public IEntryService EntryService { get; set; }
            public WorkflowsController Subject { get; set; }

            public WorkflowsControllerFixture WithAddEntryReturns(int id = 100, string description = "entry Test", short sequence = 5)
            {
                EntryService.AddEntry(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<bool>()).ReturnsForAnyArgs(new DataEntryTask
                {
                    Id = 100,
                    Description = description,
                    DisplaySequence = sequence
                });
                return this;
            }

            public WorkflowsControllerFixture WithAddEventsEntryReturns(int id = 100, string description = "entry Test", short sequence = 5)
            {
                EntryService.AddEntryWithEvents(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int[]>(), Arg.Any<bool>()).ReturnsForAnyArgs(new DataEntryTask
                {
                    Id = 100,
                    Description = description,
                    DisplaySequence = sequence
                });
                return this;
            }
        }
    }
}