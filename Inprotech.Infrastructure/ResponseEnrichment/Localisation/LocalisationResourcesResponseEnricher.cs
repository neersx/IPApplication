using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.Localisation;

namespace Inprotech.Infrastructure.ResponseEnrichment.Localisation
{
    public class LocalisationResourcesResponseEnricher : IResponseEnricher
    {
        const string ExtractAppilcationNamePattern = "/api/(?<appName>([^/].*?).*)/";

        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ILocalisationResources _localisationResources;

        public LocalisationResourcesResponseEnricher(IPreferredCultureResolver preferredCultureResolver, ILocalisationResources localisationResources)
        {
            if (preferredCultureResolver == null) throw new ArgumentNullException("preferredCultureResolver");
            if (localisationResources == null) throw new ArgumentNullException("localisationResources");

            _preferredCultureResolver = preferredCultureResolver;
            _localisationResources = localisationResources;
        }

        public Task Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            if (actionExecutedContext == null) throw new ArgumentNullException("actionExecutedContext");
            if (enrichment == null) throw new ArgumentNullException("enrichment");

            var applications = ResolveApplications(actionExecutedContext).ToArray();
            if (!applications.Any())
            {
                return Task.FromResult(0);
            }

            var candidateCultures = _preferredCultureResolver.ResolveWith(actionExecutedContext.Request.Headers);
            var resources = _localisationResources.For(applications, candidateCultures);

            enrichment.Add("__resources", resources);

            return Task.FromResult(0);
        }

        static IEnumerable<string> ResolveApplications(HttpActionExecutedContext actionExecutedContext)
        {
            var ad = actionExecutedContext.ActionContext.ActionDescriptor;

            var includeLocAttr = ad.GetCustomAttributes<IncludeLocalisationResourcesAttribute>().SingleOrDefault();
            if (includeLocAttr == null)
                yield break;

            var pathAndQuery = actionExecutedContext.Request.RequestUri.PathAndQuery;
            if (!string.IsNullOrEmpty(includeLocAttr.ApplicationName))
            {
                yield return includeLocAttr.ApplicationName;
                foreach (var component in includeLocAttr.Components)
                    yield return component;
            }
            else
            {
                yield return Match(ExtractAppilcationNamePattern, pathAndQuery) ?? "portal";
            }
        }

        static string Match(string pattern, string pathAndQuery)
        {
            var match = Regex.Match(pathAndQuery, pattern, RegexOptions.Compiled | RegexOptions.IgnoreCase);
            if (match.Success && !string.IsNullOrWhiteSpace(match.Groups["appName"].Value))
                return match.Groups["appName"].Value;

            return null;
        }
    }
}