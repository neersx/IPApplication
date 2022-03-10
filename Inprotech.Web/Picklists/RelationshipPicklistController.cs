using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/relationship")]
    public class RelationshipPicklistController : ApiController
    {
        readonly CommonQueryParameters _queryParameters;
        private readonly IDbContext _dbContext;
        readonly IRelationshipPicklistMaintenance _relationshipPicklistMaintenance;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public RelationshipPicklistController(IDbContext dbContext, IRelationshipPicklistMaintenance relationshipPicklistMaintenance, IPreferredCultureResolver preferredCultureResolver)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            if (relationshipPicklistMaintenance == null) throw new ArgumentNullException(nameof(relationshipPicklistMaintenance));
            if (preferredCultureResolver == null) throw new ArgumentNullException(nameof(preferredCultureResolver));

            _dbContext = dbContext;
            _relationshipPicklistMaintenance = relationshipPicklistMaintenance;
            _preferredCultureResolver = preferredCultureResolver;
            _queryParameters = new CommonQueryParameters { SortBy = "Value" };
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(Relationship), ApplicationTask.MaintainValidCombinations)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route("{relationshipId}")]
        [PicklistPayload(typeof(Relationship), ApplicationTask.MaintainValidCombinations)]
        public Relationship Relationship(string relationshipId)
        {
            return Interimresult().Single(_ => _.Code == relationshipId);
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(Relationship), ApplicationTask.MaintainValidCombinations)]
        public PagedResults Relationships(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            return Helpers.GetPagedResults(MatchingItems(search),
                                           extendedQueryParams,
                                           x => x.Code, x => x.Value, search);
        }

        IEnumerable<Relationship> MatchingItems(string search = "")
        {
            var result = Interimresult(true).AsEnumerable();

            if (!string.IsNullOrEmpty(search))
            {
                result = result.Where(_ => _.Code.Equals(search, StringComparison.InvariantCultureIgnoreCase) ||
                                           _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            return result;
        }

        private IQueryable<Relationship> Interimresult(bool translateDescription = false)
        {
            var culture = _preferredCultureResolver.Resolve();
            var interimresult =
                _dbContext.Set<CaseRelation>().Select(_ => new Relationship
                {
                    Code = _.Relationship,
                    Value = translateDescription ? DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture) : _.Description,
                    Notes = _.Notes,
                    EarliestDateFlag = _.EarliestDateFlag == 1m,
                    ShowFlag = _.ShowFlag == 1m,
                    PriorArtFlag = _.PriorArtFlag.HasValue && _.PriorArtFlag.Value,
                    PointsToParent = _.PointsToParent == 1m,
                    FromEvent = _.FromEvent != null ? new Event
                    {
                        Key = _.FromEvent.Id,
                        Code = _.FromEvent.Code,
                        Value = DbFuncs.GetTranslation(_.FromEvent.Description, null, _.FromEvent.DescriptionTId, culture)
                    }
                    : null,
                    ToEvent = _.ToEvent != null ? new Event
                    {
                        Key = _.ToEvent.Id,
                        Code = _.ToEvent.Code,
                        Value = DbFuncs.GetTranslation(_.ToEvent.Description, null, _.ToEvent.DescriptionTId, culture)
                    }
                    : null,
                    DisplayEvent = _.DisplayEvent != null ? new Event
                    {
                        Key = _.DisplayEvent.Id,
                        Code = _.DisplayEvent.Code,
                        Value = DbFuncs.GetTranslation(_.DisplayEvent.Description, null, _.DisplayEvent.DescriptionTId, culture)
                    }
                    : null
                });
            return interimresult;
        }

        [HttpPut]
        [Route("{relationshipId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(string relationshipId, Relationship relationship)
        {
            if (relationship == null) throw new ArgumentNullException(nameof(relationship));

            return _relationshipPicklistMaintenance.Save(relationship, Operation.Update);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic AddOrDuplicate(Relationship relationship)
        {
            if (relationship == null) throw new ArgumentNullException(nameof(relationship));

            return _relationshipPicklistMaintenance.Save(relationship, Operation.Add);
        }

        [HttpDelete]
        [Route("{relationshipId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(string relationshipId)
        {
            return _relationshipPicklistMaintenance.Delete(relationshipId);
        }
    }

    public class Relationship
    {
        public Relationship() { }

        public Relationship(string code, string description)
        {
            Code = code;
            Value = description;
        }
        [PicklistKey]
        public string Key => Code;

        [Required]
        [DisplayName(@"Code")]
        [PicklistCode]
        [MaxLength(3)]
        [PicklistColumn]
        [DisplayOrder(1)]
        public string Code { get; set; }

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        [PicklistColumn]
        [DisplayOrder(0)]
        public string Value { get; set; }

        public bool EarliestDateFlag { get; set; }

        public bool PointsToParent { get; set; }

        public bool ShowFlag { get; set; }

        public bool PriorArtFlag { get; set; }

        public string Notes { get; set; }

        public Event ToEvent { get; set; }

        public Event FromEvent { get; set; }

        public Event DisplayEvent { get; set; }
    }
}
