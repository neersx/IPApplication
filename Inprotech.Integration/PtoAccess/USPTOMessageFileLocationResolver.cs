using System.IO;

namespace Inprotech.Integration.PtoAccess
{
    public interface IUsptoMessageFileLocationResolver
    {
        string ResolveMessagePath();
        string ResolveRootDirectory();
    }

    public class UsptoMessageFileLocationResolver : IUsptoMessageFileLocationResolver
    {
        public string ResolveMessagePath()
        {
            return Path.Combine(ResolveRootDirectory(), "Messages");
        }

        public string ResolveRootDirectory()
        {
            return "IPOne";
        }
    }
}
