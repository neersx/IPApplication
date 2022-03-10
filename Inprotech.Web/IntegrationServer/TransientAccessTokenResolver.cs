using System;
using Inprotech.Infrastructure.Hosting;

namespace Inprotech.Web.IntegrationServer
{
    public interface ITransientAccessTokenResolver
    {
        bool TryResolve(out Guid token);
    }

    public class TransientAccessTokenResolver : ITransientAccessTokenResolver
    {
        readonly ICurrentOwinContext _owinContext;

        public TransientAccessTokenResolver(ICurrentOwinContext owinContext)
        {
            _owinContext = owinContext;
        }

        public bool TryResolve(out Guid token)
        {
            var apiKey = _owinContext.OwinContext.Request.Headers["X-ApiKey"];

            if (!string.IsNullOrEmpty(apiKey) && Guid.TryParse(apiKey, out token))
            {
                return true;
            }

            token = Guid.Empty;
            return false;
        }
    }
}