using System;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Components.Cases.Extensions
{
    public static class NameTypeExtensions
    {
        public static short[] AllowableInclusions(this NameType nameType)
        {
            if (nameType == null) throw new ArgumentNullException(nameof(nameType));

            return NameCharacteristics.AllowableUsage(
                                                      nameType.AllowIndividualNames,
                                                      nameType.AllowOrganisationNames,
                                                      nameType.AllowStaffNames,
                                                      nameType.AllowClientNames);
        }

        public static IQueryable<NameType> StaffNames(this IQueryable<NameType> nameTypes)
        {
            return from n in nameTypes
                   where (n.PickListFlags & KnownNameTypeAllowedFlags.StaffNames) == KnownNameTypeAllowedFlags.StaffNames
                   select n;
        }

        public static bool MultipleNamesAllowed(this NameType nameType)
        {
            if (nameType == null) throw new ArgumentNullException(nameof(nameType));

            return nameType.MaximumAllowed.GetValueOrDefault() > 1;
        }

        public static IQueryable<NameType> WithoutUnrestricted(this IQueryable<NameType> nameTypes)
        {
            return nameTypes.Where(_ => _.NameTypeCode != KnownNameTypes.UnrestrictedNameTypes);
        }

        public static string Format(this NameType nameType, Name name, NameStyles? fallbackNameStyle = null)
        {
            if (nameType == null || name == null || name.NameCode.IsNullOrEmpty()) return name?.Formatted(fallbackNameStyle: fallbackNameStyle);
            switch (nameType.ShowNameCode)
            {
                case 1m: return $"{{{name.NameCode}}} {name.Formatted(fallbackNameStyle: fallbackNameStyle)}";
                case 2m: return $"{name.Formatted(fallbackNameStyle: fallbackNameStyle)} {{{name.NameCode}}}";
                default: return name.Formatted(fallbackNameStyle: fallbackNameStyle);
            }
        }

        public static string Format(this ShowNameCode showNameCode, string formattedName, string nameCode)
        {
            if (nameCode.IsNullOrEmpty()) return formattedName;

            switch (showNameCode)
            {
                case ShowNameCode.First: return $"{{{nameCode}}} {formattedName}";
                case ShowNameCode.Last: return $"{formattedName} {{{nameCode}}}";
                default: return formattedName;
            }
        }

        public static string ToShowNameCode(this NameType nameType, bool camelCase = true)
        {
            if (nameType == null) return string.Empty;
            var d = (decimal) (nameType.ShowNameCode == null ? 0 : nameType.ShowNameCode);
            var s = ((ShowNameCode) Convert.ToInt32(d)).ToString();
            return camelCase ? s.ToCamelCase() : s;
        }
    }

    public enum ShowNameCode
    {
        First = 1,
        Last = 2,
        None = 0
    }
}