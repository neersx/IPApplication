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
    [RoutePrefix("api/picklists/web-parts")]
    public class WebPartPicklistController : ApiController
    {
        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Title",
                SortDir = "asc"
            });

        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public WebPartPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, Func<DateTime> clock)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _clock = clock;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(WebPartPicklistItem))]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var queryParams = SortByParameters.Extend(queryParameters);
            var culture = _preferredCultureResolver.Resolve();
            var webParts = from wp in _dbContext.Set<WebpartModule>()
                           join v in _dbContext.ValidObjects("MODULE", _clock().Date) on wp.Id.ToString() equals v.ObjectIntegerKey
                           select new
                           {
                               ModuleKey = v.ObjectIntegerKey,
                               Title = DbFuncs.GetTranslation(wp.Title, null, wp.TitleTId, culture),
                               Description = DbFuncs.GetTranslation(wp.Description, null, wp.DescriptionTId, culture),
                               v.InternalUse,
                               v.ExternalUse
                           };

            if (!string.IsNullOrEmpty(search))
            {
                webParts = webParts.Where(_ => _.Title.Contains(search) || _.Description.Contains(search));
            }

            return Helpers.GetPagedResults(webParts.Select(wp => new WebPartPicklistItem
            {
                Key = wp.ModuleKey,
                Title = wp.Title,
                Description = wp.Description,
                IsInternal = wp.InternalUse,
                IsExternal = wp.ExternalUse
            }), queryParams, null, null, null);
        }
    }

    public class WebPartPicklistItem
    {
        [PicklistKey]
        public string Key { get; set; }

        [PicklistDescription]
        public string Title { get; set; }

        public string Description { get; set; }

        public bool? IsExternal { get; set; }
        public bool? IsInternal { get; set; }
    }
}