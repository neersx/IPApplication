using System;
using System.Linq;

namespace Inprotech.Setup.Actions.Utilities
{
    public static class VersionNumberUtitlity
    {
        public static bool IsLegacyVersion(string connectionString)
        {
            var sqlVerision = DatabaseUtility.GetSqlVersion(connectionString);
            var majorversion = Convert.ToInt16(string.Concat(sqlVerision.TakeWhile((c) => c != '.')));
            return majorversion <= 10;
        }
    }
}