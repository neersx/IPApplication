using System.Net;
using System.Net.Http;
using Microsoft.Owin;

namespace Inprotech.Infrastructure.Hosting
{
    public interface ISourceIpAddressResolver
    {
        string Resolve(HttpRequestMessage request);
        string Resolve(IOwinContext context);
    }

    public class SourceIpAddressResolver : ISourceIpAddressResolver
    {
        public string Resolve(HttpRequestMessage request)
        {
            return GetSourceIpFromEnvironment(request.GetOwinContext());
        }

        public string Resolve(IOwinContext context)
        {
            return GetSourceIpFromEnvironment(context);
        }

        static string GetSourceIpFromEnvironment(IOwinContext context)
        {
            var source = string.Empty;
            var remoteIpAddress = context.Environment["server.RemoteIpAddress"] as string;
            if (!string.IsNullOrWhiteSpace(remoteIpAddress) && IPAddress.TryParse(remoteIpAddress, out var address) && !IPAddress.IsLoopback(address))
            {
                source = address.ToString();
            }

            return string.IsNullOrWhiteSpace(source) ? null : source;
        }
    }
}