using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.Analytics;
using Inprotech.Integration.SchemaMapping.XmlGen;

namespace Inprotech.Web.SchemaMapping
{
    [RequiresApiKey(ExternalApplicationName.Inprotech)]
    [NoEnrichment]
    public class XmlGenApiController : XmlGenBaseController
    {
        readonly IBus _bus;

        public XmlGenApiController(IXmlGenService xmlGenService, IBus bus) : base(xmlGenService)
        {
            _bus = bus;
        }

        [HttpGet]
        [Route("api/schemamappings/{mappingId}/xml")]
        public async Task<HttpResponseMessage> Get(int mappingId)
        {
            var parameters = ResolveParameters();

            var r = await GetXmlResponse(mappingId, parameters);

            await _bus.PublishAsync(new TransactionalAnalyticsMessage
            {
                EventType = TransactionalEventTypes.SchemaMappingGeneratedViaApi,
                Value = mappingId.ToString()
            });

            return r;
        }
    }
}