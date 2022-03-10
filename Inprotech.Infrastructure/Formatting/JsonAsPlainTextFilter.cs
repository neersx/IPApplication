using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;

namespace Inprotech.Infrastructure.Formatting
{
    /// <summary>
    ///     Used to render the response of actions marked with <see cref="JsonAsPlainTextAttribute" /> attribute
    ///     as json as plain/text.
    ///     Here's an example scenario
    ///     1. User uses a HTML form to post multipart form data to an action marked with JsonAsPlainText.
    ///     2. We have some HTML/JS/iframe magic to read the response from the server.
    ///     2.1 We cannot set Content-Type to application/json because then some browsers
    ///     provide a download option. So our best bet is to return text/plain.
    ///     2.2 We would still like to read response as json because then it makes it easier to
    ///     read it in JS.
    ///     3. When browser posts data, request comes with browser's default accept headers for
    ///     multipart form data requests (e.g. chrome's default is text/plain; application/xml).
    ///     In this situation, this filter will
    ///     1. Set content type to text/plain
    ///     2. If the response body is an object, it ensures that it's serialized as json
    /// </summary>
    /// <remarks>
    ///     This is very special filter developped to support ajax like file upload scenario in
    ///     /#/new-certificate feature.
    ///     Review your usecase before using this!
    /// </remarks>
    public class JsonAsPlainTextFilter : IAutofacActionFilter
    {
        public Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }

        public Task OnActionExecutedAsync(HttpActionExecutedContext context, CancellationToken cancellationToken)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));

            if (!context.ActionContext.ActionDescriptor.GetCustomAttributes<JsonAsPlainTextAttribute>().Any())
            {
                return Task.FromResult(0);
            }

            // Set the response if we are dealing with an unhandled exception
            if (context.Exception != null)
            {
                context.Response = context
                    .Request
                    .CreateErrorResponse(
                                         HttpStatusCode.InternalServerError,
                                         context.Exception);
            }

            var response = context.Response;

            // Default ObjectContent construction infers the media type formatter
            // from accept header. This is problamatic because even though we set Content-Type
            // to be text/plain, the actual reponse content will be formatted using 
            // inferred formatter.
            // Therefore if we have an ObjectContent replace it with a new one 
            // with JsonMediaTypeFormatter. 
            // 
            var objectContent = response.Content as ObjectContent;
            if (objectContent != null)
            {
                response.Content = new ObjectContent(
                                                     objectContent.ObjectType,
                                                     objectContent.Value,
                                                     // Important to use the formatter from config to use the same settings as everything else
                                                     context.ActionContext.RequestContext.Configuration.Formatters.JsonFormatter);
            }

            // Finally set the content type header on content 
            if (response.Content != null)
            {
                response.Content.Headers.ContentType = new MediaTypeHeaderValue("text/plain");
            }

            return Task.FromResult(0);
        }
    }
}