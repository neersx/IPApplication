using System;
using System.Net;

namespace Inprotech.Setup.Actions.Utilities
{
    public class NetworkUtility
    {
        public static bool TryGetPublicIpAddress(out IPAddress ipAddress, out string error)
        {
            ipAddress = IPAddress.None;
            error = null;
            try
            {
                var address = new WebClient().DownloadString("https://api.ipify.org");
                
                if (IPAddress.TryParse(address, out ipAddress))
                    return true;
            }
            catch (Exception ex)
            {
                error = ex.ToString();
            }

            return false;
        }
    }
}
