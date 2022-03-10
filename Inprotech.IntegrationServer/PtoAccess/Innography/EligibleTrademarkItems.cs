using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IEligibleTrademarkItems
    {
        IEnumerable<EligibleInnographyItem> Retrieve(params int[] caseIds);
    }

    public class EligibleTrademarkItems : IEligibleTrademarkItems
    {
        const string SystemCode = "IpOneData";
        readonly IDbContext _dbContext;
        readonly IMappedParentRelatedCasesResolver _mappedParentRelatedCasesResolver;
        readonly IEventMappingsResolver _eventMappingsResolver;
        readonly ICountryCodeResolver _countryCodeResolver;

        public EligibleTrademarkItems(IDbContext dbContext,
                                      IMappedParentRelatedCasesResolver mappedParentRelatedCasesResolver,
                                      IEventMappingsResolver eventMappingsResolver,
                                      ICountryCodeResolver countryCodeResolver)
        {
            _dbContext = dbContext;
            _mappedParentRelatedCasesResolver = mappedParentRelatedCasesResolver;
            _countryCodeResolver = countryCodeResolver;
            _eventMappingsResolver = eventMappingsResolver;
        }

        public IEnumerable<EligibleInnographyItem> Retrieve(params int[] caseIds)
        {
            caseIds = caseIds ?? new int[0];

            var trademarks = _dbContext.FilterEligibleCasesForComparison(SystemCode)
                                       .Where(ec => ec.PropertyType == KnownPropertyTypes.TradeMark);

            if (!trademarks.Any())
                return Enumerable.Empty<EligibleInnographyItem>();

            var eventsMap = _eventMappingsResolver.Resolve(new[]
            {
                Events.Application, Events.Publication, Events.RegistrationOrGrant, Events.Expiry, Events.Termination
            }, SystemCode);

            eventsMap.TryGetValue(Events.Application, out var caseAppEvents);
            eventsMap.TryGetValue(Events.Publication, out var casePubEvents);
            eventsMap.TryGetValue(Events.RegistrationOrGrant, out var caseRegEvents);
            eventsMap.TryGetValue(Events.Expiry, out var caseExpiryEvents);
            eventsMap.TryGetValue(Events.Termination, out var caseTerminationEvents);

            var casesLinked = _dbContext.Set<CpaGlobalIdentifier>();
            var parents = _mappedParentRelatedCasesResolver.Resolve(caseIds).ToArray();

            var countryCodes = _countryCodeResolver.ResolveMapping();

            var interim = (from c in trademarks
                           join ceApp in caseAppEvents on c.CaseKey equals ceApp.CaseId into ceApp1
                           from ceApp in ceApp1.DefaultIfEmpty()
                           join cePub in casePubEvents on c.CaseKey equals cePub.CaseId into cePub1
                           from cePub in cePub1.DefaultIfEmpty()
                           join ceReg in caseRegEvents on c.CaseKey equals ceReg.CaseId into ceReg1
                           from ceReg in ceReg1.DefaultIfEmpty()
                           join ceExp in caseExpiryEvents on c.CaseKey equals ceExp.CaseId into ceExp1
                           from ceExp in ceExp1.DefaultIfEmpty()
                           join ceTerm in caseTerminationEvents on c.CaseKey equals ceTerm.CaseId into ceTerm1
                           from ceTerm in ceTerm1.DefaultIfEmpty()
                           join clink in casesLinked on c.CaseKey equals clink.CaseId into clink1
                           from clink in clink1.DefaultIfEmpty()
                           where caseIds.Contains(c.CaseKey)
                           select new EligibleInnographyItem
                           {
                               CaseKey = c.CaseKey,
                               IpId = clink == null ? string.Empty : clink.InnographyId,
                               SystemCode = c.SystemCode,
                               CountryCode = c.CountryCode,
                               ApplicationNumber = c.ApplicationNumber,
                               ApplicationDate = ceApp != null ? ceApp.EventDate : null,
                               PublicationNumber = c.PublicationNumber,
                               PublicationDate = cePub != null ? cePub.EventDate : null,
                               RegistrationNumber = c.RegistrationNumber,
                               RegistrationDate = ceReg != null ? ceReg.EventDate : null,
                               ExpirationDate = ceExp != null ? ceExp.EventDate : null,
                               TerminationDate = ceTerm != null ? ceTerm.EventDate : null
                           })
                          .Distinct()
                          .ToArray();

            return from i in interim
                   join cnt in _dbContext.Set<Country>() on i.CountryCode equals cnt.Id into cnt1
                   from cnt in cnt1.DefaultIfEmpty()
                   join priority in parents on new {i.CaseKey, RelationshipId = Model.Relations.EarliestPriority} equals new {priority.CaseKey, priority.RelationshipId} into priority1
                   from priority in priority1.DefaultIfEmpty()
                   select new EligibleInnographyItem
                   {
                       CaseKey = i.CaseKey,
                       IpId = i.IpId,
                       SystemCode = i.SystemCode,
                       CountryCode = countryCodes.Get(i.CountryCode) ?? cnt?.AlternateCode ?? i.CountryCode,
                       ApplicationNumber = i.ApplicationNumber,
                       ApplicationDate = i.ApplicationDate,
                       PublicationNumber = i.PublicationNumber,
                       PublicationDate = i.PublicationDate,
                       RegistrationNumber = i.RegistrationNumber,
                       RegistrationDate = i.RegistrationDate,
                       ExpirationDate = i.ExpirationDate,
                       TerminationDate = i.TerminationDate,
                       PriorityCountry = priority?.CountryCode,
                       PriorityNumber = priority?.Number,
                       PriorityDate = priority?.Date
                   };
        }
    }
}
