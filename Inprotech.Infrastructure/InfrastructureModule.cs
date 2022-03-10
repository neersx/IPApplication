using System;
using System.Reflection;
using Autofac;
using Inprotech.Contracts;
using Inprotech.Infrastructure.IO;
using Inprotech.Infrastructure.ThirdPartyLicensing;

namespace Inprotech.Infrastructure
{
    public static class InfrastructureModule
    {
        public static void Assemble(ContainerBuilder builder)
        {
            builder.RegisterAssemblyModules(Assembly.GetExecutingAssembly());
            builder.RegisterType<ConfigurationSettings>().As<IConfigurationSettings>();
            builder.RegisterType<ConnectionStrings>().As<IConnectionStrings>();
            builder.RegisterType<TemporaryStorage>().AsImplementedInterfaces().SingleInstance();
            builder.RegisterType<FileHelpers>().As<IFileHelpers>();
            builder.RegisterType<FileSystem>().As<IFileSystem>();
            builder.RegisterType<CompressionUtility>().As<ICompressionUtility>();
            builder.RegisterType<CompressionHelper>().As<ICompressionHelper>();
            builder.Register<Func<Guid>>(c => () => Guid.NewGuid());
            builder.RegisterType<UriHelper>().As<IUriHelper>();
            builder.RegisterType<ThirdPartyLicensing.ThirdPartyLicensing>().As<IThirdPartyLicensing>();
            builder.RegisterType<FileTypeChecker>().As<IFileTypeChecker>();
        }
    }
}