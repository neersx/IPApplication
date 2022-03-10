using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Settings;
using Name = InprotechKaizen.Model.Components.Cases.Comparison.Models.Name;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareNamesScenario : IComparisonScenarioResolver
    {
        public IEnumerable<ComparisonScenario> Resolve(CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messageDetails)
        {
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));
            if (messageDetails == null) throw new ArgumentNullException(nameof(messageDetails));

            return (caseDetails.NameDetails ?? new List<NameDetails>())
                .Select(nameDetails =>
                            new ComparisonScenario<Name>(From(nameDetails), ComparisonType.Names));
        }

        public bool IsAllowed(string source)
        {
            return true;
        }

        static Name From(NameDetails nameDetails)
        {
            var address = nameDetails.ReadOnlyFormattedAddress();
            var formattedName = nameDetails.ReadOnlyFormattedName();
            var addressStreetLines =
                string.Join(Environment.NewLine, BuildAddressLines(address)
                                .Where(_ => !string.IsNullOrWhiteSpace(_))
                                .Select(_ => _.Trim())
                                .ToArray());

            if (!CpaXmlScenario.AddressComparisonAllowed.Contains(nameDetails.NameTypeCode))
            {
                return new Name
                       {
                           NameTypeCode = nameDetails.NameTypeCode,
                           FreeFormatName = nameDetails.ReadOnlyFreeFormatNameLine(),
                           FirstName = formattedName.FirstName,
                           LastName = formattedName.LastName,
                           IsIndividual = DeriveFromNameKind(nameDetails),
                           NameReference = nameDetails.NameReference
                       };
            }

            return new Name
                   {
                       NameTypeCode = nameDetails.NameTypeCode,
                       FreeFormatName = nameDetails.ReadOnlyFreeFormatNameLine(),
                       FirstName = formattedName.FirstName,
                       LastName = formattedName.LastName,
                       Street = addressStreetLines,
                       City = address.AddressCity,
                       StateName = address.AddressState,
                       Postcode = address.AddressPostcode,
                       CountryCode = address.AddressCountryCode,
                       IsIndividual = DeriveFromNameKind(nameDetails),
                       NameReference = nameDetails.NameReference
                   };
        }

        static IEnumerable<string> BuildAddressLines(FormattedAddress address)
        {
            var firstLine = address.AddressRoom + " " + address.AddressFloor;
            if (!string.IsNullOrWhiteSpace(firstLine.Trim()))
            {
                yield return firstLine;
            }

            yield return address.AddressBuilding;

            yield return address.AddressStreet;

            if (address.AddressLine == null) yield break;

            foreach (var l in address.AddressLine)
                yield return l;
        }

        static bool? DeriveFromNameKind(NameDetails nameDetails)
        {
            var nameKind = nameDetails.DerivedNameKind();
            if (nameKind == null)
            {
                return null;
            }

            return nameKind == NameKindType.Individual;
        }
    }

    public static class NameDetailsExt
    {
        static FormattedNameAddress ReadOnlyFreeFormattedNameAddress(this NameDetails nameDetails)
        {
            var formattedNameAddress = nameDetails.AddressBook ?? new AddressBook();

            return formattedNameAddress.FormattedNameAddress ?? new FormattedNameAddress();
        }

        static FreeFormatName ReadOnlyFreeFormatName(this NameDetails nameDetails)
        {
            var name = nameDetails.ReadOnlyFreeFormattedNameAddress().Name;

            if (name == null || name.FreeFormatName == null)
            {
                return new FreeFormatName();
            }

            return name.FreeFormatName;
        }

        public static FormattedAddress ReadOnlyFormattedAddress(this NameDetails nameDetails)
        {
            var address = nameDetails.ReadOnlyFreeFormattedNameAddress().Address ?? new Address();

            return address.FormattedAddress ?? new FormattedAddress();
        }

        public static FormattedName ReadOnlyFormattedName(this NameDetails nameDetails)
        {
            var name = nameDetails.ReadOnlyFreeFormattedNameAddress().Name;

            if (name == null)
            {
                return new FormattedName();
            }

            return name.FormattedName ?? new FormattedName();
        }

        public static string ReadOnlyFreeFormatNameLine(this NameDetails nameDetails)
        {
            var freeFormatName = nameDetails.ReadOnlyFreeFormatName();

            return ((freeFormatName.FreeFormatNameDetails ?? new FreeFormatNameDetails())
                    .FreeFormatNameLine ?? new List<string>())
                .FirstOrDefault();
        }

        public static NameKindType? DerivedNameKind(this NameDetails nameDetails)
        {
            var freeFormatName = nameDetails.ReadOnlyFreeFormatName();

            if (freeFormatName.NameKind.HasValue)
            {
                return freeFormatName.NameKind.Value;
            }

            var formattedName = nameDetails.ReadOnlyFormattedName();
            if (string.IsNullOrWhiteSpace(formattedName.FirstName))
            {
                return NameKindType.Individual;
            }

            return null;
        }
    }
}