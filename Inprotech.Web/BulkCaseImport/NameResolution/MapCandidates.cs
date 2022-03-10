using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Legacy;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.BulkCaseImport;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport.NameResolution
{
    public interface IMapCandidates
    {
        IEnumerable<dynamic> For(EdeUnresolvedName unresolvedName, int? candidateId = null);
    }

    public class MapCandidates : IMapCandidates
    {
        readonly IDbContext _dbContext;
        readonly ISiteConfiguration _siteConfiguration;
        readonly IPotentialNameMatches _potentialNameMatches;

        public MapCandidates(IDbContext dbContext, IPotentialNameMatches potentialNameMatches,
            ISiteConfiguration siteConfiguration)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _siteConfiguration = siteConfiguration ?? throw new ArgumentNullException(nameof(siteConfiguration));
            _potentialNameMatches = potentialNameMatches ?? throw new ArgumentNullException(nameof(potentialNameMatches));
        }

        public IEnumerable<dynamic> For(EdeUnresolvedName unresolvedName, int? candidateId = null)
        {
            if (unresolvedName == null) throw new ArgumentNullException(nameof(unresolvedName));

            var useStreetAddress = false;
            string restrictByNameType = null;

            if (!string.IsNullOrEmpty(unresolvedName.NameType))
            {
                var nameType = _dbContext.Set<NameType>().Single(nt => nt.NameTypeCode == unresolvedName.NameType);
                useStreetAddress = nameType.KeepStreetFlag == 1;
                restrictByNameType = nameType.IsClassified ? unresolvedName.NameType : null;
            }

            var homeCountry = _siteConfiguration.HomeCountry();

            var candidates = candidateId != null
                ? FetchCandidate(candidateId.Value)
                : ListMapCandidates(unresolvedName.Name, unresolvedName.FirstName, useStreetAddress,
                    restrictByNameType);

            foreach (var candidate in candidates)
            {
                var c = candidate.Key;
                var n = candidate.Value;
                var formattedAddress = useStreetAddress
                    ? n.StreetAddress().FormattedOrNull(homeCountry, AddressShowCountry.NonLocalOnly)
                    : n.PostalAddress().FormattedOrNull(homeCountry, AddressShowCountry.NonLocalOnly);

                yield return new
                             {
                                 Id = c.NameNo,
                                 c.NameCode,
                                 c.Name,
                                 c.FirstName,
                                 FormattedName = FormattedName.For(c.Name, c.FirstName),
                                 c.SearchKey1,
                                 n.Remarks,
                                 FormattedAddress = formattedAddress,
                                 Phone = n.MainPhone().FormattedOrNull(),
                                 Fax = n.MainFax().FormattedOrNull(),
                                 Email = n.MainEmail().FormattedOrNull(),
                                 Contact = n.MainContact.FormattedNameOrNull(),
                                 DetailsLink = string.Format(KnownUrls.Name, c.NameNo)
                             };
            }
        }

        Dictionary<PotentialNameMatchItem, Name> FetchCandidate(int candidateId)
        {
            var name = _dbContext.Set<Name>()
                .Include(n => n.Addresses.Select(a => a.Address.Country.States))
                .Include(n => n.Telecoms.Select(t => t.Telecommunication))
                .Include(n => n.MainContact)
                .Single(n => candidateId == n.Id);

            return new Dictionary<PotentialNameMatchItem, Name>
                   {
                       {
                           new PotentialNameMatchItem
                           {
                               NameNo = candidateId,
                               NameCode = name.NameCode,
                               FirstName = name.FirstName,
                               Name = name.LastName,
                               SearchKey1 = name.SearchKey1,
                               Remarks = name.Remarks
                           },
                           name
                       }
                   };
        }

        Dictionary<PotentialNameMatchItem, Name> ListMapCandidates(string name, string firstName, bool useStreetAddress,
            string restrictByNameType)
        {
            var candidates =
                _potentialNameMatches.For(name, firstName, null, useStreetAddress, true, restrictByNameType)
                    .ToArray();

            var ids = candidates.Select(p => p.NameNo);

            var names = _dbContext.Set<Name>()
                .Include(n => n.Addresses.Select(a => a.Address.Country.States))
                .Include(n => n.Telecoms.Select(t => t.Telecommunication))
                .Include(n => n.MainContact)
                .Where(n => ids.Contains(n.Id)).ToArray();

            return candidates.ToDictionary(k => k,
                v => names.Single(n => n.Id == v.NameNo));
        }
    }
}