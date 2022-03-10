using System;
using System.Collections.Generic;
using System.Linq;
using AutoMapper;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    /// <summary>
    /// Steps is contained in Entry -> WindowControl ("WorkflowWizard") -> TopicControls (Step)
    /// </summary>
    public class StepsMaintenance : ISectionMaintenance, IReorderableSection
    {
        readonly IChangeTracker _changeTracker;
        readonly IDbContext _dbContext;
        readonly IMapper _mapper;
        readonly IWorkflowEntryStepsService _stepsService;

        public StepsMaintenance(IWorkflowEntryStepsService stepsService, IDbContext dbContext, IMapper mapper, IChangeTracker changeTracker)
        {
            _stepsService = stepsService;
            _dbContext = dbContext;
            _mapper = mapper;
            _changeTracker = changeTracker;
        }

        public void UpdateDisplayOrder(DataEntryTask entry, EntryControlRecordMovements movements)
        {
            if (!movements.StepMovements.Any())
                return;

            ApplyNewDisplayOrder(entry, movements);
            SetNextStepHash(entry, movements);
        }

        public bool PropagateDisplayOrder(EntryReorderSouce source, DataEntryTask target, EntryControlRecordMovements movements)
        {
            if (!movements.StepMovements.Any() || !(target.WorkflowWizard?.TopicControls.Any() ?? false))
                return false;

            var sourceSteps = source.StepsInDisplayOrder().Select(_ => _.Hash).ToArray();
            var targetSteps = target.StepsInDisplayOrder().Select(_ => _.HashCode()).ToArray();

            var common = sourceSteps.Intersect(targetSteps).ToArray();

            if (!common.Any())
                return false;

            var orderedSourceCommon = sourceSteps.Where(common.Contains).ToArray();
            var orderedTargetCommon = targetSteps.Where(common.Contains).ToArray();

            if (!orderedSourceCommon.SequenceEqual(orderedTargetCommon))
                return false;

            return ApplyNewDisplayOrder(target, movements);
        }

        public IEnumerable<ValidationError> Validate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues)
        {
            return _stepsService.Validate(entry, newValues);
        }

        public void SetDeltaForUpdate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var existingInheritedHashCodes = entry.WorkflowWizard?.TopicControls.Where(_ => _.IsInherited)
                                                  .Select(_ => _.HashCode())
                                                  .ToArray() ?? Enumerable.Empty<int>();

            var allExistingHashCodes = entry.WorkflowWizard?.TopicControls
                                            .Select(_ => _.HashCode())
                                            .ToList() ?? new List<int>();

            //For Updates
            //Take only inherited steps
            fieldsToUpdate.StepsDelta.Updated = fieldsToUpdate.StepsDelta.Updated
                                                              .Where(_ => _.OriginalHashCode.HasValue && existingInheritedHashCodes.Contains(_.OriginalHashCode.Value))
                                                              .ToArray();

            //Skip updates which can cause duplicates - remove inheritance for such items
            fieldsToUpdate.StepsRemoveInheritanceFor = (from possibleUpdate in fieldsToUpdate.StepsDelta.Updated
                                                        where possibleUpdate.OriginalHashCode.HasValue && possibleUpdate.NewHashCode.HasValue
                                                        where (possibleUpdate.OriginalHashCode != possibleUpdate.NewHashCode) && allExistingHashCodes.Contains(possibleUpdate.NewHashCode.Value)
                                                        select possibleUpdate.OriginalHashCode.Value).ToList();
            fieldsToUpdate.StepsDelta.Updated = fieldsToUpdate.StepsDelta.Updated
                                                              .Where(_ => _.OriginalHashCode.HasValue && !fieldsToUpdate.StepsRemoveInheritanceFor.Contains(_.OriginalHashCode.Value))
                                                              .ToArray();

            //For Deletes
            //Take only inherited steps
            fieldsToUpdate.StepsDelta.Deleted = fieldsToUpdate.StepsDelta.Deleted
                                                              .Where(_ => _.OriginalHashCode.HasValue && existingInheritedHashCodes.Contains(_.OriginalHashCode.Value))
                                                              .ToArray();

            //For Additions
            //Skip existing step and if it can cause duplication for steps with non-mandatory filters
            allExistingHashCodes.AddRange(from step in newValues.StepsDelta.Added
                                          where StepCategoryCodes.FilterOptional.Contains(step.ScreenType.Trim())
                                                && (entry.WorkflowWizard?.TopicControls.Any(_ => _.Name == step.Name) == true)
                                          select step.HashCode());

            fieldsToUpdate.StepsDelta.Added = fieldsToUpdate.StepsDelta.Added
                                                            .Where(_ => _.NewHashCode.HasValue && !allExistingHashCodes.Contains(_.NewHashCode.Value))
                                                            .ToArray();
        }

        public void ApplyChanges(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            ApplyDelete(entry, fieldsToUpdate);

            ApplyUpdates(entry, newValues, fieldsToUpdate);

            ApplyAdditions(entry, newValues, fieldsToUpdate);
        }

        public void RemoveInheritance(DataEntryTask entry, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var currentEntryTopicControls = entry.TaskSteps.SelectMany(_ => _.TopicControls).ToArray();
            var deltas = new[] { fieldsToUpdate.StepsDelta.Updated, fieldsToUpdate.StepsDelta.Deleted }.SelectMany(_ => _).Select(s => s.OriginalHashCode);

            foreach (var delta in deltas.Where(_ => _.HasValue))
                RemoveInheritanceFor(currentEntryTopicControls, delta.Value);
        }

        public void Reset(DataEntryTask entryToReset, DataEntryTask parentEntry, WorkflowEntryControlSaveModel newValues)
        {
            var allScreens = _dbContext.Set<Screen>();

            foreach (var s in parentEntry.TaskSteps)
            {
                foreach (var t in s.TopicControls)
                {
                    var saveModel = TopicControlToStepDelta(t);
                    saveModel.ScreenType = allScreens.Single(_ => _.ScreenName == t.Name).ScreenType;

                    // there should only be one "WorkflowWizard" window control per entry that contains the task steps
                    var windowControl = entryToReset.TaskSteps.FirstOrDefault();
                    if (windowControl != null)
                    {
                        var match = windowControl.TopicControls.SingleOrDefault(_ => _.HashCode() == saveModel.HashCode());
                        if (match != null)
                        {
                            saveModel.Id = match.Id;
                            newValues.StepsDelta.Updated.Add(saveModel);
                        }
                        else
                        {
                            newValues.StepsDelta.Added.Add(saveModel);
                        }
                    }
                    else
                    {
                        newValues.StepsDelta.Added.Add(saveModel);
                    }
                }
            }

            var steps = entryToReset.TaskSteps?.FirstOrDefault();
            if (steps != null)
            {
                var keep = newValues.StepsDelta.Updated.Select(_ => _.HashCode());
                var deletes = steps.TopicControls.Where(_ => !keep.Contains(_.HashCode()))
                                   .Select(_ => TopicControlToStepDelta(_, _.Id));
                newValues.StepsDelta.Deleted.AddRange(deletes);
            }
        }

        static StepDelta TopicControlToStepDelta(TopicControl t, int? id = null)
        {
            var stepDelta = new StepDelta
            {
                Id = id,
                Name = t.Name,
                Title = t.Title,
                ScreenTip = t.ScreenTip,
                IsMandatory = t.IsMandatory,
                OverrideRowPosition = t.RowPosition
            };

            var categories = new List<StepCategory>();
            
            if (!string.IsNullOrEmpty(t.Filter1Name))
                categories.Add(new StepCategory(StepCategoryCodes.PickerName(t.Filter1Name), t.Filter1Value));

            if (!string.IsNullOrEmpty(t.Filter2Name))
                categories.Add(new StepCategory(StepCategoryCodes.PickerName(t.Filter2Name), t.Filter2Value));

            stepDelta.Categories = categories.ToArray();

            return stepDelta;
        }

        void RemoveInheritanceFor(TopicControl[] topicControls, int hashCode)
        {
            var corresponding = topicControls.Where(_ => _.IsInherited)
                                             .Where(_ => _.HashCode() == hashCode)
                                             .ToList();
            if (!corresponding.Any())
                return;

            corresponding.ForEach(_ => _.IsInherited = false);
        }

        void ApplyDelete(DataEntryTask entry, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var stepHashCodesToBeDeleted = fieldsToUpdate.StepsDelta.Deleted.Select(_ => _.OriginalHashCode);
            var stepsToBeDeleted = entry.WorkflowWizard?.TopicControls.Where(_ => stepHashCodesToBeDeleted.Contains(_.HashCode())).ToArray() ?? Enumerable.Empty<TopicControl>();

            foreach (var deleted in stepsToBeDeleted)
                _dbContext.Set<TopicControl>().Remove(deleted);
        }

        void ApplyUpdates(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var isUpdatingChildCriteria = Helper.IsUpdateForChildCriteria(entry, newValues);
            var current = entry.TaskSteps.SelectMany(_ => _.TopicControls).ToArray();

            foreach (var updated in fieldsToUpdate.StepsDelta.Updated)
            {
                var target = current.Single(_ => updated.OriginalHashCode.HasValue && (_.HashCode() == updated.OriginalHashCode.Value));
                var change = newValues.StepsDelta.Updated.Single(_ => updated.NewHashCode.HasValue && (_.HashCode() == updated.NewHashCode.Value));

                target.Title = change.Title;
                target.ScreenTip = change.ScreenTip;
                target.IsMandatory = change.IsMandatory;

                if (!string.IsNullOrWhiteSpace(change.Filter1Name))
                {
                    target.Filter1Name = change.Filter1Name;
                    target.Filter1Value = change.Filter1Value.WhiteSpaceAsNull();
                }

                if (!string.IsNullOrWhiteSpace(change.Filter2Name))
                {
                    target.Filter2Name = change.Filter2Name;
                    target.Filter2Value = change.Filter2Value.WhiteSpaceAsNull();
                }

                if (!isUpdatingChildCriteria)
                    target.IsInherited = newValues.ResetInheritance;

                if (change.OverrideRowPosition.HasValue)
                    target.RowPosition = change.OverrideRowPosition.Value;
            }

            foreach (var topicControlHashCode in fieldsToUpdate.StepsRemoveInheritanceFor)
                RemoveInheritanceFor(current, topicControlHashCode);
        }

        void ApplyAdditions(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var isUpdatingChildCriteria = Helper.IsUpdateForChildCriteria(entry, newValues);

            foreach (var stepDelta in fieldsToUpdate.StepsDelta.Added)
            {
                var addedStep = newValues.StepsDelta.Added.Single(_ => _.HashCode() == stepDelta.NewHashCode);
                var displaySeq = addedStep.OverrideRowPosition ?? (entry.WorkflowWizard?.TopicControls.Any() == true ? entry.WorkflowWizard?.TopicControls.Max(_ => _.RowPosition) + 1 : 1);

                if (entry.WorkflowWizard != null && !newValues.ResetInheritance)
                {
                    if (stepDelta.RelativeHashCode.HasValue)
                    {
                        var relativeStep = entry.WorkflowWizard.TopicControls.Where(_ => _.HashCode() == stepDelta.RelativeHashCode.Value).ToArray();
                        if (relativeStep.Any() && (relativeStep.Length == 1))
                        {
                            displaySeq = relativeStep.Single().RowPosition + 1;
                            PushStepsDown(entry, displaySeq);
                        }
                    }
                    else
                    {
                        displaySeq = entry.WorkflowWizard?.TopicControls.Any() == true ? entry.WorkflowWizard.TopicControls.Min(_ => _.RowPosition) : 1;
                        PushStepsDown(entry, displaySeq);
                    }
                }

                var newStep = _mapper.Map<TopicControl>(addedStep);
                newStep.TopicSuffix = Guid.NewGuid().ToString();
                newStep.RowPosition = (short)displaySeq;
                newStep.IsInherited = isUpdatingChildCriteria || newValues.ResetInheritance;

                entry.AddWorkflowWizardStep(newStep);
            }
        }

        bool ApplyNewDisplayOrder(DataEntryTask entry, EntryControlRecordMovements movements)
        {
            var steps = entry.WorkflowWizard?.TopicControls.ToDictionary(_ => _.HashCode(), _ => _);
            if (steps == null)
                return false;

            var min = entry.StepsInDisplayOrder().Any() ? entry.StepsInDisplayOrder().DefaultIfEmpty().Min(_ => _.RowPosition) : (short)1;

            var hasChanged = false;

            foreach (var s in movements.StepMovements)
            {
                TopicControl target;
                TopicControl relativeTopicControl;

                if (!steps.TryGetValue(s.OriginalStepHashCode, out target))
                    continue;

                int? targetPosition = null;
                if (!s.PrevStepHashCode.HasValue)
                {
                    targetPosition = min;
                }
                else if (steps.TryGetValue(s.PrevStepHashCode.Value, out relativeTopicControl))
                {
                    targetPosition = relativeTopicControl.RowPosition + 1;
                }
                else if (s.NextStepHashCode.HasValue && steps.TryGetValue(s.NextStepHashCode.Value, out relativeTopicControl))
                {
                    targetPosition = relativeTopicControl.RowPosition;
                }

                if (targetPosition.HasValue)
                {
                    PushStepsDown(entry, targetPosition);
                    target.RowPosition = (short)targetPosition;
                }

                if (!hasChanged)
                    hasChanged = _changeTracker.HasChanged(target);
            }

            if (hasChanged)
                entry.ResequenceSteps();

            return hasChanged;
        }

        static void SetNextStepHash(DataEntryTask entry, EntryControlRecordMovements movements)
        {
            var hashCodes = entry.StepsInDisplayOrder().DefaultIfEmpty().Select(_ => _.HashCode()).ToList();
            foreach (var s in movements.StepMovements)
            {
                if (!hashCodes.Contains(s.OriginalStepHashCode) || !s.PrevStepHashCode.HasValue)
                    continue;

                var prevStepIndex = hashCodes.FindIndex(_ => _ == s.OriginalStepHashCode);
                s.NextStepHashCode = hashCodes.Skip(prevStepIndex + 1).Any() ? hashCodes.Skip(prevStepIndex + 1).First() : null;
            }
        }

        static void PushStepsDown(DataEntryTask entry, int? from)
        {
            if (entry.WorkflowWizard == null || !entry.WorkflowWizard.TopicControls.Any())
                return;

            foreach (var entryStep in entry.WorkflowWizard.TopicControls.Where(_ => _.RowPosition >= from))
                entryStep.RowPosition++;
        }
    }
}