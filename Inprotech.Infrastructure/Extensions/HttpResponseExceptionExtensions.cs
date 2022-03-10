using System;
using System.Net.Http;

namespace Inprotech.Infrastructure.Extensions
{
    public static class HttpClientExtension
    {
        public static void NoTimeout(this HttpClient client)
        {
            client.Timeout = TimeSpan.FromMilliseconds(-1.0);
        }
    }
}