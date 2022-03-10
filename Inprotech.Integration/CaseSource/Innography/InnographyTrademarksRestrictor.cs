using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Integration.PtoAccess;

namespace Inprotech.Integration.CaseSource.Innography
{
    public interface IInnographyTrademarksRestrictor
    {
        IQueryable<EligibleCaseItem> Restrict(IQueryable<EligibleCaseItem> cases, string systemCode);
    }

    public class InnographyTrademarksRestrictor : IInnographyTrademarksRestrictor
    {
        readonly IEventMappingsResolver _eventMappingsResolver;
        readonly INationalCasesResolver _nationalCasesResolver;

        public InnographyTrademarksRestrictor(IEventMappingsResolver eventMappingsResolver, INationalCasesResolver nationalCasesResolver)
        {
            _eventMappingsResolver = eventMappingsResolver;
            _nationalCasesResolver = nationalCasesResolver;
        }

        public IQueryable<EligibleCaseItem> Restrict(IQueryable<EligibleCaseItem> cases, string systemCode)
        {
            var trademarks = cases.Where(_ => _.PropertyType == KnownPropertyTypes.TradeMark);

            var eventsMap = _eventMappingsResolver.Resolve(new[]
            {
                Events.Application, Events.Publication, Events.RegistrationOrGrant
            }, systemCode);

            eventsMap.TryGetValue(Events.Application, out var caseAppEvents);
            eventsMap.TryGetValue(Events.RegistrationOrGrant, out var caseRegEvents);

            var tmEligibleCases = from c in trademarks
                                  join ceApp in caseAppEvents on c.CaseKey equals ceApp.CaseId into ceApp1
                                  from ceApp in ceApp1.DefaultIfEmpty()
                                  join ceReg in caseRegEvents on c.CaseKey equals ceReg.CaseId into ceReg1
                                  from ceReg in ceReg1.DefaultIfEmpty()
                                  where c.ApplicationNumber != null && c.ApplicationNumber != string.Empty && ceApp != null && ceApp.EventDate != null
                                        || c.RegistrationNumber != null && c.RegistrationNumber != string.Empty && ceReg != null && ceReg.EventDate != null
                                  select c;

            var nationalCases = _nationalCasesResolver.FindExclusions(systemCode);

            tmEligibleCases = tmEligibleCases.Where(_ => !nationalCases.Contains(_.CaseKey));

            return tmEligibleCases;
        }
    }
}
