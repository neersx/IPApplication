using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.Diagnostics.PtoAccess;

namespace Inprotech.IntegrationServer.PtoAccess.Diagnostics
{
    [RequiresApiKey(ExternalApplicationName.InprotechServer, IsOneTimeUse = true)]
    public class DiagnosticLogsController : ApiController
    {
        readonly IFileSystem _fileSystem;
        readonly ICompressionUtility _compressionUtility;
        readonly IEnumerable<IArchivable> _archivables;

        public DiagnosticLogsController(IFileSystem fileSystem, ICompressionUtility compressionUtility, IEnumerable<IArchivable> archivables)
        {
            _fileSystem = fileSystem;
            _compressionUtility = compressionUtility;
            _archivables = archivables;
        }

        [HttpGet]
        [Route("api/ptoaccess/diagnostic-logs/export")]
        public async Task<HttpResponseMessage> Export()
        {
            var allDiagnosticSources = _archivables
                .Where(archivable =>
                           archivable is ICompressedServerLogs ||
                           archivable is IDiagnosticsArtefacts);

            var archive = await _compressionUtility.CreateArchive("IntegrationServer.logs.zip", allDiagnosticSources);

            var response = new HttpResponseMessage(HttpStatusCode.OK)
                           {
                               Content = new StreamContent(_fileSystem.OpenRead(archive))
                           };

            response.Content.Headers.ContentType = new MediaTypeHeaderValue("application/zip");

            response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment") {FileName = "IntegrationServer.diagnostics.logs.zip"};

            return response;
        }
    }
}