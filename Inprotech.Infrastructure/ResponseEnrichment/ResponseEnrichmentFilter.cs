using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;

namespace Inprotech.Infrastructure.ResponseEnrichment
{
    /// <summary>
    ///     Enriches a response with an object entity with additional information
    ///     provided by series of enrichers.
    /// </summary>
    public class ResponseEnrichmentFilter : IAutofacActionFilter
    {
        static readonly Type ResponseType = typeof(Dictionary<string, object>);

        readonly IEnumerable<IResponseEnricher> _responseEnrichers;

        public ResponseEnrichmentFilter(IEnumerable<IResponseEnricher> responseEnrichers)
        {
            _responseEnrichers = responseEnrichers ?? throw new ArgumentNullException(nameof(responseEnrichers));
        }

        public Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }

        public async Task OnActionExecutedAsync(HttpActionExecutedContext context, CancellationToken cancellationToken)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));

            if (context.Response == null) return;

            var existing = context.Response.Content as ObjectContent;

            if (existing == null ||
                context.ActionContext.ControllerContext.ControllerDescriptor != null &&
                context.ActionContext.ControllerContext.ControllerDescriptor.GetCustomAttributes<NoEnrichmentAttribute>().Any() ||
                context.ActionContext.ActionDescriptor.GetCustomAttributes<NoEnrichmentAttribute>().Any())
            {
                return;
            }

            var replacementData = new Dictionary<string, object>();

            foreach (var enricher in _responseEnrichers)
                await enricher.Enrich(context, replacementData);

            replacementData.Add("result", existing.Value);

            context.Response.Content = new ObjectContent(
                                                         ResponseType,
                                                         replacementData,
                                                         existing.Formatter);

            return;
        }
    }
}