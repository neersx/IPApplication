using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/images")]
    public class ImagesPickListController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly CommonQueryParameters _defaultQueryParameters;

        public ImagesPickListController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _defaultQueryParameters = CommonQueryParameters.Default.Extend(new CommonQueryParameters {SortBy = "description"});
        }

        [HttpGet]
        [Route]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "", bool isUsedByEventCategory = false, bool isUsedByPropertyTypes = false)
         {
            var extendedQueryParams = _defaultQueryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var culture = _preferredCultureResolver.Resolve();
            var images = from d in _dbContext.Set<ImageDetail>()//.AsEnumerable()
                         join i in _dbContext.Set<Image>() on d.ImageId equals i.Id
                         join s in _dbContext.Set<TableCode>() on d.ImageStatus equals s.Id into status
                         from s in status.DefaultIfEmpty()
                         where ((search == null || search == string.Empty) || d.ImageDescription != null && d.ImageDescription.Contains(search)) 
                                && (!isUsedByEventCategory || d.ImageStatus == ProtectedTableCode.EventCategoryImageStatus)
                               && (!isUsedByPropertyTypes || d.ImageStatus == ProtectedTableCode.PropertyTypeImageStatus)
                         select new ImageModel
                         {
                             Description = d == null ? null : DbFuncs.GetTranslation(d.ImageDescription, null, d.DescriptionTId, culture),
                             ImageStatus = s == null ? null : DbFuncs.GetTranslation(s.Name, null, s.NameTId, culture),
                             Key = i.Id,
                             Image = i.ImageData
                         };

            var results = Helpers.GetPagedResults(images,
                                                  extendedQueryParams,
                                                  null, x => x.Description, search);
            return results;
        }
    }

    public class ImageModel
    {
        public int Key { get; set; }
        public string Description { get; set; }
        public string ImageStatus { get; set; }
        public byte[] Image { get; set; }
    }
}
