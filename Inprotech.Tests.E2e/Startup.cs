using System.Web.Http;
using System.Web.Http.Dispatcher;
using Microsoft.Owin.FileSystems;
using Microsoft.Owin.StaticFiles;
using Newtonsoft.Json.Serialization;
using Owin;

namespace Inprotech.Tests.E2e
{
    public class Startup
    {
        static HttpConfiguration HttpConfiguration
        {
            get
            {
                var config = new HttpConfiguration();

                config.MapHttpAttributeRoutes();

                config.IncludeErrorDetailPolicy = IncludeErrorDetailPolicy.Always;

                config.Formatters.JsonFormatter.SerializerSettings.ContractResolver =
                    new CamelCasePropertyNamesContractResolver();

                config.Services.Replace(typeof(IAssembliesResolver), new PreferredAssemblyResolver());

                return config;
            }
        }

        public void Configuration(IAppBuilder appBuilder)
        {
            var config = HttpConfiguration;
            ConfigureStaticFiles(appBuilder);
            appBuilder.UseWebApi(config);
        }

        static void ConfigureStaticFiles(IAppBuilder appBuilder)
        {
            var fs = new PhysicalFileSystem("Contents");

            appBuilder.UseDefaultFiles(new DefaultFilesOptions {FileSystem = fs});
            appBuilder.UseStaticFiles(new StaticFileOptions {FileSystem = fs});
        }
    }
}