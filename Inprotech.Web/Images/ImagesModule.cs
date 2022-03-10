using Autofac;

namespace Inprotech.Web.Images
{
    public class ImagesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<ImageService>().As<IImageService>();
        }
    }
}
