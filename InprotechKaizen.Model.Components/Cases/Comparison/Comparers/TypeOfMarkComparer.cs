using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using Case = InprotechKaizen.Model.Cases.Case;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class TypeOfMarkComparer : ISpecificComparer
    {
        readonly IDbContext _dbContext;
        readonly string _culture;

        public TypeOfMarkComparer(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _culture = preferredCultureResolver.Resolve();
        }

        public void Compare(Case @case, IEnumerable<ComparisonScenario> comparisonScenarios, ComparisonResult result)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (comparisonScenarios == null) throw new ArgumentNullException(nameof(comparisonScenarios));
            if (result == null) throw new ArgumentNullException(nameof(result));

            var scenarios = comparisonScenarios.OfType<ComparisonScenario<TypeOfMark>>().ToArray();

            if (!scenarios.Any())
                return;

            var typeOfMark = scenarios.Single().Mapped;

            var inprotechTypeOfMark = _dbContext.Set<Case>()
                                                .Where(_ => _.Id == @case.Id)
                                                .Select(_ => new
                                                {
                                                    Description = DbFuncs.GetTranslation(_.TypeOfMark.Name, null, _.TypeOfMark.NameTId, _culture)
                                                }).FirstOrDefault();

            var innographyTypeOfMark = _dbContext.Set<TableCode>()
                                                 .Where(_ => _.TableTypeId == (int) TableTypes.TypeOfMark && _.Id == typeOfMark.Id)
                                                 .Select(_ => new
                                                 {
                                                     Description = DbFuncs.GetTranslation(_.Name, null, _.NameTId, _culture)
                                                 }).FirstOrDefault();

            var typeOfMarkResult = new Value<string>
            {
                OurValue = inprotechTypeOfMark?.Description,
                TheirValue = typeOfMark.Id.ToString(),
                TheirDescription = typeOfMark.Description,
                Different = IsDifferent(inprotechTypeOfMark?.Description, innographyTypeOfMark?.Description),
                Updateable = IsDifferent(inprotechTypeOfMark?.Description, innographyTypeOfMark?.Description)
                             && !string.IsNullOrWhiteSpace(typeOfMark.Description)
            };

            if (result.Case == null)
            {
                result.Case = new Results.Case
                {
                    TypeOfMark = typeOfMarkResult
                }; 
            }
            else
            {
                result.Case.TypeOfMark = typeOfMarkResult;
            }
        }

        static bool IsDifferent(string a, string b)
        {
            return !string.Equals(a, b, StringComparison.InvariantCultureIgnoreCase);
        }
    }
}
