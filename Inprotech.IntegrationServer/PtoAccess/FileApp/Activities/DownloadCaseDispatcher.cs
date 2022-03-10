using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.Activities
{
    public interface IDownloadCaseDispatcher
    {
        Task<Activity> Dispatch(DataDownload[] cases);
    }

    public class DownloadCaseDispatcher : IDownloadCaseDispatcher
    {
        readonly IBufferedStringWriter _bufferedStringWriter;
        readonly Func<Guid> _chunkIdGenerator;
        readonly IPtoAccessCase _ptoAccessCase;
        readonly IDataDownloadLocationResolver _resolver;
        int _callerCount;

        public DownloadCaseDispatcher(
            IDataDownloadLocationResolver resolver,
            IBufferedStringWriter bufferedStringWriter,
            IPtoAccessCase ptoAccessCase,
            Func<Guid> chunkIdGenerator)
        {
            _resolver = resolver;
            _bufferedStringWriter = bufferedStringWriter;
            _ptoAccessCase = ptoAccessCase;
            _chunkIdGenerator = chunkIdGenerator;

            _callerCount = 1;
        }

        public async Task<Activity> Dispatch(DataDownload[] cases)
        {
            var location = _callerCount++;

            foreach (var dataDownload in cases)
                dataDownload.Chunk = location;

            var batchFirst = cases.First();

            var chunkData = "chunk_" + _chunkIdGenerator() + ".json";

            var path = _resolver.ResolveRoot(batchFirst, chunkData);

            var list = _resolver.ResolveRoot(batchFirst, "applicationlist.json");

            await _bufferedStringWriter.Write(path, JsonConvert.SerializeObject(cases));

            await _ptoAccessCase.EnsureAvailableDetached(cases.Select(_ => _.Case).ToArray());

            return Activity.Run<DownloadRequired>(_ => _.FromTheIPPlatform(path, list));
        }
    }
}