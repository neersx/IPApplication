using System.Diagnostics;
using System.Security;

namespace Inprotech.Setup.Core.Utilities
{
    public static class ProcessStartInfoExtensions
    {
        public static ProcessStartInfo RunAs(this ProcessStartInfo processStartInfo, string username, string password)
        {
            var unparts = username.Split('\\');

            processStartInfo.Domain = unparts.Length == 2 ? unparts[0] : processStartInfo.Domain;
            processStartInfo.UserName = unparts.Length == 2 ? unparts[1] : unparts[0];
            processStartInfo.Password = new SecureString();
            processStartInfo.Verb = "Runas";

            foreach (var c in password.ToCharArray())
                processStartInfo.Password.AppendChar(c);

            return processStartInfo;
        }
    }
}