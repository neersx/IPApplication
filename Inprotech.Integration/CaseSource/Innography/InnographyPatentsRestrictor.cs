using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Integration.PtoAccess;

namespace Inprotech.Integration.CaseSource.Innography
{
    public interface IInnographyPatentsRestrictor
    {
        IQueryable<EligibleCaseItem> Restrict(IQueryable<EligibleCaseItem> cases, string systemCode);
    }

    public class InnographyPatentsRestrictor : IInnographyPatentsRestrictor
    {
        readonly IEventMappingsResolver _eventMappingsResolver;

        public InnographyPatentsRestrictor(IEventMappingsResolver eventMappingsResolver)
        {
            _eventMappingsResolver = eventMappingsResolver;
        }

        public IQueryable<EligibleCaseItem> Restrict(IQueryable<EligibleCaseItem> cases, string systemCode)
        {
            var patents = cases.Where(_ => _.PropertyType != KnownPropertyTypes.TradeMark);

            var eventsMap = _eventMappingsResolver.Resolve(new[]
            {
                Events.Application, Events.Publication, Events.RegistrationOrGrant
            }, systemCode);
            eventsMap.TryGetValue(Events.Application, out var caseAppEvents);
            eventsMap.TryGetValue(Events.Publication, out var casePubEvents);
            eventsMap.TryGetValue(Events.RegistrationOrGrant, out var caseRegEvents);

            var patentEligibleCases = from c in patents
                                     join ceApp in caseAppEvents on c.CaseKey equals ceApp.CaseId into ceApp1
                                     from ceApp in ceApp1.DefaultIfEmpty()
                                     join cePub in casePubEvents on c.CaseKey equals cePub.CaseId into cePub1
                                     from cePub in cePub1.DefaultIfEmpty()
                                     join ceReg in caseRegEvents on c.CaseKey equals ceReg.CaseId into ceReg1
                                     from ceReg in ceReg1.DefaultIfEmpty()
                                     where c.ApplicationNumber != null && c.ApplicationNumber != string.Empty && ceApp != null && ceApp.EventDate != null
                                           || c.PublicationNumber != null && c.PublicationNumber != string.Empty && cePub != null && cePub.EventDate != null
                                           || c.RegistrationNumber != null && c.RegistrationNumber != string.Empty && ceReg != null && ceReg.EventDate != null
                                     select c;

            return patentEligibleCases;
        }
    }
}
