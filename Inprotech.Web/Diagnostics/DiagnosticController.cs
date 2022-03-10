using System;
using System.Collections.Generic;
using System.Web.Http;
using Inprotech.Contracts.DocItems;
using Inprotech.Web.Messaging;
using Newtonsoft.Json;

namespace Inprotech.Web.Diagnostics
{
    [Authorize]
    public class DiagnosticController : ApiController
    {
        readonly IClientMessageBroker _clientMessageBroker;
        readonly IDocItemRunner _docItemRunner;

        public DiagnosticController(IClientMessageBroker clientMessageBroker, IDocItemRunner docItemRunner)
        {
            if (clientMessageBroker == null) throw new ArgumentNullException("messageBroker"); 
            if (docItemRunner == null) throw new ArgumentNullException("docItemRunner");
            _clientMessageBroker = clientMessageBroker;
            _docItemRunner = docItemRunner;
        }

        [HttpPost]
        [Route("api/diagnostics/messageBroker/publish")]
        public void PublishMessageToBroker(dynamic body)
        {
            var routing = (string)body.routing;
            var message = (string)body.message;

            _clientMessageBroker.Publish(routing, message == null ? null : JsonConvert.DeserializeObject(message));
        }

        [HttpGet]
        [Route("api/diagnostics/docitem/execute")]
        public dynamic Execute(int id, string paramName, string paramValue)
        {
            var mappedParams = new Dictionary<string, object>
            {
                {paramName, paramValue}
            };

            return _docItemRunner.Run(id, mappedParams);
        }
    }
}
