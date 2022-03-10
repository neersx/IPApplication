using System;
using Autofac;
using Inprotech.Setup.Core;
using Module = Autofac.Module;

namespace Inprotech.Setup.CommandLine.DevOps
{
    class DevOpsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<FakeIisAppInfoManager>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<IiisAppInfoManagerSelector>().AsSelf();
            builder.Register<Func<string, IIisAppInfoManager>>(c =>
            {
                var context = c.Resolve<IComponentContext>();
                return x =>
                {
                    if (string.IsNullOrWhiteSpace(x))
                    {
                        return context.Resolve<IisAppInfoManager>();
                    }

                    return context.Resolve<FakeIisAppInfoManager>(new NamedParameter("profilePath", x));
                };
            });

        }
    }
}
