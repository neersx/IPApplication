using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public interface IInterimCriticalDatesResolver
    {
        Task<IEnumerable<InterimCriticalDate>> Resolve(User user, string culture, CriticalDatesMetadata metadata);
    }

    public class InterimCriticalDatesResolver : IInterimCriticalDatesResolver
    {
        readonly IDbContext _dbContext;
        readonly INumberForEventResolver _numberForEventResolver;
        readonly IExternalPatentInfoLinkResolver _externalPatentInfoLinkResolver;

        public InterimCriticalDatesResolver(IDbContext dbContext, INumberForEventResolver numberForEventResolver, IExternalPatentInfoLinkResolver externalPatentInfoLinkResolver)
        {
            _dbContext = dbContext;
            _numberForEventResolver = numberForEventResolver;
            _externalPatentInfoLinkResolver = externalPatentInfoLinkResolver;
        }

        public async Task<IEnumerable<InterimCriticalDate>> Resolve(User user, string culture, CriticalDatesMetadata metadata)
        {
            if (user == null) throw new ArgumentNullException(nameof(user));
            if (metadata == null) throw new ArgumentNullException(nameof(metadata));

            var caseId = metadata.CaseId;

            var eventControl = user.IsExternalUser
                ? from ec in _dbContext.Set<ValidEvent>()
                  join e in _dbContext.FilterUserEvents(user.Id, culture, user.IsExternalUser) on ec.EventId equals e.EventNo into e1
                  from e in e1
                  select ec
                : _dbContext.Set<ValidEvent>().AsQueryable();

            var dueDatesOfLowestCycle = from cdd in _dbContext.GetCaseDueDates()
                                        group cdd by new {cdd.CaseId, cdd.EventNo}
                                        into g1
                                        select new DueDateLowestCycle
                                        {
                                            CaseId = g1.Key.CaseId,
                                            EventNo = g1.Key.EventNo,
                                            Cycle = g1.Min(_ => _.Cycle)
                                        };

            var caseEvents = _dbContext.Set<CaseEvent>().AsQueryable();

            var nextRenewalDate = metadata.CpaRenewalDate ?? metadata.NextRenewalDate;

            var interim = await (
                from ec in eventControl
                join dd in dueDatesOfLowestCycle on new {ec.EventId, CaseId = caseId} equals new {EventId = dd.EventNo, dd.CaseId} into dd1
                from dd in dd1.DefaultIfEmpty()
                join ce in caseEvents on new {ec.EventId, CaseId = caseId} equals new {EventId = ce.EventNo, ce.CaseId} into ce1
                from ce in (from ceInner in ce1
                            where ceInner.Cycle == (dd != null
                                      ? dd.Cycle
                                      : (from ceOccurred in caseEvents
                                         where ceOccurred.CaseId == ceInner.CaseId && ceOccurred.EventDate != null && ceOccurred.EventNo == ceInner.EventNo
                                         select ceOccurred.Cycle).DefaultIfEmpty().Max())
                            select ceInner).DefaultIfEmpty()
                join o in _numberForEventResolver.Resolve(caseId) on ec.EventId equals o.EventNo into o1
                from o in o1.DefaultIfEmpty()
                join sc in _dbContext.Set<SiteControl>() on SiteControls.ClientsUnawareofCPA equals sc.ControlId into sc1
                from sc in sc1.DefaultIfEmpty()
                where ec.CriteriaId == metadata.CriteriaNo
                select new InterimCriticalDate
                {
                    CaseKey = caseId,
                    EventDescription = DbFuncs.GetTranslation(ec.Description, null, ec.DescriptionTId, culture),
                    EventDefinition = DbFuncs.GetTranslation(ec.Event.Notes, null, ec.Event.NotesTId, culture),
                    DisplayDate = ec.EventId == (int) KnownEvents.NextRenewalDate
                        ? nextRenewalDate
                        : (ec.EventId == metadata.PriorityEventNo
                            ? metadata.EarliestPriorityDate
                            : ce != null
                                ? (ce.EventDate != null ? ce.EventDate : ce.EventDueDate)
                                : null),
                    OfficialNumber = ce != null && ce.EventNo == metadata.PriorityEventNo ? metadata.EarliestPriorityNumber : (o != null ? o.OfficialNumber : null),
                    CountryCode = ce != null && ce.EventNo == metadata.PriorityEventNo ? metadata.EarliestPriorityCountry : null,
                    IsLastOccurredEvent = false,
                    IsNextDueEvent = false,
                    IsCPARenewalDate = (sc == null || sc.BooleanValue != true || !user.IsExternalUser) && ec.EventId == (int) KnownEvents.NextRenewalDate && metadata.CpaRenewalDate != null,
                    DisplaySequence = ec.DisplaySequence,
                    RenewalYear = ec.EventId == (int) KnownEvents.NextRenewalDate ? metadata.AgeOfCase : null,
                    RowKey = ec.EventId.ToString(),
                    EventKey = ec.EventId,
                    CountryKey = ce != null && ce.EventNo == metadata.PriorityEventNo ? metadata.EarliestPriorityCountryId : null,
                    IsPriorityEvent = ec.EventId == metadata.DefaultPriorityEventNo,
                    NumberTypeCode = ec.EventId == metadata.DefaultPriorityEventNo ? KnownNumberTypes.Application : (o != null ? o.NumberType : null),
                    NumberTypeDataItemId = o != null ? o.DataItemId : null,
                    IsOccurred = ec.EventId != (int) KnownEvents.NextRenewalDate && (ec.EventId == metadata.PriorityEventNo || ce != null && ce.IsOccurredFlag >= 1)
                }).ToArrayAsync();

            foreach (var i in interim)
            {
                if (metadata.ExternalPatentInfoUriForPriorityEvent != null
                    && i.CountryCode == metadata.EarliestPriorityCountry
                    && i.OfficialNumber == metadata.EarliestPriorityNumber)

                {
                    i.ExternalPatentInfoUri = metadata.ExternalPatentInfoUriForPriorityEvent;
                    continue;
                }

                if (i.NumberTypeDataItemId != null && _externalPatentInfoLinkResolver.Resolve(metadata.CaseRef, i.NumberTypeDataItemId.Value, out Uri externalUri))
                {
                    i.ExternalPatentInfoUri = externalUri;
                }
            }

            return interim;
        }

        public class DueDateLowestCycle
        {
            public int CaseId { get; set; }

            public int EventNo { get; set; }

            public short Cycle { get; set; }
        }
    }
}