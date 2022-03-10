using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.SchemaMapping.XmlGen;

namespace Inprotech.Web.SchemaMapping
{
    public abstract class XmlGenBaseController : ApiController
    {
        protected readonly IXmlGenService XmlGenService;

        protected IDictionary<string, object> ResolveParameters()
        {
            return Request.GetQueryNameValuePairs().ToDictionary(pair => pair.Key, pair => (object)pair.Value);
        }

        protected XmlGenBaseController(IXmlGenService xmlGenService)
        {
            XmlGenService = xmlGenService;
        }

        protected async Task<HttpResponseMessage> GetXmlResponse(int mappingId, IDictionary<string, object> parameters)
        {
            try
            {
                var xml = Helpers.GetXml(await XmlGenService.Generate(mappingId, parameters));

                return HttpResponseMessageBuilder.Xml(HttpStatusCode.OK, xml);
            }
            catch (XmlGenException ex)
            {                
                return XmlGenerationFailure(ex);
            }
        }

        protected HttpResponseMessage XmlGenerationFailure(XmlGenException ex)
        {
            return HttpResponseMessageBuilder.Json(HttpStatusCode.InternalServerError, new
            {
                Status = "FailedToGenerateXml",
                Xml = (ex as XmlGenValidationException)?.OutputXml,
                Error = ex.Message
            });
        }
    }
}