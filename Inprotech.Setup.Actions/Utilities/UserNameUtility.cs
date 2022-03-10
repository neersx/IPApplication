using System;

namespace Inprotech.Setup.Actions.Utilities
{
    public static class UserNameUtility
    {
        public static string ToCanonicalUserName(this string userName)
        {
            if (userName == null) throw new ArgumentNullException(nameof(userName));
            if (userName.Contains("\\")) return userName;

            return $"{Environment.MachineName}\\{userName}";
        }
    }
}