using System.IO;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;

#pragma warning disable CS1998 // Async method lacks 'await' operators and will run synchronously

namespace Inprotech.Web.Diagnostics
{
    public class InprotechServerLogs : ICompressedServerLogs
    {
        readonly ICompressionHelper _compressionHelper;

        public InprotechServerLogs(ICompressionHelper compressionHelper)
        {
            _compressionHelper = compressionHelper;
        }

        public string Name => "Inprotech.Server.zip";

        public async Task Prepare(string basePath)
        {
            if (!Directory.Exists("Logs"))
            {
                return;
            }

            _compressionHelper.CreateFromDirectory("Logs", Path.Combine(basePath, "Inprotech.Server.zip"));
        }
    }
}