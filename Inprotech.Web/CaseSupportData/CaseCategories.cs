using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Web.CaseSupportData
{
    public interface ICaseCategories
    {
        IEnumerable<KeyValuePair<string, string>> Get(
            string q,
            string caseType,
            string[] countries,
            string[] propertyTypes);

        IEnumerable<CaseCategoryListItem> GetCaseCategories(
            string caseType,
            string[] countries,
            string[] propertyTypes);

        CaseCategoryListItem Get(int caseCategoryId);
        CaseCategoryListItem Get(string caseCategoryCode, string caseTypeKey);
        string GetCaseCategory(Case @case);
    }

    public class CaseCategories : ICaseCategories
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        
        public CaseCategories(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IEnumerable<CaseCategoryListItem> GetCaseCategories(string caseType,
                                                                   string[] countries,
                                                                   string[] propertyTypes)
        {
            countries = countries ?? new string[0];
            propertyTypes = propertyTypes ?? new string[0];

            var culture = _preferredCultureResolver.Resolve();
            IEnumerable< CaseCategoryListItem> results;

            if (countries.Length == 1 && propertyTypes.Length == 1 && !string.IsNullOrEmpty(caseType))
            {
                var country = countries[0];
                var propertyType = propertyTypes[0];
                var filteredByQuery = (from vc in _dbContext.Set<ValidCategory>()
                                       where vc.CaseTypeId == caseType && vc.PropertyTypeId == propertyType
                                       select new CaseCategoryListItem
                                       {
                                           CaseCategoryKey = vc.CaseCategoryId,
                                           CaseCategoryDescription = DbFuncs.GetTranslation(vc.CaseCategoryDesc, null, vc.CaseCategoryDescTid, culture),
                                           CountryKey = vc.CountryId,
                                           IsDefaultCountry = vc.CountryId == InprotechKaizen.Model.KnownValues.DefaultCountryCode ? 1 : 0,
                                           PropertyTypeKey = vc.PropertyTypeId,
                                           CaseTypeKey = vc.CaseTypeId
                                       })
                    .OrderBy(_ => _.CaseCategoryDescription)
                    .ToArray();
                
                results = filteredByQuery.Where(a => a.CountryKey == country)
                                         .ToArray();

                if (!results.Any())
                {
                    results = filteredByQuery.Where(a => a.IsDefaultCountry == 1)
                                             .ToArray();
                }
            }
            else if (!string.IsNullOrEmpty(caseType))
            {
                results = (from cc in _dbContext.Set<CaseCategory>()
                          where cc.CaseTypeId == caseType
                          select new CaseCategoryListItem
                              {
                                  CaseCategoryKey = cc.CaseCategoryId,
                                  CaseCategoryDescription = DbFuncs.GetTranslation(cc.Name, null, cc.NameTId, culture),
                                  CaseTypeKey = cc.CaseTypeId
                              })
                             .OrderBy(_ => _.CaseCategoryDescription)
                             .ToArray();
            }
            else
            {
                results = (from cc in _dbContext.Set<CaseCategory>()
                           select new CaseCategoryListItem
                           {
                               CaseCategoryKey = cc.CaseCategoryId,
                               CaseCategoryDescription = DbFuncs.GetTranslation(cc.Name, null, cc.NameTId, culture)
                           })
                    .OrderBy(_ => _.CaseCategoryDescription)
                    .ToArray();
            }
            return results;
        }

        public IEnumerable<KeyValuePair<string, string>> Get(
            string q,
            string caseType,
            string[] countries,
            string[] propertyTypes)
        {
            q = q ?? string.Empty;

            var results = GetCaseCategories(caseType, countries, propertyTypes);

            return results.Where(a => a.CaseCategoryDescription.StartsWith(q, StringComparison.OrdinalIgnoreCase))
                          .Select(a => new KeyValuePair<string, string>(a.CaseCategoryKey, a.CaseCategoryDescription))
                          .ToArray();
        }

        public CaseCategoryListItem Get(int caseCategoryId)
        {
            var caseCategory = _dbContext.Set<CaseCategory>()
                                         .Single(_ => _.Id == caseCategoryId);
            return new CaseCategoryListItem
            {
                Id = caseCategory.Id,
                CaseCategoryDescription = caseCategory.Name,
                CaseCategoryKey = caseCategory.CaseCategoryId,
                CaseTypeKey = caseCategory.CaseTypeId,
                CaseTypeDescription = caseCategory.CaseType.Name
            };
        }

        public CaseCategoryListItem Get(string caseCategoryCode, string caseTypeKey)
        {
            var caseCategory = _dbContext.Set<CaseCategory>()
                                         .Single(_ => _.CaseCategoryId == caseCategoryCode && _.CaseTypeId == caseTypeKey);
            return new CaseCategoryListItem
            {
                Id = caseCategory.Id,
                CaseCategoryDescription = caseCategory.Name,
                CaseCategoryKey = caseCategory.CaseCategoryId,
                CaseTypeKey = caseCategory.CaseTypeId,
                CaseTypeDescription = caseCategory.CaseType.Name
            };
        }

        public string GetCaseCategory(Case @case)
        {
            if (string.IsNullOrEmpty(@case.Category?.Name)) return null;

            var validCaseCategory = GetCaseCategories(@case.Type?.Code, new[] {@case.Country?.Id}, new[] {@case.PropertyType?.Code}).FirstOrDefault(v => v.CaseCategoryKey == @case.Category?.CaseCategoryId);

            return validCaseCategory == null ? @case.Category?.Name : validCaseCategory.CaseCategoryDescription;
        }
    }
}