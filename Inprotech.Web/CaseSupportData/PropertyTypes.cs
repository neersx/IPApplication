using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.ValidCombinations;
using KnownValues = InprotechKaizen.Model.KnownValues;

namespace Inprotech.Web.CaseSupportData
{
    public interface IFilterPropertyType
    {
        IQueryable<ValidProperty> FilterPropertyTypesByRowAccess(IQueryable<ValidProperty> validProperties);
    }

    public class FilterPropertyType : IFilterPropertyType
    {
        readonly IUserAccessSecurity _userAccessSecurity;

        public FilterPropertyType(IUserAccessSecurity userAccessSecurity)
        {
            _userAccessSecurity = userAccessSecurity;
        }

        public IQueryable<ValidProperty> FilterPropertyTypesByRowAccess(IQueryable<ValidProperty> validProperties)
        {
            var rowAccessPropertyTypes = _userAccessSecurity.CurrentUserRowAccessDetails(RowAccessType.Case, (short) AccessPermissionLevel.Select)
                                                            .Select(_ => _.PropertyType)
                                                            .ToArray();

            // DR-4298 - Return all if user has unrestricted access in any Row Access context.
            if (rowAccessPropertyTypes.Any(_ => _ == null)) return validProperties;

            validProperties = from v in validProperties
                              join r in rowAccessPropertyTypes
                              on v.PropertyTypeId equals r.Code
                              select v;

            return validProperties;
        }
    }

    public interface IPropertyTypes
    {
        IEnumerable<KeyValuePair<string, string>> Get(string q, string[] countries);
        IEnumerable<PropertyTypeListItem> GetPropertyTypes(string[] countries, bool checkRowAccess = true);
        PropertyTypeListItem Get(int propertyTypeId);
        PropertyTypeListItem Get(string propertyTypeId);
        IEnumerable<PropertyTypeListItem> Get(string[] lstPropertyTypeKey);
        string GetCasePropertyType(Case @case);
    }

    public class PropertyTypes : IPropertyTypes
    {
        readonly IDbContext _dbContext;
        readonly IFilterPropertyType _filterPropertyType;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly IUserAccessSecurity _userAccessSecurity;

        public PropertyTypes(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, IUserAccessSecurity userAccessSecurity, IFilterPropertyType filterPropertyTypeByRowAcces)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _userAccessSecurity = userAccessSecurity;
            _filterPropertyType = filterPropertyTypeByRowAcces;
        }

        public IEnumerable<PropertyTypeListItem> GetPropertyTypes(string[] countries, bool checkRowAccess = true)
        {
            countries = countries ?? new string[0];

            var country = countries.Length == 1 ? countries[0] : null;
            var culture = _preferredCultureResolver.Resolve();

            IEnumerable<PropertyTypeListItem> results;

            if (country == null)
            {
                results =
                    _dbContext.GetPropertyTypes(
                                                _securityContext.User.Id,
                                                _preferredCultureResolver.Resolve(),
                                                _securityContext.User.IsExternalUser)
                              .ToArray();
            }
            else
            {
                var validProperties = _dbContext.Set<ValidProperty>().Where(_ => _.CountryId == country);

                if (!validProperties.Any())
                {
                    validProperties = _dbContext.Set<ValidProperty>().Where(_ => _.CountryId == KnownValues.DefaultCountryCode);
                }

                if (checkRowAccess && _userAccessSecurity.HasRowAccessSecurity(RowAccessType.Case))
                {
                    validProperties = _filterPropertyType.FilterPropertyTypesByRowAccess(validProperties);
                }

                results = validProperties.Select(_ => new PropertyTypeListItem
                                         {
                                             PropertyTypeDescription = DbFuncs.GetTranslation(_.PropertyName, null, _.PropertyNameTId, culture),
                                             PropertyTypeKey = _.PropertyTypeId,
                                             CountryKey = _.CountryId,
                                             IsDefaultCountry = _.CountryId == KnownValues.DefaultCountryCode ? 1 : 0,
                                             AllowSubClass = _.PropertyType.AllowSubClass,
                                             Image = _.PropertyType.IconImage
                                         })
                                         .OrderBy(_ => _.PropertyTypeDescription);
            }

            return results;
        }

        public IEnumerable<KeyValuePair<string, string>> Get(string q, string[] countries)
        {
            q = q ?? string.Empty;
            var results = GetPropertyTypes(countries);

            return results.Where(p => p.PropertyTypeDescription.StartsWith(q, StringComparison.OrdinalIgnoreCase))
                          .Select(p =>
                                      new KeyValuePair<string, string>(p.PropertyTypeKey, p.PropertyTypeDescription))
                          .ToArray();
        }

        public PropertyTypeListItem Get(int propertyTypeId)
        {
            var propertyType = _dbContext.Set<PropertyType>()
                                         .Single(_ => _.Id == propertyTypeId);
            return new PropertyTypeListItem
            {
                Id = propertyType.Id,
                PropertyTypeKey = propertyType.Code,
                PropertyTypeDescription = propertyType.Name,
                AllowSubClass = propertyType.AllowSubClass,
                CrmOnly = propertyType.CrmOnly.HasValue && propertyType.CrmOnly.Value,
                Image = propertyType.IconImage
            };
        }

        public PropertyTypeListItem Get(string propertyTypeId)
        {
            var propertyType = _dbContext.Set<PropertyType>()
                                         .Single(_ => _.Code == propertyTypeId);
            return new PropertyTypeListItem
            {
                Id = propertyType.Id,
                PropertyTypeKey = propertyType.Code,
                PropertyTypeDescription = propertyType.Name,
                AllowSubClass = propertyType.AllowSubClass,
                CrmOnly = propertyType.CrmOnly.HasValue && propertyType.CrmOnly.Value,
                Image = propertyType.IconImage
            };
        }

        public IEnumerable<PropertyTypeListItem> Get(string[] lstPropertyTypeKey)
        {
            return _dbContext.Set<PropertyType>()
                             .Where(_ => lstPropertyTypeKey.Contains(_.Code))
                             .Select(_ => new PropertyTypeListItem
                             {
                                 Id = _.Id,
                                 PropertyTypeKey = _.Code,
                                 PropertyTypeDescription = _.Name,
                                 AllowSubClass = _.AllowSubClass,
                                 Image = _.IconImage
                             })
                             .ToArray();
        }

        public string GetCasePropertyType(Case @case)
        {
            if (string.IsNullOrEmpty(@case.PropertyType?.Name)) return null;

            var country = new[] {@case.Country.Id};
            var validPropertyType = GetPropertyTypes(country, false).SingleOrDefault(v => v.PropertyTypeKey == @case.PropertyType?.Code);

            return validPropertyType == null ? @case.PropertyType?.Name : validPropertyType.PropertyTypeDescription;
        }
    }
}