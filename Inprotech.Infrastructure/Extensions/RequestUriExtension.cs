using System;
using System.Linq;

namespace Inprotech.Infrastructure.Extensions
{
    public static class RequestUriExtension
    {
        public static string RelativeUri(this Uri uri, string redirectedFromControllerName)
        {
            return uri.AbsoluteUri.Substring(
                                             0,
                                             uri.AbsoluteUri
                                                .ToLower()
                                                .IndexOf(
                                                         redirectedFromControllerName,
                                                         StringComparison
                                                             .Ordinal));
        }

        public static Uri ReplaceStartingFromSegment(this Uri uri, string segment, string putAfter)
        {
            var segments = uri.Segments.ToList();
            var idx = segments.FindIndex(x => x.Equals(segment, StringComparison.InvariantCultureIgnoreCase) ||
                                              x.Equals(segment + "/", StringComparison.InvariantCultureIgnoreCase));

            if (idx < 1) throw new Exception("segment " + segment + " was not found in uri " + uri);

            segments = segments.Take(idx).ToList();
            segments.Add(putAfter);

            return new Uri($"{uri.Scheme}://{uri.Authority}{string.Join(string.Empty, segments)}");
        }
    }
}