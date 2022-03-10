using System.Net;
using System.Net.Http;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;

namespace Inprotech.Infrastructure
{
    public enum ErrorMessageFormat
    {
        None,
        Underscore
    }

    public class HttpResponseExceptionHelper
    {
        public static void RaiseBadRequest(string errorMessage, ErrorMessageFormat format = ErrorMessageFormat.Underscore)
        {
            RaiseException(HttpStatusCode.BadRequest, errorMessage, format);
        }

        public static void RaiseNotFound(string errorMessage, ErrorMessageFormat format = ErrorMessageFormat.Underscore)
        {
            RaiseException(HttpStatusCode.NotFound, errorMessage, format);
        }

        public static void RaiseUnauthorized(string errorMessage, ErrorMessageFormat format = ErrorMessageFormat.Underscore)
        {
            RaiseException(HttpStatusCode.Unauthorized, errorMessage, format);
        }

        public static void RaiseFound(string errorMessage, ErrorMessageFormat format = ErrorMessageFormat.Underscore)
        {
            RaiseException(HttpStatusCode.Found, errorMessage, format);
        }

        public static void RaiseInternalServerError(string errorMessage, ErrorMessageFormat format = ErrorMessageFormat.Underscore)
        {
            RaiseException(HttpStatusCode.InternalServerError, errorMessage, format);
        }

        public static void RaiseForbidden(string errorMessage, ErrorMessageFormat format = ErrorMessageFormat.Underscore)
        {
            RaiseException(HttpStatusCode.Forbidden, errorMessage, format);
        }

        public static void RaiseNotAcceptable(string errorMessage, ErrorMessageFormat format = ErrorMessageFormat.Underscore)
        {
            RaiseException(HttpStatusCode.NotAcceptable, errorMessage, format);
        }

        static void RaiseException(HttpStatusCode httpStatusCode, string errorMessage, ErrorMessageFormat format)
        {
            if (format == ErrorMessageFormat.Underscore)
                errorMessage = errorMessage.CamelCaseToUnderscore();

            var msg = new HttpResponseMessage(httpStatusCode)
            {
                Content = new StringContent(errorMessage),
                ReasonPhrase = errorMessage.CamelCaseToUnderscore()
            };
            throw new HttpResponseException(msg);
        }
    }
}
