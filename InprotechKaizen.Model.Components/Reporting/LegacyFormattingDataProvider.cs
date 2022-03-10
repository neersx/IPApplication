using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Reporting
{
    public interface ILegacyFormattingDataProvider
    {
        LegacyStandardReportFormattingData Provide(string culture);
    }

    public class LegacyFormattingDataProvider : ILegacyFormattingDataProvider
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;

        public enum SettingsType
        {
            CurrencyFormat,
            LocalCurrencyFormat,
            LocalCurrencyFormatNoSymbol
        }

        static readonly ConcurrentDictionary<string, StaticCurrencyFormat> Cache = 
            new (StringComparer.InvariantCultureIgnoreCase);
        
        public LegacyFormattingDataProvider(IDbContext dbContext, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
        }

        public LegacyStandardReportFormattingData Provide(string culture)
        {
            var currencyFormat = Cache.GetOrAdd(culture, x => new StaticCurrencyFormat
            {
                Default = GetCurrencyFormat(culture),
                LocalWithSymbol = GetCurrencyFormat(culture, SettingsType.LocalCurrencyFormat),
                LocalWithoutSymbol =GetCurrencyFormat(culture, SettingsType.LocalCurrencyFormatNoSymbol)
            });

            var dateStyle = _siteControlReader.Read<int>(SiteControls.DateStyle);
            var currencyWholeUnits = _siteControlReader.Read<bool>(SiteControls.CurrencyWholeUnits);
            var homeCurrency = _siteControlReader.Read<string>(SiteControls.CURRENCY);
            var allCurrencies = _dbContext.Set<Currency>().ToDictionary(k => k.Id, v => v.DecimalPlaces ?? 2);
            if (currencyWholeUnits)
            {
                allCurrencies[homeCurrency] = 0;
            }

            return new LegacyStandardReportFormattingData
            {
                DateFormat = GetDateFormat(culture, dateStyle),
                TimeFormat = GetTimeFormat(culture),
                CurrencyFormat = currencyFormat.Default,
                LocalCurrencyFormat = currencyFormat.LocalWithoutSymbol,
                LocalCurrencyFormatWithSymbol = currencyFormat.LocalWithSymbol,
                CurrencyDecimalPlaces = allCurrencies
            };
        }

        static string GetTimeFormat(string culture)
        {
            var dtInfo = new CultureInfo(culture).DateTimeFormat;
            return dtInfo.GetAllDateTimePatterns('t')[0];
        }

        static string GetDateFormat(string culture, int dateStyle)
        {
            string GetCultureDateFormat(char requestFormat)
            {
                var dtInfo = new CultureInfo(culture).DateTimeFormat;
                return dtInfo.GetAllDateTimePatterns(requestFormat)[0];
            }

            if (!string.IsNullOrEmpty(culture) && culture.StartsWith("zh"))
            {
                return GetCultureDateFormat('d');
            }

            return dateStyle switch
            {
                1 => "dd-MMM-yyyy",
                2 => "MMM-dd-yyyy",
                3 => "yyyy-MMM-dd",
                _ => GetCultureDateFormat('d')
            };
        }

        static string GetCurrencyFormat(string culture, SettingsType setting = SettingsType.CurrencyFormat, int digits = 2)
        {
            CultureInfo.CreateSpecificCulture(culture);
            var numFormat = (NumberFormatInfo)CultureInfo.CreateSpecificCulture(culture).NumberFormat.Clone();

            var posFormatSpecifier = string.Empty;
            var negFormatSpecifier = string.Empty;

            var groupOfDigits = string.Empty;
            for (var i = 0; i < numFormat.CurrencyGroupSizes.Length; i++)
            {
                for (var j = 0; j < numFormat.CurrencyGroupSizes[i]; j++)
                    groupOfDigits = "#" + groupOfDigits;

                if (i == 0)
                {
                    if (i == numFormat.CurrencyGroupSizes.Length - 1)
                    {
                        groupOfDigits = "#" + numFormat.CurrencyGroupSeparator + groupOfDigits;
                    }
                    else
                    {
                        groupOfDigits = numFormat.CurrencyGroupSeparator + groupOfDigits;
                    }
                }
                else if (i == numFormat.NumberGroupSizes.Length + 1)
                {
                    groupOfDigits = "#" + numFormat.CurrencyGroupSeparator + groupOfDigits;
                }
                else
                {
                    groupOfDigits = numFormat.CurrencyGroupSeparator + groupOfDigits;
                }
            }

            var baseFormatSpecifier = groupOfDigits.Substring(0, groupOfDigits.Length - 1) + "0";
            if (digits < 0) digits = 0;
            if (digits > 0)
            {
                baseFormatSpecifier += numFormat.CurrencyDecimalSeparator;
                for (var i = 0; i < digits; i++)
                    baseFormatSpecifier += "0";
            }

            if (setting == SettingsType.CurrencyFormat)
            {
                numFormat.CurrencySymbol = "$"; // this is replaced in the FormatCurrency template in Utils.xslt

                posFormatSpecifier = numFormat.CurrencyPositivePattern switch
                {
                    0 => numFormat.CurrencySymbol + baseFormatSpecifier, // $n
                    1 => baseFormatSpecifier + numFormat.CurrencySymbol, // n$
                    2 => numFormat.CurrencySymbol + " " + baseFormatSpecifier, // $ n
                    3 => baseFormatSpecifier + " " + numFormat.CurrencySymbol, // n $
                    _ => posFormatSpecifier
                };

                negFormatSpecifier = numFormat.CurrencyNegativePattern switch
                {
                    0 => "(" + numFormat.CurrencySymbol + baseFormatSpecifier + ")", // ($n) 
                    1 => numFormat.NegativeSign + numFormat.CurrencySymbol + baseFormatSpecifier, // -$n 
                    2 => numFormat.CurrencySymbol + numFormat.NegativeSign + baseFormatSpecifier, // $-n 
                    3 => numFormat.CurrencySymbol + baseFormatSpecifier + numFormat.NegativeSign, // $n- 
                    4 => "(" + baseFormatSpecifier + numFormat.CurrencySymbol + ")", // (n$) 
                    5 => numFormat.NegativeSign + baseFormatSpecifier + numFormat.CurrencySymbol, // -n$ 
                    6 => baseFormatSpecifier + numFormat.NegativeSign + numFormat.CurrencySymbol, // n-$ 
                    7 => baseFormatSpecifier + numFormat.CurrencySymbol + numFormat.NegativeSign, // n$- 
                    8 => numFormat.NegativeSign + baseFormatSpecifier + " " + numFormat.CurrencySymbol, // -n $ 
                    9 => numFormat.NegativeSign + numFormat.CurrencySymbol + " " + baseFormatSpecifier, // -$ n 
                    10 => baseFormatSpecifier + " " + numFormat.CurrencySymbol + numFormat.NegativeSign, // n $- 
                    11 => numFormat.CurrencySymbol + " " + baseFormatSpecifier + numFormat.NegativeSign, // $ n- 
                    12 => numFormat.CurrencySymbol + " " + numFormat.NegativeSign + baseFormatSpecifier, // $ -n 
                    13 => baseFormatSpecifier + numFormat.NegativeSign + " " + numFormat.CurrencySymbol, // n- $ 
                    14 => "(" + numFormat.CurrencySymbol + " " + baseFormatSpecifier + ")", // ($ n) 
                    15 => "(" + baseFormatSpecifier + " " + numFormat.CurrencySymbol + ")", // (n $) 
                    _ => negFormatSpecifier
                };
            }
            else
            {
                posFormatSpecifier = baseFormatSpecifier;

                negFormatSpecifier = numFormat.CurrencyNegativePattern switch
                {
                    0 => "(" + baseFormatSpecifier + ")", // ($n) 
                    1 => numFormat.NegativeSign + baseFormatSpecifier, // -$n 
                    2 => numFormat.NegativeSign + baseFormatSpecifier, // $-n 
                    3 => baseFormatSpecifier + numFormat.NegativeSign, // $n- 
                    4 => "(" + baseFormatSpecifier + ")", // (n$) 
                    5 => numFormat.NegativeSign + baseFormatSpecifier, // -n$ 
                    6 => baseFormatSpecifier + numFormat.NegativeSign, // n-$ 
                    7 => baseFormatSpecifier + numFormat.NegativeSign, // n$- 
                    8 => numFormat.NegativeSign + baseFormatSpecifier, // -n $ 
                    9 => numFormat.NegativeSign + " " + baseFormatSpecifier, // -$ n 
                    10 => baseFormatSpecifier + " " + numFormat.NegativeSign, // n $- 
                    11 => baseFormatSpecifier + numFormat.NegativeSign, // $ n- 
                    12 => numFormat.NegativeSign + baseFormatSpecifier, // $ -n 
                    13 => baseFormatSpecifier + numFormat.NegativeSign, // n- $ 
                    14 => "(" + baseFormatSpecifier + ")", // ($ n) 
                    15 => "(" + baseFormatSpecifier + ")", // (n $) 
                    _ => negFormatSpecifier
                };
            }

            return posFormatSpecifier + ";" + negFormatSpecifier;
        }

        class StaticCurrencyFormat
        {
            public string Default { get; set; }

            public string LocalWithSymbol { get; set; }

            public string LocalWithoutSymbol { get; set; }
        }
    }

    public class LegacyStandardReportFormattingData
    {
        public string DateFormat { get; set; }

        public string TimeFormat { get; set; }

        public string CurrencyFormat { get; set; }

        public string LocalCurrencyFormat { get; set; }

        public string LocalCurrencyFormatWithSymbol { get; set; }

        public Dictionary<string, byte> CurrencyDecimalPlaces { get; set; } = new();
    }
}
