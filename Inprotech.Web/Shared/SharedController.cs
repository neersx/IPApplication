using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Web.Images;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Shared
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/shared")]
    public class SharedController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IImageService _imageService;

        public SharedController(IDbContext dbContext, IImageService imageService)
        {
            _dbContext = dbContext;
            _imageService = imageService;
        }

        [HttpGet]
        [Route("image/{imageKey:int}/{maxWidth?}/{maxHeight?}")]
        public dynamic GetImage(int imageKey, int? maxWidth = null, int? maxHeight = null)
        {
            var image = _dbContext.Set<Image>().SingleOrDefault(_ => _.Id == imageKey)?.ImageData;

            return image == null ? null : _imageService.ResizeImage(image, maxWidth, maxHeight);
        }
    }
}
