using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Innography.PrivatePair;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public interface IGlobErrors
    {
        Task<IEnumerable<JObject>> For(DataDownload dataDownload, string context = null);

        Task<IEnumerable<JObject>> GlobFor(ApplicationDownload application, AvailableDocument availableDocument = null);

        Task<IEnumerable<JObject>> GlobFor(Session session);
    }

    public class GlobErrors : IGlobErrors
    {
        readonly IDataDownloadLocationResolver _locationResolver;
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IFileSystem _fileSystem;
        readonly IBufferedStringReader _bufferedStringReader;

        public GlobErrors(IDataDownloadLocationResolver locationResolver,IArtifactsLocationResolver artifactsLocationResolver, IFileSystem fileSystem, IBufferedStringReader bufferedStringReader)
        {
            _locationResolver = locationResolver;
            _artifactsLocationResolver = artifactsLocationResolver;
            _fileSystem = fileSystem; 
            _bufferedStringReader = bufferedStringReader;
        }

        public async Task<IEnumerable<JObject>> For(DataDownload dataDownload, string context = null)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var c = string.IsNullOrEmpty(context) ? null : context + "-";
            return await GlobErrorLogsFrom(_locationResolver.ResolveForErrorLog(dataDownload), c);
        }

        public async Task<IEnumerable<JObject>> GlobFor(ApplicationDownload application,
                                                        AvailableDocument availableDocument = null)
        {
            var context = availableDocument == null ? string.Empty : (availableDocument.FileNameObjectId ?? availableDocument.ObjectId);

            return await GlobErrorLogsFrom(_artifactsLocationResolver.Resolve(application, "Logs"), context);
        }

        public async Task<IEnumerable<JObject>> GlobFor(Session session)
        {
            return await GlobErrorLogsFrom(_artifactsLocationResolver.Resolve(session, "Logs"));
        }

        async Task<IEnumerable<JObject>> GlobErrorLogsFrom(string path, string context = null)
        {
            var list = new List<JObject>();
            foreach (var file in _fileSystem.Files(path, (context ?? string.Empty) + "*.log"))
                list.Add(JObject.Parse(await _bufferedStringReader.Read(file)));
            return list;
        }
    }
}