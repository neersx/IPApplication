using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IEligiblePatentItems
    {
        IEnumerable<EligibleInnographyItem> Retrieve(params int[] caseIds);
    }

    public class EligiblePatentItems : IEligiblePatentItems
    {
        const string SystemCode = "IpOneData";
        readonly IDbContext _dbContext;
        readonly ITypeCodeResolver _typeCodeResolver;
        readonly IMappedParentRelatedCasesResolver _mappedParentRelatedCasesResolver;
        readonly IEventMappingsResolver _eventMappingsResolver;

        public EligiblePatentItems(IDbContext dbContext,
                                    ITypeCodeResolver typeCodeResolver,
                                    IMappedParentRelatedCasesResolver mappedParentRelatedCasesResolver,
                                    IEventMappingsResolver eventMappingsResolver)
        {
            _dbContext = dbContext;
            _typeCodeResolver = typeCodeResolver;
            _mappedParentRelatedCasesResolver = mappedParentRelatedCasesResolver;
            _eventMappingsResolver = eventMappingsResolver;
        }

        public IEnumerable<EligibleInnographyItem> Retrieve(params int[] caseIds)
        {
            caseIds = caseIds ?? new int[0];

            var patents = _dbContext.FilterEligibleCasesForComparison(SystemCode)
                                    .Where(ec => ec.PropertyType != KnownPropertyTypes.TradeMark);

            if (!patents.Any())
                return Enumerable.Empty<EligibleInnographyItem>();

            var eventsMap = _eventMappingsResolver.Resolve(new[]
            {
                Events.Application, Events.Publication, Events.RegistrationOrGrant, Events.GrantPublication
            }, SystemCode);

            eventsMap.TryGetValue(Events.Application, out var caseAppEvents);
            eventsMap.TryGetValue(Events.Publication, out var casePubEvents);
            eventsMap.TryGetValue(Events.RegistrationOrGrant, out var caseRegEvents);
            eventsMap.TryGetValue(Events.GrantPublication, out var caseGrantPubEvents);

            var casesLinked = _dbContext.Set<CpaGlobalIdentifier>();
            var parents = _mappedParentRelatedCasesResolver.Resolve(caseIds).ToArray();
            var typeCodes = _typeCodeResolver.GetTypeCodes();
            
            var interim = (from c in patents
                           join ceApp in caseAppEvents on c.CaseKey equals ceApp.CaseId into ceApp1
                           from ceApp in ceApp1.DefaultIfEmpty()
                           join cePub in casePubEvents on c.CaseKey equals cePub.CaseId into cePub1
                           from cePub in cePub1.DefaultIfEmpty()
                           join ceReg in caseRegEvents on c.CaseKey equals ceReg.CaseId into ceReg1
                           from ceReg in ceReg1.DefaultIfEmpty()
                           join ceGrantPub in caseGrantPubEvents on c.CaseKey equals ceGrantPub.CaseId into ceGrantPub1
                           from ceGrantPub in ceGrantPub1.DefaultIfEmpty()
                           join tc in typeCodes on c.CaseKey equals tc.CaseId into t1
                           from tc in t1.DefaultIfEmpty()
                           join clink in casesLinked on c.CaseKey equals clink.CaseId into clink1
                           from clink in clink1.DefaultIfEmpty()
                           where caseIds.Contains(c.CaseKey)
                           select new EligibleInnographyItem
                           {
                               CaseKey = c.CaseKey,
                               IpId = clink == null ? string.Empty : clink.InnographyId,
                               SystemCode = c.SystemCode,
                               CountryCode = c.CountryCode,
                               TypeCode = tc != null ? tc.TypeCode : null,
                               ApplicationNumber = c.ApplicationNumber,
                               ApplicationDate = ceApp != null ? ceApp.EventDate : null,
                               PublicationNumber = c.PublicationNumber,
                               PublicationDate = cePub != null ? cePub.EventDate : null,
                               RegistrationNumber = c.RegistrationNumber,
                               RegistrationDate = ceReg != null ? ceReg.EventDate : null,
                               GrantPublicationDate = ceGrantPub != null ? ceGrantPub.EventDate : null
                           })
                          .Distinct()
                          .ToArray();

            return from i in interim
                   join pct in parents on new {i.CaseKey, RelationshipId = Model.Relations.PctApplication} equals new {pct.CaseKey, pct.RelationshipId} into pct1
                   from pct in pct1.DefaultIfEmpty()
                   join priority in parents on new {i.CaseKey, RelationshipId = Model.Relations.EarliestPriority} equals new {priority.CaseKey, priority.RelationshipId} into priority1
                   from priority in priority1.DefaultIfEmpty()
                   select new EligibleInnographyItem
                   {
                       CaseKey = i.CaseKey,
                       IpId = i.IpId,
                       SystemCode = i.SystemCode,
                       CountryCode = i.CountryCode,
                       TypeCode = i.TypeCode,
                       ApplicationNumber = i.ApplicationNumber,
                       ApplicationDate = i.ApplicationDate,
                       PublicationNumber = i.PublicationNumber,
                       PublicationDate = i.PublicationDate,
                       RegistrationNumber = i.RegistrationNumber,
                       RegistrationDate = i.RegistrationDate,
                       GrantPublicationDate = i.GrantPublicationDate,
                       PctCountry = pct?.CountryCode,
                       PctNumber = pct?.Number,
                       PctDate = pct?.Date,
                       PriorityCountry = priority?.CountryCode,
                       PriorityNumber = priority?.Number,
                       PriorityDate = priority?.Date
                   };
        }
    }
}
