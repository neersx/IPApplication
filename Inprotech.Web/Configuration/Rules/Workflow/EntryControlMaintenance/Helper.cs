using System;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    public static class Helper
    {
        public static bool IsUpdateForChildCriteria(DataEntryTask entry, WorkflowEntryControlSaveModel newValues)
        {
            return newValues.CriteriaId != entry.CriteriaId;
        }

        public static bool AreDescriptionsDifferent(string description1, string description2, bool considerAlphanumericsOnly = true)
        {
            if (string.IsNullOrEmpty(description1) && string.IsNullOrEmpty(description2))
                return false;

            if (considerAlphanumericsOnly)
            {
                return (description1 ?? string.Empty).ToLower().StripNonAlphanumerics() != (description2 ?? string.Empty).ToLower().StripNonAlphanumerics();
            }

            return !string.Equals(description1 ?? string.Empty, description2 ?? string.Empty, StringComparison.CurrentCultureIgnoreCase);
        }
    }
}
