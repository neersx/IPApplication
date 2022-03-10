using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

namespace Inprotech.Integration.Persistence
{
    public static class IntegrationDbContextHelpers
    {
        static IEnumerable<IModelBuilder> _cached = Enumerable.Empty<IModelBuilder>();

        internal static IEnumerable<IModelBuilder> ResolveModelBuilders()
        {
            if (!_cached.Any())
            {
                _cached = Assembly.GetExecutingAssembly()
                                  .GetExportedTypes()
                                  .Where(t => IsAssignableTo<IModelBuilder>(t) && t.IsClass && !t.IsAbstract)
                                  .Select(Activator.CreateInstance)
                                  .Cast<IModelBuilder>()
                                  .ToArray();
            }

            return _cached;
        }

        static bool IsAssignableTo<T>(Type @this)
        {
            if (@this == null) throw new ArgumentNullException(nameof(@this));

            return typeof(T).GetTypeInfo().IsAssignableFrom(@this.GetTypeInfo());
        }
    }
}