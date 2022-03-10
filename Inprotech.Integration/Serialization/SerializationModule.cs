using Autofac;

namespace Inprotech.Integration.Serialization
{
    public class SerializationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<JsonSerializer>().As<ISerializeJson>();
            builder.RegisterType<XmlSerialization>().As<ISerializeXml>();
        }
    }
}