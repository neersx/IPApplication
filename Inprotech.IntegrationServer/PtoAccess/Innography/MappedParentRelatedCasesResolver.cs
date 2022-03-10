using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.DataVerification;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IMappedParentRelatedCasesResolver
    {
        IEnumerable<RelatedParent> Resolve(int[] caseIds);
    }

    public class MappedParentRelatedCasesResolver : IMappedParentRelatedCasesResolver
    {
        readonly ICountryCodeResolver _countryCodeResolver;
        readonly IParentRelatedCases _parentRelatedCases;
        readonly IRelationshipCodeResolver _relationshipCodeResolver;

        public MappedParentRelatedCasesResolver(IParentRelatedCases parentRelatedCases,
                                          IRelationshipCodeResolver relationshipCodeResolver,
                                          ICountryCodeResolver countryCodeResolver)
        {
            _parentRelatedCases = parentRelatedCases;
            _relationshipCodeResolver = relationshipCodeResolver;
            _countryCodeResolver = countryCodeResolver;
        }

        public IEnumerable<RelatedParent> Resolve(int[] caseIds)
        {
            var relations = GetMappedRelationsOrDefault();

            var relationshipCodes = relations.Values.ToArray();

            var countryCodes = _countryCodeResolver.ResolveMapping();

            return from e in _parentRelatedCases.Resolve(caseIds, relationshipCodes)
                   select new RelatedParent
                   {
                       CaseKey = e.CaseKey,
                       CountryCode = countryCodes.Get(e.CountryCode) ?? e.CountryCode,
                       Date = e.Date,
                       Number = e.Number,
                       Relationship = e.Relationship,
                       RelationshipId = relations[Relations.PctApplication] == e.Relationship ? Relations.PctApplication : Relations.EarliestPriority
                   };
        }

        Dictionary<string, string> GetMappedRelationsOrDefault()
        {
            var mappedRelations = _relationshipCodeResolver.ResolveMapping(Relations.PctApplication, Relations.EarliestPriority);

            return new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase)
            {
                {Relations.PctApplication, mappedRelations.Get(Relations.PctApplication) ?? KnownRelations.PctParentApp},
                {Relations.EarliestPriority, mappedRelations.Get(Relations.EarliestPriority) ?? KnownRelations.EarliestPriority}
            };
        }
    }

    public class RelatedParent
    {
        public int CaseKey { get; set; }
        public string CountryCode { get; set; }
        public string Number { get; set; }
        public DateTime? Date { get; set; }
        public string Relationship { get; set; }
        public string RelationshipId { get; set; }
    }
}