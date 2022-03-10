using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Components.Names.Extensions
{
    public enum AddressShowCountry
    {
        Always,
        NonLocalOnly
    }

    public static class AddressExtensions
    {
        public static string FormattedOrNull(this Address address, AddressStyles addressStyles = AddressStyles.Default)
        {
            return address == null ? null : Formatted(address, address.Country, AddressShowCountry.Always, addressStyles);
        }

        public static string FormattedOrNull(this Address address, Country homeCountry, AddressShowCountry addressShowCountry, AddressStyles addressStyles = AddressStyles.Default)
        {
            return address == null ? null : Formatted(address, homeCountry, addressShowCountry, addressStyles);
        }

        public static string Formatted(this Address address, AddressStyles addressStyles = AddressStyles.Default)
        {
            if (address == null) throw new ArgumentNullException(nameof(address));

            return Formatted(address, address.Country, AddressShowCountry.Always, addressStyles);
        }

        [SuppressMessage("Microsoft.Usage", "CA1801:ReviewUnusedParameters", MessageId = "addressStyles")]
        public static string Formatted(this Address address, Country homeCountry, AddressShowCountry addressShowCountry,
                                       AddressStyles addressStyles = AddressStyles.Default)
        {
            if (address == null) throw new ArgumentNullException(nameof(address));
            if (homeCountry == null) throw new ArgumentNullException(nameof(homeCountry));

            var addressStyle = address.Country.AddressStyleId;
            var state = string.IsNullOrWhiteSpace(address.State)
                ? null
                : address.Country.States.FirstOrDefault(s => s.Code == address.State);

            var showCountry = address.Country != homeCountry || addressShowCountry == AddressShowCountry.Always;

            return FormattedAddress.For(
                                        address.Street1,
                                        address.Street2,
                                        address.City,
                                        address.State,
                                        state != null ? state.Name : null,
                                        address.PostCode,
                                        showCountry ? address.Country.PostalName : string.Empty,
                                        address.Country.PostCodeFirst == 1,
                                        address.Country.StateAbbreviated == 1,
                                        address.Country.PostCodeLiteral,
                                        addressStyle == null ? AddressStyles.Default : (AddressStyles) addressStyle
                                       );
        }
    }
}