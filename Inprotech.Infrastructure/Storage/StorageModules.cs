using Autofac;

namespace Inprotech.Infrastructure.Storage
{
    public class StorageModules : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BufferedStringWriter>().As<IBufferedStringWriter>();
            builder.RegisterType<BufferedStringReader>().As<IBufferedStringReader>();
            builder.RegisterType<ChunkedStreamWriter>().As<IChunkedStreamWriter>();
            //builder.RegisterType<PermanentStorageWriter>().As<IPermanentStorageWriter>();
            builder.RegisterType<ContentHasher>().As<IContentHasher>();
            builder.RegisterType<ZipStreamHelper>().As<IZipStreamHelper>();
        }
    }
}