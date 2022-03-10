using System.Collections.Generic;
using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Names;

namespace InprotechKaizen.Model.Components.Cases
{
    public static class CaseExtension
    {
        public static IQueryable<Case> ByPropertyType(this IDbSet<Case> cases, string propertyType)
        {
            return cases.Where(c => c.PropertyType.Code == propertyType);
        }

        [SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Nos")]
        public static string OfficialNos(this Case @case)
        {
            var first3 = @case.CurrentOfficialNumbers().Take(3).Select(s => s.Number).ToArray();
            return first3.Any() ? string.Join(", ", first3) : string.Empty;
        }

        public static IEnumerable<OfficialNumber> CurrentOfficialNumbers(this Case @case)
        {
                return @case.OfficialNumbers.Where(on => on.IsCurrent == 1)
                                      .OrderBy(on => on.NumberType.DisplayPriority)
                                      .ThenBy(on => on.NumberType.Name)
                                      .ThenBy(on => on.DateEntered)
                                      .ThenBy(on => on.Number);
        }

        public static CaseName WorkingAttorneyName(this Case @case)
        {
                if (!@case.CaseNames.Any()) return null;
                return @case.CaseNames.Where(cn => cn.NameType.NameTypeCode == KnownNameTypes.StaffMember)
                             .OrderBy(cn => cn.Sequence)
                             .FirstOrDefault();
        }

        public static string WorkingAttorney(this Case @case)
        {
            var workingAttorney = @case.WorkingAttorneyName();
            return workingAttorney?.Name.FormattedNameOrNull();
        }

        public static string FirstApplicant(this Case @case)
        {
            if (!@case.CaseNames.Any()) return null;
            var owner = @case.CaseNames.Where(cn => cn.NameType.NameTypeCode == KnownNameTypes.Owner)
                             .OrderBy(cn => cn.Sequence)
                             .FirstOrDefault();
            return owner != null ? owner.NameType.Format(owner.Name) : string.Empty;
        }

        public static CaseName Client(this Case @case)
        {
            if (!@case.CaseNames.Any()) return null;
            return @case
                   .CaseNames.Where(cn => cn.NameType.NameTypeCode == KnownNameTypes.Instructor)
                   .OrderBy(cn => cn.Sequence)
                   .FirstOrDefault();
        }

        public static string ClientName(this Case @case)
        {
            var client = @case.Client();
            return client == null ? string.Empty : client.NameType.Format(client.Name);
        }

        public static string ClientReference(this Case @case)
        {
            var client = @case.Client();
            return client == null ? string.Empty : client.Reference;
        }

        public static CaseLocation MostRecentCaseLocation(this Case @case)
        {
            return @case.CaseLocations.OrderByDescending(c => c.WhenMoved).FirstOrDefault();
        }

        public static IEnumerable<CaseText> GoodsAndServices(this Case @case)
        {
            return @case.CaseTexts.Where(_ => _.Class != null && _.Type == KnownTextTypes.GoodsServices);
        }
    }
}