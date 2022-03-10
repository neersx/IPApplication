using Autofac;

namespace Inprotech.Infrastructure.Validations
{
    public class ValidationsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<EmailValidator>().As<IEmailValidator>();
        }
    }
}
