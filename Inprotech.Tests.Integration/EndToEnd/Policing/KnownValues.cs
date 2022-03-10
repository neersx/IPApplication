using System.Collections.Generic;

namespace Inprotech.Tests.Integration.EndToEnd.Policing
{
    static class KnownValues
    {
        public static readonly Dictionary<string, int> StringToHoldFlag =
            new Dictionary<string, int>
            {
                {"in-error", 4},
                {"on-hold", 9},
                {"waiting-to-start", 0},
                {"in-progress", 3}
            };

        public static readonly Dictionary<string, int> StringToTypeOfRequest =
            new Dictionary<string, int>
            {
                {"open-action", 1},
                {"due-date-changed", 2},
                {"event-occurred", 3},
                {"action-recalculation", 4},
                {"designated-country-change", 5},
                {"due-date-recalculation", 6},
                {"patent-term-adjustment", 7},
                {"document-case-changes", 8},
                {"prior-art-distribution", 9}
            };
    }
}