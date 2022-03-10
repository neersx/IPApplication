using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Images;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Names
{
    
    [Authorize]
    [RoutePrefix("api/search")]
    public class NameImageController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IImageService _imageService;

        public NameImageController(IDbContext dbContext, IImageService imageService)
        {
            _dbContext = dbContext;
            _imageService = imageService;
        }

        [HttpGet]
        [RequiresNameAuthorization(PropertyName = "itemKey")]
        [Route("name/image/{imageKey:int}/{itemKey:int}/{maxWidth?}/{maxHeight?}")]
        [Route("lead/image/{imageKey:int}/{itemKey:int}/{maxWidth?}/{maxHeight?}")]
        public dynamic GetImage(int imageKey, int itemKey, int? maxWidth = null, int? maxHeight = null)
        {
            var image = _dbContext.Set<Image>().SingleOrDefault(_ => _.Id == imageKey)?.ImageData;

            return image == null ? null : _imageService.ResizeImage(image, maxWidth, maxHeight);
        }
    }
}