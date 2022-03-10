using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.Controllers;
using Autofac.Core;
using Inprotech.Server;

namespace Inprotech.Tests.Server
{
    public class AllRegisteredControllers
    {
        public static IEnumerable<Type> Get()
        {
            var builder = Dependencies.Configure(new HttpConfiguration());

            var container = builder.Build();

            return from r in container.ComponentRegistry.Registrations
                   from s in r.Services
                   where s is TypedService
                   let ts = (TypedService) s
                   where typeof(IHttpController).IsAssignableFrom(ts.ServiceType)
                   select ts.ServiceType;
        }
    }
}