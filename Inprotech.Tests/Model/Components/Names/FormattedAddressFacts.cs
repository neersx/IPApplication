using System;
using InprotechKaizen.Model.Components.Names;
using Xunit;

namespace Inprotech.Tests.Model.Components.Names
{
    public class FormattedAddressFacts
    {
        [Theory]
        [InlineData(ExpectedPostCodeBeforeCityFullState.AllSet, "street 1", "street 2", "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.PostCodeBeforeCityFullState)]
        [InlineData(ExpectedPostCodeBeforeCityFullState.NoStreet2, "street 1", null, "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.PostCodeBeforeCityFullState)]
        [InlineData(ExpectedPostCodeBeforeCityFullState.CountryOnly, null, null, null, null, null, null, "australia", true, true, "post code", AddressStyles.PostCodeBeforeCityFullState)]
        [InlineData(ExpectedPostCodeBeforeCityShortState.AllSet, "street 1", "street 2", "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.PostCodeBeforeCityShortState)]
        [InlineData(ExpectedPostCodeBeforeCityShortState.NoStreet2, "street 1", null, "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.PostCodeBeforeCityShortState)]
        [InlineData(ExpectedPostCodeBeforeCityShortState.CountryOnly, null, null, null, null, null, null, "australia", true, true, "post code", AddressStyles.PostCodeBeforeCityShortState)]
        [InlineData(ExpectedPostCodeBeforeCityNoState.AllSet, "street 1", "street 2", "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.PostCodeBeforeCityNoState)]
        [InlineData(ExpectedPostCodeBeforeCityNoState.NoStreet2, "street 1", null, "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.PostCodeBeforeCityNoState)]
        [InlineData(ExpectedPostCodeBeforeCityNoState.CountryOnly, null, null, null, null, null, null, "australia", true, true, "post code", AddressStyles.PostCodeBeforeCityNoState)]
        [InlineData(ExpectedCityBeforePostCodeFullState.AllSet, "street 1", "street 2", "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.CityBeforePostCodeFullState)]
        [InlineData(ExpectedCityBeforePostCodeFullState.NoStreet2, "street 1", null, "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.CityBeforePostCodeFullState)]
        [InlineData(ExpectedCityBeforePostCodeFullState.CountryOnly, null, null, null, null, null, null, "australia", true, true, "post code", AddressStyles.CityBeforePostCodeFullState)]
        [InlineData(ExpectedCityBeforePostCodeShortState.AllSet, "street 1", "street 2", "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.CityBeforePostCodeShortState)]
        [InlineData(ExpectedCityBeforePostCodeShortState.NoStreet2, "street 1", null, "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.CityBeforePostCodeShortState)]
        [InlineData(ExpectedCityBeforePostCodeShortState.CountryOnly, null, null, null, null, null, null, "australia", true, true, "post code", AddressStyles.CityBeforePostCodeShortState)]
        [InlineData(ExpectedCityBeforePostCodeNoState.AllSet, "street 1", "street 2", "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.CityBeforePostCodeNoState)]
        [InlineData(ExpectedCityBeforePostCodeNoState.NoStreet2, "street 1", null, "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.CityBeforePostCodeNoState)]
        [InlineData(ExpectedCityBeforePostCodeNoState.CountryOnly, null, null, null, null, null, null, "australia", true, true, "post code", AddressStyles.CityBeforePostCodeNoState)]
        [InlineData(ExpectedCountryFullStateCityStreetThenPostCode.AllSet, "street 1", "street 2", "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.CountryFullStateCityStreetThenPostCode)]
        [InlineData(ExpectedCountryFullStateCityStreetThenPostCode.NoStreet2, "street 1", null, "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.CountryFullStateCityStreetThenPostCode)]
        [InlineData(ExpectedCountryFullStateCityStreetThenPostCode.CountryOnly, null, null, null, null, null, null, "australia", true, true, "post code", AddressStyles.CountryFullStateCityStreetThenPostCode)]
        [InlineData(ExpectedCountryPostcodeFullStateCityThenStreet.AllSet, "street 1", "street 2", "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.CountryPostcodeFullStateCityThenStreet)]
        [InlineData(ExpectedCountryPostcodeFullStateCityThenStreet.NoStreet2, "street 1", null, "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.CountryPostcodeFullStateCityThenStreet)]
        [InlineData(ExpectedCountryPostcodeFullStateCityThenStreet.CountryOnly, null, null, null, null, null, null, "australia", true, true, "post code", AddressStyles.CountryPostcodeFullStateCityThenStreet)]
        [InlineData(ExpectedDefault.AllSet, "street 1", "street 2", "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.Default)]
        [InlineData(ExpectedDefault.NoStreet2, "street 1", null, "sydney", "nsw", "new south wales", "2000", "australia", true, true, "post code", AddressStyles.Default)]
        [InlineData(ExpectedDefault.CountryOnly, null, null, null, null, null, null, "australia", true, true, "post code", AddressStyles.Default)]
        public void ShouldFormatAddressAccordingly(string expected, string street1, string street2, string city, string state, string stateName,
                                                   string postCode, string country, bool postCodeFirst, bool stateAbbreviated, string postCodeLiteral, AddressStyles style)
        {
            var formattedAddress = FormattedAddress.For(
                                                        street1,
                                                        street2,
                                                        city,
                                                        state, stateName,
                                                        postCode,
                                                        country,
                                                        postCodeFirst, stateAbbreviated, postCodeLiteral, style);

            Assert.Equal(expected.Replace("_", Environment.NewLine), formattedAddress);
        }

        public static class ExpectedPostCodeBeforeCityFullState
        {
            public const string AllSet = @"street 1_street 2_2000 sydney_new south wales_australia";
            public const string NoStreet2 = @"street 1_2000 sydney_new south wales_australia";
            public const string CountryOnly = @"australia";
        }

        public static class ExpectedPostCodeBeforeCityShortState
        {
            public const string AllSet = @"street 1_street 2_2000 sydney nsw_australia";
            public const string NoStreet2 = @"street 1_2000 sydney nsw_australia";
            public const string CountryOnly = @"australia";
        }

        public static class ExpectedPostCodeBeforeCityNoState
        {
            public const string AllSet = @"street 1_street 2_2000 sydney_australia";
            public const string NoStreet2 = @"street 1_2000 sydney_australia";
            public const string CountryOnly = @"australia";
        }

        public static class ExpectedCityBeforePostCodeFullState
        {
            public const string AllSet = @"street 1_street 2_sydney_new south wales_2000_australia";
            public const string NoStreet2 = @"street 1_sydney_new south wales_2000_australia";
            public const string CountryOnly = @"australia";
        }

        public static class ExpectedCityBeforePostCodeShortState
        {
            public const string AllSet = @"street 1_street 2_sydney nsw 2000_australia";
            public const string NoStreet2 = @"street 1_sydney nsw 2000_australia";
            public const string CountryOnly = @"australia";
        }

        public static class ExpectedCityBeforePostCodeNoState
        {
            public const string AllSet = @"street 1_street 2_sydney 2000_australia";
            public const string NoStreet2 = @"street 1_sydney 2000_australia";
            public const string CountryOnly = @"australia";
        }

        public static class ExpectedCountryFullStateCityStreetThenPostCode
        {
            public const string AllSet = @"australia new south wales sydney street 1_post code: 2000";
            public const string NoStreet2 = @"australia new south wales sydney street 1_post code: 2000";
            public const string CountryOnly = @"australia";
        }

        public static class ExpectedCountryPostcodeFullStateCityThenStreet
        {
            public const string AllSet = @"australia_2000 nsw sydney_street 1_street 2";
            public const string NoStreet2 = @"australia_2000 nsw sydney_street 1";
            public const string CountryOnly = @"australia";
        }

        public static class ExpectedDefault
        {
            public const string AllSet = @"street 1_street 2_2000 sydney nsw_australia";
            public const string NoStreet2 = @"street 1_2000 sydney nsw_australia";
            public const string CountryOnly = @"australia";
        }
    }
}