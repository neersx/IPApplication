using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Web.CaseSupportData
{
    public interface ISubTypes
    {
        IEnumerable<KeyValuePair<string, string>> Get(
            string caseType,
            string[] countries,
            string[] propertyTypes,
            string[] caseCategories);

        IEnumerable<SubTypeListItem> GetSubTypes(
            string caseType,
            string[] countries,
            string[] propertyTypes,
            string[] caseCategories);

        SubType Get(string subTypeId);
        string GetCaseSubType(EntityModel.Case @case);
    }

    public class SubTypes : ISubTypes
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public SubTypes(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
        }

        public IEnumerable<SubTypeListItem> GetSubTypes(string caseType,
                                                        string[] countries,
                                                        string[] propertyTypes,
                                                        string[] caseCategories)
        {
            caseType = caseType ?? string.Empty;
            countries = countries ?? new string[0];
            propertyTypes = propertyTypes ?? new string[0];
            caseCategories = caseCategories ?? new string[0];

            var culture = _preferredCultureResolver.Resolve();

            IEnumerable<SubTypeListItem> results;

            if (!string.IsNullOrEmpty(caseType) &&
                countries.Length == 1 &&
                propertyTypes.Length == 1 &&
                caseCategories.Length == 1)
            {
                var country = countries[0];
                var propertyType = propertyTypes[0];
                var caseCategory = caseCategories[0];

                var types = (from vst in _dbContext.Set<ValidSubType>()
                             select new ValidSubTypeListItem
                             {
                                 SubTypeKey = vst.SubtypeId,
                                 SubTypeDescription = DbFuncs.GetTranslation(vst.SubTypeDescription, null, vst.SubTypeDescriptionTid, culture),
                                 CountryKey = vst.CountryId,
                                 IsDefaultCountry = vst.CountryId == KnownValues.DefaultCountryCode ? 1 : 0,
                                 PropertyTypeKey = vst.PropertyTypeId,
                                 CaseTypeKey = vst.CaseTypeId,
                                 CaseCategoryKey = vst.CaseCategoryId
                             })
                    .OrderBy(_ => _.SubTypeDescription)
                    .ToArray();

                results =
                    types.Where(
                                a =>
                                    a.CaseTypeKey == caseType &&
                                    a.PropertyTypeKey == propertyType &&
                                    a.CaseCategoryKey == caseCategory &&
                                    a.CountryKey == country)
                         .ToArray();

                if (!results.Any())
                {
                    results = types.Select(_ => new ValidSubTypeListItem
                    {
                        SubTypeDescription = _.SubTypeDescription,
                        SubTypeKey = _.SubTypeKey,
                        CaseTypeKey = _.CaseTypeKey,
                        PropertyTypeKey = _.PropertyTypeKey,
                        CaseCategoryKey = _.CaseCategoryKey,
                        CountryKey = _.CountryKey,
                        IsDefaultCountry = 1
                    }).Where(a =>
                                 a.CaseTypeKey == caseType &&
                                 a.PropertyTypeKey == propertyType &&
                                 a.CaseCategoryKey == caseCategory &&
                                 a.CountryKey == KnownValues.DefaultCountryCode).ToArray();
                }
            }
            else
            {
                results = (from st in _dbContext.Set<EntityModel.SubType>()
                           select new SubTypeListItem
                           {
                               SubTypeKey = st.Code,
                               SubTypeDescription = DbFuncs.GetTranslation(st.Name, null, st.NameTId, culture)
                           })
                    .OrderBy(_ => _.SubTypeDescription)
                    .ToArray();
            }

            return results;
        }

        public IEnumerable<KeyValuePair<string, string>> Get(
            string caseType,
            string[] countries,
            string[] propertyTypes,
            string[] caseCategories)
        {
            return GetSubTypes(caseType, countries, propertyTypes, caseCategories)
                .Select(a => new KeyValuePair<string, string>(a.SubTypeKey, a.SubTypeDescription))
                .ToArray();
        }

        public SubType Get(string subTypeId)
        {
            if (subTypeId == null) throw new ArgumentNullException(nameof(subTypeId));
            var subtype = _dbContext.Set<EntityModel.SubType>()
                                    .Single(_ => _.Code == subTypeId);
            if (subtype == null)
            {
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.SubTypeDoesNotExist.ToString());
            }

            return new SubType(subtype.Code, subtype.Name) {Key = subtype.Id};
        }

        public string GetCaseSubType(EntityModel.Case @case)
        {
            if (string.IsNullOrEmpty(@case.SubType?.Name)) return null;

            var validSubType = GetSubTypes(@case.Type.Code, new[] {@case.Country?.Id}, new[] {@case.PropertyType?.Code}, new[] {@case.Category?.CaseCategoryId}).FirstOrDefault(v => v.SubTypeKey == @case.SubType?.Code);

            return validSubType == null ? @case.SubType?.Name : validSubType.SubTypeDescription;
        }
    }
}