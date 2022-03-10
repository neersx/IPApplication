using System;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/tags")]
    public class TagsPicklistController : ApiController
    {
        static readonly CommonQueryParameters DefaulQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "TagName" // Overwrite sortBy which is default to 'id'
            });

        readonly IDbContext _dbContext;
        readonly ITagsPicklistMaintenance _tagsPicklistMaintenance;

        public TagsPicklistController(IDbContext dbContext, ITagsPicklistMaintenance tagsPicklistMaintenance)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _tagsPicklistMaintenance = tagsPicklistMaintenance ?? throw new ArgumentNullException(nameof(tagsPicklistMaintenance));
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(Tags), ApplicationTask.AllowedAccessAlways)]
        [PicklistMaintainabilityActions(allowDuplicate: false)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(Tags), ApplicationTask.AllowedAccessAlways)]
        public PagedResults Tags(string search = "", [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            if (search == null)
            {
                search = string.Empty;
            }

            queryParameters = DefaulQueryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var tags = _dbContext.Set<Tag>()
                                 .Select(_ => new Tags
                                 {
                                     TagName = _.TagName,
                                     Id = _.Id
                                 });

            if (!string.IsNullOrWhiteSpace(search))
            {
                tags = tags.Where(_ => _.TagName.Contains(search));
            }

            return Helpers.GetPagedResults(tags,
                                           queryParameters ?? new CommonQueryParameters(),
                                           x => x.Id.ToString(), x => x.TagName, search);
        }

        [HttpGet]
        [Route("{id}")]
        [PicklistPayload(typeof(Tags), ApplicationTask.AllowedAccessAlways)]
        public dynamic Tag(string id)
        {
            int tagId;

            if (int.TryParse(id, out tagId))
            {
                return _dbContext.Set<Tag>().SingleOrDefault(_ => _.Id == tagId);
            }
            throw new ArgumentException(nameof(id));
        }

        [HttpPost]
        [Route]
        public dynamic Add(Tags tags)
        {
            if (tags == null) throw new ArgumentNullException(nameof(tags));

            return _tagsPicklistMaintenance.Save(tags);
        }

        [HttpPut]
        [Route("{id}")]
        public dynamic Update(string id, Tags tags)
        {
            if (tags == null) throw new ArgumentNullException(nameof(tags));

            return _tagsPicklistMaintenance.Update(tags);
        }

        [HttpPut]
        [Route("updateconfirm")]
        public dynamic UpdateConfirm(Tags tags)
        {
            if (tags == null) throw new ArgumentNullException(nameof(tags));

            return _tagsPicklistMaintenance.UpdateConfirm(tags);
        }

        [HttpDelete]
        [Route("{id}")]
        public dynamic Delete(int id, bool confirm)
        {
            return _tagsPicklistMaintenance.Delete(id, confirm);
        }
    }

    public class Tags
    {
        [PicklistKey]
        public int Key => Id;

        [PicklistCode]
        public int Id { get; set; }

        [Required]
        [MaxLength(30)]
        [PicklistDescription]
        public string TagName { get; set; }
    }
}