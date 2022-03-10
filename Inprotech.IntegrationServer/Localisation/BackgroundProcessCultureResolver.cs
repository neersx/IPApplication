using System.Collections.Generic;
using System.Linq;
using System.Net.Http.Headers;
using Inprotech.Infrastructure.Localisation;

namespace Inprotech.IntegrationServer.Localisation
{
    public class BackgroundProcessCultureResolver : IPreferredCultureResolver
    {
        public IEnumerable<string> ResolveWith(HttpRequestHeaders headers)
        {
            return Enumerable.Empty<string>();
        }

        public IEnumerable<string> ResolveAll()
        {
            return Enumerable.Empty<string>();
        }

        public string Resolve()
        {
            return null;
        }
    }
}