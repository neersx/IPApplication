using System;
using System.Net;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2240:ImplementISerializableCorrectly")]
    [Serializable]
    public class FileIntegrationException : Exception
    {
        public FileIntegrationException(JObject integrationError, Exception innerException)
            : base("File integration error. " + Environment.NewLine + integrationError.ToString(Formatting.Indented), innerException)
        {
            StatusCode = (HttpStatusCode) (int) integrationError["StatusCode"];
        }

        public HttpStatusCode StatusCode { get; }
    }
}