using System;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.SchemaMapping
{
    [Authorize]
    [NoEnrichment]
    public class DocItemController : ApiController
    {
        readonly IDocItemReader _docItemReader;

        public DocItemController(IDocItemReader docItemReader)
        {
            _docItemReader = docItemReader;
        }

        [HttpGet]
        [Route("api/schemamapping/docItem")]
        public dynamic Get(int id)
        {
            try
            {
                return _docItemReader.Read(id);
            }
            catch (Exception ex)
            {
                return HttpResponseMessageBuilder.Json(HttpStatusCode.InternalServerError, new
                {
                    Status = "FailedToReadDocItem",                   
                    Error = ex.Message
                });
            }
        }
    }
}