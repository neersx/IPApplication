using System.Collections.Generic;
using System.Globalization;
using System.IO;
using Inprotech.Integration.Schedules;

namespace Inprotech.Integration.Artifacts
{
    public interface IDataDownloadLocationResolver
    {
        string ResolveRoot(DataDownload dataDownload, string fileName = null);

        string Resolve(DataDownload dataDownload, string fileName = null);

        string ResolveForErrorLog(DataDownload dataDownload, string fileName = null);
    }

    public class DataDownloadLocationResolver : IDataDownloadLocationResolver
    {
        const string LogFolder = "Logs";
        readonly IResolveScheduleExecutionRootFolder _rootResolver;

        public DataDownloadLocationResolver(IResolveScheduleExecutionRootFolder rootResolver)
        {
            _rootResolver = rootResolver;
        }

        public string ResolveRoot(DataDownload dataDownload, string fileName = null)
        {
            var parts = new List<string>
            {
                _rootResolver.Resolve(dataDownload.Id)
            };

            if (!string.IsNullOrWhiteSpace(fileName))
            {
                parts.Add(fileName);
            }

            return Path.Combine(parts.ToArray());
        }

        public string Resolve(DataDownload dataDownload, string fileName = null)
        {
            var parts = new List<string> { _rootResolver.Resolve(dataDownload.Id) };

            if (dataDownload.Chunk.HasValue)
            {
                parts.Add(dataDownload.Chunk.Value.ToString(CultureInfo.InvariantCulture));
            }

            if (dataDownload.Case != null)
            {
                parts.Add(dataDownload.Case.CaseKey.ToString(CultureInfo.InvariantCulture));
            }

            if (!string.IsNullOrWhiteSpace(fileName))
            {
                parts.Add(fileName);
            }

            return Path.Combine(parts.ToArray());
        }

        public string ResolveForErrorLog(DataDownload dataDownload, string fileName = null)
        {
            var parts = new List<string> {_rootResolver.Resolve(dataDownload.Id)};

            if (dataDownload.Chunk.HasValue)
            {
                parts.Add(dataDownload.Chunk.Value.ToString(CultureInfo.InvariantCulture));
            }

            parts.Add(LogFolder);

            if (dataDownload.Case != null)
            {
                parts.Add(dataDownload.Case.CaseKey.ToString(CultureInfo.InvariantCulture));
            }

            if (!string.IsNullOrWhiteSpace(fileName))
            {
                parts.Add(fileName);
            }

            return Path.Combine(parts.ToArray());
        }
    }
}