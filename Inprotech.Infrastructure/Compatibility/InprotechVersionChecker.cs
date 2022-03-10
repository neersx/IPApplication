using System.Linq;

namespace Inprotech.Infrastructure.Compatibility
{
    public interface IInprotechVersionChecker
    {
        bool CheckMinimumVersion(int majorVersion, int minorVersion = 0);
    }

    public class InprotechVersionChecker : IInprotechVersionChecker
    {
        readonly IConfigurationSettings _configurationSettings;

        public InprotechVersionChecker(IConfigurationSettings configurationSettings)
        {
            _configurationSettings = configurationSettings;
        }

        public bool CheckMinimumVersion(int majorVersion, int minorVersion = 0)
        {
            var checkResult = false;

            var version = _configurationSettings["InprotechVersion"];
            if (version != null)
            {
                var versionBreakDown = version.Split('.');
                int thisMajorVersion, thisMinorVersion;
                int.TryParse(versionBreakDown.FirstOrDefault() ?? "0", out thisMajorVersion);
                int.TryParse(versionBreakDown.Length > 1 ? versionBreakDown[1] : "0", out thisMinorVersion);
                checkResult = thisMajorVersion > majorVersion || (thisMajorVersion == majorVersion && thisMinorVersion >= minorVersion);
            }

            return checkResult;
        }
    }
}