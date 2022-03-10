using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.BulkCaseImport.NameResolution;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.BulkCaseImport)]
    [RoutePrefix("api/bulkcaseimport")]
    [ViewInitialiser]
    public class NameIssuesViewController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ISiteConfiguration _siteConfiguration;
        readonly IMapCandidates _mapCandidates;

        public NameIssuesViewController(IDbContext dbContext, ISiteConfiguration siteConfiguration, IMapCandidates mapCandidates)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (siteConfiguration == null) throw new ArgumentNullException("siteConfiguration");
            if (mapCandidates == null) throw new ArgumentNullException("mapCandidates");

            _dbContext = dbContext;
            _siteConfiguration = siteConfiguration;
            _mapCandidates = mapCandidates;
        }

        [HttpGet]
        [Route("nameissuesview")]
        public dynamic Get(int batchId)
        {
            var nametypes = _dbContext.Set<NameType>().Select(ni => new {ni.Name, ni.NameTypeCode}).ToArray();

            var homeCountry = _siteConfiguration.HomeCountry();

            var batch = _dbContext.Set<EdeSenderDetails>()
                                  .Include(s => s.TransactionHeader)
                                  .Include(s => s.TransactionHeader.UnresolvedNames)
                                  .SingleOrDefault(s => s.TransactionHeader.BatchId == batchId);

            if (batch == null)
                return new HttpResponseMessage(HttpStatusCode.NotFound);

            var namingIssueCaseCount = batch.TransactionHeader.TransactionBodies.Count(tb => tb.TransactionStatus.Id == (int) TransactionStatus.UnresolvedNames);

            var names = GetUnresolvedNamesFromBatch(batch).ToArray();

            var firstUnresolvedName = names.FirstOrDefault();

            var countries = CountriesForNamesWithIssues(names);

            var namesWithBlankSenderNameId = names.Where(n => string.IsNullOrWhiteSpace(n.SenderNameIdentifier)).Select(n => n.Id);

            var receiverNameIdsMap = CreateReceiverNameIdsMap(batchId, namesWithBlankSenderNameId);

            string recieverNameIdentifier;

            return new
                   {
                       BatchId = batchId,
                       BatchIdentifier = batch.SenderRequestIdentifier,
                       NamingIssueCaseCount = namingIssueCaseCount,
                       NameIssues = names.Select(un => new
                                                       {
                                                           un.Id,
                                                           FormattedName = FormattedName.For(un.Name, un.FirstName),
                                                           NameCode = DeriveNameCode(un, receiverNameIdsMap, out recieverNameIdentifier),
                                                           NameType = nametypes.First(ni => ni.NameTypeCode == un.NameType).Name,
                                                           FormattedAddress = FormattedAddress.For(
                                                                                                   un.AddressLine,
                                                                                                   null,
                                                                                                   un.City,
                                                                                                   un.State,
                                                                                                   FullStateName(countries, un.CountryCode, un.State),
                                                                                                   un.PostCode,
                                                                                                   CountryPostalName(countries, un.CountryCode),
                                                                                                   BestCountry(countries, homeCountry, un.CountryCode).PostCodeFirst == 1,
                                                                                                   BestCountry(countries, homeCountry, un.CountryCode).StateAbbreviated == 1,
                                                                                                   BestCountry(countries, homeCountry, un.CountryCode).PostCodeLiteral,
                                                                                                   BestCountry(countries, homeCountry, un.CountryCode).AddressStyleId),
                                                           un.Phone,
                                                           un.Fax,
                                                           un.Email,
                                                           Contact = FormattedName.For(un.AttentionLastName, un.AttentionFirstName, null, null, un.AttentionTitle),
                                                           MapCandidates = un == firstUnresolvedName ? _mapCandidates.For(firstUnresolvedName) : null
                                                       })
                   };
        }

        static string DeriveNameCode(EdeUnresolvedName un, Dictionary<int?, string> receiverNameIdsMap, out string recieverNameIdentifier)
        {
            recieverNameIdentifier = null;

            return string.IsNullOrWhiteSpace(un.SenderNameIdentifier)
                ? (receiverNameIdsMap.TryGetValue(un.Id, out recieverNameIdentifier) ? recieverNameIdentifier : null)
                : un.SenderNameIdentifier;
        }

        static IOrderedEnumerable<EdeUnresolvedName> GetUnresolvedNamesFromBatch(EdeSenderDetails batch)
        {
            return batch.TransactionHeader.UnresolvedNames.OrderBy(_ => FormattedName.For(_.Name, _.FirstName));
        }

        IQueryable<Country> CountriesForNamesWithIssues(IEnumerable<EdeUnresolvedName> names)
        {
            var allCountries = names.Select(n => n.CountryCode).Distinct().ToArray();

            return _dbContext.Set<Country>()
                             .Include(c => c.States)
                             .Where(c => allCountries.Contains(c.Id));
        }

        Dictionary<int?, string> CreateReceiverNameIdsMap(int batchId, IEnumerable<int> namesWithBlankSenderNameId)
        {
            return (from a in _dbContext.Set<EdeName>()
                    join b in _dbContext.Set<EdeAddressBook>()
                        on new {a.BatchId, a.TransactionId, a.NameTypeCode, a.NamesSequenceNo} equals new {b.BatchId, b.TransactionId, b.NameTypeCode, b.NamesSequenceNo}
                    where (b.BatchId == batchId) && (b.UnresolvedNameId != null) && namesWithBlankSenderNameId.Contains((int) b.UnresolvedNameId)
                    select new {b.UnresolvedNameId, a.ReceiverNameIdentifier})
                .DistinctBy(_ => _.UnresolvedNameId)
                .ToDictionary(k => k.UnresolvedNameId, v => v.ReceiverNameIdentifier);
        }

        static string FullStateName(IEnumerable<Country> countries, string countryCode, string state)
        {
            if (string.IsNullOrWhiteSpace(state))
                return string.Empty;

            var country = countries.FirstOrDefault(c => string.Equals(c.Id, countryCode, StringComparison.CurrentCultureIgnoreCase));
            if (country == null)
                return string.Empty;

            var s = country.States.FirstOrDefault(_ => _.Code == state);
            return s != null ? s.Name : string.Empty;
        }

        static string CountryPostalName(IEnumerable<Country> countries, string countryCode)
        {
            if (string.IsNullOrWhiteSpace(countryCode))
                return countryCode;

            var country = countries.FirstOrDefault(c => string.Equals(c.Id, countryCode, StringComparison.CurrentCultureIgnoreCase));
            return country != null ? country.PostalName : string.Empty;
        }

        static Country BestCountry(IEnumerable<Country> countries, Country homeCountry, string currentCountryCode)
        {
            if (string.IsNullOrWhiteSpace(currentCountryCode))
                return homeCountry;

            return countries.FirstOrDefault(c => string.Equals(c.Id, currentCountryCode, StringComparison.CurrentCultureIgnoreCase)) ?? homeCountry;
        }
    }
}