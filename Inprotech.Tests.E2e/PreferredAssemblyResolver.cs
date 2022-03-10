using System.Collections.Generic;
using System.Reflection;
using System.Web.Http.Dispatcher;

namespace Inprotech.Tests.E2e
{
    public class PreferredAssemblyResolver : IAssembliesResolver
    {
        public ICollection<Assembly> GetAssemblies()
        {
            return new List<Assembly>(new[] {GetType().Assembly});
        }
    }
}
