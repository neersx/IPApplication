using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Infrastructure.ResponseShaping.Picklists
{
    public class PicklistResponseFilter : IAutofacActionFilter
    {
        static readonly Type ResponseType = typeof(Dictionary<string, object>);
        readonly IEnumerable<IPicklistPayloadData> _dataEnrichers;

        public PicklistResponseFilter(IEnumerable<IPicklistPayloadData> dataEnrichers)
        {
            _dataEnrichers = dataEnrichers ?? throw new ArgumentNullException(nameof(dataEnrichers));
        }

        public Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }

        public Task OnActionExecutedAsync(HttpActionExecutedContext context, CancellationToken cancellationToken)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));

            if (context.Response == null || context.Response.StatusCode != HttpStatusCode.OK)
            {
                return Task.FromResult(0);
            }

            var existing = context.Response.Content as ObjectContent;

            var t = context.PicklistPayloadAttribute();
            if (existing == null || t == null)
            {
                return Task.FromResult(0);
            }

            var replacementData = new Dictionary<string, object>();

            if (existing.ObjectType == typeof(PagedResults) || existing.Value?.GetType() == typeof(PagedResults))
            {
                var pagedResults = (PagedResults) existing.Value;
                replacementData.Add("data", pagedResults.Data);
                replacementData.Add("pagination", pagedResults.Pagination);
            }
            else
            {
                replacementData.Add("data", existing.Value);
            }

            foreach (var enricher in _dataEnrichers)
                enricher.Enrich(context, replacementData);

            context.Response.Content = new ObjectContent(
                                                         ResponseType,
                                                         replacementData,
                                                         existing.Formatter);

            return Task.FromResult(0);
        }
    }
}