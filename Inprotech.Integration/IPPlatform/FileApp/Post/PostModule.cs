using Autofac;

namespace Inprotech.Integration.IPPlatform.FileApp.Post
{
    public class PostModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<UploadTrademarkImage>().As<IUploadTrademarkImage>();

            builder.RegisterType<TrademarkImageResolver>().As<ITrademarkImageResolver>();

            builder.RegisterType<FileImageStorageHandler>().As<IFileImageStorageHandler>();

            builder.RegisterType<FileTrademarkPostCreationTasks>()
                   .Keyed<IPostInstructionCreationTasks>(IpTypes.TrademarkDirect);
        }
    }
}