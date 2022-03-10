using System.Net.Http;
using Microsoft.Owin;

namespace Inprotech.Infrastructure.Hosting
{
    public static class OwinContextExtensions
    {
        public static OwinContext GetOwinContext(this HttpRequestMessage request)
        {
            if (!request.Properties.TryGetValue("MS_OwinContext", out var ctxObj) || ctxObj == null)
            {
                return null;
            }

            return ctxObj as OwinContext;
        }
    }

    public interface ICurrentOwinContext
    {
        IOwinContext OwinContext { get; }
    }
}