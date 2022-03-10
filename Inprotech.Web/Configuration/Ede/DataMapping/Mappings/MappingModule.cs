using Autofac;
using InprotechKaizen.Model.Ede.DataMapping;

namespace Inprotech.Web.Configuration.Ede.DataMapping.Mappings
{
    public class MappingModule : Module
    {
        public const string MapStructureId = "MapStructureId";

        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<Mappings>().As<IMappings>();
            builder.RegisterType<MappingPersistence>().As<IMappingPersistence>();
            builder.RegisterType<MappingHandlerResolver>().As<IMappingHandlerResolver>();
            
            builder.RegisterType<EventMappingHandler>()
                .As<IMappingHandler>()
                .WithMetadata(MapStructureId, KnownMapStructures.Events);

            builder.RegisterType<EventMappingHandler>()
                .As<IMappingHandler>()
                .WithMetadata(MapStructureId, KnownMapStructures.Documents);
        }
    }
}