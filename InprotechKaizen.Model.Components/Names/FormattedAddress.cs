using System;
using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Components.Names
{
    public enum AddressStyles
    {
        Default = -1,
        PostCodeBeforeCityFullState = 7201,
        PostCodeBeforeCityShortState = 7202,
        PostCodeBeforeCityNoState = 7203,
        CityBeforePostCodeFullState = 7204,
        CityBeforePostCodeShortState = 7205,
        CityBeforePostCodeNoState = 7206,
        CountryPostcodeFullStateCityThenStreet = 7207,
        CountryFullStateCityStreetThenPostCode = 7208
    }

    public static class FormattedAddress
    {
        const string Space = " ";
        const string Empty = "";

        static Dictionary<AddressStyles, Func<string, string, string, string, string, string, string, bool, bool, string, IEnumerable<string>>>
            _ = new Dictionary<AddressStyles, Func<string, string, string, string, string, string, string, bool, bool, string, IEnumerable<string>>>
                {
                    {AddressStyles.Default, Default},
                    {AddressStyles.PostCodeBeforeCityFullState, PostCodeBeforeCityFullState},
                    {AddressStyles.PostCodeBeforeCityShortState, PostCodeBeforeCityShortState},
                    {AddressStyles.PostCodeBeforeCityNoState, PostCodeBeforeCityNoState},
                    {AddressStyles.CityBeforePostCodeFullState, CityBeforePostCodeFullState},
                    {AddressStyles.CityBeforePostCodeShortState, CityBeforePostCodeShortState},
                    {AddressStyles.CityBeforePostCodeNoState, CityBeforePostCodeNoState},
                    {AddressStyles.CountryPostcodeFullStateCityThenStreet, CountryPostcodeFullStateCityThenStreet},
                    {AddressStyles.CountryFullStateCityStreetThenPostCode, CountryFullStateCityStreetThenPostCode}
                };

        public static string For(string street1, string street2, string city, string state, string stateName,
            string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral,
            int? addressStyle = null)
        {
            var style = (AddressStyles)(addressStyle ?? (int) AddressStyles.Default);

            return For(
                street1, street2, city, state, stateName, postCode, country, postCodeFirst, stateAbbreviated, postCodeLiteral, style);
        }

        public static string For(string street1, string street2, string city, string state, string stateName,
            string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral,
            AddressStyles? addressStyle = AddressStyles.Default)
        {
            var lines = _[addressStyle ?? AddressStyles.Default]
                (street1, street2, city, state, stateName, postCode, country, postCodeFirst, stateAbbreviated, postCodeLiteral);

            var formattedAddress = string.Join(Environment.NewLine,
                lines.Where(r => !string.IsNullOrWhiteSpace(r))
                    .Select(r => r.Trim())
                    .ToArray());

            return string.IsNullOrWhiteSpace(formattedAddress) ? null : formattedAddress;
        }

        static IEnumerable<string> Default(string street1, string street2, string city, string state, string stateName,
            string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral)
        {
            return postCodeFirst
                ? (stateAbbreviated
                    ? PostCodeBeforeCityShortState(street1, street2, city, state, stateName, postCode, country, true, true, postCodeLiteral)
                    : PostCodeBeforeCityFullState(street1, street2, city, state, stateName, postCode, country, true, false, postCodeLiteral))
                : (stateAbbreviated
                    ? CityBeforePostCodeShortState(street1, street2, city, state, stateName, postCode, country, false, true, postCodeLiteral)
                    : CityBeforePostCodeFullState(street1, street2, city, state, stateName, postCode, country, false, false, postCodeLiteral));
        }

        static IEnumerable<string> PostCodeBeforeCityFullState(string street1, string street2, string city, string state, string stateName,
            string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral)
        {
            yield return street1;
            yield return street2;
            yield return Build(postCode, city);
            yield return stateName;
            yield return country;
        }

        static IEnumerable<string> PostCodeBeforeCityShortState(string street1, string street2, string city, string state, string stateName,
            string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral)
        {
            yield return street1;
            yield return street2;
            yield return Build(postCode, city, state);
            yield return country;
        }

        static IEnumerable<string> PostCodeBeforeCityNoState(string street1, string street2, string city, string state, string stateName,
            string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral)
        {
            yield return street1;
            yield return street2;
            yield return Build(postCode, city);
            yield return country;
        }

        static IEnumerable<string> CityBeforePostCodeFullState(string street1, string street2, string city, string state, string stateName,
            string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral)
        {
            yield return street1;
            yield return street2;
            yield return city;
            yield return stateName;
            yield return postCode;
            yield return country;
        }

        static IEnumerable<string> CityBeforePostCodeShortState(string street1, string street2, string city, string state, string stateName,
            string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral)
        {
            yield return street1;
            yield return street2;
            yield return Build(city, state, postCode);
            yield return country;
        }

        static IEnumerable<string> CityBeforePostCodeNoState(string street1, string street2, string city, string state, string stateName,
            string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral)
        {
            yield return street1;
            yield return street2;
            yield return Build(city, postCode);
            yield return country;
        }

        static IEnumerable<string> CountryPostcodeFullStateCityThenStreet(string street1, string street2, string city, string state, string stateName,
            string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral)
        {
            yield return country;
            yield return Build(postCode, stateAbbreviated ? state : stateName, city);
            yield return street1;
            yield return street2;
        }

        static IEnumerable<string> CountryFullStateCityStreetThenPostCode(string street1, string street2, string city, string state, string stateName,
            string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral)
        {
            var postCodeHeading = postCodeLiteral + ":";
            var postCodeLine = Build(string.IsNullOrWhiteSpace(postCodeLiteral) ? Empty : postCodeHeading, postCode);

            yield return Build(country, stateName, city, street1);
            yield return postCodeLine == postCodeHeading ? Empty : postCodeLine;
        }

        static string Build(params string[] components)
        {
            return string.Join(Space, components.Where(c => !string.IsNullOrWhiteSpace(c)).Select(c => c.Trim())).Trim();
        }
    }
}