using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Names
{
    public interface IFormattedNameAddressTelecom
    {
        Task<Dictionary<int, NameFormatted>> GetFormatted(int[] nameIds,
                                                      NameStyles fallbackNameStyle = NameStyles.Default);

        Task<Dictionary<int, AddressFormatted>> GetAddressesFormatted(int[] addressIds,
                                                                      AddressStyles fallbackAddressStyles = AddressStyles.Default,
                                                                      AddressShowCountry addressShowCountry = AddressShowCountry.Always);
    }

    public class FormattedNameAddressTelecom : IFormattedNameAddressTelecom
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public FormattedNameAddressTelecom(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public async Task<Dictionary<int, NameFormatted>> GetFormatted(int[] nameIds,
                                                                   NameStyles fallbackNameStyle = NameStyles.Default)
        {
            var distinctNameIds = nameIds.Distinct();
            var culture = _preferredCultureResolver.Resolve();

            var websiteData = from n in _dbContext.Set<Name>()
                              where distinctNameIds.Contains(n.Id)
                                  select new WebsiteData
                                  {
                                      NameId = n.Id,
                                      WebAddress = n.Telecoms.FirstOrDefault(_ => _.Telecommunication.TelecomType.Id == (int) KnownTelecomTypes.Website).Telecommunication.TelecomNumber
                                  };

            return (await (from n in _dbContext.Set<Name>()
                           join phone in _dbContext.Set<Telecommunication>() on n.MainPhoneId equals phone.Id into phone1
                           from phone in phone1.DefaultIfEmpty()
                           join email in _dbContext.Set<Telecommunication>() on n.MainEmailId equals email.Id into email1
                           from email in email1.DefaultIfEmpty()
                           join website in websiteData on n.Id equals website.NameId into website1
                           from website in website1.DefaultIfEmpty()
                           where distinctNameIds.Contains(n.Id)
                           select new InterimContactDetails
                           {
                               NameId = n.Id,
                               NameCode = n.NameCode,
                               FirstName = n.FirstName,
                               MiddleName = n.MiddleName,
                               LastName = n.LastName,
                               Suffix = n.Suffix,
                               Title = n.Title,
                               NameStyle = n.NameStyle,
                               NationalityAdjective = n.Nationality != null
                                   ? DbFuncs.GetTranslation(n.Nationality.CountryAdjective, null, n.Nationality.CountryAdjectiveTId, culture)
                                   : null,
                               NationalityNameStyle = n.Nationality.NameStyleId,
                               StreetAddressId = n.StreetAddressId,
                               PostalAddressId = n.PostalAddressId,
                               Email = email != null ? email.TelecomNumber : null,
                               PhoneIsd = phone != null ? phone.Isd : null,
                               PhoneAreaCode = phone != null ? phone.AreaCode : null,
                               PhoneNumber = phone != null ? phone.TelecomNumber : null,
                               PhoneExtension = phone != null ? phone.Extension : null,
                               WebAddress = website.WebAddress
                           })
                    .ToArrayAsync())
                .ToDictionary(k => k.NameId,
                              v => new NameFormatted
                              {
                                  NameId = v.NameId,
                                  Name = FormattedName.For(v.LastName, v.FirstName, v.Title, v.MiddleName, v.Suffix, EffectiveNameStyle(v.NameStyle, v.NationalityNameStyle, fallbackNameStyle)),
                                  MainStreetAddressId = v.StreetAddressId,
                                  MainPostalAddressId = v.PostalAddressId,
                                  MainPhone = FormattedTelecom.For(v.PhoneIsd, v.PhoneAreaCode, v.PhoneNumber, v.PhoneExtension),
                                  MainEmail = v.Email,
                                  NameCode = v.NameCode,
                                  Nationality = v.NationalityAdjective,
                                  WebAddress = v.WebAddress
                              });
        }

        public async Task<Dictionary<int, AddressFormatted>> GetAddressesFormatted(int[] addressIds,
                                                                                   AddressStyles fallbackAddressStyles = AddressStyles.Default,
                                                                                   AddressShowCountry addressShowCountry = AddressShowCountry.Always)
        {
            var distinctAddressIds = addressIds.Distinct();

            return (await (from a in _dbContext.Set<Address>()
                           join country in _dbContext.Set<Country>() on a.CountryId equals country.Id into country1
                           from country in country1.DefaultIfEmpty()
                           join state in _dbContext.Set<State>() on new {Code = a.State, CountryCode = a.CountryId} equals new {state.Code, state.CountryCode} into state1
                           from state in state1.DefaultIfEmpty()
                           join homeCountrySetting in _dbContext.Set<SiteControl>() on SiteControls.HOMECOUNTRY equals homeCountrySetting.ControlId into homeCountry1
                           from homeCountrySetting in homeCountry1.DefaultIfEmpty()
                           where distinctAddressIds.Contains(a.Id)
                           select new InterimAddress
                           {
                               HomeCountry = homeCountrySetting != null ? homeCountrySetting.StringValue : null,
                               AddressId = a.Id,
                               Address1 = a != null ? a.Street1 : null,
                               Address2 = a != null ? a.Street2 : null,
                               City = a != null ? a.City : null,
                               StateName = state != null ? state.Name : null,
                               PostCode = a != null ? a.PostCode : null,
                               PostalCountryName = country != null ? country.PostalName : null,
                               PostCodeFirst = country != null ? country.PostCodeFirst == 1 : false,
                               StateAbbreviated = country != null ? country.StateAbbreviated == 1 : false,
                               PostCodeLiteral = country != null ? country.PostCodeLiteral : null,
                               AddressStyle = country != null ? country.AddressStyleId : null
                           })
                    .ToArrayAsync())
                .ToDictionary(k => k.AddressId,
                              v => new AddressFormatted
                              {
                                  Id = v.AddressId,
                                  Address = FormattedAddress.For(v.Address1, v.Address2, v.City, v.PostalState, v.StateName, v.PostCode,
                                                                 EffectiveCountry(addressShowCountry, v.HomeCountry, v.PostalCountryName),
                                                                 v.PostCodeFirst, v.StateAbbreviated, v.PostCodeLiteral,
                                                                 EffectiveAddressStyle(v.AddressStyle, fallbackAddressStyles))
                              });
        }

        static AddressStyles EffectiveAddressStyle(int? dataAddressStyle, AddressStyles defaultAddressStyle)
        {
            return dataAddressStyle != null
                ? (AddressStyles) dataAddressStyle
                : defaultAddressStyle;
        }

        static string EffectiveCountry(AddressShowCountry addressShowCountry, string homeCountry, string addrCountry)
        {
            if (addressShowCountry == AddressShowCountry.Always) return addrCountry;
            return string.Compare(homeCountry, addrCountry, StringComparison.CurrentCultureIgnoreCase) == 0 ? null : addrCountry;
        }

        static NameStyles EffectiveNameStyle(int? nameStyle, int? nationalityNameStyle, NameStyles fallbackNameStyle)
        {
            var dataNameStyle = nameStyle ?? nationalityNameStyle;
            return dataNameStyle != null
                ? (NameStyles) dataNameStyle
                : fallbackNameStyle;
        }

        public class InterimContactDetails
        {
            public int NameId { get; set; }

            public string NameCode { get; set; }

            public string FirstName { get; set; }

            public string MiddleName { get; set; }

            public string LastName { get; set; }

            public string Suffix { get; set; }

            public string Title { get; set; }

            public int? NameStyle { get; set; }

            public string NationalityAdjective { get; set; }

            public int? NationalityNameStyle { get; set; }

            public int? StreetAddressId { get; set; }

            public int? PostalAddressId { get; set; }

            public string Email { get; set; }

            public string PhoneIsd { get; set; }

            public string PhoneAreaCode { get; set; }

            public string PhoneNumber { get; set; }

            public string PhoneExtension { get; set; }
            
            public string WebAddress { get; set; }
        }

        public class InterimAddress
        {
            public string HomeCountry { get; set; }

            public int AddressId { get; set; }

            public string Address1 { get; set; }

            public string Address2 { get; set; }

            public string City { get; set; }

            public string PostalState { get; set; }

            public string StateName { get; set; }

            public string PostCode { get; set; }

            public string PostalCountryName { get; set; }

            public bool PostCodeFirst { get; set; }

            public bool StateAbbreviated { get; set; }

            public string PostCodeLiteral { get; set; }

            public int? AddressStyle { get; set; }
        }
    }

    public class NameFormatted
    {
        public int NameId { get; set; }

        public string Name { get; set; }

        public string NameCode { get; set; }

        public string Nationality { get; set; }

        public int? MainPostalAddressId { get; set; }

        public int? MainStreetAddressId { get; set; }

        public string MainPhone { get; set; }

        public string MainEmail { get; set; }

        public string WebAddress { get; set; }
    }

    public class AddressFormatted
    {
        public int Id { get; set; }

        public string Address { get; set; }
    }

    public class WebsiteData
    {
        public int NameId { get; set; }

        public string WebAddress { get; set; }
    }
}