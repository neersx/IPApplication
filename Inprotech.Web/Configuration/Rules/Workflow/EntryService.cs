using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

#pragma warning disable 618

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public interface IEntryService
    {
        void GetAdjacentEntries(int criteriaId, short entryId, out short? prevId, out short? nextId);

        void ReorderEntries(int criteriaId, short sourceEntryId, short targetEntryId, bool insertBefore);

        void ReorderDescendantEntries(int criteriaId, short sourceEntryId, short targetEntryId, short? prevTargetId, short? nextTargetId, bool insertBefore);

        dynamic AddEntry(int criteriaId, string entryDescription, int? insertAfterEntryId, bool applyToChildren, bool isSeparator = false);

        dynamic AddEntryWithEvents(int criteriaId, string entryDescription, int[] eventNo, bool applyToChildren);

        void DeleteEntries(int criteriaId, short[] entryIds, bool appliesToDescendants);
    }

    public class EntryService : IEntryService
    {
        readonly IDbContext _dbContext;
        readonly IInheritance _inheritance;
        readonly IDescriptionValidator _descriptionValidator;

        public EntryService(IDbContext dbContext, IInheritance inheritance, IDescriptionValidator descriptionValidator)
        {
            _dbContext = dbContext;
            _inheritance = inheritance;
            _descriptionValidator = descriptionValidator;
        }

        public void GetAdjacentEntries(int criteriaId, short entryId, out short? prevId, out short? nextId)
        {
            prevId = nextId = null;
            var entryIds = _dbContext.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteriaId).OrderBy(_ => _.DisplaySequence).Select(_ => _.Id).ToList();
            var targetIndex = entryIds.IndexOf(entryId);

            if (targetIndex == -1)
                return;

            prevId = targetIndex > 0 ? entryIds[targetIndex - 1] : (short?) null;
            nextId = targetIndex < entryIds.Count - 1 ? entryIds[targetIndex + 1] : (short?) null;
        }

        public void ReorderEntries(int criteriaId, short sourceEntryId, short targetEntryId, bool insertBefore)
        {
            if (sourceEntryId == targetEntryId)
                return;

            var entries = _dbContext.Set<DataEntryTask>()
                                    .Where(_ => _.CriteriaId == criteriaId && (_.Id == targetEntryId || _.Id == sourceEntryId))
                                    .Select(_ => new {_.Id, _.DisplaySequence})
                                    .ToArray();

            if (entries.Count(_ => _.Id == sourceEntryId) != 1)
                throw new KeyNotFoundException("sourceEntryId");

            var target = entries.SingleOrDefault(_ => _.Id == targetEntryId);
            if (target == null)
                throw new KeyNotFoundException("targetEntryId");

            PushEntriesDownByOneLevel(criteriaId, sourceEntryId, insertBefore ? target.DisplaySequence : target.DisplaySequence + 1);
        }

        public void ReorderDescendantEntries(int criteriaId, short sourceEntryId, short targetEntryId, short? prevTargetId, short? nextTargetId, bool insertBefore)
        {
            var descendantIds = _inheritance.GetDescendantsWithMatchedDescription(criteriaId, sourceEntryId).ToArray();
            if (!descendantIds.Any())
                return;

            short? fallbackTargetId;
            bool fallbackInsertBefore;
            DetermineFallback(targetEntryId, prevTargetId, nextTargetId, insertBefore, out fallbackTargetId, out fallbackInsertBefore);

            var ids = new[] {sourceEntryId, targetEntryId, fallbackTargetId};
            var descriptions = _dbContext.Set<DataEntryTask>()
                                         .Where(_ => _.CriteriaId == criteriaId && ids.Contains(_.Id))
                                         .Select(_ => new {_.Id, _.Description, _.IsSeparator})
                                         .ToDictionary(arg => arg.Id, arg => new EntryDescription {Description = arg.Description, IsSeparator = arg.IsSeparator});

            var fallbackTarget = fallbackTargetId.HasValue && descriptions.ContainsKey(fallbackTargetId.Value) ? descriptions[fallbackTargetId.Value] : null;

            foreach (var descendantId in descendantIds)
            {
                ReorderChildEntries(descendantId, descriptions[sourceEntryId], descriptions[targetEntryId], insertBefore, fallbackTarget, fallbackInsertBefore);
            }
        }

        public class EntryDescription
        {
            public string Description { get; set; }
            public bool IsSeparator { get; set; }
        }

        public dynamic AddEntry(int criteriaId, string entryDescription, int? insertAfterEntryId, bool applyToChildren, bool isSeparator = false)
        {
            return AddEntry(criteriaId, entryDescription, insertAfterEntryId, applyToChildren, isSeparator, null);
        }

        public dynamic AddEntryWithEvents(int criteriaId, string entryDescription, int[] eventNo, bool applyToChildren)
        {
            return AddEntry(criteriaId, entryDescription, null, applyToChildren, false, eventNo);
        }

        public void DeleteEntries(int criteriaId, short[] entryIds, bool appliesToDescendants)
        {
            using (var trans = _dbContext.BeginTransaction())
            {
                var descendantIds = _inheritance.GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(criteriaId, entryIds, !appliesToDescendants).ToArray();
                var groupedEntriesByCriteria = descendantIds.GroupBy(_ => _.CriteriaId)
                                                            .Select(g => new
                                                            {
                                                                g.Key,
                                                                EntryIds = g.Select(_ => _.EntryId).ToArray()
                                                            });

                var dataEntryTasks = appliesToDescendants
                    ? _dbContext.Set<DataEntryTask>()
                    : _dbContext.Set<DataEntryTask>()
                                .Include(_ => _.AvailableEvents)
                                .Include(_ => _.DocumentRequirements)
                                .Include(_ => _.GroupsAllowed)
                                .Include(_ => _.UsersAllowed)
                                .Include(_ => _.TaskSteps);

                var eligibleEntries = Enumerable.Empty<DataEntryTask>().AsQueryable();

                foreach (var group in groupedEntriesByCriteria)
                {
                    eligibleEntries = eligibleEntries.Concat(dataEntryTasks.Where(_ => _.CriteriaId == group.Key && group.EntryIds.Contains(_.Id)).ToArray());
                }

                if (appliesToDescendants)
                {
                    _dbContext.RemoveRange(eligibleEntries.ToArray());
                }
                else
                {
                    eligibleEntries.ToList().ForEach(_ => _.RemoveInheritance());
                }

                if (entryIds.Any())
                {
                    _dbContext.Delete(_dbContext.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteriaId && entryIds.Contains(_.Id)));
                }

                _dbContext.SaveChanges();
                trans.Complete();
            }
        }

        static void DetermineFallback<T>(T targetEntryId, T prevTargetId, T nextTargetId, bool insertBefore, out T fallbackTargetId, out bool fallbackInsertBefore)
        {
            if (insertBefore)
            {
                if (prevTargetId != null)
                {
                    //Previous entry is fallback, if promoting
                    fallbackTargetId = prevTargetId;
                    fallbackInsertBefore = false;
                }
                else
                {
                    // but if moving to top, use next entry as fallback
                    fallbackTargetId = nextTargetId;
                    fallbackInsertBefore = true;
                }
            }
            else
            {
                if (nextTargetId != null)
                {
                    //Next entry is fallback, if demoting
                    fallbackTargetId = nextTargetId;
                    fallbackInsertBefore = true;
                }
                else
                {
                    // but if moving to bottom, use previous entry as fallback
                    fallbackTargetId = prevTargetId;
                    fallbackInsertBefore = false;
                }
            }
        }

        void ReorderChildEntries(int criteriaId, EntryDescription sourceEntry, EntryDescription targetEntry, bool insertBefore, EntryDescription fallbackEntry, bool fallbackInsertbefore)
        {
            var entries = _dbContext.Set<DataEntryTask>()
                                    .Where(_ => _.CriteriaId == criteriaId)
                                    .Select(_ => new {_.Id, _.Description, _.DisplaySequence, _.IsSeparator})
                                    .ToList();

            var sources = entries.Where(_ => _.IsSeparator == sourceEntry.IsSeparator).Where(_ => !Helper.AreDescriptionsDifferent(_.Description, sourceEntry.Description, !sourceEntry.IsSeparator)).ToArray();
            var targets = entries.Where(_ => _.IsSeparator == targetEntry.IsSeparator).Where(_ => !Helper.AreDescriptionsDifferent(_.Description, targetEntry.Description, !targetEntry.IsSeparator)).ToArray();
            var fallbacks = !string.IsNullOrEmpty(fallbackEntry.Description)
                ? entries.Where(_ => _.IsSeparator == fallbackEntry.IsSeparator).Where(_ => !Helper.AreDescriptionsDifferent(_.Description, fallbackEntry.Description, !fallbackEntry.IsSeparator)).ToArray()
                : Enumerable.Empty<dynamic>().ToArray();

            if (sources.Length != 1 || targets.Length > 1)
                return;

            var sourceId = sources.Single().Id;
            var target = targets.SingleOrDefault();

            if (target != null)
            {
                PushEntriesDownByOneLevel(criteriaId, sourceId, insertBefore ? target.DisplaySequence : target.DisplaySequence + 1);
            }
            else
            {
                if (fallbacks.Length != 1)
                    return;

                var fallbackTarget = fallbacks.Single();
                PushEntriesDownByOneLevel(criteriaId, sourceId, fallbackInsertbefore ? fallbackTarget.DisplaySequence : fallbackTarget.DisplaySequence + 1);
            }
        }

        internal void PushEntriesDownByOneLevel(int criteriaId, int moveEntryId, int fromdisplaySeq)
        {
            _dbContext.Update(_dbContext.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteriaId && _.DisplaySequence >= fromdisplaySeq),
                              _ =>
                                  new DataEntryTask
                                  {
                                      DisplaySequence = (short) (_.DisplaySequence + 1)
                                  });
            _dbContext.Update(_dbContext.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteriaId && _.Id == moveEntryId),
                              _ =>
                                  new DataEntryTask
                                  {
                                      DisplaySequence = (short) fromdisplaySeq
                                  });
        }

        dynamic AddEntry(int criteriaId, string entryDescription, int? insertAfterEntryId, bool applyToChildren, bool isSeparator, int[] eventIds)
        {
            var criteria = _dbContext.Set<Criteria>()
                                     .Include(x => x.DataEntryTasks).WhereWorkflowCriteria().Single(_ => _.Id == criteriaId);

            if (string.IsNullOrWhiteSpace(entryDescription) && !isSeparator)
                return ValidationErrors.SetError("entryDescription", "required").AsErrorResponse();

            if (!_descriptionValidator.IsDescriptionUniqueIn(criteria.DataEntryTasks.ToArray(), entryDescription, isSeparator))
                return ValidationErrors.SetError("entryDescription", "notunique").AsErrorResponse();

            List<Event> events = null;

            if (eventIds != null)
            {
                events = criteria.ValidEvents
                                 .Where(_ => eventIds.Contains(_.EventId))
                                 .OrderBy(_ => _.DisplaySequence)
                                 .Select(_ => _.Event)
                                 .ToList();
            }

            var newEntry = CreateNewEntry(criteria, entryDescription, isSeparator);

            using (var tx = _dbContext.BeginTransaction())
            {
                var insertAfterEntry = criteria.DataEntryTasks.SingleOrDefault(_ => _.Id == insertAfterEntryId);

                short seq;

                if (insertAfterEntry != null)
                {
                    seq = insertAfterEntry.DisplaySequence;
                    IncrementSequencesAfter(criteria, seq);
                }
                else
                {
                    seq = MaxValidEntrySequence(criteria.DataEntryTasks);
                }

                newEntry.DisplaySequence = (short) (seq + 1);
                newEntry.Id = (short) (criteria.DataEntryTasks.Any() ? criteria.DataEntryTasks.Max(_ => _.Id) + 1 : 0);

                if (events != null)
                    AddEventsToEntry(newEntry, events);

                _dbContext.Set<DataEntryTask>().Add(newEntry);

                if (applyToChildren)
                {
                    var descendentModels = ApplyToChildren(newEntry, events, insertAfterEntry);
                    _dbContext.AddRange(descendentModels);
                }

                _dbContext.SaveChanges();

                tx.Complete();
            }

            return newEntry;
        }

        short MaxValidEntrySequence(IEnumerable<DataEntryTask> entries)
        {
            var validEntries = entries.ToArray();
            return (short) (validEntries.Any() ? validEntries.Max(e => e.DisplaySequence) : 0);
        }

        void IncrementSequencesAfter(Criteria criteria, int sequence)
        {
            _dbContext.Update(_dbContext.Set<DataEntryTask>()
                                        .Where(e => e.CriteriaId == criteria.Id && e.DisplaySequence > sequence), ve => new DataEntryTask {DisplaySequence = (short) (ve.DisplaySequence + 1)});
        }

        DataEntryTask CreateNewEntry(Criteria criteria, string description, bool isSeparator)
        {
            // use Create method to ensure EF attaches new model to db context, otherwise lazy loading nav properties returns null
            var newEntry = _dbContext.Set<DataEntryTask>().Create();
            newEntry.CriteriaId = criteria.Id;
            newEntry.Id = (short) ((criteria.DataEntryTasks.Any() ? criteria.DataEntryTasks.Max(_ => _.Id) : 0) + 1);
            newEntry.Description = description;
            newEntry.IsSeparator = isSeparator;
            return newEntry;
        }

        DataEntryTask CreateNewInheritedEntry(Criteria c, DataEntryTask e, short sequence, int? parentCriteriaId)
        {
            var newEntry = CreateNewEntry(c, e.Description, e.IsSeparator);
            newEntry.DisplaySequence = sequence;
            newEntry.ParentCriteriaId = parentCriteriaId;
            newEntry.IsInherited = true;

            return newEntry;
        }

        void AddEventsToEntry(DataEntryTask entry, IEnumerable<Event> events)
        {
            short displaySequence = 1;
            foreach (var @event in events)
            {
                entry.AvailableEvents.Add(new AvailableEvent(entry, @event)
                {
                    EventAttribute = (short) EntryAttribute.EntryOptional,
                    DisplaySequence = displaySequence++,
                    IsInherited = entry.IsInherited
                });
            }
        }

        List<DataEntryTask> ApplyToChildren(DataEntryTask newEntry, List<Event> events, DataEntryTask insertAfterEntry)
        {
            var descendents = _inheritance.GetDescendantsWithoutEntry(newEntry.CriteriaId, newEntry.Description, newEntry.IsSeparator).ToArray();
            var descendentModels = new List<DataEntryTask>();
            if (insertAfterEntry != null)
            {
                foreach (var d in descendents)
                {
                    var validEntry = d.criteria.DataEntryTasks.SingleOrDefault(ve => DbFuncs.StripNonAlphanumerics(ve.Description) == DbFuncs.StripNonAlphanumerics(insertAfterEntry.Description));
                    if (validEntry != null)
                    {
                        var newSequence = (short) (validEntry.DisplaySequence + 1);
                        IncrementSequencesAfter(d.criteria, validEntry.DisplaySequence);
                        descendentModels.Add(CreateNewInheritedEntry(d.criteria, newEntry, newSequence, d.parentCriteriaId));
                    }
                    else
                    {
                        descendentModels.Add(CreateNewInheritedEntry(d.criteria, newEntry, (short) (MaxValidEntrySequence(d.criteria.DataEntryTasks) + 1), d.parentCriteriaId));
                    }
                }
            }
            else
            {
                descendentModels = descendents.Select(d => CreateNewInheritedEntry(d.criteria, newEntry, (short) (MaxValidEntrySequence(d.criteria.DataEntryTasks) + 1), d.parentCriteriaId)).ToList();
            }

            if (events != null)
                descendentModels.ForEach(_ => AddEventsToEntry(_, events));

            foreach (var d in descendentModels)
            {
                var correspondingParentEntry = d.ParentCriteriaId == newEntry.CriteriaId
                    ? newEntry
                    : descendentModels.Single(_ => _.CriteriaId == d.ParentCriteriaId);

                d.ParentEntryId = correspondingParentEntry.Id;
            }

            return descendentModels;
        }
    }
}