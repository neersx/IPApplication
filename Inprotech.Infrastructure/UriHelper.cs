using System;

namespace Inprotech.Infrastructure
{
    public interface IUriHelper
    {
        bool TryAbsolute(string url, out Uri uri);
    }

    class UriHelper : IUriHelper
    {
        public bool TryAbsolute(string url, out Uri uri)
        {
            if (string.IsNullOrWhiteSpace(url) || !Uri.TryCreate(url, UriKind.RelativeOrAbsolute, out uri))
            {
                uri = null;
                return false;
            }

            if (!uri.IsAbsoluteUri
                && !url.StartsWith(Uri.UriSchemeHttp, StringComparison.InvariantCultureIgnoreCase)
                && !Uri.TryCreate(Uri.UriSchemeHttp + Uri.SchemeDelimiter + url, UriKind.Absolute, out uri))
            {
                return false;
            }

            return true;
        }
    }
}