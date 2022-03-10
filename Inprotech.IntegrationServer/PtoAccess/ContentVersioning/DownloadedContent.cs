using System;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.ContentVersioning
{
    public interface IDownloadedContent
    {
        Task<string> MakeVersionable(DataDownload dataDownload);
    }

    public class DownloadedContent : IDownloadedContent
    {
        readonly IDefaultVersionableContentResolver _defaultResolver;
        readonly IIndex<DataSourceType, IVersionableContentResolver> _versionableContentResolvers;

        public DownloadedContent(IDefaultVersionableContentResolver defaultResolver, IIndex<DataSourceType, IVersionableContentResolver> versionableContentResolvers)
        {
            _defaultResolver = defaultResolver;
            _versionableContentResolvers = versionableContentResolvers;
        }

        public async Task<string> MakeVersionable(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            if (_versionableContentResolvers.TryGetValue(dataDownload.DataSourceType, out IVersionableContentResolver specificResolver))
            {
                return await specificResolver.Resolve(dataDownload);
            }

            return await _defaultResolver.Resolve(dataDownload);
        }
    }
}