using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
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
    [RoutePrefix("api/picklists/nameTypeGroup")]
    public class NameTypeGroupsPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly INameTypeGroupsPicklistMaintenance _nameTypeGroupsPicklistMaintenance;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly CommonQueryParameters _queryParameters;

        public NameTypeGroupsPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, INameTypeGroupsPicklistMaintenance nameTypeGroupsPicklistMaintenance)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _nameTypeGroupsPicklistMaintenance = nameTypeGroupsPicklistMaintenance ?? throw new ArgumentNullException(nameof(nameTypeGroupsPicklistMaintenance));
            _queryParameters = new CommonQueryParameters
            {
                SortBy = "Value",
                SortDir = "asc"
            };
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(NameTypeGroup), ApplicationTask.MaintainNameTypes)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        public PagedResults Get([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var culture = _preferredCultureResolver.Resolve();

            var query = from ng in _dbContext.Set<NameGroup>()
                        select new NameTypeGroup
                        {
                            Value = DbFuncs.GetTranslation(ng.Value, null, ng.NameTId, culture),
                            Key = ng.Id,
                            Members = ng.Members.Select(_ => DbFuncs.GetTranslation(_.NameType.Name, null, _.NameType.NameTId, culture)),
                            NameType = ng.Members.Select(_ => new NameTypeModel
                            {
                                Key = _.NameType.Id,
                                Code = _.NameType.NameTypeCode,
                                Value = _.NameType.Name
                            }).ToList()
                        };

            if (!string.IsNullOrWhiteSpace(search))
                query = query.Where(_ => _.Value.Contains(search));

            var result = Helpers.GetPagedResults(query, extendedQueryParams, null, x => x.Value, search);

            result.Ids = query.OrderByProperty(extendedQueryParams.SortBy, extendedQueryParams.SortDir).Select(_ => _.Key);

            return result;
        }

        [HttpPost]
        [Route]
        public dynamic Add(NameTypeGroup nameTypeGroup)
        {
            if (nameTypeGroup == null) throw new ArgumentNullException(nameof(nameTypeGroup));

            return _nameTypeGroupsPicklistMaintenance.Save(nameTypeGroup, Operation.Add);
        }

        [HttpGet]
        [Route("{id}")]
        [PicklistPayload(typeof(NameTypeGroup), ApplicationTask.MaintainNameTypes)]
        public dynamic NameTypeGroup(short id)
        {
            var results = from ngt in _dbContext.Set<NameGroup>()
                          where ngt.Id == id
                          select new NameTypeGroup
                          {
                              Value = ngt.Value,
                              Key = ngt.Id,
                              NameType = ngt.Members.Select(_ => new NameTypeModel
                              {
                                  Key = _.NameType.Id,
                                  Code = _.NameType.NameTypeCode,
                                  Value = _.NameType.Name
                              }).ToList()
                          };

            return results.FirstOrDefault();
        }

        [HttpPut]
        [Route("{id}")]
        public dynamic Update(string id, NameTypeGroup nameTypeGroup)
        {
            if (nameTypeGroup == null) throw new ArgumentNullException(nameof(nameTypeGroup));

            return _nameTypeGroupsPicklistMaintenance.Save(nameTypeGroup, Operation.Update);
        }

        [HttpDelete]
        [Route("{id}")]
        public dynamic Delete(int id)
        {
            return _nameTypeGroupsPicklistMaintenance.Delete(id);
        }
    }

    public class NameTypeGroup
    {
        public NameTypeGroup()
        {
            Members = new string[0];
        }

        [PicklistKey]
        public short Key { get; set; }

        [PicklistCode]
        public short Code => Key;

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        public string Value { get; set; }

        public IEnumerable<string> Members { get; set; }

        [PicklistDescription]
        public string NameTypes => string.Join(", ", Members);

        public ICollection<NameTypeModel> NameType { get; set; }
    }
}