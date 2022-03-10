using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    [NoEnrichment]
    public class TagsController : ApiController
    {
        static readonly CommonQueryParameters DefaulQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "TagName" // Overwrite sortBy which is default to 'id'
            });

        readonly IDbContext _dbContext;

        public TagsController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("api/configuration/tags")]
        public dynamic FindTags(string q, int take)
        {
            var tags = (IQueryable<Tag>) _dbContext.Set<Tag>();
            if (!string.IsNullOrWhiteSpace(q))
            {
                tags = tags.Where(_ => _.TagName.Contains(q));
            }

            return tags.OrderBy(_ => _.TagName).Take(take);
        }

        [HttpGet]
        [Route("api/configuration/tagslist")]
        public PagedResults FindTagsList(string search = "", [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            if (search == null)
            {
                search = string.Empty;
            }

            queryParameters = DefaulQueryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            var tags = _dbContext.Set<Tag>()
                                 .Select(_ => new TagResult
                                 {
                                     Id = _.Id,
                                     TagName = _.TagName
                                 });

            if (!string.IsNullOrWhiteSpace(search))
            {
                tags = tags.Where(_ => _.TagName.Contains(search));
            }

            return Helpers.GetPagedResults(tags,
                                           queryParameters ?? new CommonQueryParameters(),
                                           null, x => x.TagName, search);
        }

        [HttpPost]
        [Route("api/configuration/tags")]
        public dynamic CreateTag(JObject data)
        {
            var newTag = data["newTag"].ToString();
            if (string.IsNullOrWhiteSpace(newTag)) throw new Exception("Tag cannot be empty");

            var tag = _dbContext.Set<Tag>().SingleOrDefault(t => t.TagName == newTag);

            if (tag == null)
            {
                tag = new Tag {TagName = newTag};
                _dbContext.Set<Tag>().Add(tag);
                _dbContext.SaveChanges();
            }

            return tag.Id;
        }
    }

    public class TagResult
    {
        public int Id { get; set; }
        public string TagName { get; set; }
    }
}