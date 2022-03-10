using System;
using System.Data.Entity;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Contents
{
    [Authorize]
    public class ImageController : ApiController
    {
        readonly ICryptoService _crypto;
        readonly IDbContext _dbContext;
        readonly IIntegrationServerClient _integrationServerClient;

        public ImageController(IDbContext dbContext, IIntegrationServerClient integrationServerClient, ICryptoService crypto)
        {
            _dbContext = dbContext;
            _integrationServerClient = integrationServerClient;
            _crypto = crypto;
        }

        [HttpGet]
        [Route("api/img")]
        public async Task<HttpResponseMessage> Get(string id, string source)
        {
            if (int.TryParse(_crypto.Decrypt(id), out var actualId))
            {
                if (source == "filestore")
                {
                    return await _integrationServerClient.GetResponse("api/filestore/" + actualId);
                }

                if (source == "inprotech.image")
                {
                    var imageData = (await _dbContext.Set<Image>().SingleAsync(_ => _.Id == actualId)).ImageData;

                    var response = new HttpResponseMessage
                    {
                        Content = new StreamContent(new MemoryStream(imageData))
                    };

                    response.Content.Headers.ContentType = new MediaTypeHeaderValue(MimeMapping.GetMimeMapping("image.png"));

                    return response;
                }
            }

            throw new ArgumentException("source not supported");
        }

        [HttpGet]
        [Route("api/img/refresh")]
        public async Task<HttpResponseMessage> Refresh(int notificationId)
        {
            return await _integrationServerClient.GetResponse("api/dataextract/storage/image?notificationId=" + notificationId + "&refresh=true");
        }
    }
}