using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public interface IWorkflowEntryInheritanceService
    {
        IEnumerable<DataEntryTask> InheritNewEntries(Criteria criteria, IEnumerable<DataEntryTask> newParentCriteriaEntries, bool replaceCommonRules);
    }

    public class WorkflowEntryInheritanceService : IWorkflowEntryInheritanceService
    {
        readonly IDbContext _dbContext;

        public WorkflowEntryInheritanceService(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<DataEntryTask> InheritNewEntries(Criteria criteria, IEnumerable<DataEntryTask> newParentCriteriaEntries, bool replaceCommonRules)
        {
            var parentCriteriaEntries = newParentCriteriaEntries as DataEntryTask[] ?? newParentCriteriaEntries.ToArray();

            var duplicates = parentCriteriaEntries
                .GroupBy(i => i.IsSeparator ? i.Description.ToLower() : i.Description.ToLower().StripNonAlphanumerics())
                .Where(g => g.Count() > 1)
                .Select(g => g)
                .Union(criteria.DataEntryTasks
                               .GroupBy(i => i.IsSeparator ? i.Description.ToLower() : i.Description.ToLower().StripNonAlphanumerics())
                               .Where(g => g.Count() > 1)
                               .Select(g => g)).ToArray();

            if (duplicates.Any())
                throw new DuplicateEntryDescriptionException(string.Join(", ", duplicates.Select(d => d.First().CriteriaId + " - " + d.First().Description)));

            var matchedEntries = SplitMatchingAndNonMatching(criteria.DataEntryTasks.ToArray(), parentCriteriaEntries).ToArray();

            // always add the non-matching entries
            var nonMatchingEntries = matchedEntries.Where(_ => !_.IsMatch).Select(_ => _.ParentEntry).OrderBy(_ => _.DisplaySequence).ToList();
            var lastChildDisplaySequence = criteria.DataEntryTasks.Any() ? criteria.DataEntryTasks.Max(_ => _.DisplaySequence) : (short) -1;
            var lastChildEntryId = criteria.DataEntryTasks.Any() ? criteria.DataEntryTasks.Max(_ => _.Id) : (short) -1;
            var inheritedEntries = nonMatchingEntries.Select(_ => InheritDataEntryTask(criteria, _, ++lastChildEntryId, ++lastChildDisplaySequence)).ToList();

            if (replaceCommonRules)
            {
                var matchingChildEntryIds = matchedEntries.Where(_ => _.IsMatch).Select(_ => _.ChildEntry.Id).ToList();
                var stepsToDelete = _dbContext.Set<WindowControl>().Where(_ => _.CriteriaId == criteria.Id && _.EntryNumber != null && matchingChildEntryIds.Contains(_.EntryNumber.Value));

                if (stepsToDelete.Any())
                    _dbContext.Delete(stepsToDelete);

                var entriesToDelete = _dbContext.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteria.Id && matchingChildEntryIds.Contains(_.Id));
                if (entriesToDelete.Any())
                    _dbContext.Delete(_dbContext.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteria.Id && matchingChildEntryIds.Contains(_.Id)));

                inheritedEntries.AddRange(matchedEntries.Where(_ => _.IsMatch).Select(_ => InheritDataEntryTask(criteria, _.ParentEntry, _.ChildEntry.Id, _.ChildEntry.DisplaySequence)));
            }

            InheritDataEntryTaskSteps(inheritedEntries);

            _dbContext.AddRange(inheritedEntries);
            _dbContext.SaveChanges();

            return inheritedEntries;
        }

        public virtual IEnumerable<EntryMatch> SplitMatchingAndNonMatching(DataEntryTask[] criteriaEntries, DataEntryTask[] parentCriteriaEntries)
        {
            return (from p in parentCriteriaEntries
                    join c in criteriaEntries on p.Description.ToLower().StripNonAlphanumerics() equals c.Description.ToLower().StripNonAlphanumerics() into pc
                    from c in pc.DefaultIfEmpty()
                    where !p.IsSeparator
                    select new EntryMatch(p, c))
                    .Union(from p in parentCriteriaEntries
                           join c in criteriaEntries on p.Description.ToLower() equals c.Description.ToLower() into pc
                           from c in pc.DefaultIfEmpty()
                           where p.IsSeparator
                           select new EntryMatch(p, c))
                    .ToArray();
        }

        public virtual DataEntryTask InheritDataEntryTask(Criteria criteria, DataEntryTask parentDataEntryTask, short entryId, short displaySequence)
        {
            var newDataEntryTask = new DataEntryTask(criteria, entryId) {DisplaySequence = displaySequence};
            newDataEntryTask.InheritRuleFrom(parentDataEntryTask);

            newDataEntryTask.AvailableEvents = parentDataEntryTask.AvailableEvents.Any() ? parentDataEntryTask.AvailableEvents.Select(_ => new AvailableEvent(newDataEntryTask, _.Event).InheritRuleFrom(_)).ToList() : new List<AvailableEvent>();
            newDataEntryTask.DocumentRequirements = parentDataEntryTask.DocumentRequirements.Any() ? parentDataEntryTask.DocumentRequirements.Select(_ => new DocumentRequirement(criteria, newDataEntryTask, _.Document).InheritRuleFrom(_)).ToList() : new List<DocumentRequirement>();
            newDataEntryTask.GroupsAllowed = parentDataEntryTask.GroupsAllowed.Any() ? parentDataEntryTask.GroupsAllowed.Select(_ => new GroupControl(newDataEntryTask, _.SecurityGroup) {IsInherited = true}).ToList() : new List<GroupControl>();
            newDataEntryTask.UsersAllowed = parentDataEntryTask.UsersAllowed.Any() ? parentDataEntryTask.UsersAllowed.Select(_ => new UserControl(_.UserId, criteria.Id, newDataEntryTask.Id) {IsInherited = true}).ToList() : new List<UserControl>();
            newDataEntryTask.RolesAllowed = parentDataEntryTask.RolesAllowed.Any() ? parentDataEntryTask.RolesAllowed.Select(_ => new RolesControl(_.RoleId, criteria.Id, newDataEntryTask.Id) {Inherited = true}).ToList() : new List<RolesControl>();

            return newDataEntryTask;
        }

        public virtual void InheritDataEntryTaskSteps(IEnumerable<DataEntryTask> inheritedDataEntryTasks)
        {
            var dataEntryTasks = inheritedDataEntryTasks as DataEntryTask[] ?? inheritedDataEntryTasks.ToArray();
            if (!dataEntryTasks.Any()) return;

            var parentCriteriaId = dataEntryTasks.First().ParentCriteriaId;
            var parentSteps = _dbContext.Set<WindowControl>().Where(_ => _.CriteriaId == parentCriteriaId).ToArray();
            
            foreach (var t in dataEntryTasks)
            {
                var parentEntrySteps = parentSteps.Where(_ => _.EntryNumber == t.ParentEntryId).SelectMany(_=>_.TopicControls);

                foreach (var step in parentEntrySteps)
                {
                    t.AddWorkflowWizardStep(step.InheritRuleFrom());
                }
            }
        }

        public class EntryMatch
        {
            public EntryMatch(DataEntryTask parent, DataEntryTask child)
            {
                ParentEntry = parent;
                ChildEntry = child;
            }

            public DataEntryTask ParentEntry { get; set; }
            public DataEntryTask ChildEntry { get; set; }

            public bool IsMatch => ChildEntry != null;
        }
    }

    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable")]
    public class DuplicateEntryDescriptionException : Exception
    {
        public DuplicateEntryDescriptionException(string message) : base(message)
        {
        }
    }
}