using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.Picklists
{
    public class AvailableTopic
    {
        public string Key { get; set; }

        public string DefaultTitle { get; set; }

        public string Value => DefaultTitle;

        public string Type { get; set; }

        public string TypeDescription { get; set; }

        public bool IsWebEnabled { get; set; }
    }

    public static class AvailableTopicExt
    {
        public static IEnumerable<AvailableTopic> ForOnlyEntries(this IEnumerable<AvailableTopic> screens)
        {
            const string edeScreenPrefix = "frmEDECaseResolution";

            return screens.Where(s => !s.Key.StartsWith(edeScreenPrefix));
        }

        public static IEnumerable<AvailableTopic> ExcludeDefaultExistingForEntry(this IEnumerable<AvailableTopic> screens)
        {
            return screens.Where(s => !StepsExistingByDefaultForEntry.All.Contains(s.Key));
        }
    }

    public class StepsExistingByDefaultForEntry
    {
        public const string CaseDetails = "frmCaseDetail";
        public const string Letters = "frmLetters";

        public static string[] All => typeof(StepsExistingByDefaultForEntry).GetFields().Select(_ => _.GetRawConstantValue() as string).ToArray();
    }
}
