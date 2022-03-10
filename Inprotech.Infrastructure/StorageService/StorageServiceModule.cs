using Autofac;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Infrastructure.StorageService
{
    public class StorageServiceModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<StorageServiceClient>().As<IStorageServiceClient>();
            builder.RegisterType<ValidateHttpOrHttpsString>().As<IValidateHttpOrHttpsString>();
        }
    }
}
