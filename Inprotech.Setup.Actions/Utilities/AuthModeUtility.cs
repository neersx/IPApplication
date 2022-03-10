using System.Collections.Generic;

namespace Inprotech.Setup.Actions.Utilities
{
    public static class AuthModeUtility
    {
        public static bool IsAuthModeEnabled(IDictionary<string, object> context, string authmode)
        {
            return context?.ContainsKey("AuthenticationMode") == true && ((string) context["AuthenticationMode"]).Contains(authmode);
        }
    }
}