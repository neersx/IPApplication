using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/Subjects")]
    public class SubjectPicklistController : ApiController
    {
        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Name",
                SortDir = "asc"
            });

        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public SubjectPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, Func<DateTime> clock)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _clock = clock;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(DataTopicItems))]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var queryParams = SortByParameters.Extend(queryParameters);
            var culture = _preferredCultureResolver.Resolve();
            var query = from d in _dbContext.Set<DataTopic>()
                        join p in _dbContext.ValidObjects("DATATOPIC", _clock().Date) on d.Id.ToString() equals p.ObjectIntegerKey
                        join data in _dbContext.ValidObjects("DATATOPICREQUIRES", _clock().Date) on d.Id.ToString() equals data.ObjectIntegerKey
                        select new
                        {
                            d.Id,
                            Name = DbFuncs.GetTranslation(d.Name, null, d.TopicNameTId, culture),
                            Description = DbFuncs.GetTranslation(d.Description, null, d.DescriptionTId, culture),
                            p.InternalUse,
                            p.ExternalUse
                        };

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(_ => _.Name.Contains(search) || _.Description.Contains(search));
            }

            var result = Helpers.GetPagedResults(query.Select(p => new DataTopicItems
            {
                Key = p.Id,
                Name = p.Name,
                Description = p.Description,
                InternalUse = p.InternalUse,
                ExternalUse = p.ExternalUse
            }), queryParams, null, null, null);

            return result;
        }
    }

    public class DataTopicItems
    {
        [PicklistKey]
        public int Key { get; set; }

        [PicklistDescription]
        public string Name { get; set; }
        public string Description { get; set; }
        public bool? InternalUse { get; set; }
        public bool? ExternalUse { get; set; }
        public bool SelectPermission { get; set; }
    }
}