using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public interface IBillingLanguageResolver
    {
        string this[(int? LanguageKey, string Culture) languageCultureKey] { get; }

        Task<int?> Resolve(int? debtorKey, int? caseId = null, string action = null, bool? deriveAction = true);

        Dictionary<int, string> GetLanguageDescription(string culture, params int[] languageKeys);
    }

    public class BillingLanguageResolver : IBillingLanguageResolver
    {
        static readonly ConcurrentBag<string> Cultures = new();
        static readonly ConcurrentDictionary<(int, string), string> DescriptionCache = new();

        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;

        public BillingLanguageResolver(IDbContext dbContext, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _now = now;
        }

        public async Task<int?> Resolve(int? debtorKey, int? caseId = null, string action = null, bool? deriveAction = true)
        {
            if (caseId == null && debtorKey == null) return null;

            return caseId == null
                ? await ReturnFirstNameLanguageConfigurationForDebtor(debtorKey)
                : await ReturnBestNameLanguageConfiguration(debtorKey, caseId, action, deriveAction);
        }

        public Dictionary<int, string> GetLanguageDescription(string culture, params int[] languageKeys)
        {
            PopulateIntoCacheIfRequired(culture);

            var r = new Dictionary<int, string>();
            foreach (var languageKey in languageKeys)
            {
                if (DescriptionCache.TryGetValue((languageKey, culture), out var translated))
                {
                    r[languageKey] = translated;
                }
            }

            return r;
        }

        public string this[(int? LanguageKey, string Culture) languageCultureKey] =>
            languageCultureKey.LanguageKey == null
                ? null
                : GetLanguageDescription(languageCultureKey.Culture, (int) languageCultureKey.LanguageKey)[(int) languageCultureKey.LanguageKey];

        Task<int?> ReturnFirstNameLanguageConfigurationForDebtor(int? debtorKey)
        {
            return debtorKey == null
                ? null
                : (from nl in _dbContext.Set<NameLanguage>()
                    where nl.NameId == debtorKey &&
                          nl.PropertyTypeId == null &&
                          nl.ActionId == null
                    select (int?) nl.LanguageId)
                .FirstOrDefaultAsync();
        }

        Task<int?> ReturnBestNameLanguageConfiguration(int? debtorKey, int? caseId = null, string action = null, bool? deriveAction = true)
        {
            var now = _now();

            var debtorsFromCase = from cn in _dbContext.Set<CaseName>()
                                  where cn.NameTypeId == KnownNameTypes.Debtor
                                        && cn.CaseId == caseId
                                        && (cn.StartingDate == null || cn.StartingDate <= now.Date)
                                        && (cn.ExpiryDate == null || cn.ExpiryDate > now.Date)
                                  orderby cn.Sequence
                                  select cn.NameId;

            var mostRecentOpenActionForTheCase = from oa in _dbContext.Set<OpenAction>()
                                                 where oa.CaseId == caseId
                                                 orderby oa.PoliceEvents descending, oa.DateUpdated descending
                                                 select oa.ActionId;

            return (from nl in _dbContext.Set<NameLanguage>()
                    join c in _dbContext.Set<Case>() on caseId equals c.Id into c1
                    from c in c1.DefaultIfEmpty()
                    where nl.NameId == (
                              debtorKey == null
                                  ? debtorsFromCase.FirstOrDefault()
                                  : debtorKey) &&
                          (nl.PropertyTypeId == c.PropertyTypeId || nl.PropertyTypeId == null) &&
                          (nl.ActionId == (
                              action == null && deriveAction == true
                                  ? mostRecentOpenActionForTheCase.FirstOrDefault()
                                  : action) || nl.ActionId == null)
                    let bestFitScore = "1" +
                                       (nl.PropertyTypeId == null ? "0" : "1") +
                                       (nl.ActionId == null ? "0" : "1") +
                                       nl.LanguageId
                    orderby bestFitScore descending
                    select (int?) nl.LanguageId)
                .FirstOrDefaultAsync();
        }

        void PopulateIntoCacheIfRequired(string culture)
        {
            if (!Cultures.Contains(culture))
            {
                var languages = (from t in _dbContext.Set<TableCode>()
                                 where t.TableTypeId == (short) TableTypes.Language
                                 select new
                                 {
                                     t.Id,
                                     Description = DbFuncs.GetTranslation(t.Name, null, t.NameTId, culture)
                                 }).ToArray();

                foreach (var language in languages) DescriptionCache.GetOrAdd((language.Id, culture), language.Description);

                Cultures.Add(culture);
            }
        }
    }
}