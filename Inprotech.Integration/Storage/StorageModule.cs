using Autofac;
using Inprotech.Contracts;
using Inprotech.Contracts.Storage;

namespace Inprotech.Integration.Storage
{
    public class StorageModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<StorageLocation>().As<IStorageLocation>();
            builder.RegisterType<FileMetadataRepository>().As<IFileMetadataRepository>();
            builder.RegisterType<FileSystemStorage>().As<IStorage>();
            builder.RegisterType<FileSystemPathBuilder>().As<IBuildFileSystemPaths>();
            builder.RegisterType<Md5HashingStorer>().As<IStoreAndHashFiles>();
        }
    }
}
