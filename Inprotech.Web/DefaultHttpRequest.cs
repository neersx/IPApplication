using System.Collections.Specialized;
using System.Net.Http;
using System.Web;

namespace Inprotech.Web
{
    public interface IHttpRequest
    {
        string RawUrl { get; }

        NameValueCollection Headers { get; }

        bool IsAuthenticated { get; }

        HttpMethod HttpMethod { get; }
    }

    public class DefaultHttpRequest : IHttpRequest
    {
        public string RawUrl
        {
            get { return HttpContext.Current.Request.RawUrl; }
        }

        public NameValueCollection Headers
        {
            get { return HttpContext.Current.Request.Headers; }
        }

        public bool IsAuthenticated
        {
            get { return HttpContext.Current.Request.IsAuthenticated; }
        }

        public HttpMethod HttpMethod
        {
            get { return new HttpMethod(HttpContext.Current.Request.HttpMethod); }
        }
    }
}