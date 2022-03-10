using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Caching;

namespace InprotechKaizen.Model.Components.Configuration.SiteControl
{
    public interface ISiteControlCache : IDisableApplicationCache
    {
        bool IsEmpty { get; }

        IEnumerable<ICachedSiteControl> Resolve(Func<IEnumerable<string>, IEnumerable<ICachedSiteControl>> valuesFactory, params string[] names);

        void Clear(params string[] siteControls);
    }

    public class SiteControlCache : ISiteControlCache
    {
        readonly ConcurrentDictionary<string, ICachedSiteControl> _cache = new ConcurrentDictionary<string, ICachedSiteControl>(StringComparer.InvariantCultureIgnoreCase);

        public IEnumerable<ICachedSiteControl> Resolve(Func<IEnumerable<string>, IEnumerable<ICachedSiteControl>> valuesFactory, params string[] names)
        {
            if (IsDisabled)
            {
                foreach (var resolvedValue in valuesFactory(names))
                    yield return resolvedValue;

                yield break;
            }

            var r = new List<string>();

            foreach (var cached in names)
            {
                if (_cache.TryGetValue(cached, out var value))
                {
                    yield return value;
                    continue;
                }

                r.Add(cached);
            }

            if (!r.Any()) yield break;

            foreach (var isc in valuesFactory(r).ToArray()) yield return _cache.GetOrAdd(isc.Id, x => isc);
        }

        public void Clear(params string[] siteControls)
        {
            if (!siteControls.Any())
            {
                _cache.Clear();
                return;
            }

            foreach (var sc in siteControls) _cache.TryRemove(sc, out _);
        }

        public bool IsEmpty => _cache.IsEmpty;

        public bool IsDisabled { get; set; }
    }
}