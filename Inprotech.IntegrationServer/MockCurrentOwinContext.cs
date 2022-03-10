using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Hosting;
using Microsoft.Owin;

namespace Inprotech.IntegrationServer
{
    class MockCurrentOwinContext : ICurrentOwinContext
    {
        public IOwinContext OwinContext => null;
    }
}
