using Autofac;

namespace Inprotech.Integration.Accounting.Time.Posting
{
    public class PostTimeModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PostTime>().AsSelf();
            builder.RegisterType<PostTimeHandler>().AsImplementedInterfaces();
            builder.RegisterType<PostTimeJob>().AsImplementedInterfaces().AsSelf();
        }
    }
}
