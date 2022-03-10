using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using AvailableTopic = Inprotech.Web.Picklists.AvailableTopic;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public interface IWorkflowEntryStepsService
    {
        IOrderedEnumerable<WorkflowEntryStepViewModel> GetSteps(int criteriaId, int entryId);
        IEnumerable<ValidationError> Validate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues);
    }

    public class WorkflowEntryStepsService : IWorkflowEntryStepsService
    {
        readonly IAvailableTopicsReader _availableTopicsReader;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly Dictionary<string, IStepCategory> _categories;
        readonly IDbContext _dbContext;
        readonly IWorkflowPermissionHelper _permissionHelper;

        public WorkflowEntryStepsService(IDbContext dbContext, IWorkflowPermissionHelper permissionHelper, IAvailableTopicsReader availableTopicsReader, IEnumerable<IStepCategory> categories, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _permissionHelper = permissionHelper;
            _availableTopicsReader = availableTopicsReader;
            _preferredCultureResolver = preferredCultureResolver;
            _categories = categories.ToDictionary(k => k.CategoryType, v => v);
        }

        public IOrderedEnumerable<WorkflowEntryStepViewModel> GetSteps(int criteriaId, int entryId)
        {
            var criteria = _dbContext.Set<Criteria>().Single(_ => _.Id == criteriaId && _.PurposeCode == CriteriaPurposeCodes.EventsAndEntries);

            var windowControl = _dbContext.Set<WindowControl>()
                                          .Include(_ => _.TopicControls.Select(t => t.Filters))
                                          .FirstOrDefault(_ => _.CriteriaId == criteriaId && _.EntryNumber == entryId);

            if (windowControl == null || !windowControl.TopicControls.Any())
                return Enumerable.Empty<WorkflowEntryStepViewModel>().OrderBy(x => 1);

            var topicControls = windowControl.TopicControls.Select(t => t.Name).ToArray();

            var canEdit = _permissionHelper.CanEdit(criteria);

            var steps = _availableTopicsReader.Retrieve()
                                              .Where(_ => topicControls.Contains(_.Key))
                                              .ToArray()
                                              .Select(_ => new AvailableTopic
                                                      {
                                                          Key = _.Key,
                                                          DefaultTitle = _.DefaultTitle,
                                                          IsWebEnabled = _.IsWebEnabled,
                                                          Type = _.Type
                                                      })
                                              .ToDictionary(k => k.Key, v => v);

            var result = windowControl.TopicControls
                                .Select(t => new WorkflowEntryStepViewModel
                                        {
                                            Id = t.Id,
                                            Step = steps[t.Name],
                                            Title = t.Title,
                                            ScreenTip = t.ScreenTip,
                                            DisplaySequence = t.RowPosition,
                                            IsInherited = t.IsInherited,
                                            IsMandatory = t.IsMandatory,
                                            Categories = t.Filters.Any() ?
                                                t.Filters.Select(f => ConvertFilterToStepCategory(criteria, f)).Where(c => c != null).ToArray()
                                                : new StepCategory[] {}
                                        })
                                .ToArray()
                                .OrderBy(_ => _.DisplaySequence);

            if (!canEdit)
            {
                var culture = _preferredCultureResolver.Resolve();

                var ids = result.Select(_ => _.Id).ToArray();

                var translated = _dbContext.Set<TopicControl>()
                                           .Where(_ => ids.Contains(_.Id))
                                           .Select(_ => new
                                                        {
                                                            _.Id,
                                                            Title = DbFuncs.GetTranslation(_.Title, null, _.TitleTId, culture),
                                                            ScreenTip = DbFuncs.GetTranslation(_.ScreenTip, null, _.ScreenTipTId, culture)
                                                        }).ToDictionary(k => k.Id, v => v);

                foreach (var r in result)
                {
                    r.Title = translated[r.Id].Title;
                    r.ScreenTip = translated[r.Id].ScreenTip;
                }
            }

            return result;
        }

        public IEnumerable<ValidationError> Validate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues)
        {
            var duplicates = new HashSet<StepDelta>();
            var required = new HashSet<StepDelta>();
            var existing = entry.TaskSteps.SelectMany(_ => _.TopicControls).Cast<IFlattenTopic>().ToArray();
            var equalityComparer = new FlattenTopicEqualityComparer();
            var addedOrModified = new[]
                {
                    newValues.StepsDelta.Added,
                    newValues.StepsDelta.Updated
                }
                .SelectMany(_ => _)
                .ToDictionary(k => k, v => (IFlattenTopic) v);

            foreach (var step in addedOrModified)
            {
                var update = newValues.StepsDelta.Updated.Contains(step.Key);

                if (existing.Contains(step.Value, equalityComparer) && !update)
                {
                    duplicates.Add(step.Key);
                }

                if (update && addedOrModified.Values.Count(_ => equalityComparer.Equals(_, step.Value)) > 1)
                {
                    duplicates.Add(step.Key);
                }

                if (!update && StepCategoryCodes.FilterOptional.Contains(step.Key.ScreenType.Trim()) && existing.Any(_ => _.Name == step.Key.Name))
                {
                    duplicates.Add(step.Key);
                }

                if (!StepCategoryCodes.FilterOptional.Contains(step.Key.ScreenType.Trim()) && step.Key.Categories.Any(_ => _.CategoryValue == null))
                {
                    required.Add(step.Key);
                }
            }

            foreach (var duplicateStep in duplicates)
            {
                yield return ValidationErrors.NotUnique("steps", "title", duplicateStep.Id);
            }

            foreach (var other in required.Except(duplicates))
            {
                yield return ValidationErrors.Required("steps", "categoryValue", other.Id.HasValue? other.Id.ToString() : other.NewItemId);
            }
        }

        StepCategory ConvertFilterToStepCategory(Criteria criteria, TopicControlFilter filter)
        {
            if (filter == null)
            {
                return null;
            }

            var pickerModel = StepCategoryCodes.PickerName(filter.FilterName);
            return pickerModel == null ? null : _categories[pickerModel].Get(filter, criteria);
        }
    }
}