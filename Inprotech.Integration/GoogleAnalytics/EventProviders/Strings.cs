using System;
using System.Collections.Generic;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    public class Strings
    {
        public static readonly Dictionary<string, string> CaseTypes =
            new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase)
            {
                {"A", "Properties"},
                {"B", "Oppositions/Owner"},
                {"C", "Oppositions/Opponent"},
                {"D", "Searching"},
                {"E", "Assignment/recordals"},
                {"F", "Miscellaneous"},
                {"G", "Cancellation/Owner"},
                {"H", "Cancellation/Challenger"},
                {"I", "Licensing"},
                {"M", "Marketing Activities"},
                {"O", "CRM"},
                {"W", "Document"},
                {"X", "Draft Property"},
                {"Y", "Internal"},
                {"Z", "Interim"}
            };

        public static readonly Dictionary<string, string> PropertyTypes =
            new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase)
            {
                {"#", "No IP Rules Set Up"},
                {"~", "Unrestricted"},
                {"1", "Geographical Indication"},
                {"A", "Opportunity"},
                {"B", "Business Names"},
                {"C", "Copyright"},
                {"D", "Designs"},
                {"E", "Marketing Event"},
                {"F", "Campaign"},
                {"I", "Domain Name"},
                {"N", "Innovation Patent"},
                {"P", "Patent"},
                {"R", "Customs Recordals"},
                {"T", "Trademark"},
                {"U", "Utility Models / Petty Patents"},
                {"V", "Plant Variety Right"}
            };
    }
}