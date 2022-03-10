using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public interface ICriticalDatesPriorityInfoResolver
    {
        Task Resolve(User user, string culture, CriticalDatesMetadata result);
    }

    public class CriticalDatesPriorityInfoResolver : ICriticalDatesPriorityInfoResolver
    {
        readonly IDbContext _dbContext;
        readonly IExternalPatentInfoLinkResolver _externalPatentInfoLinkResolver;

        public CriticalDatesPriorityInfoResolver(IDbContext dbContext, IExternalPatentInfoLinkResolver externalPatentInfoLinkResolver)
        {
            _dbContext = dbContext;
            _externalPatentInfoLinkResolver = externalPatentInfoLinkResolver;
        }

        public async Task Resolve(User user, string culture, CriticalDatesMetadata result)
        {
            if (user == null) throw new ArgumentNullException(nameof(user));
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (!result.CriteriaNo.HasValue) throw new ArgumentException("CriteriaNo is required");

            result.DefaultPriorityEventNo = await (from sc in _dbContext.Set<SiteControl>()
                                                   where sc.ControlId == SiteControls.EarliestPriority
                                                   join cr in _dbContext.Set<CaseRelation>() on new {relationship = sc.StringValue} equals new {relationship = cr.Relationship} into crMain
                                                   from cr in crMain.DefaultIfEmpty()
                                                   select cr.DisplayEventId == null ? cr.FromEventId : cr.DisplayEventId)
                .SingleOrDefaultAsync();

            var caseRelations = _dbContext.Set<CaseRelation>().AsQueryable();
            if (user.IsExternalUser)
            {
                caseRelations = from cr in _dbContext.Set<CaseRelation>()
                                join e in _dbContext.FilterUserEvents(user.Id, culture, user.IsExternalUser) on cr.ToEventId equals e.EventNo into e1
                                from e in e1
                                select cr;
            }

            var earliestEvent = _dbContext.Set<CaseRelation>().Where(_ => _.EarliestDateFlag == 1);
            var relatedToThisCase = _dbContext.Set<RelatedCase>().Where(_ => _.CaseId == result.CaseId);
            var thisCriteria = _dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == result.CriteriaNo);
            var cycle1OccurredEvent = _dbContext.Set<CaseEvent>().Where(_ => _.Cycle == 1 && _.EventDate != null);
            var cycle1Event = _dbContext.Set<CaseEvent>().Where(_ => _.Cycle == 1);
            var applicationNumber = _dbContext.Set<OfficialNumber>().Where(_ => _.NumberTypeId == KnownNumberTypes.Application && _.IsCurrent == 1);

            var interim = from sc in _dbContext.Set<SiteControl>()
                          /* For that relationship we need to determine the EventNo that will hold the earliest priority date */
                          join cr in caseRelations on new {relationship = sc.StringValue} equals new {relationship = cr.Relationship} into crMain
                          from cr in crMain
                          /* Now find all of the relationships that use the same EventNo that have the Earliest Date Flag set on. */
                          join cr1 in earliestEvent on cr.ToEventId equals cr1.ToEventId into cre
                          from cr1 in cre
                          join rc in relatedToThisCase on cr1.Relationship equals rc.Relationship into rc1
                          from rc in rc1
                          /* Now ensure that the earliest priority date is one of the events included in the Critical Events criteria */
                          join ve in thisCriteria on cr.ToEventId equals ve.EventId into ve1
                          from ve in ve1
                          join ce in cycle1OccurredEvent on new {caseId = rc.CaseId, eventId = (int) cr.ToEventId} equals new {caseId = ce.CaseId, eventId = ce.EventNo} into cel
                          from ce in cel
                          join ce1 in cycle1Event on new {caseId = rc.RelatedCaseId, eventId = cr.FromEventId} equals new {caseId = (int?) ce1.CaseId, eventId = (int?) ce1.EventNo} into cel2
                          from ce1 in cel2.DefaultIfEmpty()
                          /* If the case that priority is being claimed from is in the database then get the Official Number and Country from it. */
                          join c in _dbContext.Set<Case>() on rc.RelatedCaseId equals c.Id into c1
                          from c in c1.DefaultIfEmpty()
                          join o in applicationNumber on rc.RelatedCaseId equals o.CaseId into o1
                          from o in o1.DefaultIfEmpty()
                          where sc.ControlId == SiteControls.EarliestPriority
                                && (ce1 != null && ce1.EventDate == ce.EventDate || (ce1 == null || ce1.EventDate == null) && rc.PriorityDate == ce.EventDate)
                          select new
                          {
                              EarliestPriorityDate = ce.EventDate,
                              EarliestPriorityNumber = o == null
                                  ? (c == null || c.CurrentOfficialNumber == null ? rc.OfficialNumber : c.CurrentOfficialNumber)
                                  : o.Number,
                              EarliestPriorityCountryId = c == null
                                  ? rc.CountryCode
                                  : c.Country.Id,
                              PriorityEventNo = ve.EventId
                          };

            var priorityDetails = await (from all in interim
                                         join ct in _dbContext.Set<Country>() on all.EarliestPriorityCountryId equals ct.Id into ct1
                                         from ct in ct1.DefaultIfEmpty()
                                         select new
                                         {
                                             all.PriorityEventNo,
                                             all.EarliestPriorityNumber,
                                             all.EarliestPriorityDate,
                                             all.EarliestPriorityCountryId,
                                             EarliestPriorityCountry = DbFuncs.GetTranslation(ct.Name, null, ct.NameTId, culture)
                                         })
                .OrderBy(_ => _.EarliestPriorityDate)
                .ThenBy(_ => _.EarliestPriorityCountry)
                .FirstOrDefaultAsync();

            if (priorityDetails != null)
            {
                result.EarliestPriorityDate = priorityDetails.EarliestPriorityDate;
                result.EarliestPriorityNumber = priorityDetails.EarliestPriorityNumber;
                result.EarliestPriorityCountry = priorityDetails.EarliestPriorityCountry;
                result.EarliestPriorityCountryId = priorityDetails.EarliestPriorityCountryId;
                result.PriorityEventNo = priorityDetails.PriorityEventNo;
            }

            if (_externalPatentInfoLinkResolver.Resolve(result.CaseRef, result.EarliestPriorityCountryId, result.EarliestPriorityNumber, out Uri externalLink))
            {
                result.ExternalPatentInfoUriForPriorityEvent = externalLink;
            }
        }
    }
}