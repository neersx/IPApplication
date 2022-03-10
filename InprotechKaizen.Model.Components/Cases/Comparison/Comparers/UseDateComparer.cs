using System;
using System.Globalization;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public interface IUseDateComparer
    {
        FirstUsedDate Compare(DateTime? inproUseDate, string sourceUseDate);
    }

    public class UseDateComparer : IUseDateComparer
    {
        public FirstUsedDate Compare(DateTime? inproUseDate, string sourceUseDate)
        {
            string parseError;

            var r = new FirstUsedDate
                    {
                        Format = GetFirstUsedDateFormat(sourceUseDate),
                        OurValue = inproUseDate,
                        TheirValue = ParseFirstUsedDate(sourceUseDate, out parseError),
                        ParseError = parseError
                    };

            CheckDifference(r);

            return r;
        }

        static string GetFirstUsedDateFormat(string value)
        {
            if (value == null) return "P";

            if (value.EndsWith("0000"))
                return "Year";

            if (value.EndsWith("00"))
                return "MonthYear";

            return "P";
        }

        static bool AreFirstUsedDatesSame(DateTime? date1, DateTime? date2, string format)
        {
            if (format == "Year" && date1.HasValue && date2.HasValue)
                return date1.Value.Year == date2.Value.Year;

            if (format == "MonthYear" && date1.HasValue && date2.HasValue)
                return date1.Value.Year == date2.Value.Year && date1.Value.Month == date2.Value.Month;

            return date1 == date2;
        }

        static void CheckDifference(FirstUsedDate date)
        {
            date.Different = !AreFirstUsedDatesSame(date.OurValue, date.TheirValue, date.Format);
            date.Updateable = (bool) date.Different && date.TheirValue != null;
        }

        static DateTime? ParseFirstUsedDate(string value, out string parseError)
        {
            parseError = null;
            if (string.IsNullOrEmpty(value)) return null;
            
            DateTime result;
            if (value.EndsWith("0000"))
            {
                value = value.Substring(0, value.Length - 4) + "1231";
            }
            else if (value.EndsWith("00"))
            {
                value = value.Substring(0, value.Length - 2) + "01";
                if (DateTime.TryParseExact(value, "yyyyMMdd", null, DateTimeStyles.None, out result))
                    return result.AddMonths(1).AddDays(-1);
            }

            if (DateTime.TryParseExact(value, "yyyyMMdd", null, DateTimeStyles.None, out result))
                return result;

            parseError = $"Unable to recognize date '{value}'.";
            return null;
        }
    }
}