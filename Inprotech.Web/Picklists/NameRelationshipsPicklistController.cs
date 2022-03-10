using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    public class NameRelationshipsPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _defaultQueryParameters;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public NameRelationshipsPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;

            _defaultQueryParameters = CommonQueryParameters.Default.Extend(new CommonQueryParameters { SortBy = "RelationDescription" });
        }

        [HttpGet]
        [Route("api/configuration/nameRelationships")]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "")
        {
            var culture = _preferredCultureResolver.Resolve();

            var extendedQueryParams = _defaultQueryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            search = !string.IsNullOrEmpty(search) ? search.ToLower() : null;
            var nameRelationships = _dbContext.Set<NameRelation>().Select(_ => new
                                                                          {
                                                                              _.Id,
                                                                              _.RelationshipCode,
                                                                              RelationDescription = DbFuncs.GetTranslation(_.RelationDescription, null, _.RelationDescriptionTId, culture),
                                                                              ReverseDescription = DbFuncs.GetTranslation(_.ReverseDescription, null, _.ReverseDescriptionTId, culture)
                                                                          }).AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
                nameRelationships = nameRelationships.Where(_ => _.RelationDescription.ToLower().Contains(search) || _.ReverseDescription.ToLower().Contains(search) || _.RelationshipCode.ToLower().Contains(search));

            var nameRelationshipModels = nameRelationships.ToArray().Select(_ => new NameRelationshipModel(_.RelationshipCode, _.RelationDescription, _.ReverseDescription, search));

            if (!string.IsNullOrEmpty(search))
                nameRelationshipModels = nameRelationshipModels.Where(_ => _.RelationDescription.StartsWith(search, StringComparison.InvariantCultureIgnoreCase) || _.ReverseDescription.StartsWith(search, StringComparison.InvariantCultureIgnoreCase));

            return Helpers.GetPagedResults(nameRelationshipModels,
                                           extendedQueryParams,
                                           x => x.Code, x => x.RelationDescription, search);
        }

    }

    public class NameRelationshipModel
    {
        public NameRelationshipModel() { }
        public NameRelationshipModel(string id, string relationDescription, string reverseDescription,string remarks, string search = null)
        {
            Value = relationDescription;
            Code = id;
            Key = id;
            RelationDescription = relationDescription;
            ReverseDescription = reverseDescription;
            Remarks = remarks;
        }

        public string Code { get; set; }

        public string Key { get; set; }

        public string Value { get; set; }

        public string RelationDescription { get; set; }

        public string ReverseDescription { get; set; }

        public string Remarks { get; set; }
    }
}
