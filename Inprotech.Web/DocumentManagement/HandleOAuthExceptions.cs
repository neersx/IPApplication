using System.Net;
using System.Net.Http;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.DocumentManagement
{
    public class HandleOAuthExceptions
    {
        public static HttpResponseMessage Handle()
        {
            return HttpResponseMessageBuilder.Json(HttpStatusCode.OK, new
            {
                IsAuthRequired = true
            });
        }

        public static HttpResponseMessage HandleDocumentDownload()
        {
            return HttpResponseMessageBuilder.Html(HttpStatusCode.OK, "Your session has expired, please login iManage again");
        }
    }
}