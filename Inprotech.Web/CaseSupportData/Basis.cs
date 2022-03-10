using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Web.CaseSupportData
{
    public interface IBasis
    {
        IEnumerable<KeyValuePair<string, string>> Get(
            string caseType,
            string[] countries,
            string[] propertyTypes,
            string[] caseCategories);

        IEnumerable<BasisListItem> GetBasis(
            string caseType,
            string[] countries,
            string[] propertyTypes,
            string[] caseCategories);

        string GetCaseBasis(Case @case);

        BasisListItem Get(string basisId);

        IEnumerable<BasisListItem> Get(string[] lstBasisKey);
    }

    public class Basis : IBasis
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public Basis(
            IDbContext dbContext,
            IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
        }

        public IEnumerable<BasisListItem> GetBasis(
            string caseType,
            string[] countries,
            string[] propertyTypes,
            string[] caseCategories)
        {
            var country = (countries ?? new string[0]).FirstOrDefault();
            var propertyType = (propertyTypes ?? new string[0]).FirstOrDefault();
            var culture = _preferredCultureResolver.Resolve();

            if (string.IsNullOrEmpty(country) || string.IsNullOrEmpty(propertyType))
            {
                return GetBaseList(culture);
            }

            var caseCategory = (caseCategories ?? new string[0]).FirstOrDefault();
            caseType = string.IsNullOrEmpty(caseType) ? null : caseType;

            var allValidBasis = (from vb in _dbContext.Set<ValidBasis>()
                                 join vbx in _dbContext.Set<ValidBasisEx>() on new {vb.CountryId, vb.PropertyTypeId, vb.BasisId} equals new {vbx.CountryId, vbx.PropertyTypeId, vbx.BasisId} into vbx1
                                 from vbx in vbx1.DefaultIfEmpty()
                                 select new ValidBasisListItem
                                 {
                                     ApplicationBasisKey = vb.BasisId,
                                     ApplicationBasisDescription = DbFuncs.GetTranslation(vb.BasisDescription, null, vb.BasisDescriptionTId, culture),
                                     CountryKey = vb.CountryId,
                                     IsDefaultCountry = vb.CountryId == KnownValues.DefaultCountryCode ? 1 : 0,
                                     PropertyTypeKey = vb.PropertyTypeId,
                                     CaseTypeKey = vbx != null ? vbx.CaseTypeId : null,
                                     CaseCategoryKey = vbx != null ? vbx.CaseCategoryId : null
                                 })
                .OrderBy(_ => _.ApplicationBasisDescription)
                .ToArray();

            var results = FilterValidBasisExOrValidBasis(allValidBasis, caseType, country, propertyType, caseCategory);

            if (!results.Any())
            {
                results = FilterValidBasisExOrValidBasis(allValidBasis, caseType, KnownValues.DefaultCountryCode, propertyType, caseCategory);
            }

            var baseList = GetBaseList(culture).ToArray();
            return results.Any() ? results : baseList;
        }

        public IEnumerable<KeyValuePair<string, string>> Get(
            string caseType,
            string[] countries,
            string[] propertyTypes,
            string[] caseCategories)
        {
            return
                GetBasis(caseType, countries, propertyTypes, caseCategories)
                    .Select(a => new KeyValuePair<string, string>(a.ApplicationBasisKey, a.ApplicationBasisDescription))
                    .Distinct();
        }

        public BasisListItem Get(string basisId)
        {
            var applicationBasis = _dbContext.Set<ApplicationBasis>()
                                             .Single(_ => _.Code == basisId);
            return new BasisListItem
            {
                Id = applicationBasis.Id,
                ApplicationBasisKey = applicationBasis.Code,
                ApplicationBasisDescription = applicationBasis.Name,
                Convention = applicationBasis.Convention
            };
        }

        public IEnumerable<BasisListItem> Get(string[] lstBasisKey)
        {
            return _dbContext.Set<ApplicationBasis>().Where(_ => lstBasisKey.Contains(_.Code))
                             .Select(_ => new BasisListItem
                             {
                                 Id = _.Id,
                                 ApplicationBasisKey = _.Code,
                                 ApplicationBasisDescription = _.Name,
                                 Convention = _.Convention
                             }).ToArray();
        }

        public string GetCaseBasis(Case @case)
        {
            string basis = null;

            if (string.IsNullOrEmpty(@case.Property?.Basis)) return null;
            var validBasis = GetBasis(@case.Type.Code, new[] {@case.Country.Id}, new[] {@case.PropertyType.Code}, new[] {@case.CategoryId}).ToArray();
            if (validBasis.Any(_ => _.ApplicationBasisKey == @case.Property.Basis))
            {
                basis = validBasis.First(_ => _.ApplicationBasisKey == @case.Property.Basis).ApplicationBasisDescription;
            }
            return basis;
        }

        static ValidBasisListItem[] FilterValidBasisExOrValidBasis(ValidBasisListItem[] basisList, string caseType, string country, string propertyType, string caseCategory)
        {
            var results = new ValidBasisListItem[0];

            if (!string.IsNullOrEmpty(caseCategory))
            {
                // try ValidBasisEx
                results = FilterValidBasisEx(basisList, caseType, country, propertyType, caseCategory);
            }

            if (!results.Any())
            {
                // fallback to ValidBasis
                results = FilterValidBasis(basisList, country, propertyType).Distinct().ToArray();
            }

            return results;
        }

        static ValidBasisListItem[] FilterValidBasisEx(IEnumerable<ValidBasisListItem> validBasisList, string caseType, string country, string propertyType, string caseCategory)
        {
            return validBasisList.Where(b => b.CountryKey == country && b.PropertyTypeKey == propertyType
                                             && b.CaseTypeKey == caseType && b.CaseCategoryKey == caseCategory).ToArray();
        }

        static ValidBasisListItem[] FilterValidBasis(IEnumerable<ValidBasisListItem> validBasisList, string country, string propertyType)
        {
            return validBasisList.Where(b => b.CountryKey == country && b.PropertyTypeKey == propertyType).ToArray();
        }

        IEnumerable<BasisListItem> GetBaseList(string culture)
        {
            return (from ab in _dbContext.Set<ApplicationBasis>()
                    select new BasisListItem
                    {
                        ApplicationBasisKey = ab.Code,
                        ApplicationBasisDescription = DbFuncs.GetTranslation(ab.Name, null, ab.NameTId, culture)
                    })
                .OrderBy(_ => _.ApplicationBasisDescription);
        }
    }
}