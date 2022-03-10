using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents
{
    public class InnographyIdApiRequest
    {
        [JsonProperty(PropertyName = "patent_data")]
        public PatentDataMatchingRequest[] PatentData { get; set; }

        public InnographyIdApiRequest(IEnumerable<PatentDataMatchingRequest> data)
        {
            PatentData = data?.ToArray() ?? throw new ArgumentNullException(nameof(data));
        }
    }
}