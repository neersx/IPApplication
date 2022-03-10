using System;
using System.Net;
using System.Net.Http;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Infrastructure.Legacy
{
    public interface IDataService
    {
        Uri GetParentUri(string path);
    }

    /// <summary>
    /// Service for accessing legacy inprotech data services.
    /// Scope: InstancePerLifetimeScope
    /// </summary>
    public class DataService : IDataService, IDisposable
    {
        readonly IRequestContext _requestContext;
        readonly string _parentPath;
        readonly CookieContainer _cookieContainer = new CookieContainer();
        readonly HttpClient _httpClient;

        public DataService(IConfigurationSettings configurationSettings, IRequestContext requestContext)
        {
            _parentPath = configurationSettings["ParentPath"];
            _requestContext = requestContext;

            _httpClient = new HttpClient(new HttpClientHandler {CookieContainer = _cookieContainer});
        }

        public Uri GetParentUri(string path)
        {
            var curi = _requestContext.Request.RequestUri;

            var uriBuilder = new UriBuilder(curi.Scheme, curi.Host, curi.Port);

            var requestUri = new Uri(
                                     uriBuilder.Uri,
                                     new Uri(path.StartsWith("/") ? path : _parentPath + "/" + path, UriKind.Relative));

            return requestUri;
        }

        void Dispose(bool disposing)
        {
            if (disposing)
            {
                _httpClient.Dispose();
            }
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        ~DataService()
        {
            Dispose(false);
        }
    }
}