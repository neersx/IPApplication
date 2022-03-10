using System;
using Autofac;
using Autofac.Extras.AttributeMetadata;
using InprotechKaizen.Model.Components.System.BackgroundProcess;

namespace Inprotech.Web
{
    public class WebModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {

            builder.RegisterModule<AttributedMetadataModule>();

            builder.RegisterType<DefaultHttpRequest>().As<IHttpRequest>();
            builder.RegisterType<BackgroundProcessMessageClient>().AsImplementedInterfaces();
            builder.Register(c => Guid.NewGuid());
        }
    }
}