using System.IO;
using System.Net.Http;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Web
{
    public interface IIntegrationServerClient
    {
        Task<string> DownloadString(string api);

        Task<HttpResponseMessage> GetResponse(string api);

        Task<Stream> DownloadContent(string api);
        
        Task Post(string relativeUrl, object message);

        Task<HttpResponseMessage> Put(string relativeUrl, object message);
    }
}