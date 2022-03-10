using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public interface IDownloadCaseDispatcher
    {
        Task<Activity> DispatchForMatching(DataDownload[] cases);
        Task<Activity> DispatchForVerification(DataDownload[] cases);
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

        string ResolvePath(DataDownload firstCase)
        {
            var chunkData = "chunk_" + _chunkIdGenerator() + ".json";

            return _resolver.ResolveRoot(firstCase, chunkData);
        }

        async Task WriteCases(string path, DataDownload[] cases)
        {
            var location = _callerCount++;

            foreach (var dataDownload in cases)
            {
                dataDownload.Chunk = location;
            }

            await _bufferedStringWriter.Write(path, JsonConvert.SerializeObject(cases));

            await _ptoAccessCase.EnsureAvailableDetached(cases.Select(_ => _.Case).ToArray());
        }

        public async Task<Activity> DispatchForMatching(DataDownload[] cases)
        {
            var path = ResolvePath(cases.First());

            await WriteCases(path, cases);

            return Activity.Run<DownloadRequired>(_ => _.FromInnography(path));
        }

        public async Task<Activity> DispatchForVerification(DataDownload[] cases)
        {
            var path = ResolvePath(cases.First());

            await WriteCases(path, cases);

            return Activity.Run<VerificationRequired>(_ => _.FromInnography(path));
        }
    }
}