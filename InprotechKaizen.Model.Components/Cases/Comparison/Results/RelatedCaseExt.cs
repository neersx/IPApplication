using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.System.Utilities;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    public static class RelatedCaseExt
    {
        public static RelatedCase Build()
        {
            return new RelatedCase
                   {
                       CountryCode = new Value<string>(),

                       ParentStatus = new Value<string>(),

                       PriorityDate = new Value<DateTime?>(),

                       RelationshipCode = new Value<string>(),

                       Description = new Value<string>(),

                       EventId = new Value<int?>(),

                       EventDescription = new Value<string>(),

                       OfficialNumber = new Value<string>(),

                       RegistrationNumber = new Value<string>()
                   };
        }

        public static RelatedCase BuildFor(Components.Cases.Comparison.Models.RelatedCase imported, CaseRelation relation)
        {
            if (imported == null) throw new ArgumentNullException(nameof(imported));

            return new RelatedCase
                   {
                       CountryCode = new Value<string>
                                     {
                                         TheirValue = imported.CountryCode
                                     },

                       ParentStatus = new Value<string>
                                      {
                                          TheirValue = imported.Status
                                      },

                       PriorityDate = new Value<DateTime?>
                                      {
                                          TheirValue = imported.EventDate
                                      },

                       RelationshipCode = new Value<string>
                                          {
                                              TheirValue = relation?.Relationship
                                          },

                       Description = new Value<string>
                                     {
                                         TheirValue = relation?.Description
                                     },

                       EventId = new Value<int?>
                                 {
                                     TheirValue = relation?.FromEventId
                                 },

                       EventDescription = new Value<string>
                                          {
                                              TheirValue = relation?.FromEvent?.Description
                                          },

                       OfficialNumber = new Value<string>
                                        {
                                            TheirValue = imported.OfficialNumber
                                        },
                       RegistrationNumber = new Value<string>
                                            {
                                                TheirValue = imported.RegistrationNumber
                                            }
                   };
        }

        public static RelatedCase SetInprotechData(this RelatedCase thisRelatedCase, Model.Cases.Case relatedCase, CaseRelation relation)
        {
            if (thisRelatedCase == null) throw new ArgumentNullException(nameof(thisRelatedCase));
            if (relatedCase == null) throw new ArgumentNullException(nameof(relatedCase));
            if (relation == null) throw new ArgumentNullException(nameof(relation));

            thisRelatedCase.CountryCode.OurValue = relatedCase.Country.Id;
            thisRelatedCase.RelatedCaseRef = relatedCase.Irn;
            thisRelatedCase.RelatedCaseId = relatedCase.Id;

            if (relation.FromEventId != null)
            {
                thisRelatedCase.PriorityDate.OurValue = relatedCase.CaseEvents.Where(_ => _.EventNo == relation.FromEventId)
                                                                   .Select(_ => _.EventDate)
                                                                   .OrderByDescending(e => e)
                                                                   .FirstOrDefault();
            }

            thisRelatedCase.ParentStatus.OurValue = relatedCase.CaseStatus?.Name;

            thisRelatedCase.OfficialNumber.OurValue = relatedCase.CurrentOfficialNumber;

            return thisRelatedCase;
        }

        public static RelatedCase SetInprotechData(this RelatedCase thisRelatedCase, Model.Cases.RelatedCase relatedCase)
        {
            if (thisRelatedCase == null) throw new ArgumentNullException(nameof(thisRelatedCase));
            if (relatedCase == null) throw new ArgumentNullException(nameof(relatedCase));

            thisRelatedCase.RelatedCaseRef = null;

            thisRelatedCase.CountryCode.OurValue = relatedCase.CountryCode;

            thisRelatedCase.OfficialNumber.OurValue = relatedCase.OfficialNumber;

            thisRelatedCase.PriorityDate.OurValue = relatedCase.PriorityDate;

            return thisRelatedCase;
        }

        public static RelatedCase SetRelationData(this RelatedCase relatedCase, CaseRelation relation)
        {
            if (relatedCase == null) throw new ArgumentNullException(nameof(relatedCase));
            if (relation == null)
            {
                return relatedCase;
            }

            relatedCase.RelationshipCode.OurValue = relation.Relationship;
            relatedCase.Description.OurValue = relation.Description;
            relatedCase.EventId.OurValue = relation.FromEventId;
            relatedCase.EventDescription.OurValue = relation.FromEvent?.Description;

            return relatedCase;
        }

        public static RelatedCase SetMatchedOfficialNumber(this RelatedCase relatedCase, Value<string> matchedOfficialNumbers)
        {
            if (matchedOfficialNumbers == null)
            {
                return relatedCase;
            }

            if (relatedCase == null) throw new ArgumentNullException(nameof(relatedCase));

            relatedCase.OfficialNumber = matchedOfficialNumbers;
            relatedCase.RegistrationNumber.TheirValue = null;

            return relatedCase;
        }

        public static RelatedCase EvaluateDifferences(this RelatedCase relatedCase)
        {
            if (relatedCase == null) throw new ArgumentNullException(nameof(relatedCase));

            relatedCase.RelationshipCode.Different = !Helper.AreStringsEqual(relatedCase.RelationshipCode.OurValue, relatedCase.RelationshipCode.TheirValue);

            relatedCase.Description.Different = !Helper.AreStringsEqual(relatedCase.Description.OurValue, relatedCase.Description.TheirValue);

            relatedCase.ParentStatus.Different = !Helper.AreStringsEqual(relatedCase.ParentStatus.OurValue, relatedCase.ParentStatus.TheirValue);

            if (relatedCase.PriorityDate.TheirValue.HasValue && Nullable.Compare(relatedCase.PriorityDate.OurValue, relatedCase.PriorityDate.TheirValue) != 0)
            {
                relatedCase.PriorityDate.Different = true;
            }
            else
            {
                relatedCase.PriorityDate.Different = false;
            }

            return relatedCase;
        }
    }
}