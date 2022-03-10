using Inprotech.Infrastructure.Hosting;
using Microsoft.Owin;

namespace Inprotech.IntegrationServer
{
    public class MockCurrentOwinContext: ICurrentOwinContext
    {
        public IOwinContext OwinContext => null;
    }
}