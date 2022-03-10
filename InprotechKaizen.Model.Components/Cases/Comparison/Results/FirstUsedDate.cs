using System;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    public class FirstUsedDate : Value<DateTime?>
    {
        public string Format { get; set; }

        public string ParseError { get; set; }
    }

    public static class FirstUseDateExtension
    {
        public static bool HasParseError(this FirstUsedDate firstUseDate)
        {
            return !string.IsNullOrWhiteSpace(firstUseDate?.ParseError);
        }
    }
}