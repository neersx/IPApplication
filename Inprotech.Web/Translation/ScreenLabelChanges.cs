using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.Translation
{
    public class ScreenLabelChanges
    {
        public string LanguageCode { get; set; }

        public IEnumerable<ChangedTranslation> Translations { get; set; }

        public ScreenLabelChanges()
        {
            Translations = new ChangedTranslation[0];
        }
    }

    public class ChangedTranslation
    {
        public string Key { get; set; }

        public string Value { get; set; }
    }

    public static class ChangedTranslationExtensions
    {
        public static string ResourceId(this ChangedTranslation changedTranslation)
        {
            return (changedTranslation.Key ?? string.Empty).Split('-').Last();
        }

        public static ChangedTranslation RemoveCondorPrefixFromKey(this ChangedTranslation changedTranslation)
        {
            var key = changedTranslation.Key ?? string.Empty;
            if (key.StartsWith("condor-"))
                changedTranslation.Key = key.Substring(7);

            return changedTranslation;
        }

        public static IEnumerable<ChangedTranslation> WithoutCondorPrefix(this IEnumerable<ChangedTranslation> source)
        {
            return source.Select(_ => _.RemoveCondorPrefixFromKey());
        }

        public static IEnumerable<ChangedTranslation> CondorTranslations(this IEnumerable<ChangedTranslation> source)
        {
            return source.Where(_ => _.Key.StartsWith("condor-"));
        }
    }
}