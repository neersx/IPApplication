using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using EventModel = InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Web.Picklists
{
    public interface IEventsPicklistMaintenance
    {
        dynamic Save(EventSaveDetails saveEvent, Operation operation);
        dynamic Delete(int eventId);
    }

    internal class EventsPicklistMaintenance : IEventsPicklistMaintenance
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public EventsPicklistMaintenance(ILastInternalCodeGenerator lastInternalCodeGenerator, IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider)
        {
            if (lastInternalCodeGenerator == null) throw new ArgumentNullException(nameof(lastInternalCodeGenerator));
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            if (taskSecurityProvider == null) throw new ArgumentNullException(nameof(taskSecurityProvider));

            _lastInternalCodeGenerator = lastInternalCodeGenerator;
            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
        }

        public dynamic Save(EventSaveDetails saveEvent, Operation operation)
        {
            if (saveEvent == null) throw new ArgumentNullException(nameof(saveEvent));
            var validationErrors = Validate(saveEvent, operation).ToArray();

            if (validationErrors.Any()) return validationErrors.AsErrorResponse();

            using (var tcs = _dbContext.BeginTransaction())
            {
                var model = operation == Operation.Update
                    ? _dbContext.Set<EventModel.Event>().Single(_ => _.Id == saveEvent.Key)
                    : NewEvent();

                var originalDescription = model.Description;

                model.Description = saveEvent.Description;
                model.Code = saveEvent.Code;
                model.RecalcEventDate = saveEvent.RecalcEventDate;
                model.IsAccountingEvent = saveEvent.IsAccountingEvent;
                model.ShouldPoliceImmediate = saveEvent.AllowPoliceImmediate;
                model.NumberOfCyclesAllowed = saveEvent.UnlimitedCycles ? 9999 : saveEvent.MaxCycles;
                model.Notes = saveEvent.Notes;
                model.SuppressCalculation = saveEvent.SuppressCalculation;
                model.ClientImportanceLevel = saveEvent.ClientImportance;
                model.GroupId = saveEvent.Group?.Key;
                model.ImportanceLevel = saveEvent.InternalImportance;
                model.ControllingAction = saveEvent.ControllingAction?.Code;
                model.DraftEventId = saveEvent.DraftCaseEvent?.Key;
                model.CategoryId = saveEvent.Category?.Key;
                model.NoteGroupId = saveEvent.NotesGroup?.Key;
                model.NotesSharedAcrossCycles = saveEvent.NotesSharedAcrossCycles;

                if (operation == Operation.Update && saveEvent.HasUpdatableCriteria && saveEvent.PropagateChanges.GetValueOrDefault())
                {
                    var canUpdateProtectedRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected);
                    var canUpdateUnprotectedRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules);
                    var forUpdate = (from criteria in _dbContext.Set<Criteria>()
                                                               .WhereWorkflowCriteria()
                                                               .Where(_ => _.UserDefinedRule == null || _.UserDefinedRule == 0 && canUpdateProtectedRules || _.UserDefinedRule != 0 && canUpdateUnprotectedRules)
                                     join _ in _dbContext.Set<ValidEvent>() on criteria.Id equals _.CriteriaId
                                     where _.EventId == saveEvent.Key
                                     select _)
                                    .ToArray();

                    foreach (var v in forUpdate)
                    {
                        if (v.Description == originalDescription && !string.Equals(originalDescription, saveEvent.Description))
                            v.Description = saveEvent.Description;

                        v.NumberOfCyclesAllowed = saveEvent.MaxCycles;
                        v.ImportanceLevel = saveEvent.InternalImportance;
                        v.RecalcEventDate = saveEvent.RecalcEventDate;
                        v.SuppressDueDateCalculation = saveEvent.SuppressCalculation;
                    }
                }

                _dbContext.SaveChanges();
                tcs.Complete();

                return new
                {
                    Result = "success",
                    Key = model.Id
                };
            }
        }

        public dynamic Delete(int eventId)
        {
            var validationErrors = ValidateDelete(eventId).ToArray();
            if (validationErrors.Any())
            {
                return new { Title = Resources.DeleteErrorTitle, Errors = validationErrors };
            }

            try
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext
                        .Set<EventModel.Event>()
                        .Single(_ => _.Id == eventId);

                    _dbContext.Set<EventModel.Event>().Remove(model);

                    _dbContext.SaveChanges();
                    tcs.Complete();
                }

                return new
                {
                    Result = "success"
                };
            }
            catch (Exception ex)
            {
                if (!ex.IsForeignKeyConstraintViolation())
                    throw;

                return KnownSqlErrors.CannotDelete.AsHandled();
            }
        }

        IEnumerable<ValidationError> Validate(EventSaveDetails saveEvent, Operation operation)
        {
            if (!Enum.IsDefined(typeof(Operation), operation)) throw new InvalidEnumArgumentException(nameof(operation), (int)operation, typeof(Operation));

            var all = _dbContext.Set<EventModel.Event>().ToArray();

            if (operation == Operation.Update && all.All(v => v.Id != saveEvent.Key)) throw new ArgumentException("Unable to retrieve event for update.");

            foreach (var validationError in CommonValidations.Validate(saveEvent))
                yield return validationError;
        }

        IEnumerable<dynamic> ValidateDelete(int eventId)
        {
            var all = _dbContext.Set<EventModel.Event>().ToArray();

            if (all.All(v => v.Id != eventId))
            {
                throw new ArgumentException("Cannot delete, event does not exist.");
            }

            var criterionList = FindCriterionEventUsedIn(eventId).ToArray();

            if (criterionList.Any())
            {
                yield return new { Message = Resources.DeleteEventErrorCritieria + string.Join(", ", criterionList) };
            }

            if (IsEventUsedInCases(eventId) && !criterionList.Any())
            {
                yield return new { Message = Resources.DeleteEventErrorOrphan };
            }
        }

        bool IsEventUsedInCases(int eventId)
        {
            return _dbContext.Set<CaseEvent>().Any(v => v.EventNo == eventId);
        }

        IEnumerable<int> FindCriterionEventUsedIn(int eventId)
        {
            var usedInChecklistItem = _dbContext.Set<ChecklistItem>().Where(v => v.YesAnsweredEventId == eventId || v.NoAnsweredEventId == eventId).Select(q => q.CriteriaId);
            var usedInDetailControl = _dbContext.Set<DataEntryTask>().Where(v => v.DisplayEventNo == eventId || v.HideEventNo == eventId || v.DimEventNo == eventId).Select(q => q.CriteriaId);
            var usedInEdeCaseEventRule = _dbContext.Set<EdeCaseEventRule>().Where(v => v.EventId == eventId).Select(q => q.CriteriaId);
            var usedInEventControl = _dbContext.Set<ValidEvent>().Where(v => v.EventId == eventId || v.SyncedEventId == eventId).Select(q => q.CriteriaId);
            var usedInFeesCalc = _dbContext.Set<FeesCalculation>().Where(v => v.FromEventId == eventId).Select(q => q.CriteriaId);

            var criterionList = usedInChecklistItem.Concat(usedInDetailControl).Concat(usedInEdeCaseEventRule).Concat(usedInEventControl).Concat(usedInFeesCalc);

            return criterionList;
        }

        EventModel.Event NewEvent()
        {
            var eventId = _taskSecurityProvider.HasAccessTo(ApplicationTask.CreateNegativeWorkflowRules)
                ? _lastInternalCodeGenerator.GenerateNegativeLastInternalCode(KnownInternalCodeTable.EventsMaxim)
                : _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Events);

            return _dbContext.Set<EventModel.Event>().Add(new EventModel.Event(eventId));
        }
    }
}