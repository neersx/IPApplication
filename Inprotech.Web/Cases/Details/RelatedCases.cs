using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.ValidCombinations;
using Newtonsoft.Json;
using KnownValues = InprotechKaizen.Model.KnownValues;

namespace Inprotech.Web.Cases.Details
{
    public interface IRelatedCases
    {
        Task<IQueryable<RelatedCase>> Retrieve(int caseKey);
    }

    public class RelatedCases : IRelatedCases
    {
        readonly ICaseAuthorization _caseAuthorization;
        readonly IDbContext _dbContext;

        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public RelatedCases(ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, IDbContext dbContext, ICaseAuthorization caseAuthorization)
        {
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _dbContext = dbContext;
            _caseAuthorization = caseAuthorization;
        }

        public async Task<IQueryable<RelatedCase>> Retrieve(int caseKey)
        {
            var user = _securityContext.User;
            var isExternalUser = user.IsExternalUser;
            var culture = _preferredCultureResolver.Resolve();

            var relatedCases = _dbContext.Set<InprotechKaizen.Model.Cases.RelatedCase>().Where(r => r.CaseId == caseKey);

            if (!isExternalUser)
            {
                var accessibleCases = (from ap in await _caseAuthorization.AccessibleCases(await (from rc in relatedCases
                                                                                                  where rc.RelatedCaseId != null
                                                                                                  select (int) rc.RelatedCaseId
                                                                                           ).ToArrayAsync())
                                       select ap).ToArray();

                relatedCases = from rc in relatedCases
                               where rc.RelatedCaseId == null || rc.RelatedCaseId != null && accessibleCases.Contains((int) rc.RelatedCaseId)
                               select rc;
            }
            
            var officialNumber = from o in _dbContext.Set<OfficialNumber>()
                                 join sc in _dbContext.Set<SiteControl>() on SiteControls.EarliestPriority equals sc.ControlId into sc1
                                 from sc in sc1.DefaultIfEmpty()
                                 where o.NumberTypeId == KnownNumberTypes.Application && o.IsCurrent == 1
                                 select new
                                 {
                                     o.CaseId,
                                     o.Number,
                                     EarliestPriority = sc != null ? sc.StringValue : null
                                 };

            var sortByDate = await _dbContext.Set<SiteControl>()
                                             .SingleOrDefaultAsync(_ => _.ControlId == SiteControls.RelatedCasesSortOrder && _.StringValue == "DATE");

            var result = (from rc in relatedCases
                          join cr in _dbContext.Set<CaseRelation>() on rc.Relationship equals cr.Relationship
                          join c1 in _dbContext.Set<Case>() on rc.CaseId equals c1.Id
                          join c2 in _dbContext.Set<Case>() on rc.RelatedCaseId equals c2.Id into c2j
                          from c2 in c2j.DefaultIfEmpty()
                          join cntr in _dbContext.Set<Country>() on new {CountryCode = c2 == null ? rc.CountryCode : c2.Country.Id} equals new {CountryCode = cntr.Id} into cntr1
                          from cntr in cntr1.DefaultIfEmpty()
                          join ce in _dbContext.Set<CaseEvent>()
                          on new {EventNo = cr.DisplayEventId == null ? cr.FromEventId : cr.DisplayEventId, Cycle = 1, CaseId = rc.RelatedCaseId}
                          equals new {EventNo = (int?) ce.EventNo, Cycle = (int) ce.Cycle, CaseId = (int?) ce.CaseId} into ce1
                          from ce in ce1.DefaultIfEmpty()
                          join e in _dbContext.Set<Event>() on new {EventNo = cr.DisplayEventId == null ? cr.FromEventId : cr.DisplayEventId} equals new {EventNo = (int?) e.Id} into e1
                          from e in e1.DefaultIfEmpty()
                          join oa in _dbContext.Set<OpenAction>() on new {CaseId = ce != null ? (int?) ce.CaseId : null, ActionId = e.ControllingAction} equals new {CaseId = (int?) oa.CaseId, oa.ActionId} into oa1
                          from oa in oa1.DefaultIfEmpty()
                          join ec in _dbContext.Set<ValidEvent>()
                          on new {CriteriaId = oa == null ? null : oa.CriteriaId, EventId = ce == null ? null : (int?) ce.EventNo}
                          equals new {CriteriaId = (int?) ec.CriteriaId, EventId = (int?) ec.EventId} into ec1
                          from ec in ec1.DefaultIfEmpty()
                          join o in officialNumber on new {CaseId = rc.RelatedCaseId, rc.Relationship} equals new {CaseId = (int?) o.CaseId, Relationship = o.EarliestPriority} into o1
                          from o in o1.DefaultIfEmpty()
                          join fc in _dbContext.FilterUserCases(user.Id, true, null) on new {CaseId = c2 != null ? (int?) c2.Id : null, IsExternal = isExternalUser} equals new {CaseId = (int?) fc.CaseId, IsExternal = true} into fc1
                          from fc in fc1.DefaultIfEmpty()
                          /* for determining pointer to child */
                          join vrZzz in _dbContext.Set<ValidRelationship>()
                            on new {RelationshipCode = cr.Relationship, PropertyType = c2 != null ? c2.PropertyType.Code : c1.PropertyType.Code, CountryCode = KnownValues.DefaultCountryCode}
                            equals new {vrZzz.RelationshipCode, PropertyType = vrZzz.PropertyTypeId, CountryCode = vrZzz.CountryId} into vrZzz1
                          from vrZzz in vrZzz1.DefaultIfEmpty()
                          join vr in _dbContext.Set<ValidRelationship>() 
                            on new {RelationshipCode = cr.Relationship, PropertyType = c2 != null ? c2.PropertyType.Code : c1.PropertyType.Code, CountryCode = cntr != null ? cntr.Id : null}
                            equals new {vr.RelationshipCode, PropertyType = vr.PropertyTypeId, CountryCode = vr.CountryId} into vr1
                          from vr in vr1.DefaultIfEmpty()
                          join crReciprocal in _dbContext.Set<CaseRelation>() 
                            on new {r = vr != null ? vr.ReciprocalRelationshipCode : (vrZzz != null ? vrZzz.ReciprocalRelationshipCode : null), _ = (int?)1}
                            equals new {r = crReciprocal.Relationship, _ = (int?)crReciprocal.PointsToParent } into crReciprocal1
                          from crReciprocal in crReciprocal1.DefaultIfEmpty()
                          /* end for determining pointer to child */
                          where cr.ShowFlag == 1 && (isExternalUser && fc != null || c2 == null || !isExternalUser)
                          select new RelatedCase
                          {
                              CaseId = rc.RelatedCaseId,
                              OfficialNumber = o == null ? (c2 == null || c2.CurrentOfficialNumber == null ? rc.OfficialNumber : c2.CurrentOfficialNumber) : o.Number,
                              InternalReference = c2 == null ? null : c2.Irn,
                              ClientReference = fc == null ? null : fc.ClientReferenceNo,
                              CountryCode = cntr == null ? null : cntr.Id,
                              Jurisdiction = cntr == null ? null : DbFuncs.GetTranslation(cntr.Name, null, cntr.NameTId, culture),
                              Title = rc.RelatedCaseId == null ? rc.Title : DbFuncs.GetTranslation(c2.Title, null, c2.TitleTId, culture),
                              Classes = c2 == null ? rc.Class : c2.LocalClasses,
                              Status = c2 == null || c2.CaseStatus == null
                                  ? null
                                  : DbFuncs.GetTranslation(
                                                           isExternalUser
                                                               ? c2.CaseStatus.ExternalName
                                                               : c2.CaseStatus.Name, null,
                                                           isExternalUser
                                                               ? c2.CaseStatus.ExternalNameTId
                                                               : c2.CaseStatus.NameTId, culture),
                              Relationship = DbFuncs.GetTranslation(cr.Description, null, cr.DescriptionTId, culture),
                              RelationshipNo = rc.RelationshipNo,
                              SpecificEvent = ec == null ? null : DbFuncs.GetTranslation(ec.Description, null, ec.DescriptionTId, culture),
                              BaseEvent = e == null ? null : DbFuncs.GetTranslation(e.Description, null, e.DescriptionTId, culture),
                              EventDefinition = e == null ? null : DbFuncs.GetTranslation(e.Notes, null, e.NotesTId, culture),
                              EventDate = ce == null || ce.EventDate == null ? rc.PriorityDate : ce.EventDate,
                              Cycle = rc.Cycle,
                              IsPointingToParent = cr.PointsToParent == 1,
                              IsPointingToChild = crReciprocal != null
                          }).Distinct();

            return (sortByDate == null
                    ? from rc in result orderby rc.RelationshipNo select rc
                    : from rc in result
                      orderby rc.EventDate, rc.Relationship, rc.InternalReference, rc.OfficialNumber
                      select rc)
                .AsQueryable();
        }
    }

    public class RelatedCase : IFileCaseViewable
    {
        [JsonIgnore]
        public bool IsPointingToParent { get; set; }

        [JsonIgnore]
        public bool IsPointingToChild { get; set; }

        public string Direction
        {
            get
            {
                if (IsPointingToParent)
                {
                    return "up";
                }

                if (IsPointingToChild)
                {
                    return "down";
                }

                return null;
            }
        }

        public int? CaseId { get; set; }

        public string InternalReference { get; set; }

        public string ClientReference { get; set; }

        public string Title { get; set; }

        public string Classes { get; set; }

        public string Relationship { get; set; }

        [JsonIgnore]
        public int RelationshipNo { get; set; }

        public string CountryCode { get; set; }

        public string Jurisdiction { get; set; }

        public string OfficialNumber { get; set; }

        public short? Cycle { get; set; }

        [JsonIgnore]
        public string SpecificEvent { get; set; }

        [JsonIgnore]
        public string BaseEvent { get; set; }

        public string EventDescription => SpecificEvent ?? BaseEvent;

        public string EventDefinition { get; set; }

        public DateTime? EventDate { get; set; }

        public string Status { get; set; }

        public Uri ExternalInfoLink { get; set; }

        public bool IsFiled { get; set; }

        public bool CanViewInFile { get; set; }
    }
}