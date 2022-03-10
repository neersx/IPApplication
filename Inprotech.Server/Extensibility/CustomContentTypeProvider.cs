using Microsoft.Owin.StaticFiles.ContentTypes;

namespace Inprotech.Server.Extensibility
{
    public class CustomContentTypeProvider : FileExtensionContentTypeProvider
    {
        public CustomContentTypeProvider()
        {
            Mappings.Add(".json", "application/json");
        }
    }

}
