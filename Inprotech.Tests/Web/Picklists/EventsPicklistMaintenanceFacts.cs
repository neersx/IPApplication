using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;
using Action = InprotechKaizen.Model.Cases.Action;
using Case = InprotechKaizen.Model.Cases.Case;
using CaseType = InprotechKaizen.Model.Cases.CaseType;
using EntityModel = InprotechKaizen.Model.Cases.Events;
using PropertyType = InprotechKaizen.Model.Cases.PropertyType;

namespace Inprotech.Tests.Web.Picklists
{
    internal class EventsPicklistMaintenanceFixture : IFixture<EventsPicklistMaintenance>
    {
        readonly InMemoryDbContext _db;

        public EventsPicklistMaintenanceFixture(InMemoryDbContext db)
        {
            _db = db;
            LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            Subject = new EventsPicklistMaintenance(LastInternalCodeGenerator, db, TaskSecurityProvider);
        }

        public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public EventsPicklistMaintenance Subject { get; set; }

        public EntityModel.Event CreateEvent()
        {
            var e = new EntityModel.Event(Fixture.Integer())
            {
                Code = "USOA",
                Description = "FINAL 3 month Office Action-Last Day",
                ImportanceLevel = "5",
                InternalImportance = new Importance
                {
                    Level = "5",
                    Description = "Normal"
                },
                NumberOfCyclesAllowed = 9999
            }.In(_db);

            var eZ = new EntityModel.Event(Fixture.Integer())
            {
                Code = "VQ",
                Description = Fixture.String("Very Quality Law"),
                ImportanceLevel = "1",
                InternalImportance = new Importance
                {
                    Level = "1",
                    Description = Fixture.String("Critical")
                },
                NumberOfCyclesAllowed = 7,
                CategoryId = 444,
                Category = new EntityModel.EventCategory(444) { Name = "Q Category" },
                ClientImportanceLevel = "10",
                ClientImportance = new Importance
                {
                    Level = "10",
                    Description = Fixture.String("Serious")
                },
                ShouldPoliceImmediate = true,
                ControllingAction = "VA",
                Action = new Action("VQAction", null, 1, "VA"),
                DraftEventId = e.Id,
                DraftEvent = e,
                IsAccountingEvent = true,
                Notes = Fixture.String("VQ Notes"),
                RecalcEventDate = true,
                SuppressCalculation = false
            }.In(_db);

            return eZ;
        }
    }

    public class EventsPicklistMaintenanceFacts
    {
        public class EditingEvent : FactBase
        {
            [Theory]
            [InlineData(1, true, true, true, true, true)]
            [InlineData(2, false, true, true, true, true)]
            [InlineData(3, false, false, false, false, false)]
            public void PropagatesChangesToControls(int eventId, bool updatedDescription, bool updatedImportance, bool updatedCycles, bool updatedRecalcEventDate, bool updatedNoDueDateCalc)
            {
                SetupUpdatableControl();
                var v = new EventsPicklistMaintenanceFixture(Db);
                var eventDetails = new EventSaveDetails
                {
                    AllowPoliceImmediate = Fixture.Boolean(),
                    ClientImportance = Fixture.String(),
                    Code = Fixture.String(),
                    Description = Fixture.String(),
                    Group = new TableCodePicklistController.TableCodePicklistItem { Key = Fixture.Integer(), Value = Fixture.String("Group") },
                    InternalImportance = Fixture.String(),
                    IsAccountingEvent = Fixture.Boolean(),
                    Key = eventId,
                    MaxCycles = 9999,
                    Notes = Fixture.String(),
                    RecalcEventDate = updatedRecalcEventDate,
                    SuppressCalculation = updatedNoDueDateCalc,
                    HasUpdatableCriteria = true,
                    PropagateChanges = true
                };
                v.Subject.Save(eventDetails, Operation.Update);
                var newEventDetails = Db.Set<EntityModel.Event>().Single(l => l.Id == eventId);
                var validEventDetails = Db.Set<ValidEvent>().SingleOrDefault(_ => _.CriteriaId == eventId && _.EventId == eventId);
                Assert.Equal(updatedDescription, validEventDetails != null && newEventDetails.Description == validEventDetails.Description);
                Assert.Equal(updatedImportance, validEventDetails != null && newEventDetails.ImportanceLevel == validEventDetails.ImportanceLevel);
                Assert.Equal(updatedCycles, validEventDetails != null && newEventDetails.NumberOfCyclesAllowed == validEventDetails.NumberOfCyclesAllowed);
                Assert.Equal(updatedRecalcEventDate, validEventDetails != null && newEventDetails.RecalcEventDate == validEventDetails.RecalcEventDate);
                Assert.Equal(updatedNoDueDateCalc, validEventDetails != null && newEventDetails.SuppressCalculation == validEventDetails.SuppressDueDateCalculation);
            }

            void SetupUpdatableControl()
            {
                new Criteria { Id = 1, PurposeCode = CriteriaPurposeCodes.EventsAndEntries }.In(Db);
                new Criteria { Id = 2, PurposeCode = CriteriaPurposeCodes.EventsAndEntries }.In(Db);
                new Criteria { Id = 3, PurposeCode = CriteriaPurposeCodes.EventsAndEntries }.In(Db);

                new EntityModel.Event(1)
                {
                    Description = "Event1",
                    ImportanceLevel = "5",
                    NumberOfCyclesAllowed = 2,
                    RecalcEventDate = false,
                    SuppressCalculation = false,
                    ValidEvents = new List<ValidEvent> { new ValidEvent(1, 1, "Event1") { ImportanceLevel = "3", NumberOfCyclesAllowed = 1 }.In(Db) }
                }.In(Db);

                new EntityModel.Event(2)
                {
                    Description = "Event2",
                    ImportanceLevel = "5",
                    NumberOfCyclesAllowed = 2,
                    RecalcEventDate = false,
                    SuppressCalculation = false,
                    ValidEvents = new List<ValidEvent> { new ValidEvent(2, 2, Fixture.String("new")) { ImportanceLevel = "5", NumberOfCyclesAllowed = 9999 }.In(Db) }
                }.In(Db);

                new EntityModel.Event(3)
                {
                    Description = "Event5",
                    ImportanceLevel = "9",
                    NumberOfCyclesAllowed = 1,
                    RecalcEventDate = false,
                    SuppressCalculation = false
                }.In(Db);
            }

            [Fact]
            public void UpdatedEventRequiresCycle()
            {
                var v = new EventsPicklistMaintenanceFixture(Db);
                var q = v.CreateEvent();

                var eventDetails = new EventSaveDetails
                {
                    AllowPoliceImmediate = Fixture.Boolean(),
                    ClientImportance = Fixture.String(),
                    Code = Fixture.String(),
                    Description = Fixture.String(),
                    Group = new TableCodePicklistController.TableCodePicklistItem { Key = Fixture.Integer(), Value = Fixture.String("NoteGroup") },
                    InternalImportance = Fixture.String(),
                    IsAccountingEvent = Fixture.Boolean(),
                    Key = q.Id,
                    MaxCycles = null,
                    Notes = Fixture.String(),
                    RecalcEventDate = Fixture.Boolean(),
                    SuppressCalculation = Fixture.Boolean()
                };

                var result = v.Subject.Save(eventDetails, Operation.Update);

                Assert.Equal("maxCycles", result.Errors[0].Field);
                Assert.Equal("field.errors.required", result.Errors[0].Message);
            }

            [Fact]
            public void UpdatedEventRequiresDescription()
            {
                var v = new EventsPicklistMaintenanceFixture(Db);
                var q = v.CreateEvent();

                var eventDetails = new EventSaveDetails
                {
                    AllowPoliceImmediate = Fixture.Boolean(),
                    ClientImportance = Fixture.String(),
                    Code = Fixture.String(),
                    Description = null,
                    Group = new TableCodePicklistController.TableCodePicklistItem { Key = Fixture.Integer(), Value = Fixture.String("NoteGroup") },
                    InternalImportance = Fixture.String(),
                    IsAccountingEvent = Fixture.Boolean(),
                    Key = q.Id,
                    MaxCycles = Fixture.Short(),
                    Notes = Fixture.String(),
                    RecalcEventDate = Fixture.Boolean(),
                    SuppressCalculation = Fixture.Boolean()
                };

                var result = v.Subject.Save(eventDetails, Operation.Update);

                Assert.Equal("description", result.Errors[0].Field);
                Assert.Equal("field.errors.required", result.Errors[0].Message);
            }

            [Fact]
            public void UpdatesEventDetails()
            {
                var v = new EventsPicklistMaintenanceFixture(Db);
                var q = v.CreateEvent();

                var updatedEventDetails = new EventSaveDetails
                {
                    AllowPoliceImmediate = Fixture.Boolean(),
                    ClientImportance = Fixture.String(),
                    Code = Fixture.String(),
                    Description = Fixture.String(),
                    Group = new TableCodePicklistController.TableCodePicklistItem { Key = Fixture.Integer(), Value = Fixture.String("Group") },
                    InternalImportance = Fixture.String(),
                    IsAccountingEvent = Fixture.Boolean(),
                    Key = q.Id,
                    MaxCycles = Fixture.Short(),
                    Notes = Fixture.String(),
                    RecalcEventDate = Fixture.Boolean(),
                    SuppressCalculation = Fixture.Boolean(),
                    NotesSharedAcrossCycles = Fixture.Boolean()
                };

                var result = v.Subject.Save(updatedEventDetails, Operation.Update);
                var newEventDetails = Db.Set<EntityModel.Event>().Where(l => l.Id == q.Id).ToArray();

                Assert.Equal("success", result.Result);
                Assert.Equal(updatedEventDetails.AllowPoliceImmediate, newEventDetails[0].ShouldPoliceImmediate);
                Assert.Equal(updatedEventDetails.ClientImportance, newEventDetails[0].ClientImportanceLevel);
                Assert.Equal(updatedEventDetails.Code, newEventDetails[0].Code);
                Assert.Equal(updatedEventDetails.Description, newEventDetails[0].Description);
                Assert.Equal(updatedEventDetails.Group.Key, newEventDetails[0].GroupId);
                Assert.Equal(updatedEventDetails.InternalImportance, newEventDetails[0].ImportanceLevel);
                Assert.Equal(updatedEventDetails.IsAccountingEvent, newEventDetails[0].IsAccountingEvent);
                Assert.Equal(updatedEventDetails.MaxCycles, newEventDetails[0].NumberOfCyclesAllowed);
                Assert.Equal(updatedEventDetails.Notes, newEventDetails[0].Notes);
                Assert.Equal(updatedEventDetails.RecalcEventDate, newEventDetails[0].RecalcEventDate);
                Assert.Equal(updatedEventDetails.SuppressCalculation, newEventDetails[0].SuppressCalculation);
                Assert.Equal(updatedEventDetails.NotesSharedAcrossCycles, newEventDetails[0].NotesSharedAcrossCycles);
            }
        }

        public class AddingEvent : FactBase
        {
            int _newEventId;

            dynamic NewEvent()
            {
                var eventCategory = new EntityModel.EventCategory
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String()
                }.In(Db);

                var controllingAction = new Action { Code = "AB", Name = Fixture.String() }.In(Db);
                var draftCaseEvent = new EntityModel.Event(Fixture.Integer()).In(Db);
                _newEventId = Fixture.Integer();
                return new
                {
                    Id = _newEventId,
                    Description = Fixture.String(),
                    Code = Fixture.String(),
                    AllowPoliceImmediate = Fixture.Boolean(),
                    RecalcEventDate = Fixture.Boolean(),
                    IsAccountingEvent = Fixture.Boolean(),
                    Notes = Fixture.String(),
                    SuppressCalculation = Fixture.Boolean(),
                    Category = new EventCategory(eventCategory.Id, eventCategory.Name, Fixture.String(), Fixture.RandomBytes(1), Fixture.String(), Fixture.Integer(), Fixture.String()),
                    ClientImportance = Fixture.Short().ToString(),
                    InternalImportance = Fixture.Short().ToString(),
                    ControllingAction = new Inprotech.Web.Picklists.Action(controllingAction.Code, controllingAction.Name),
                    DraftCaseEvent = new Event { Key = draftCaseEvent.Id },
                    NotesGroup = new TableCodePicklistController.TableCodePicklistItem { Key = Fixture.Integer(), Value = Fixture.String("NoteGroup") },
                    NotesSharedAcrossCycles = Fixture.Boolean()
                };
            }

            [Fact]
            public void AddsNewEvent()
            {
                var newEvent = NewEvent();
                var f = new EventsPicklistMaintenanceFixture(Db);
                f.LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Events).Returns(_newEventId);
                var r = f.Subject.Save(new EventSaveDetails
                {
                    Description = newEvent.Description,
                    MaxCycles = 1,
                    Code = newEvent.Code,
                    AllowPoliceImmediate = newEvent.AllowPoliceImmediate,
                    RecalcEventDate = newEvent.RecalcEventDate,
                    IsAccountingEvent = newEvent.IsAccountingEvent,
                    Notes = newEvent.Notes,
                    SuppressCalculation = newEvent.SuppressCalculation,
                    Category = newEvent.Category,
                    ClientImportance = newEvent.ClientImportance,
                    InternalImportance = newEvent.InternalImportance,
                    ControllingAction = newEvent.ControllingAction,
                    DraftCaseEvent = newEvent.DraftCaseEvent,
                    NotesGroup = newEvent.NotesGroup,
                    NotesSharedAcrossCycles = newEvent.NotesSharedAcrossCycles
                }, Operation.Add);
                var saved = Db.Set<EntityModel.Event>().Last();

                Assert.Equal("success", r.Result);
                Assert.Equal(newEvent.Description, saved.Description);
                Assert.Equal(newEvent.Code, saved.Code);
                Assert.Equal(1, saved.NumberOfCyclesAllowed.GetValueOrDefault());
                Assert.Equal(newEvent.AllowPoliceImmediate, saved.ShouldPoliceImmediate);
                Assert.Equal(newEvent.RecalcEventDate, saved.RecalcEventDate);
                Assert.Equal(newEvent.IsAccountingEvent, saved.IsAccountingEvent);
                Assert.Equal(newEvent.Notes, saved.Notes);
                Assert.Equal(newEvent.SuppressCalculation, saved.SuppressCalculation);
                Assert.Equal(newEvent.Category.Key, saved.CategoryId);
                Assert.Equal(newEvent.ClientImportance, saved.ClientImportanceLevel);
                Assert.Equal(newEvent.InternalImportance, saved.ImportanceLevel);
                Assert.Equal(newEvent.ControllingAction.Code, saved.ControllingAction);
                Assert.Equal(newEvent.DraftCaseEvent.Key, saved.DraftEventId);
                Assert.Equal(newEvent.NotesGroup.Key, saved.NoteGroupId);
                Assert.Equal(newEvent.NotesSharedAcrossCycles, saved.NotesSharedAcrossCycles);
                Assert.Equal(_newEventId, saved.Id);
            }

            [Fact]
            public void AddsNewEventWithNegativeNumber()
            {
                var newEvent = NewEvent();
                _newEventId = -100;
                
                var f = new EventsPicklistMaintenanceFixture(Db);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.CreateNegativeWorkflowRules).Returns(true);
                f.LastInternalCodeGenerator.GenerateNegativeLastInternalCode(KnownInternalCodeTable.EventsMaxim).Returns(_newEventId);
                
                var r = f.Subject.Save(new EventSaveDetails
                {
                    Description = newEvent.Description,
                    MaxCycles = 1,
                    Code = newEvent.Code,
                    AllowPoliceImmediate = newEvent.AllowPoliceImmediate,
                    RecalcEventDate = newEvent.RecalcEventDate,
                    IsAccountingEvent = newEvent.IsAccountingEvent,
                    Notes = newEvent.Notes,
                    SuppressCalculation = newEvent.SuppressCalculation,
                    Category = newEvent.Category,
                    ClientImportance = newEvent.ClientImportance,
                    InternalImportance = newEvent.InternalImportance,
                    ControllingAction = newEvent.ControllingAction,
                    DraftCaseEvent = newEvent.DraftCaseEvent,
                    NotesGroup = newEvent.NotesGroup,
                    NotesSharedAcrossCycles = newEvent.NotesSharedAcrossCycles
                }, Operation.Add);
                var saved = Db.Set<EntityModel.Event>().Last();

                Assert.Equal("success", r.Result);
                Assert.Equal(newEvent.Description, saved.Description);
                Assert.Equal(newEvent.Code, saved.Code);
                Assert.Equal(1, saved.NumberOfCyclesAllowed.GetValueOrDefault());
                Assert.Equal(newEvent.AllowPoliceImmediate, saved.ShouldPoliceImmediate);
                Assert.Equal(newEvent.RecalcEventDate, saved.RecalcEventDate);
                Assert.Equal(newEvent.IsAccountingEvent, saved.IsAccountingEvent);
                Assert.Equal(newEvent.Notes, saved.Notes);
                Assert.Equal(newEvent.SuppressCalculation, saved.SuppressCalculation);
                Assert.Equal(newEvent.Category.Key, saved.CategoryId);
                Assert.Equal(newEvent.ClientImportance, saved.ClientImportanceLevel);
                Assert.Equal(newEvent.InternalImportance, saved.ImportanceLevel);
                Assert.Equal(newEvent.ControllingAction.Code, saved.ControllingAction);
                Assert.Equal(newEvent.DraftCaseEvent.Key, saved.DraftEventId);
                Assert.Equal(newEvent.NotesGroup.Key, saved.NoteGroupId);
                Assert.Equal(newEvent.NotesSharedAcrossCycles, saved.NotesSharedAcrossCycles);
                Assert.Equal(_newEventId, saved.Id);
            }

            [Fact]
            public void AddsWithUnlimitedCycles()
            {
                var newEvent = NewEvent();
                var f = new EventsPicklistMaintenanceFixture(Db);
                f.LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Events).Returns(_newEventId);
                var r = f.Subject.Save(new EventSaveDetails
                {
                    Description = newEvent.Description,
                    Code = newEvent.Code,
                    AllowPoliceImmediate = newEvent.AllowPoliceImmediate,
                    RecalcEventDate = newEvent.RecalcEventDate,
                    IsAccountingEvent = newEvent.IsAccountingEvent,
                    Notes = newEvent.Notes,
                    SuppressCalculation = newEvent.SuppressCalculation,
                    Category = newEvent.Category,
                    ClientImportance = newEvent.ClientImportance,
                    InternalImportance = newEvent.InternalImportance,
                    ControllingAction = newEvent.ControllingAction,
                    DraftCaseEvent = newEvent.DraftCaseEvent,
                    MaxCycles = 1,
                    UnlimitedCycles = true
                }, Operation.Add);
                var saved = Db.Set<EntityModel.Event>().Last();

                Assert.Equal("success", r.Result);
                Assert.Equal(newEvent.Description, saved.Description);
                Assert.Equal(newEvent.Code, saved.Code);
                Assert.Equal(newEvent.AllowPoliceImmediate, saved.ShouldPoliceImmediate);
                Assert.Equal(newEvent.RecalcEventDate, saved.RecalcEventDate);
                Assert.Equal(newEvent.IsAccountingEvent, saved.IsAccountingEvent);
                Assert.Equal(newEvent.Notes, saved.Notes);
                Assert.Equal(newEvent.SuppressCalculation, saved.SuppressCalculation);
                Assert.Equal(newEvent.Category.Key, saved.CategoryId);
                Assert.Equal(newEvent.ClientImportance, saved.ClientImportanceLevel);
                Assert.Equal(newEvent.InternalImportance, saved.ImportanceLevel);
                Assert.Equal(newEvent.ControllingAction.Code, saved.ControllingAction);
                Assert.Equal(newEvent.DraftCaseEvent.Key, saved.DraftEventId);

                Assert.Equal(9999, saved.NumberOfCyclesAllowed.GetValueOrDefault());
            }

            [Fact]
            public void NewEventRequiresCycle()
            {
                var v = new EventsPicklistMaintenanceFixture(Db);
                var newEvent = NewEvent();
                var eventDetails = new EventSaveDetails
                {
                    Description = newEvent.Description,
                    MaxCycles = null,
                    Code = newEvent.Code,
                    AllowPoliceImmediate = newEvent.AllowPoliceImmediate,
                    RecalcEventDate = newEvent.RecalcEventDate,
                    IsAccountingEvent = newEvent.IsAccountingEvent,
                    Notes = newEvent.Notes,
                    SuppressCalculation = newEvent.SuppressCalculation,
                    Category = newEvent.Category,
                    ClientImportance = newEvent.ClientImportance,
                    InternalImportance = newEvent.InternalImportance,
                    ControllingAction = newEvent.ControllingAction,
                    DraftCaseEvent = newEvent.DraftCaseEvent
                };
                var result = v.Subject.Save(eventDetails, Operation.Add);

                Assert.Equal("maxCycles", result.Errors[0].Field);
                Assert.Equal("field.errors.required", result.Errors[0].Message);
            }

            [Fact]
            public void NewEventRequiresDescription()
            {
                var v = new EventsPicklistMaintenanceFixture(Db);
                var newEvent = NewEvent();
                var eventDetails = new EventSaveDetails
                {
                    Description = null,
                    MaxCycles = 1,
                    Code = newEvent.Code,
                    AllowPoliceImmediate = newEvent.AllowPoliceImmediate,
                    RecalcEventDate = newEvent.RecalcEventDate,
                    IsAccountingEvent = newEvent.IsAccountingEvent,
                    Notes = newEvent.Notes,
                    SuppressCalculation = newEvent.SuppressCalculation,
                    Category = newEvent.Category,
                    ClientImportance = newEvent.ClientImportance,
                    InternalImportance = newEvent.InternalImportance,
                    ControllingAction = newEvent.ControllingAction,
                    DraftCaseEvent = newEvent.DraftCaseEvent
                };
                var result = v.Subject.Save(eventDetails, Operation.Add);

                Assert.Equal("description", result.Errors[0].Field);
                Assert.Equal("field.errors.required", result.Errors[0].Message);
            }
        }

        public class DeleteingEvent : FactBase
        {
            [Fact]
            public void DeleteEventNotUsedInCriteriaRuleAndNotOrphanedShouldSucceed()
            {
                var f = new EventsPicklistMaintenanceFixture(Db);
                var eventToDelete = f.CreateEvent();

                var r = f.Subject.Delete(eventToDelete.Id);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<EntityModel.Event>().Any(v => v.Id == eventToDelete.Id));
            }

            [Fact]
            public void DeleteEventUsedInCriteriaRuleShouldNotSucceed()
            {
                var f = new EventsPicklistMaintenanceFixture(Db);
                var eventToDelete = f.CreateEvent();
                var criteria = new Criteria { Id = Fixture.Integer() }.In(Db);
                var eventControl = new ValidEvent(criteria, eventToDelete, Fixture.String()).In(Db);

                var r = f.Subject.Delete(eventToDelete.Id);

                Assert.Equal(Resources.DeleteErrorTitle, r.Title);
                Assert.Equal(Resources.DeleteEventErrorCritieria + eventControl.CriteriaId, r.Errors[0].Message);
                Assert.True(Db.Set<EntityModel.Event>().Any(v => v.Id == eventToDelete.Id));
            }

            [Fact]
            public void DeleteOrphanedEventShouldNotSucceed()
            {
                var f = new EventsPicklistMaintenanceFixture(Db);
                var eventToDelete = f.CreateEvent();
                var @case = new Case(Fixture.Integer(), Fixture.String(), new Country(Fixture.String(), Fixture.String()), new CaseType(Fixture.String(), Fixture.String()), new PropertyType(Fixture.String(), Fixture.String())).In(Db);
                var caseEvent = new CaseEvent(@case.Id, eventToDelete.Id, 1).In(Db);

                var r = f.Subject.Delete(eventToDelete.Id);

                Assert.Equal(Resources.DeleteErrorTitle, r.Title);
                Assert.Equal(Resources.DeleteEventErrorOrphan, r.Errors[0].Message);
                Assert.True(Db.Set<EntityModel.Event>().Any(v => v.Id == eventToDelete.Id));
                Assert.True(Db.Set<CaseEvent>().Any(v => v.EventNo == caseEvent.EventNo && v.CaseId == caseEvent.CaseId));
            }
        }
    }
}