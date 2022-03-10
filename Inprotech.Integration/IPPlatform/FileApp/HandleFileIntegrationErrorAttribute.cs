using System;
using System.Net;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    [AttributeUsage(AttributeTargets.Method)]
    public class HandleFileIntegrationErrorAttribute : Attribute
    {
        public HandleFileIntegrationErrorAttribute(HttpStatusCode[] statuses)
        {
            StatusCodes = statuses ?? new HttpStatusCode[0];
        }

        public HttpStatusCode[] StatusCodes { get; }
    }
}