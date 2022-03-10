using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http.Headers;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Infrastructure.Localisation
{
    public interface IPreferredCultureResolver
    {
        IEnumerable<string> ResolveWith(HttpRequestHeaders headers);

        IEnumerable<string> ResolveAll();

        string Resolve();
    }

    public class PreferredCultureResolver : IPreferredCultureResolver
    {
        static readonly IEnumerable<CultureInfo> All = CultureInfo.GetCultures(CultureTypes.AllCultures);

        readonly IPreferredCultureSettings _preferredCultureSettings;
        readonly IRequestContext _requestContext;
        readonly List<string> _resolvedDefault = new List<string>();
        IEnumerable<string> _requestLanguages;

        public PreferredCultureResolver(
            IPreferredCultureSettings preferredCultureSettings,
            IRequestContext requestContext)
        {
            _preferredCultureSettings = preferredCultureSettings;
            _requestContext = requestContext;
        }

        public IEnumerable<string> ResolveWith(HttpRequestHeaders headers)
        {
            var preferred = _preferredCultureSettings.ResolveAll();
            var defaultLanguages = ResolveFrom(headers);
            var allCandidates = preferred.Concat(defaultLanguages);

            return ResolveCulture(allCandidates);
        }

        public IEnumerable<string> ResolveAll()
        {
            if (!_resolvedDefault.Any())
            {
                var preferred = _preferredCultureSettings.ResolveAll();

                var defaultLanguages = _requestLanguages != null && _requestLanguages.Any()
                    ? _resolvedDefault
                    : _requestLanguages = ResolveFrom(_requestContext.Request?.Headers);

                var allCandidates = preferred.Concat(defaultLanguages);

                var r = ResolveCulture(allCandidates).ToArray();
                if (r.Any())
                {
                    _resolvedDefault.AddRange(r);
                }
            }

            return _resolvedDefault;
        }

        public string Resolve()
        {
            return (ResolveAll() ?? Enumerable.Empty<string>()).FirstOrDefault();
        }

        static IEnumerable<string> ResolveCulture(IEnumerable<string> allCandidateCultures)
        {
            foreach (var candidate in allCandidateCultures)
            {
                var c = candidate;

                var f = All.FirstOrDefault(s => string.Compare(s.Name, c, StringComparison.OrdinalIgnoreCase) == 0);
                if (f == null)
                {
                    continue;
                }

                string neutral, specific;

                if (f.IsNeutralCulture)
                {
                    neutral = f.Name;
                    specific = CultureInfo.CreateSpecificCulture(neutral).Name;
                }
                else
                {
                    neutral = f.Parent.Name;
                    specific = f.Name;
                }

                yield return specific;
                yield return neutral;
            }
        }

        static IEnumerable<string> ResolveFrom(HttpRequestHeaders headers)
        {
            if (headers == null) return Enumerable.Empty<string>();

            return headers
                   .AcceptLanguage
                   .OrderByDescending(a => a.Quality ?? (double) 1)
                   .Select(a => a.Value);
        }
    }
}