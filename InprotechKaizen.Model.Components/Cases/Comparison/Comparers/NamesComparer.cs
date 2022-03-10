using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Settings;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using Case = InprotechKaizen.Model.Cases.Case;
using CaseName = InprotechKaizen.Model.Cases.CaseName;
using Name = InprotechKaizen.Model.Components.Cases.Comparison.Models.Name;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class NamesComparer : ISpecificComparer
    {
        readonly ICaseNameAddressResolver _caseNameAddressResolver;
        readonly ICurrentNames _currentNames;
        readonly IDbContext _dbContext;
        readonly string _culture;

        public NamesComparer(IDbContext dbContext, ICurrentNames currentNames,
                             ICaseNameAddressResolver caseNameAddressResolver, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _currentNames = currentNames;
            _caseNameAddressResolver = caseNameAddressResolver;
            _culture = preferredCultureResolver.Resolve();
        }

        public void Compare(
            Case @case,
            IEnumerable<ComparisonScenario> comparisonScenarios, ComparisonResult result)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (comparisonScenarios == null) throw new ArgumentNullException(nameof(comparisonScenarios));
            if (result == null) throw new ArgumentNullException(nameof(result));

            result.CaseNames =
                Build(@case, comparisonScenarios.OfType<ComparisonScenario<Name>>().ToArray())
                    .OrderBy(_ => _.NameType)
                    .ThenBy(_ => _.Sequence);
        }

        IEnumerable<Results.CaseName> Build(Case @case, ComparisonScenario<Name>[] scenarios)
        {
            var nameTypeCodes = scenarios.Select(_ => _.Mapped.NameTypeCode).Distinct().ToArray();

            var countryCodes = scenarios.Select(_ => _.Mapped.CountryCode).Distinct().ToArray();

            var nameTypes = (from nt in _dbContext.Set<NameType>()
                            where nameTypeCodes.Contains(nt.NameTypeCode)
                            select new
                                   {
                                       NameType = nt,
                                       NameTypeTranslated = DbFuncs.GetTranslation(nt.Name, null, nt.NameTId, _culture)
                                   }).ToArray();

            var countries = _dbContext.Set<Country>().Where(_ => countryCodes.Contains(_.Id)).ToArray();

            var currentNames = _currentNames.For(@case).ToArray();
            
            foreach (var nameType in nameTypes)
            {
                var nt = nameType.NameType;
                
                var imported =
                    scenarios.Where(
                                    _ =>
                                        string.Equals(_.Mapped.NameTypeCode, nt.NameTypeCode,
                                                      StringComparison.InvariantCultureIgnoreCase))
                             .ToArray();

                var unmatchedInprotech = new List<CaseName>();

                foreach (var currentName in currentNames.Where(_ => _.NameType == nt).OrderBy(_ => _.Sequence))
                {
                    var matched = imported.FirstOrDefault(_ => NamesLookTheSame(currentName, _.Mapped));
                    if (matched != null)
                    {
                        yield return Build(nameType.NameTypeTranslated, currentName, matched.Mapped, countries);
                        imported = imported.Except(new[] {matched}).ToArray();
                        continue;
                    }

                    unmatchedInprotech.Add(currentName);
                }

                if (!nt.MultipleNamesAllowed() &&
                    unmatchedInprotech.Count == imported.Length &&
                    unmatchedInprotech.Count == 1)
                {
                    yield return Build(nameType.NameTypeTranslated, unmatchedInprotech.Single(), imported.Single().Mapped, countries);
                    continue;
                }

                foreach (var unmatched in unmatchedInprotech)
                    yield return Build(nameType.NameTypeTranslated, unmatched, null, countries);

                foreach (var unmatched in imported)
                    yield return Build(nameType.NameTypeTranslated, null, unmatched.Mapped, countries);
            }
        }

        Results.CaseName Build(string nameTypeDescription, CaseName caseName, Name mapped,
                               IEnumerable<Country> countries)
        {
            var r = new Results.CaseName
                    {
                        NameType = nameTypeDescription,
                        Name = new Value<string>(),
                        Address = new Value<string>(),
                        Reference = new Value<string>()
                    };

            if (mapped != null)
            {
                r.Name.TheirValue = mapped.FreeFormatName ?? FormattedName.For(mapped.LastName, mapped.FirstName);
                r.Address.TheirValue = BuildSourceAddress(mapped, countries);
                r.Reference.TheirValue = mapped.NameReference;
            }

            if (caseName != null)
            {
                r.NameTypeId = caseName.NameTypeId;
                r.NameId = caseName.NameId;
                r.Sequence = caseName.Sequence;
                r.Name.OurValue = caseName.Name.FormattedNameOrNull();
                r.Address.OurValue =
                    CaseComparison.AddressComparisonAllowed.Contains(caseName.NameTypeId)
                        ? _caseNameAddressResolver.Resolve(caseName).FormattedAddress
                        : string.Empty;
                r.Reference.OurValue = caseName.Reference;
            }

            r.Name.Different = !NamesLookTheSame(caseName, mapped);
            r.Address.Different = r.Name.Different.GetValueOrDefault() || !AddressLookTheSame(r.Address);
            r.Reference.Different = !string.Equals(r.Reference.TheirValue ?? string.Empty, r.Reference.OurValue ?? string.Empty) && !string.IsNullOrWhiteSpace(r.Reference.TheirValue);

            r.Name.Updateable = false;
            r.Address.Updateable = false;
            r.Reference.Updateable = r.NameId.HasValue && (!r.Name.Different ?? false) ? r.Reference.Different : false;

            return r;
        }

        static bool AddressLookTheSame(Value<string> address)
        {
            return string.Equals(
                                 (address.OurValue ?? string.Empty).Trim(),
                                 (address.TheirValue ?? string.Empty).Trim(),
                                 StringComparison.InvariantCultureIgnoreCase
                                );
        }

        static bool NamesLookTheSame(CaseName caseName, Name name)
        {
            if (caseName == null || name == null)
            {
                return false;
            }

            if (string.IsNullOrWhiteSpace(name.FreeFormatName))
            {
                return (caseName.Name.FirstName + " " + caseName.Name.LastName)
                        .TextRelaxedEquals(name.FirstName + " " + name.LastName);
            }

            var firstNameLastName = caseName.Name.FirstName + " " + caseName.Name.LastName;
            var lastNameFirstName = caseName.Name.LastName + ", " + caseName.Name.FirstName;

            var alternateInput = name.FreeFormatName;

            var freeFormat = name.FreeFormatName.Split(',');
            if (freeFormat.Length == 2)
            {
                alternateInput = freeFormat[1] + " " + freeFormat[0];
            }

            return firstNameLastName.TextRelaxedEquals(name.FreeFormatName) ||
                   lastNameFirstName.TextRelaxedEquals(name.FreeFormatName) ||
                   firstNameLastName.TextRelaxedEquals(alternateInput);
        }

        static string BuildSourceAddress(Name name, IEnumerable<Country> countries)
        {
            if (string.IsNullOrEmpty(name.CountryCode))
            {
                return null;
            }

            var country =
                countries.Single(_ => string.Equals(_.Id, name.CountryCode, StringComparison.InvariantCultureIgnoreCase));

            return FormattedAddress.For(
                                        name.Street,
                                        null,
                                        name.City,
                                        null,
                                        name.StateName,
                                        name.Postcode, country.Name,
                                        country.PostCodeFirst.GetValueOrDefault() == 1,
                                        false,
                                        null,
                                        country.AddressStyleId);
        }
    }
}