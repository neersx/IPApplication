using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Names;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface ICaseNameAddressResolver
    {
        CaseNameAddress Resolve(CaseName name);
    }

    public class CaseNameAddressResolver : ICaseNameAddressResolver
    {
        readonly ISiteConfiguration _siteConfiguration;

        public CaseNameAddressResolver(ISiteConfiguration siteConfiguration)
        {
            if (siteConfiguration == null) throw new ArgumentNullException("siteConfiguration");
            _siteConfiguration = siteConfiguration;
        }

        public CaseNameAddress Resolve(CaseName name)
        {
            if (name == null) throw new ArgumentNullException("name");

            var address = name.Address;

            var inherited = false;

            if (address == null)
            {
                var mainPostal = name.Name.PostalAddressId;
                var nameAddress = name.Name.Addresses.SingleOrDefault(_ => _.AddressId == mainPostal && _.AddressType == (int)KnownAddressTypes.PostalAddress);
                if (nameAddress != null)
                {
                    address = nameAddress.Address;
                    inherited = true;
                }
            }

            if (address == null) return new CaseNameAddress();
            
            var bestCountry = address.Country ?? _siteConfiguration.HomeCountry();

            return new CaseNameAddress
                   {
                       IsInherited = inherited,
                       FormattedAddress = FormattedAddress.For(
                           address.Street1,
                           address.Street2,
                           address.City,
                           address.State,
                           FullStateName(bestCountry, address.State),
                           address.PostCode,
                           bestCountry.PostalName,
                           bestCountry.PostCodeFirst == 1,
                           bestCountry.StateAbbreviated == 1,
                           bestCountry.PostCodeLiteral,
                           bestCountry.AddressStyleId),
                   };
        }

        static string FullStateName(Country country, string state)
        {
            if (string.IsNullOrWhiteSpace(state))
                return string.Empty;

            var s = country.States.FirstOrDefault(_ => _.Code == state);
            return s != null ? s.Name : string.Empty;
        }
    }

    public class CaseNameAddress
    {
        public string FormattedAddress { get; set; }

        public bool IsInherited { get; set; }
    }
}