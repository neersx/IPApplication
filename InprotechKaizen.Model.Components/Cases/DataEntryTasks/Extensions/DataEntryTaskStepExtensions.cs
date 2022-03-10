using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions
{
    public static class DataEntryTaskStepExtensions
    {
        public static IEnumerable<NameType> IncludedNameTypes(this IEnumerable<DataEntryTaskStep> steps)
        {
            if(steps == null) throw new ArgumentNullException("steps");

            var nameTypesAvailableForEntry = new List<NameType>();
            foreach(var step in steps)
            {
                if(step.IsNameGroupStep())
                    nameTypesAvailableForEntry.AddRange(step.NameGroup.Members.Select(b => b.NameType));

                if(step.IsNameTypeStep())
                    nameTypesAvailableForEntry.Add(step.NameType);
            }
            return nameTypesAvailableForEntry.Distinct().ToArray();
        }

        public static IEnumerable<DataEntryTaskStep> HasNameType(
            this IEnumerable<DataEntryTaskStep> steps,
            NameType nameType)
        {
            var stepArray = steps.ToArray();
            var nameTypeSteps = stepArray.Where(de => de.NameType == nameType).ToList();
            var nameGroupSteps =
                stepArray.Where(de => de.NameGroup.Members.Any(member => member.NameType == nameType)).ToList();
            return nameTypeSteps.Union(nameGroupSteps);
        }

        public static bool IsNameTypeStep(this DataEntryTaskStep step)
        {
            if(step == null) throw new ArgumentNullException("step");

            return step.NameType != null;
        }

        public static bool IsNameGroupStep(this DataEntryTaskStep step)
        {
            if(step == null) throw new ArgumentNullException("step");

            return step.NameGroup != null;
        }

        public static string ToScreenId(this DataEntryTaskStep step)
        {
            if(step == null) throw new ArgumentNullException("step");

            var screenIdTokens = Regex.Split(
                                             step.ScreenName,
                                             @"(?<!(^|[A-Z]))(?=[A-Z])|(?<!^)(?=[A-Z][a-z])")
                                      .ToList()
                                      .Where(str => !String.IsNullOrWhiteSpace(str))
                                      .Where(str => String.Compare(str, "frm", StringComparison.InvariantCulture) != 0)
                                      .Where(str => String.Compare(str, "dlg", StringComparison.InvariantCulture) != 0)
                                      .Select(str => str.ToLowerInvariant());

            return String.Join("-", screenIdTokens);
        }
    }
}