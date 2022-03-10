using System.Reflection;
using Inprotech.Infrastructure.ResponseEnrichment.ApplicationVersion.Extensions;

namespace Inprotech.Infrastructure.ResponseEnrichment.ApplicationVersion
{
    public interface IAppVersion
    {
        string CurrentVersion { get; }

        int CurrentReleaseYear { get; }
        
        string CurrentVersionFormatted { get; }
    }

    public class AppVersion : IAppVersion
    {
        public string CurrentVersionFormatted => Assembly.GetExecutingAssembly().Version();

        public string CurrentVersion => Assembly.GetExecutingAssembly().Version(string.Empty);

        public int CurrentReleaseYear => Assembly.GetExecutingAssembly().ReleaseYear();
    }
}