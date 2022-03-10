using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http.Filters;

namespace Inprotech.Infrastructure.Web
{
    public class ViewInitialiserAttribute : ActionFilterAttribute
    {
        public ICurrentRequestLifetimeScope CurrentRequestLifetimeScope { get; set; }

        public override void OnActionExecuted(HttpActionExecutedContext actionExecutedContext)
        {
            if (actionExecutedContext == null) throw new ArgumentNullException("actionExecutedContext");

            if (actionExecutedContext.Exception != null) return;
            if (actionExecutedContext.Response.StatusCode != HttpStatusCode.OK) return;

            var query = actionExecutedContext.Request.RequestUri.ParseQueryString();

            var content = (ObjectContent)actionExecutedContext.Response.Content;

            var enrichedResponse = (IDictionary<string, object>)content.Value;            

            var menu = CurrentRequestLifetimeScope.Resolve<IMenu>(actionExecutedContext.Request);

            var searchBar = CurrentRequestLifetimeScope.Resolve<ISearchBar>(actionExecutedContext.Request);

            enrichedResponse["result"] = new
            {
                ViewData = enrichedResponse["result"],
                Menu = query["menu"] == "yes" ? menu.Build().ToArray() : null,
                SearchBar = searchBar.SearchAccess()
            };    
        }
    }
}