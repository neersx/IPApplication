using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;

namespace Inprotech.IntegrationServer.PtoAccess.Activities
{
    public interface IVersionableContentResolver
    {
        Task<string> Resolve(DataDownload dataDownload);
    }

    public interface IDefaultVersionableContentResolver : IVersionableContentResolver
    {
        
    }

    public class DefaultVersionableContentResolver : IDefaultVersionableContentResolver
    {
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IBufferedStringReader _bufferedStringReader;

        public DefaultVersionableContentResolver(
            IDataDownloadLocationResolver dataDownloadLocationResolver,
            IBufferedStringReader bufferedStringReader)
        {
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _bufferedStringReader = bufferedStringReader;
        }

        public async Task<string> Resolve(DataDownload dataDownload)
        {
            var appDetailsPath = _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.ApplicationDetails);

            return await _bufferedStringReader.Read(appDetailsPath);
        }
    }
}
