using Autofac;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.SaveDraftEmails
{
    public class SaveDraftEmailModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<SaveDraftEmailRequestHandler>()
                   .Keyed<IHandleExchangeMessage>(ExchangeRequestType.SaveDraftEmail);
        }
    }
}