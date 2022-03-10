using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Integration.DataVerification;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Innography
{
    public class ParentRelatedCases : IParentRelatedCases
    {
        readonly IDbContext _dbContext;

        public ParentRelatedCases(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<ParentRelatedCase> Resolve(int[] caseIds, string[] relationshipCodes)
        {
            var interim = (from rc in _dbContext.Set<RelatedCase>()
                           join cr in _dbContext.Set<CaseRelation>() on rc.Relationship equals cr.Relationship into cr1
                           from cr in cr1
                           join c in _dbContext.Set<InprotechKaizen.Model.Cases.Case>() on new {a = rc.RelatedCaseId} equals new {a = (int?) c.Id} into c1
                           from c in c1.DefaultIfEmpty()
                           join ce in _dbContext.Set<CaseEvent>() on
                               new {e = cr.DisplayEventId == null ? cr.FromEventId : cr.DisplayEventId, c = rc.RelatedCaseId, cy = (short) 1} equals
                               new {e = (int?) ce.EventNo, c = (int?) ce.CaseId, cy = ce.Cycle} into ce1
                           from ce in ce1.DefaultIfEmpty()
                           join o in _dbContext.Set<OfficialNumber>() on
                               new {CaseId = rc.RelatedCaseId, IsCurrent = (decimal?) 1, NumberTypeId = KnownNumberTypes.Application} equals
                               new {CaseId = (int?) o.CaseId, o.IsCurrent, o.NumberTypeId} into o1
                           from o in o1.DefaultIfEmpty()
                           where relationshipCodes.Contains(rc.Relationship) && caseIds.Contains(rc.CaseId)
                           select new ParentRelatedCase
                           {
                               Relationship = rc.Relationship,
                               RelatedCaseId = rc.RelatedCaseId,
                               RelatedCaseRef = c != null ? c.Irn : null,
                               RelationId = rc.RelationshipNo,
                               CaseKey = rc.CaseId,
                               CountryCode = c != null ? c.CountryId : rc.CountryCode,
                               Number = o != null ? o.Number : c != null ? c.CurrentOfficialNumber : rc.OfficialNumber,
                               Date = ce != null && ce.EventDate != null ? ce.EventDate : rc.PriorityDate,
                               EventId = ce != null && ce.EventDate != null ? (int?) ce.EventNo : null
                           })
                .ToArray();

            var earliest = from e in from i in interim
                                     group i by new {CaseId = i.CaseKey, i.Relationship}
                                     into g1
                                     select g1.OrderBy(x => x.Date ?? DateTime.MaxValue).FirstOrDefault()
                           select e;

            return from e in earliest
                   select new ParentRelatedCase
                   {
                       CaseKey = e.CaseKey,
                       CountryCode = e.CountryCode,
                       Date = e.Date,
                       Number = e.Number,
                       Relationship = e.Relationship,
                       RelatedCaseId = e.RelatedCaseId,
                       RelatedCaseRef = e.RelatedCaseRef,
                       RelationId = e.RelationId,
                       EventId = e.EventId
                   };
        }
    }
}