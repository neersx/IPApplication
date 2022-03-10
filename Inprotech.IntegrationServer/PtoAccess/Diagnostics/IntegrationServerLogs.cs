using System.IO;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;

#pragma warning disable CS1998 // Async method lacks 'await' operators and will run synchronously

namespace Inprotech.IntegrationServer.PtoAccess.Diagnostics
{
    public class IntegrationServerLogs : ICompressedServerLogs
    {
        readonly ICompressionHelper _compressionHelper;

        public IntegrationServerLogs(ICompressionHelper compressionHelper)
        {
            _compressionHelper = compressionHelper;
        }

        public string Name => "Inprotech.IntegrationServer.zip";

        public async Task Prepare(string basePath)
        {
            if (!Directory.Exists("Logs"))
                return;

            _compressionHelper.CreateFromDirectory("Logs", Path.Combine(basePath, "Inprotech.IntegrationServer.zip"));
        }
    }
}
