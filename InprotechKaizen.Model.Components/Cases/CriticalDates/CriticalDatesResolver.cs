using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Security;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public interface ICriticalDatesResolver
    {
        Task<IEnumerable<CriticalDate>> Resolve(int caseId);
    }

    public class CriticalDatesResolver : ICriticalDatesResolver
    {
        readonly ICriticalDatesMetadataResolver _criticalDatesMetadataResolver;
        readonly IInterimCriticalDatesResolver _interimCriticalDatesResolver;
        readonly IInterimLastOccurredDateResolver _interimLastOccurredDateResolver;
        readonly IInterimNextDueEventResolver _interimNextDueEventResolver;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public CriticalDatesResolver(ICriticalDatesMetadataResolver criticalDatesMetadataResolver,
                                     IInterimCriticalDatesResolver interimCriticalDatesResolver,
                                     IInterimLastOccurredDateResolver interimLastOccurredDateResolver,
                                     IInterimNextDueEventResolver interimNextDueEventResolver,
                                     ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _criticalDatesMetadataResolver = criticalDatesMetadataResolver;
            _interimCriticalDatesResolver = interimCriticalDatesResolver;
            _interimLastOccurredDateResolver = interimLastOccurredDateResolver;
            _interimNextDueEventResolver = interimNextDueEventResolver;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public async Task<IEnumerable<CriticalDate>> Resolve(int caseId)
        {
            var user = _securityContext.User;
            var culture = _preferredCultureResolver.Resolve();

            var metadata = await _criticalDatesMetadataResolver.Resolve(user, culture, caseId);

            if (!metadata.IsComplete) return Enumerable.Empty<CriticalDate>();

            var interim1 = (await _interimCriticalDatesResolver.Resolve(user, culture, metadata)).ToArray();
            
            var interim2 = (from i2 in await _interimLastOccurredDateResolver.Resolve(user, culture, metadata)
                            join i1 in interim1 on i2.EventKey equals i1.EventKey into i1L
                            from i1 in i1L.DefaultIfEmpty()
                            where i1 == null
                            select i2).ToArray(); /* suppressed event appeared in earlier result set */

            var interim3 = await _interimNextDueEventResolver.Resolve(user, culture, metadata);

            var criticalDates = interim1.Concat(interim2).Concat(interim3)
                                        .OrderBy(_ => _.IsLastOccurredEvent)
                                        .ThenBy(_ => _.IsNextDueEvent)
                                        .ThenBy(_ => _.DisplaySequence)
                                        .ToArray();

            return from c1 in criticalDates
                   join c2 in criticalDates on new {c1.CaseKey, c1.EventKey} equals new {c2.CaseKey, c2.EventKey} into c2lj
                   from c2 in (from c2Inner in c2lj
                               where c2Inner.Sequence < c1.Sequence
                               select c2Inner).DefaultIfEmpty()
                   where c2 == null
                   orderby c1.Sequence
                   select new CriticalDate
                   {
                       CaseKey = c1.CaseKey,
                       EventDescription = c1.EventDescription,
                       EventDefinition = c1.EventDefinition,
                       Date = c1.DisplayDate,
                       OfficialNumber = c1.OfficialNumber,
                       CountryCode = c1.CountryCode,
                       IsLastEvent = c1.IsLastOccurredEvent,
                       IsNextDueEvent = c1.IsNextDueEvent,
                       IsCpaRenewalDate = c1.IsCPARenewalDate,
                       DisplaySequence = c1.DisplaySequence ?? 0,
                       RenewalYear = c1.RenewalYear,
                       RowKey = c1.RowKey,
                       EventKey = c1.EventKey,
                       CountryKey = c1.CountryKey,
                       IsPriorityEvent = c1.IsPriorityEvent,
                       NumberTypeCode = c1.NumberTypeCode,
                       IsOccurred = c1.IsOccurred,
                       ExternalInfoLink = c1.ExternalPatentInfoUri
                   };
        }
    }

    public class CriticalDate
    {
        public int CaseKey { get; set; }
        public string EventDescription { get; set; }
        public string EventDefinition { get; set; }
        public DateTime? Date { get; set; }
        public string OfficialNumber { get; set; }
        public string CountryCode { get; set; }
        public bool? IsLastEvent { get; set; }
        public bool? IsNextDueEvent { get; set; }
        public bool? IsCpaRenewalDate { get; set; }
        public short DisplaySequence { get; set; }
        public short? RenewalYear { get; set; }
        public string RowKey { get; set; }
        public int? EventKey { get; set; }
        public string CountryKey { get; set; }
        public bool? IsPriorityEvent { get; set; }
        public string NumberTypeCode { get; set; }
        public bool? IsOccurred { get; set; }
        public Uri ExternalInfoLink { get; set; }
    }
}