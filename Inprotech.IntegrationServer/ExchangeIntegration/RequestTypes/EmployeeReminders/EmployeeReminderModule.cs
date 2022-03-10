using Autofac;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Components.Profiles;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public class EmployeeReminderModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ReminderDetails>().As<IReminderDetails>();
            builder.RegisterType<ReminderFormatter>().As<IReminderFormatter>();
            builder.RegisterType<UserFormatter>().As<IUserFormatter>();
            builder.RegisterType<UserPreferenceManager>().As<IUserPreferenceManager>();
            builder.RegisterType<IntegrationValidator>().As<IIntegrationValidator>();

            builder.RegisterType<EmployeeReminderIntegrator>()
                   .Keyed<IHandleExchangeMessage>(ExchangeRequestType.Add);

            builder.RegisterType<EmployeeReminderIntegrator>()
                   .Keyed<IHandleExchangeMessage>(ExchangeRequestType.Update);

            builder.RegisterType<ExchangeDeleteHandler>()
                   .Keyed<IHandleExchangeMessage>(ExchangeRequestType.Delete);

            builder.RegisterType<ExchangeIntegrationInitialiser>()
                   .Keyed<IHandleExchangeMessage>(ExchangeRequestType.Initialise);
        }
    }
}