using System.Diagnostics.CodeAnalysis;
using System.Threading;
using Inprotech.Infrastructure.Hosting;
using Microsoft.Owin;

namespace Inprotech.Server
{
    internal static class OwinContextAccessor
    {
        internal static AsyncLocal<IOwinContext> OwinContext = new AsyncLocal<IOwinContext>();

        internal static IOwinContext CurrentContext => OwinContext.Value;
    }

    [SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Owin")]
    public class CurrentOwinContext : ICurrentOwinContext
    {
        public IOwinContext OwinContext => OwinContextAccessor.CurrentContext;
    }
}