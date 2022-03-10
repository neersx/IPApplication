using Inprotech.Infrastructure.Hosting;
using Microsoft.Owin;

namespace Inprotech.StorageService
{
    class MockCurrentOwinContext : ICurrentOwinContext
    {
        public IOwinContext OwinContext => null;
    }
}
