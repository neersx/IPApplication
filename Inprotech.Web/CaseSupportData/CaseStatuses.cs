using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.CaseSupportData
{
    public interface ICaseStatuses
    {
        IEnumerable<KeyValuePair<int, string>> Get(string q, bool isRenewal, bool isPending, bool isRegistered, bool isDead);

        IEnumerable<StatusListItem> Get(string caseType, string[] countries, string[] propertyTypes,
                                        bool? isRenewal = null, bool isPending = false, bool isRegistered = false, bool isDead = false);

        IEnumerable<StatusListItem> GetAllStatuses();

        IEnumerable<StatusListItem> GetStatusByKeys(string keys);

        dynamic IsValid(short id, string caseType, string[] countries, string[] propertyTypes,
                     bool? isRenewal = null);
    }

    public class CaseStatuses : ICaseStatuses
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly IValidStatuses _validStatuses;

        public CaseStatuses(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, IValidStatuses validStatuses)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _validStatuses = validStatuses;
        }

        public IEnumerable<KeyValuePair<int, string>> Get(string q, bool isRenewal, bool isPending, bool isRegistered, bool isDead)
        {
            q = q ?? string.Empty;

            var statusFilters = new List<Func<StatusListItem, bool>>();

            if (isPending)
                statusFilters.Add(a => a.IsPending == true);

            if (isRegistered)
                statusFilters.Add(a => a.IsRegistered == true);

            if (isDead)
                statusFilters.Add(a => a.IsDead == true);

            Func<StatusListItem, bool>[] filters =
            {
                a => !statusFilters.Any() || statusFilters.Any(statusFilter => statusFilter(a)),
                a => a.IsRenewal == isRenewal,
                a => a.StatusDescription.StartsWith(q, StringComparison.OrdinalIgnoreCase)
            };

            var results = GetAllStatuses()
                .Where(a => filters.All(filter => filter(a)))
                .ToArray();

            return results.OrderBy(a => a.StatusDescription)
                          .Select(a => new KeyValuePair<int, string>(a.StatusKey, a.StatusDescription));
        }

        public IEnumerable<StatusListItem> Get(string caseType,
                                               string[] countries,
                                               string[] propertyTypes,
                                               bool? isRenewal = null, bool isPending = false, bool isRegistered = false, bool isDead = false)
        {
            caseType = caseType ?? string.Empty;
            countries = countries ?? new string[0];
            propertyTypes = propertyTypes ?? new string[0];
            IEnumerable<StatusListItem> results;

            var culture = _preferredCultureResolver.Resolve();

            if (!isPending && !isRegistered && !isDead)
            {
                isPending = true;
                isRegistered = true;
                isDead = true;
            }

            if (!string.IsNullOrEmpty(caseType) &&
                countries.Length == 1 &&
                propertyTypes.Length == 1)
            {
                var country = countries[0];
                var propertyType = propertyTypes[0];
                var statuses = _validStatuses.All(_securityContext.User.Id, culture, isRenewal).Where(s => (s.IsRegistered.GetValueOrDefault() && isRegistered) || (s.IsDead.GetValueOrDefault() && isDead) || (s.IsPending.GetValueOrDefault() && isPending))
                    .ToArray();

                results = statuses.Where(a => a.CaseTypeKey == caseType &&
                                              a.PropertyTypeKey == propertyType &&
                                              a.CountryKey == country)
                                  .ToArray();

                if (!results.Any())
                {
                    results = statuses.Where(a =>
                                                 a.CaseTypeKey == caseType &&
                                                 a.PropertyTypeKey == propertyType &&
                                                 a.IsDefaultCountry)
                                      .ToArray();
                }
            }
            else
            {
                results = AllStatuses(culture, _securityContext.User.IsExternalUser, isRenewal)
                    .Where(s => (s.IsRegistered.GetValueOrDefault() && isRegistered) || (s.IsDead.GetValueOrDefault() && isDead) || (s.IsPending.GetValueOrDefault() && isPending))
                    .ToArray();
            }

            return results;
        }

        public IEnumerable<StatusListItem> GetAllStatuses()
        {
            var culture = _preferredCultureResolver.Resolve();

            var isExternalUser = _securityContext.User.IsExternalUser;

            return AllStatuses(culture, isExternalUser, null);
        }

        public dynamic IsValid(short id, string caseType, string[] countries, string[] propertyTypes, bool? isRenewal = null)
        {
            var culture = _preferredCultureResolver.Resolve();

            caseType = caseType ?? string.Empty;
            countries = countries ?? new string[0];
            propertyTypes = propertyTypes ?? new string[0];

            if (string.IsNullOrEmpty(caseType) || countries.Length != 1 || propertyTypes.Length != 1)
                return new { IsValid = false };

            var country = countries[0];
            var propertyType = propertyTypes[0];
            var statuses = _validStatuses.All(_securityContext.User.Id, culture, isRenewal).ToArray();

            var validCombinations = statuses.Where(a => a.CaseTypeKey == caseType &&
                                              a.PropertyTypeKey == propertyType &&
                                              a.CountryKey == country)
                                  .ToArray();
            var defaultCombination = statuses.Where(a => a.StatusKey == id &&
                                              a.CaseTypeKey == caseType &&
                                              a.PropertyTypeKey == propertyType &&
                                              a.IsDefaultCountry)
                                  .ToArray();
            return new
            {
                IsValid = validCombinations.Any(a => a.StatusKey == id) || !validCombinations.Any() && defaultCombination.Any(),
                IsDefaultCountry = !validCombinations.Any() && !defaultCombination.Any()
            };
        }

        IEnumerable<StatusListItem> AllStatuses(string culture, bool isExternalUser, bool? isRenewal)
        {
            var statuses = _dbContext.Set<Status>();

            return (from _ in statuses
                    select new StatusListItem
                    {
                        StatusKey = _.Id,
                        StatusDescription = isExternalUser
                                   ? DbFuncs.GetTranslation(_.ExternalName, null, _.ExternalNameTId, culture)
                                   : DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                        IsDead = _.LiveFlag != 1,
                        IsPending = _.LiveFlag == 1 && _.RegisteredFlag != 1,
                        IsRegistered = _.RegisteredFlag == 1,
                        IsRenewal = _.RenewalFlag == 1,
                        IsConfirmationRequired = _.ConfirmationRequiredFlag == 1
                    })
                .Where(_ => isRenewal == null || isRenewal == _.IsRenewal)
                .OrderBy(_ => _.StatusDescription);
        }

        public IEnumerable<StatusListItem> GetStatusByKeys(string keys)
        {
            var culture = _preferredCultureResolver.Resolve();
            var isExternalUser = _securityContext.User.IsExternalUser;
            var statusKeys = keys.StringToIntList(",");
            var statuses = _dbContext.Set<Status>().Where(_=>statusKeys.Contains(_.Id));
            return from _ in statuses
                             select new StatusListItem
                             {
                                 StatusKey = _.Id,
                                 StatusDescription = isExternalUser
                                     ? DbFuncs.GetTranslation(_.ExternalName, null, _.ExternalNameTId, culture)
                                     : DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                                 IsDead = _.LiveFlag != 1,
                                 IsPending = _.LiveFlag == 1 && _.RegisteredFlag != 1,
                                 IsRegistered = _.RegisteredFlag == 1,
                                 IsRenewal = _.RenewalFlag == 1
                             };
        }
    }
}