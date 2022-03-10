using System;
using System.Linq;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions
{
    public static class DataEntryTaskExtensions
    {
        public static EntryAttribute AsEntryAttribute(
            this short? attribute,
            EntryAttribute defaultAttribute = EntryAttribute.Hide)
        {
            return (EntryAttribute) attribute.GetValueOrDefault((short) defaultAttribute);
        }

        public static bool IsEditable(this EntryAttribute attribute)
        {
            return attribute == EntryAttribute.EntryMandatory ||
                   attribute == EntryAttribute.EntryOptional ||
                   attribute == EntryAttribute.DefaultToSystemDate;
        }

        public static bool IsMandatory(this EntryAttribute attribute)
        {
            return attribute == EntryAttribute.EntryMandatory;
        }

        public static AvailableEvent EventForCycleConsideration(this DataEntryTask task)
        {
            if (task == null) throw new ArgumentNullException(nameof(task));

            return task.EventsInDisplayOrder().FirstOrDefault();
        }

        public static IOrderedEnumerable<AvailableEvent> EventsInDisplayOrder(this DataEntryTask task)
        {
            if (task == null) throw new ArgumentNullException(nameof(task));

            return task.AvailableEvents.OrderBy(ae => ae.DisplaySequence);
        }

        public static void ResequenceEvents(this DataEntryTask task)
        {
            short i = 1;
            foreach (var entryAvailableEvent in task.EventsInDisplayOrder())
            {
                entryAvailableEvent.DisplaySequence = i++;
            }
        }

        public static DataEntryTask RemoveInheritance(this DataEntryTask dataEntryTask)
        {
            if (dataEntryTask == null) throw new ArgumentNullException(nameof(dataEntryTask));

            dataEntryTask.Inherited = 0;
            dataEntryTask.ParentCriteriaId = null;
            dataEntryTask.ParentEntryId = null;
            foreach (var availableEvent in dataEntryTask.AvailableEvents.Where(_ => _.IsInherited))
            {
                availableEvent.Inherited = 0;
            }

            foreach (var document in dataEntryTask.DocumentRequirements.Where(_ => _.IsInherited))
            {
                document.Inherited = 0;
            }

            foreach (var user in dataEntryTask.UsersAllowed.Where(_ => _.IsInherited))
            {
                user.Inherited = 0;
            }

            foreach (var group in dataEntryTask.GroupsAllowed.Where(_ => _.IsInherited))
            {
                group.Inherited = 0;
            }

            foreach (var task in dataEntryTask.WorkflowWizard?.TopicControls.Where(_ => _.IsInherited) ?? Enumerable.Empty<TopicControl>())
            {
                task.IsInherited = false;
            }

            foreach (var role in dataEntryTask.RolesAllowed.Where(_ => _.Inherited.GetValueOrDefault()))
            {
                role.Inherited = false;
            }

            return dataEntryTask;
        }

        public static void InheritRuleFrom(this DataEntryTask dataEntryTask, DataEntryTask from)
        {
            if (dataEntryTask == null) throw new ArgumentNullException(nameof(dataEntryTask));
            if (@from == null) throw new ArgumentNullException(nameof(@from));

            dataEntryTask.IsInherited = true;
            dataEntryTask.ParentCriteriaId = from.CriteriaId;
            dataEntryTask.ParentEntryId = from.Id;
            dataEntryTask.CopyFrom(from);
        }

        static void CopyFrom(this DataEntryTask dataEntryTask, DataEntryTask from)
        {
            dataEntryTask.Description = from.Description;
            dataEntryTask.TakeoverFlag = from.TakeoverFlag;
            dataEntryTask.DimEventNo = from.DimEventNo;
            dataEntryTask.DisplayEventNo = from.DisplayEventNo;
            dataEntryTask.HideEventNo = from.HideEventNo;
            dataEntryTask.CaseStatusCodeId = from.CaseStatusCodeId;
            dataEntryTask.RenewalStatusId = from.RenewalStatusId;
            dataEntryTask.OfficialNumberTypeId = from.OfficialNumberTypeId;
            dataEntryTask.FileLocationId = from.FileLocationId;
            dataEntryTask.UserInstruction = from.UserInstruction;
            dataEntryTask.AtLeastOneFlag = from.AtLeastOneFlag;
            dataEntryTask.ShouldPoliceImmediate = from.ShouldPoliceImmediate;
            dataEntryTask.EntryCode = from.EntryCode;
            dataEntryTask.ShowTabs = from.ShowTabs;
            dataEntryTask.ShowMenus = from.ShowMenus;
            dataEntryTask.ShowToolBar = from.ShowToolBar;
            dataEntryTask.ChargeGenerationFlag = from.ChargeGenerationFlag;
            dataEntryTask.IsSeparator = from.IsSeparator;
        }

        public static IQueryable<DataEntryTask> Inherited(this IQueryable<DataEntryTask> entries)
        {
            return entries.Where(_ => _.Inherited == 1);
        }

        public static IQueryable<DataEntryTask> PartiallyInherited(this IQueryable<DataEntryTask> entries)
        {
            return entries.Where(_ => _.AvailableEvents.Any(a => a.Inherited == 1) ||
                                      _.GroupsAllowed.Any(g => g.Inherited == 1) ||
                                      _.UsersAllowed.Any(u => u.Inherited == 1) ||
                                      _.DocumentRequirements.Any(a => a.Inherited == 1) ||
                                      _.TaskSteps.Any(t => t.IsInherited == true)
                );
        }

        public static IQueryable<TopicControl> StepsByName(this DataEntryTask task, string name)
        {
            if (task == null) throw new ArgumentNullException(nameof(task));

            return task.TaskSteps.SelectMany(_ => _.TopicControls).Where(_ => _.Name == name).AsQueryable();
        }

        public static TopicControl SingleStepByName(this DataEntryTask task, string name)
        {
            if (task == null) throw new ArgumentNullException(nameof(task));

            return task.TaskSteps.SelectMany(_ => _.TopicControls).Single(_ => _.Name == name);
        }

        public static IOrderedEnumerable<TopicControl> StepsInDisplayOrder(this DataEntryTask task)
        {
            if (task == null) throw new ArgumentNullException(nameof(task));

            return task.WorkflowWizard?.TopicControls.OrderBy(ae => ae.RowPosition);
        }

        public static void ResequenceSteps(this DataEntryTask task)
        {
            if (task == null) throw new ArgumentNullException(nameof(task));

            short i = 1;
            foreach (var step in task.StepsInDisplayOrder().DefaultIfEmpty())
            {
                step.RowPosition = i++;
            }
        }
    }
}