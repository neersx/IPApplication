using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Persistence;
using Case = InprotechKaizen.Model.Cases.Case;
using RelatedCase = InprotechKaizen.Model.Components.Cases.Comparison.Models.RelatedCase;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class ParentRelatedCasesComparer : ISpecificComparer
    {
        readonly IDbContext _dbContext;
        readonly IRelatedCaseFinder _relatedCaseFinder;
        readonly IRelatedCaseResultBuilder _relatedCaseResultBuilder;

        public ParentRelatedCasesComparer(IDbContext dbContext, IRelatedCaseFinder relatedCaseFinder, IRelatedCaseResultBuilder relatedCaseResultBuilder)
        {
            _dbContext = dbContext;
            _relatedCaseFinder = relatedCaseFinder;
            _relatedCaseResultBuilder = relatedCaseResultBuilder;
        }

        public void Compare(Case @case, IEnumerable<ComparisonScenario> comparisonScenarios, ComparisonResult result)
        {
            if (result == null) throw new ArgumentNullException(nameof(result));

            var relatedCases = comparisonScenarios.OfType<ComparisonScenario<RelatedCase>>()
                                                  .Select(_ => _.Mapped)
                                                  .ToArray();

            if (!relatedCases.Any())
            {
                return;
            }

            result.ParentRelatedCases = Build(@case, relatedCases).OrderBy(_ => _.RelationshipCode.TheirValue ?? _.RelationshipCode.OurValue);
        }

        IEnumerable<Results.RelatedCase> Build(Case @case, RelatedCase[] imported)
        {
            _relatedCaseFinder.PrepareFor(@case);

            var relations = _dbContext.Set<CaseRelation>()
                                      .Include(_ => _.FromEvent)
                                      .ToList();

            var relationsToConsider = new List<CaseRelation>();

            foreach (var m in imported.Where(m => !string.IsNullOrWhiteSpace(m.RelationshipCode)))
            {
                m.CountryCode = m.CountryCode ?? @case.Country.Id;

                var importedRelation = relations.First(_ => _.Relationship == m.RelationshipCode);
                var inprotechRelatedCase = _relatedCaseFinder.FindFor(m);

                yield return _relatedCaseResultBuilder.BuildFor(m, importedRelation, inprotechRelatedCase);

                if (!relationsToConsider.Contains(importedRelation))
                {
                    relationsToConsider.Add(importedRelation);
                }
            }

            foreach (var relatedCase in relationsToConsider.SelectMany(r => _relatedCaseFinder.FindFor(r)))
                yield return _relatedCaseResultBuilder.BuildFor(relatedCase);
        }
    }
}