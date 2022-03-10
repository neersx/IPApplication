using System.Linq;
using System.Reflection;
using Autofac;

namespace Inprotech.Setup.Core.Actions
{
    public class Module : Autofac.Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            var ignores = new[] {"Module", "Validator"};
            builder.RegisterAssemblyTypes(Assembly.GetExecutingAssembly())
                   .Where(t => t.Namespace == "Inprotech.Setup.Core.Actions" && t.IsClass && !ignores.Contains(t.Name))
                   .AsSelf();
        }
    }
}