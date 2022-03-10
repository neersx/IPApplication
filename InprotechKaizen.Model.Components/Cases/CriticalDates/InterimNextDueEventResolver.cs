using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using Action = InprotechKaizen.Model.Cases.Action;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public interface IInterimNextDueEventResolver
    {
        Task<IEnumerable<InterimCriticalDate>> Resolve(User user, string culture, CriticalDatesMetadata metadata);
    }

    public class InterimNextDueEventResolver : IInterimNextDueEventResolver
    {
        const string NextDueEvent = "N";

        readonly IDbContext _dbContext;

        public InterimNextDueEventResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<InterimCriticalDate>> Resolve(User user, string culture, CriticalDatesMetadata metadata)
        {
            var importanceLevelForStringComparison = metadata.ImportanceLevel.ToString();

            var eventControl = user.IsExternalUser
                ? from ec in _dbContext.Set<ValidEvent>()
                  join e in _dbContext.FilterUserEvents(user.Id, culture, user.IsExternalUser) on ec.EventId equals e.EventNo into e1
                  from e in e1
                  select ec
                : _dbContext.Set<ValidEvent>().AsQueryable();

            var interimDue = await (from oa in _dbContext.Set<OpenAction>()
                                    join ec in eventControl on oa.CriteriaId equals ec.CriteriaId into ecl
                                    from ec in ecl
                                    join ec1 in _dbContext.Set<ValidEvent>() on new {EventNo = (int) KnownEvents.NextRenewalDate, metadata.CriteriaNo} equals new {EventNo = ec1.EventId, CriteriaNo = (int?) ec1.CriteriaId} into ec1l
                                    from ec1 in ec1l.DefaultIfEmpty()
                                    join e in _dbContext.Set<Event>() on ec.EventId equals e.Id into e1
                                    from e in e1
                                    join a in _dbContext.Set<Action>() on oa.ActionId equals a.Code into a1
                                    from a in a1
                                    join ce in _dbContext.Set<CaseEvent>() on new {oa.CaseId, ec.EventId} equals new {ce.CaseId, EventId = ce.EventNo} into ce1
                                    from ce in from ceInner in ce1
                                                where a.NumberOfCyclesAllowed == 1 ||
                                                      ceInner.Cycle == oa.Cycle && a.NumberOfCyclesAllowed > 1
                                                select ceInner
                                    where oa.PoliceEvents == 1
                                          && oa.ActionId == (e.ControllingAction == null ? oa.ActionId : e.ControllingAction)
                                          && (oa.ActionId == metadata.RenewalAction && ce.EventNo == (int) KnownEvents.NextRenewalDate && ec1 == null || ce.EventNo != (int) KnownEvents.NextRenewalDate)
                                          && string.Compare(ec.ImportanceLevel, importanceLevelForStringComparison) >= 0
                                          && ce.IsOccurredFlag == 0
                                          && ce.CaseId == metadata.CaseId
                                    select new DueEvent
                                    {
                                        EventDueDate = ce.EventDueDate,
                                        ImportanceLevel = ec.ImportanceLevel == null ? "0" : ec.ImportanceLevel,
                                        DisplaySequence = ec.DisplaySequence,
                                        EventId = ec.EventId,
                                        CriteriaId = ec.CriteriaId,
                                        EventDescription = DbFuncs.GetTranslation(ec.Description, null, ec.DescriptionTId, culture),
                                        EventDefinition = DbFuncs.GetTranslation(ec.Event.Notes, null, ec.Event.NotesTId, culture)
                                    })
                .ToArrayAsync();

            var nextDue = interimDue.OrderBy(_ => _.Weighting).FirstOrDefault();

            return nextDue == null
                ? new InterimCriticalDate[0]
                : new[]
                {
                    new InterimCriticalDate
                    {
                        CaseKey = metadata.CaseId,
                        EventDescription = nextDue.EventDescription,
                        EventDefinition = nextDue.EventDefinition,
                        DisplayDate = nextDue.EventDueDate,
                        OfficialNumber = null,
                        CountryCode = null,
                        IsLastOccurredEvent = false,
                        IsNextDueEvent = true,
                        IsCPARenewalDate = false,
                        DisplaySequence = nextDue.DisplaySequence,
                        RenewalYear = null,
                        RowKey = NextDueEvent,
                        EventKey = nextDue.EventId,
                        CountryKey = null,
                        IsPriorityEvent = false,
                        NumberTypeCode = null,
                        IsOccurred = false
                    }
                };
        }

        public class DueEvent
        {
            public DateTime? EventDueDate { get; set; }

            public string ImportanceLevel { get; set; }

            public short? DisplaySequence { get; set; }

            public int EventId { get; set; }

            public int CriteriaId { get; set; }

            public string EventDescription { get; set; }

            public string EventDefinition { get; set; }

            public string Weighting => EventDueDate.ToSql112()
                                       + (99 - (int.TryParse(ImportanceLevel, out int il) ? il : 0)).ToString().PadRight(2)
                                       + DisplaySequence.PadRight(11)
                                       + EventId.PadRight(11)
                                       + CriteriaId.PadRight(11);
        }
    }
}