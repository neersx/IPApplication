using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Persistence;
using Case = InprotechKaizen.Model.Cases.Case;
using RelatedCase = InprotechKaizen.Model.Cases.RelatedCase;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public interface IRelatedCaseFinder
    {
        void PrepareFor(Case @case);

        RelatedCaseDetails FindFor(Models.RelatedCase imported);

        IEnumerable<RelatedCaseDetails> FindFor(CaseRelation relation);
    }

    public class RelatedCaseFinder : IRelatedCaseFinder
    {
        List<Case> _relatedCases;
        Case _case;

        readonly IDbContext _dbContext;

        public RelatedCaseFinder(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _dbContext = dbContext;
        }

        public void PrepareFor(Case @case)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            _case = @case;

            var caseIds = @case.RelatedCases.Select(rc => rc.RelatedCaseId);

            _relatedCases = _dbContext.Set<Case>()
                                      .Where(_ => caseIds.Contains(_.Id))
                                      .Include(_ => _.Country)
                                      .Include(_ => _.OfficialNumbers)
                                      .Include(_ => _.OfficialNumbers.Select(o => o.NumberType))
                                      .ToList();
        }

        public RelatedCaseDetails FindFor(Models.RelatedCase imported)
        {
            // Same relationship
            var result = FindForCondition(imported, ConditionEqual);

            //Different relationship
            return result ?? FindForCondition(imported, ConditionUnequal);
        }

        public IEnumerable<RelatedCaseDetails> FindFor(CaseRelation relation)
        {
            return _case.RelatedCases
                         .Where(_ => ConditionEqual(_, relation.Relationship))
                         .Select(relatedCase =>
                                 new RelatedCaseDetails(relatedCase, _relatedCases.FirstOrDefault(_ => _.Id == relatedCase.RelatedCaseId), null));
        }

        static bool ConditionEqual(RelatedCase relatedCase, string relationshipCode)
        {
            return Helper.AreStringsEqual(relatedCase.Relation.Relationship, relationshipCode);
        }

        static bool ConditionUnequal(RelatedCase relatedCase, string relationshipCode)
        {
            return !Helper.AreStringsEqual(relatedCase.Relation.Relationship, relationshipCode);
        }

        RelatedCaseDetails FindForCondition(Models.RelatedCase imported, Func<RelatedCase, string, bool> condition)
        {
            var relatedMatchedCases = _case.RelatedCases
                                           .Where(_ => condition(_, imported.RelationshipCode))
                                           .ToList();

            var result = relatedMatchedCases.Any() ? GetRelatedCase(relatedMatchedCases, imported) : null;

            return result;
        }

        RelatedCaseDetails GetRelatedCase(List<RelatedCase> relatedCases, Models.RelatedCase imported)
        {
            var importedNo = string.Empty;
            var inprotechNo = string.Empty;

            var ids = relatedCases.Select(_ => _.RelatedCaseId);

            //Internal Related Case - Same country, similar official number issued by IP Office
            var @relatedCaseMatch = _relatedCases
                                                .Where(_ => ids.Contains(_.Id))
                                                .FirstOrDefault(_ =>
                                                    _.Country.Id == imported.CountryCode &&
                                                    _.CurrentNumbersIssuedByIpOffices().Any(
                                                       o => (Similar(inprotechNo = o.Number, importedNo = imported.OfficialNumber) ||
                                                             Similar(inprotechNo = o.Number, importedNo = imported.RegistrationNumber))));

            if (@relatedCaseMatch != null)
            {
                _relatedCases.Remove(@relatedCaseMatch);
                var corrRelatedCase = GetCaseRelation(@relatedCaseMatch.Id);
                _case.RelatedCases.Remove(corrRelatedCase);

                return new RelatedCaseDetails(corrRelatedCase, @relatedCaseMatch, new Value<string> { OurValue = inprotechNo, TheirValue = importedNo });
            }

            //External related case - Same country, similar official number
            var @relatedEntityMatch = relatedCases.FirstOrDefault(
                                                        _ => _.RelatedCaseId == null && _.CountryCode == imported.CountryCode
                                                             && (Similar(_.OfficialNumber, importedNo = imported.OfficialNumber) ||
                                                             Similar(_.OfficialNumber, importedNo = imported.RegistrationNumber)));

            if (@relatedEntityMatch != null)
            {
                _case.RelatedCases.Remove(@relatedEntityMatch);
                return new RelatedCaseDetails(@relatedEntityMatch, null, new Value<string> { OurValue = @relatedEntityMatch.OfficialNumber, TheirValue = importedNo });
            }
            return null;
        }

        static bool Similar(string ourValue, string theirValue)
        {
            var ourValueNoOnly = Helper.StripNonNumerics(ourValue);
            var theirValueNoOnly = Helper.StripNonNumerics(theirValue);
            if (string.IsNullOrWhiteSpace(ourValueNoOnly) && string.IsNullOrWhiteSpace(theirValueNoOnly))
                return false;
            return string.Equals(ourValueNoOnly, theirValueNoOnly);
        }

        RelatedCase GetCaseRelation(int relatedCaseId)
        {
            return _case.RelatedCases.FirstOrDefault(_ => _.RelatedCaseId == relatedCaseId);
        }
    }

    public class RelatedCaseDetails
    {
        public RelatedCaseDetails(RelatedCase relatedCase, Case caseRef, Value<string> matchedOfficialNumber)
        {
            RelatedCase = relatedCase;
            CaseRef = caseRef;
            MatchedOfficialNumber = matchedOfficialNumber;
        }
        public RelatedCase RelatedCase { get; set; }

        public Case CaseRef { get; set; }

        public Value<string> MatchedOfficialNumber { get; set; }
    }
}