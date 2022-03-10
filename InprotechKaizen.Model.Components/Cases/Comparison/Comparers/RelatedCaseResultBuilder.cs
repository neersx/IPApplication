using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Components.Integration.DataVerification;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Case = InprotechKaizen.Model.Cases.Case;
using RelatedCase = InprotechKaizen.Model.Components.Cases.Comparison.Models.RelatedCase;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public interface IRelatedCaseResultBuilder
    {
        Results.RelatedCase BuildFor(RelatedCaseDetails relatedCase);

        Results.RelatedCase BuildFor(RelatedCase imported, CaseRelation mappedRelation, RelatedCaseDetails relatedCaseDetails);
        IEnumerable<Results.RelatedCase> Build(Case @case, VerifiedRelatedCase[] imported);
    }

    public class RelatedCaseResultBuilder : IRelatedCaseResultBuilder
    {
        readonly string _culture;
        readonly IDbContext _dbContext;
        readonly IParentRelatedCases _parentRelatedCases;
        readonly IValidEventResolver _validEventResolver;
        Dictionary<string, string> _caseRelationTranslations = new Dictionary<string, string>();
        Dictionary<short, string> _statusTranslations = new Dictionary<short, string>();

        public RelatedCaseResultBuilder(IDbContext dbContext, IValidEventResolver validEventResolver, IPreferredCultureResolver preferredCultureResolver, IParentRelatedCases parentRelatedCases)
        {
            _dbContext = dbContext;
            _validEventResolver = validEventResolver;
            _parentRelatedCases = parentRelatedCases;

            _culture = preferredCultureResolver.Resolve();
        }

        public Results.RelatedCase BuildFor(RelatedCaseDetails relatedCase)
        {
            BuildTranslationTables();

            var result = RelatedCaseExt.Build();

            return SetInprotechData(result, relatedCase);
        }

        public Results.RelatedCase BuildFor(RelatedCase imported, CaseRelation mappedRelation, RelatedCaseDetails relatedCaseDetails)
        {
            BuildTranslationTables();

            var result = RelatedCaseExt.BuildFor(imported, mappedRelation);

            result.Description.TheirValue = _caseRelationTranslations[mappedRelation.Relationship];

            if (relatedCaseDetails != null)
            {
                result = SetInprotechData(result, relatedCaseDetails);
            }

            return result.EvaluateDifferences();
        }

        class ImportMatched
        {
            public VerifiedRelatedCase Imported { get; set; }
            public ParentRelatedCase Inprotech { get; set; }
        }
        public IEnumerable<Results.RelatedCase> Build(Case @case, VerifiedRelatedCase[] imported)
        {
            var jurisdictions = JurisdictionNames(imported);
            var relationships = Relationships(imported);
            var importedMatched = from m in imported
                                  join p in _parentRelatedCases.Resolve(new[] { @case.Id }, relationships.Keys.ToArray()) on
                                      new
                                      {
                                          O = m.InputOfficialNumber,
                                          E = m.InputEventDate,
                                          R = m.RelationshipCode
                                      }
                                      equals new
                                      {
                                          O = p.Number,
                                          E = p.Date,
                                          R = p.Relationship
                                      }
                                      into p1
                                  from p in p1.DefaultIfEmpty()
                                  select new ImportMatched
                                  {
                                      Imported = m,
                                      Inprotech = p
                                  };

            foreach (var m in importedMatched)
            {
                var hideInprotechRelationship = HideInprotechRelationshipCode(m);
                var hideImportRelationship = HideImportedRelationshipCode(m);

                yield return new Results.RelatedCase
                {
                    CountryCode = new Value<string>
                    {
                        OurValue = jurisdictions.Get(m.Inprotech?.CountryCode ?? m.Imported.InputCountryCode),
                        TheirValue = jurisdictions.Get(m.Imported.CountryCode),
                        Different = !m.Imported.CountryCodeVerified
                    },
                    PriorityDate = new Value<DateTime?>
                    {
                        OurValue = m.Imported.InputEventDate,
                        TheirValue = m.Imported.EventDate,
                        Different = !m.Imported.EventDateVerified
                    },
                    RelationshipCode = new Value<string>
                    {
                        OurValue = m.Imported.RelationshipCode,
                        TheirValue = m.Imported.RelationshipCode,
                        Different = false
                    },
                    Description = new Value<string>
                    {
                        OurValue = hideInprotechRelationship ? null : relationships.Get(m.Imported.RelationshipCode),
                        TheirValue = hideImportRelationship ? null : relationships.Get(m.Imported.RelationshipCode)
                    },
                    EventId = new Value<int?>
                    {
                        OurValue = m.Inprotech?.EventId
                    },
                    EventDescription = new Value<string>
                    {
                        OurValue = ResolveEventDescription(m.Inprotech?.RelatedCaseId, m.Inprotech?.EventId)
                    },
                    RelatedCaseId = m.Inprotech?.RelatedCaseId,
                    RelatedCaseRef = m.Inprotech?.RelatedCaseRef,
                    OfficialNumber = new Value<string>
                    {
                        OurValue = m.Imported.InputOfficialNumber,
                        TheirValue = m.Imported.OfficialNumber,
                        Different = !m.Imported.OfficialNumberVerified
                    },
                    RegistrationNumber = new Value<string>()
                };
            }
        }

        static bool HideInprotechRelationshipCode(ImportMatched m)
        {
            var hasAllEmptyStringValues = new[]
            {
                m.Imported.InputOfficialNumber,
                m.Imported.InputCountryCode
            }.All(_ => _.IsNullOrEmpty());

            var hasAllNullDates = new[]
            {
                m.Imported.InputEventDate
            }.All(_ => !_.HasValue);

            var hideInprotechRelationship = hasAllNullDates && hasAllEmptyStringValues;
            return hideInprotechRelationship;
        }
        
        static bool HideImportedRelationshipCode(ImportMatched m)
        {
            var hasAllEmptyStringValues = new[]
            {
                m.Imported.CountryCode,
                m.Imported.OfficialNumber
            }.All(_ => _.IsNullOrEmpty());

            var hasAllNullDates = new[]
            {
                m.Imported.EventDate
            }.All(_ => !_.HasValue);

            var hideInprotechRelationship = hasAllNullDates && hasAllEmptyStringValues;
            return hideInprotechRelationship;
        }

        Results.RelatedCase SetInprotechData(Results.RelatedCase result, RelatedCaseDetails relatedCaseDetails)
        {
            if (relatedCaseDetails.CaseRef != null)
            {
                result.SetInprotechData(relatedCaseDetails.CaseRef, relatedCaseDetails.RelatedCase.Relation);
            }
            else
            {
                result.SetInprotechData(relatedCaseDetails.RelatedCase);
            }

            result.SetMatchedOfficialNumber(relatedCaseDetails.MatchedOfficialNumber);
            result.SetRelationData(relatedCaseDetails.RelatedCase.Relation);

            return SetInprotechTranslatedValues(result, relatedCaseDetails);
        }

        Results.RelatedCase SetInprotechTranslatedValues(Results.RelatedCase result, RelatedCaseDetails relatedCase)
        {
            result.Description.OurValue = _caseRelationTranslations[relatedCase.RelatedCase.Relation.Relationship];

            if (relatedCase.CaseRef == null)
            {
                return result;
            }

            if (relatedCase.CaseRef.CaseStatus != null)
            {
                result.ParentStatus.OurValue = _statusTranslations[relatedCase.CaseRef.CaseStatus.Id];
            }

            if (relatedCase.RelatedCase.Relation.FromEventId == null)
            {
                return result;
            }

            var validEvent = _validEventResolver.Resolve(relatedCase.CaseRef, (int)relatedCase.RelatedCase.Relation.FromEventId);

            if (validEvent != null)
            {
                result.EventDescription.OurValue = validEvent.Description;
            }

            return result;
        }

        void BuildTranslationTables()
        {
            if (!_caseRelationTranslations.Any())
            {
                _caseRelationTranslations = _dbContext.Set<CaseRelation>()
                                                      .ToDictionary(
                                                                    k => k.Relationship,
                                                                    v => DbFuncs.GetTranslation(v.Description, null, v.DescriptionTId, _culture));
            }

            if (!_statusTranslations.Any())
            {
                _statusTranslations = _dbContext.Set<Status>()
                                                .ToDictionary(
                                                              k => k.Id,
                                                              v => DbFuncs.GetTranslation(v.Name, null, v.NameTId, _culture));
            }
        }

        Dictionary<string, string> Relationships(VerifiedRelatedCase[] imported)
        {
            var relationshipNames = imported.Select(_ => _.RelationshipCode).Distinct().ToArray();

            if (!relationshipNames.Any()) return new Dictionary<string, string>();

            return (from c in _dbContext.Set<CaseRelation>()
                    where relationshipNames.Contains(c.Relationship)
                    select new
                    {
                        c.Relationship,
                        Name = DbFuncs.GetTranslation(c.Description, null, c.DescriptionTId, _culture),
                        c.FromEventId,
                        c.DisplayEventId
                    })
                .ToDictionary(k => k.Relationship, v => v.Name);
        }

        Dictionary<string, string> JurisdictionNames(VerifiedRelatedCase[] imported)
        {
            var countryCodes = imported.Select(_ => _.InputCountryCode)
                                       .Union(imported.Select(_ => _.CountryCode))
                                       .Where(_ => !string.IsNullOrWhiteSpace(_))
                                       .Distinct()
                                       .ToArray();

            if (!countryCodes.Any()) return new Dictionary<string, string>();

            return (from c in _dbContext.Set<Country>()
                    where countryCodes.Contains(c.Id)
                    select new
                    {
                        c.Id,
                        Name = DbFuncs.GetTranslation(c.Name, null, c.NameTId, _culture)
                    })
                .ToDictionary(k => k.Id, v => v.Name);
        }

        string ResolveEventDescription(int? caseId, int? eventId)
        {
            if (caseId == null || eventId == null) return string.Empty;

            var ve = _validEventResolver.Resolve(caseId.Value, eventId.Value);

            return _dbContext.Set<ValidEvent>()
                             .Where(_ => _.CriteriaId == ve.CriteriaId && _.EventId == ve.EventId)
                             .Select(_ => DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, _culture))
                             .Single();
        }

    }
}