using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public interface IInheritance
    {
        dynamic GetDescendants(int criteriaId);
        IEnumerable<Criteria> GetDescendantsWithoutEvent(int criteriaId, int eventid);
        IEnumerable<(Criteria criteria, int parentCriteriaId)> GetDescendantsWithoutEntry(int criteriaId, string entryDescription, bool isSeparator = false);

        /// <summary>
        ///     return all descendant criteria ids with inherited event
        /// </summary>
        IEnumerable<int> GetDescendantsWithInheritedEvent(int rootCriteriaId, int eventId);

        /// <summary>
        ///     return all descendant criteria ids with event
        /// </summary>
        IEnumerable<int> GetDescendantsWithEvent(int rootCriteriaId, int eventId);

        /// <summary>
        ///     Get the inheritance level
        ///     Full - criteria inherits all parent criteria
        ///     Partial - criteria inherits some rules from parent criteria
        ///     None - criteria has no parent or inherits no rules from parent
        /// </summary>
        IEnumerable<ValidEvent> GetEventRulesWithInheritanceLevel(int criteriaId);

        IEnumerable<DataEntryTask> GetEntriesWithInheritanceLevel(int criteriaId);

        /// <summary>
        ///     Return the inheritance level for particular event control
        /// </summary>
        InheritanceLevel GetInheritanceLevel(int criteriaId, int eventId);

        InheritanceLevel GetInheritanceLevel(int criteriaId, DataEntryTask entry);

        bool HasParentEntryWithFuzzyMatch(DataEntryTask entry);
        DataEntryTask GetParentEntryWithFuzzyMatch(DataEntryTask entry);
        bool HasSingleEntryMatch(IEnumerable<DataEntryTask> dataEntryTasks, string match);

        /// <summary>
        ///     return all descendant criteria ids with entry
        /// </summary>
        IEnumerable<int> GetDescendantsWithMatchedDescription(int rootCriteriaId, short entryId);

        IEnumerable<int> GetDescendantsWithAnyInheritedEntriesFrom(int rootCriteriaId, short[] entryIds);

        IEnumerable<CriteriaEntryIds> GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(int rootCriteriaId, short[] entryIds, bool immediateDescedentsOnly = false);

        bool CheckAnyProtectedDescendantsInTree(int parentCriteriaId);

        Criteria GetParent(int childId);
        Criteria[] GetChildren(int parentId);
    }

    internal class Inheritance : IInheritance
    {
        readonly IDbContext _dbContext;

        public Inheritance(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public dynamic GetDescendants(int criteriaId)
        {
            var parent = _dbContext.Set<Inherits>()
                                   .SingleOrDefault(i => i.CriteriaNo == criteriaId)
                                   ?.FromCriteria;

            var descendants = _dbContext.Set<Inherits>()
                                        .Where(i => i.FromCriteriaNo == criteriaId && i.CriteriaNo != criteriaId)
                                        .Select(_ => new {_.Criteria.Id, _.Criteria.Description}).ToArray();

            return new
            {
                Parent = parent == null ? null : new {parent.Id, parent.Description},
                Descendants = descendants
            };
        }

        public IEnumerable<Criteria> GetDescendantsWithoutEvent(int criteriaId, int eventId)
        {
            var descendantsWithoutEvent = new List<Criteria>();
            var childCriteria = _dbContext.Set<Inherits>()
                                          .Where(i => i.FromCriteriaNo == criteriaId && i.CriteriaNo != criteriaId)
                                          .ToArray();

            while (childCriteria.Any())
            {
                childCriteria = childCriteria.Where(c => c.Criteria.ValidEvents.All(ve => ve.EventId != eventId)).ToArray();

                descendantsWithoutEvent.AddRange(childCriteria.Select(cc => cc.Criteria));

                var currentLevelIds = childCriteria.Select(d => (int?) d.CriteriaNo).ToArray();
                var descendantIds = descendantsWithoutEvent.Select(d => d.Id);
                childCriteria = _dbContext.Set<Inherits>()
                                          .Where(c => currentLevelIds.Contains(c.FromCriteriaNo) && !descendantIds.Contains(c.CriteriaNo) && c.CriteriaNo != criteriaId)
                                          .ToArray();
            }

            return descendantsWithoutEvent;
        }

        public IEnumerable<(Criteria criteria, int parentCriteriaId)> GetDescendantsWithoutEntry(int criteriaId, string entryDescription, bool isSeparator = false)
        {
            var descendantsWithoutEntry = new List<(Criteria criteria, int parentCriteriaId)>();
            var childCriteria = _dbContext.Set<Inherits>()
                                          .Where(i => i.FromCriteriaNo == criteriaId && i.CriteriaNo != criteriaId)
                                          .ToArray();

            while (childCriteria.Any())
            {
                childCriteria = childCriteria.Where(c => c.Criteria.DataEntryTasks
                                                          .Select(_ => new {_.Description})
                                                          .AsEnumerable()
                                                          .All(ve => Helper.AreDescriptionsDifferent(ve.Description, entryDescription, !isSeparator)))
                                             .ToArray();

                descendantsWithoutEntry.AddRange(childCriteria.Select(cc => (cc.Criteria, cc.FromCriteriaNo)));

                var currentLevelIds = childCriteria.Select(d => (int?) d.CriteriaNo).ToArray();
                var descendantIds = descendantsWithoutEntry.Select(d => d.criteria.Id);
                childCriteria = _dbContext.Set<Inherits>()
                                          .Where(c => currentLevelIds.Contains(c.FromCriteriaNo) && !descendantIds.Contains(c.CriteriaNo) && c.CriteriaNo != criteriaId)
                                          .ToArray();
            }

            return descendantsWithoutEntry;
        }

        public IEnumerable<int> GetDescendantsWithInheritedEvent(int rootCriteriaId, int eventId)
        {
            return GetDescendantsWithEvent(rootCriteriaId, eventId, true);
        }

        public IEnumerable<int> GetDescendantsWithEvent(int rootCriteriaId, int eventId)
        {
            return GetDescendantsWithEvent(rootCriteriaId, eventId, false);
        }

        public IEnumerable<ValidEvent> GetEventRulesWithInheritanceLevel(int criteriaId)
        {
            var inherits = _dbContext.Set<Inherits>().SingleOrDefault(i => i.CriteriaNo == criteriaId);
            var validEvents = _dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId);

            if (inherits == null)
            {
                return validEvents;
            }

            var parentValidEvents = _dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == inherits.FromCriteriaNo);
            var validEventsWithRulesCount = ValidEventRuleCountHelper.GetRulesCount(validEvents, parentValidEvents);

            foreach (var validEventWithRulesCount in validEventsWithRulesCount)
            {
                validEventWithRulesCount.ResolveInheritanceLevel();
            }

            return validEventsWithRulesCount.Select(_ => _.ValidEvent);
        }

        public InheritanceLevel GetInheritanceLevel(int criteriaId, int eventId)
        {
            var inherits = _dbContext.Set<Inherits>().SingleOrDefault(i => i.CriteriaNo == criteriaId);
            if (inherits == null)
            {
                return InheritanceLevel.None;
            }

            var childValidEvent = _dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId && _.EventId == eventId);
            var parentValidEvent = _dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == inherits.FromCriteriaNo && _.EventId == eventId);

            var validEventWithRulesCount = ValidEventRuleCountHelper.GetRulesCount(childValidEvent, parentValidEvent).Single();
            validEventWithRulesCount.ResolveInheritanceLevel();
            return validEventWithRulesCount.ValidEvent.InheritanceLevel;
        }

        public IEnumerable<DataEntryTask> GetEntriesWithInheritanceLevel(int criteriaId)
        {
            var inherits = _dbContext.Set<Inherits>()
                                     .Include(_ => _.Criteria.DataEntryTasks.Select(en => en.AvailableEvents))
                                     .Include(_ => _.Criteria.DataEntryTasks.Select(en => en.DocumentRequirements))
                                     .Include(_ => _.Criteria.DataEntryTasks.Select(en => en.GroupsAllowed))
                                     .Include(_ => _.Criteria.DataEntryTasks.Select(en => en.UsersAllowed))
                                     .Include(_ => _.Criteria.DataEntryTasks.Select(en => en.TaskSteps))
                                     .Include(_ => _.Criteria.DataEntryTasks.Select(en => en.RolesAllowed))
                                     .Include(_ => _.FromCriteria.DataEntryTasks.Select(en => en.AvailableEvents))
                                     .Include(_ => _.FromCriteria.DataEntryTasks.Select(en => en.DocumentRequirements))
                                     .Include(_ => _.FromCriteria.DataEntryTasks.Select(en => en.GroupsAllowed))
                                     .Include(_ => _.FromCriteria.DataEntryTasks.Select(en => en.UsersAllowed))
                                     .Include(_ => _.FromCriteria.DataEntryTasks.Select(en => en.TaskSteps))
                                     .Include(_ => _.FromCriteria.DataEntryTasks.Select(en => en.RolesAllowed))
                                     .SingleOrDefault(i => i.CriteriaNo == criteriaId);

            if (inherits == null)
                return _dbContext.Set<DataEntryTask>()
                                 .Where(_ => _.CriteriaId == criteriaId);

            foreach (var entry in inherits.Criteria.DataEntryTasks)
            {
                ResolveInheritanceLevel(entry, inherits);
            }

            return inherits.Criteria.DataEntryTasks;
        }

        public InheritanceLevel GetInheritanceLevel(int criteriaId, DataEntryTask entry)
        {
            var inherits = _dbContext.Set<Inherits>()
                                     .SingleOrDefault(i => i.CriteriaNo == criteriaId);
            if (inherits != null)
                ResolveInheritanceLevel(entry, inherits);

            return entry.InheritanceLevel;
        }

        internal IEnumerable<int> GetDescendantsWithEvent(int rootCriteriaId, int eventId, bool onlyInherited)
        {
            var allIds = new List<int>();
            var idsOfCurrentLevel = _dbContext.Set<Inherits>()
                                              .Where(i => i.FromCriteriaNo == rootCriteriaId && i.CriteriaNo != rootCriteriaId)
                                              .Select(i => i.CriteriaNo)
                                              .ToArray();

            while (idsOfCurrentLevel.Any())
            {
                // only include inherited criteria with the event
                idsOfCurrentLevel = _dbContext.Set<ValidEvent>()
                                              .Where(e => (!onlyInherited || e.Inherited == 1) && e.EventId == eventId && idsOfCurrentLevel.Contains(e.CriteriaId))
                                              .Select(e => e.CriteriaId)
                                              .ToArray();

                allIds.AddRange(idsOfCurrentLevel);

                idsOfCurrentLevel = _dbContext.Set<Inherits>()
                                              .Where(c => idsOfCurrentLevel.Contains(c.FromCriteriaNo) && !allIds.Contains(c.CriteriaNo))
                                              .Select(c => c.CriteriaNo)
                                              .ToArray();
            }

            return allIds;
        }

        public bool HasParentEntryWithFuzzyMatch(DataEntryTask entry)
        {
            return GetParentEntryWithFuzzyMatch(entry) != null;
        }

        public DataEntryTask GetParentEntryWithFuzzyMatch(DataEntryTask entry)
        {
            var inherits = _dbContext.Set<Inherits>()
                                     .SingleOrDefault(i => i.CriteriaNo == entry.CriteriaId);
            return inherits?.FromCriteria.DataEntryTasks
                           .FirstOrDefault(pe => FuzzyMatch(pe.Description, entry.Description));
        }

        public bool HasSingleEntryMatch(IEnumerable<DataEntryTask> dataEntryTasks, string match)
        {
            return dataEntryTasks.Count(_ => FuzzyMatch(_.Description, match)) == 1;
        }

        bool FuzzyMatch(string left, string right)
        {
            return left?.ToLower().StripNonAlphanumerics() == right?.ToLower().StripNonAlphanumerics();
        }

        public IEnumerable<int> GetDescendantsWithMatchedDescription(int rootCriteriaId, short entryId)
        {
            var entry = _dbContext.Set<DataEntryTask>()
                                  .Where(_ => _.CriteriaId == rootCriteriaId && entryId == _.Id)
                                  .Select(_ => new {_.Description, _.IsSeparator})
                                  .SingleOrDefault();

            if (entry == null)
                return Enumerable.Empty<int>();

            var allIds = new List<int>();
            var idsOfCurrentLevel = _dbContext.Set<Inherits>()
                                              .Where(i => i.FromCriteriaNo == rootCriteriaId && i.CriteriaNo != rootCriteriaId)
                                              .Select(i => i.CriteriaNo)
                                              .ToArray();

            while (idsOfCurrentLevel.Any())
            {
                var level = idsOfCurrentLevel;
                var dataEntryTask = _dbContext.Set<DataEntryTask>()
                                              .Select(_ => new {_.CriteriaId, _.Description})
                                              .Where(_ => level.Contains(_.CriteriaId));

                dataEntryTask = entry.IsSeparator
                    ? dataEntryTask.AsEnumerable().Where(_ => !Helper.AreDescriptionsDifferent(_.Description, entry.Description, !entry.IsSeparator)).AsQueryable()
                    : dataEntryTask.Where(e => DbFuncs.StripNonAlphanumerics(entry.Description) == DbFuncs.StripNonAlphanumerics(e.Description));

                idsOfCurrentLevel = dataEntryTask.Select(e => e.CriteriaId)
                                                 .Distinct()
                                                 .ToArray();

                allIds.AddRange(idsOfCurrentLevel);

                idsOfCurrentLevel = _dbContext.Set<Inherits>()
                                              .Where(c => idsOfCurrentLevel.Contains(c.FromCriteriaNo) && !allIds.Contains(c.CriteriaNo))
                                              .Select(c => c.CriteriaNo)
                                              .ToArray();
            }

            return allIds;
        }

        public IEnumerable<int> GetDescendantsWithAnyInheritedEntriesFrom(int rootCriteriaId, short[] entryIds)
        {
            if (!entryIds.Any())
            {
                return Enumerable.Empty<int>();
            }

            var allIds = GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(rootCriteriaId, entryIds);

            return allIds.Select(_ => _.CriteriaId).Distinct();
        }

        public IEnumerable<CriteriaEntryIds> GetDescendantsWithAnyInheritedEntriesFromWithEntryIds(int rootCriteriaId, short[] entryIds, bool immediateDescedentsOnly = false)
        {
            if (!entryIds.Any())
            {
                return Enumerable.Empty<CriteriaEntryIds>();
            }

            var allIds = new List<CriteriaEntryIds>();

            var currentLevelIds = entryIds.Select(_ => new CriteriaEntryIds {CriteriaId = rootCriteriaId, EntryId = _}).ToArray();

            var dataEntryTask = _dbContext.Set<DataEntryTask>()
                                          .Inherited()
                                          .Where(e => e.ParentEntryId.HasValue && e.ParentCriteriaId.HasValue);

            while (currentLevelIds.Any())
            {
                var currentCriteriaIds = currentLevelIds.Select(c => c.CriteriaId).ToArray();

                var criteriaIdsOfCurrentLevel = _dbContext.Set<Inherits>()
                                                          .Where(i => currentCriteriaIds.Contains(i.FromCriteriaNo) && i.CriteriaNo != rootCriteriaId)
                                                          .Select(i => i.CriteriaNo)
                                                          .ToList();

                currentLevelIds = dataEntryTask.Select(_ => new {_.Id, _.CriteriaId, _.ParentCriteriaId, _.ParentEntryId})
                                               .Where(e => criteriaIdsOfCurrentLevel.Contains(e.CriteriaId))
                                               .AsEnumerable()
                                               .Where(_ => currentLevelIds.Any(c => c.CriteriaId == _.ParentCriteriaId && c.EntryId == _.ParentEntryId))
                                               .Select(e => new CriteriaEntryIds {CriteriaId = e.CriteriaId, EntryId = e.Id})
                                               .Distinct()
                                               .ToArray();

                allIds.AddRange(currentLevelIds);

                if (immediateDescedentsOnly)
                {
                    break;
                }
            }

            return allIds.Distinct();
        }

        public bool CheckAnyProtectedDescendantsInTree(int parentCriteriaId)
        {
            var children = GetChildren(parentCriteriaId);
            if (children.Any(_ => _.UserDefinedRule == 0)) return true;

            return children.Any(child => CheckAnyProtectedDescendantsInTree(child.Id));
        }

        public Criteria GetParent(int childId)
        {
            return _dbContext.Set<Inherits>()
                             .Include(_ => _.Criteria)
                             .Include(_ => _.Criteria.ValidEvents)
                             .Include(_ => _.Criteria.DataEntryTasks)
                             .Where(i => i.CriteriaNo == childId)
                             .Select(_ => _.FromCriteria)
                             .SingleOrDefault();
        }

        public Criteria[] GetChildren(int parentId)
        {
            var children = _dbContext.Set<Inherits>().Include(_ => _.Criteria)
                                     .Include(_ => _.Criteria.ValidEvents)
                                     .Include(_ => _.Criteria.DataEntryTasks)
                                     .Where(i => i.FromCriteriaNo == parentId).Select(_ => _.Criteria).ToArray();
            return children;
        }

        void ResolveInheritanceLevel(DataEntryTask entry, Inherits inherits)
        {
            if (!entry.IsInherited)
            {
                entry.InheritanceLevel = InheritanceLevel.None;
                return;
            }

            var parentRulesCount = inherits.FromCriteria.DataEntryTasks
                                           .Where(pe => entry.ParentEntryId == pe.Id)
                                           .Sum(en => en.AvailableEvents.Count
                                                      + en.DocumentRequirements.Count
                                                      + en.GroupsAllowed.Count
                                                      + en.UsersAllowed.Count
                                                      + en.TaskSteps.SelectMany(_ => _.TopicControls).Count()
                                                      + en.RolesAllowed.Count);

            var inheritedRulesCount = entry.AvailableEvents.Count(_ => _.Inherited == 1)
                                      + entry.DocumentRequirements.Count(_ => _.Inherited == 1)
                                      + entry.GroupsAllowed.Count(_ => _.Inherited == 1)
                                      + entry.UsersAllowed.Count(_ => _.Inherited == 1)
                                      + entry.TaskSteps.SelectMany(_ => _.TopicControls).Count(_ => _.IsInherited)
                                      + entry.RolesAllowed.Count(_ => _.Inherited.GetValueOrDefault());

            entry.InheritanceLevel = parentRulesCount == inheritedRulesCount ? InheritanceLevel.Full : InheritanceLevel.Partial;
        }
    }

    public class ValidEventWithRulesCount
    {
        public ValidEvent ValidEvent;
        public int RulesCount;
        public int? ParentRulesCount;

        public void ResolveInheritanceLevel()
        {
            if (!ValidEvent.IsInherited || ParentRulesCount == null)
            {
                ValidEvent.InheritanceLevel = InheritanceLevel.None;
            }
            else
            {
                ValidEvent.InheritanceLevel = RulesCount == ParentRulesCount ? InheritanceLevel.Full : InheritanceLevel.Partial;
            }
        }
    }

    static class ValidEventRuleCountHelper
    {
        public static IQueryable<ValidEventWithRulesCount> GetRulesCount(IQueryable<ValidEvent> childRules, IQueryable<ValidEvent> parentRules)
        {
            var validEventWithRulesCount = from child in childRules.CountRules(true)
                                           join parent in parentRules.CountRules()
                                               on child.ValidEvent.EventId equals parent.ValidEvent.EventId into pc
                                           from subParent in pc.DefaultIfEmpty()
                                           select new ValidEventWithRulesCount
                                           {
                                               ValidEvent = child.ValidEvent,
                                               RulesCount = child.RulesCount,
                                               ParentRulesCount = subParent == null ? (int?) null : subParent.RulesCount
                                           };

            return validEventWithRulesCount;
        }

        static IQueryable<ValidEventRuleCount> CountRules(this IQueryable<ValidEvent> validEvents, bool inheritedOnly = false)
        {
            return validEvents.Select(ve => new ValidEventRuleCount
            {
                ValidEvent = ve,
                RulesCount = ve.DueDateCalcs.Count(_ => !inheritedOnly || _.Inherited == 1)
                             + ve.RelatedEvents.Count(_ => !inheritedOnly || _.Inherited == 1)
                             + ve.DatesLogic.Count(_ => !inheritedOnly || _.Inherited == 1)
                             + ve.Reminders.Count(_ => !inheritedOnly || _.Inherited == 1)
                             + ve.NameTypeMaps.Count(_ => !inheritedOnly || _.Inherited)
                             + ve.RequiredEvents.Count(_ => !inheritedOnly || _.Inherited)
            });
        }

        class ValidEventRuleCount
        {
            public ValidEvent ValidEvent;
            public int RulesCount;
        }
    }

    public class CriteriaEntryIds
    {
        public CriteriaEntryIds()
        {
        }

        public CriteriaEntryIds(int criteriaId, short entryId)
        {
            CriteriaId = criteriaId;
            EntryId = entryId;
        }

        public int CriteriaId { get; set; }
        public short EntryId { get; set; }
    }
}