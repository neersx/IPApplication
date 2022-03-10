namespace Inprotech.Web.Security
{
    public static class Urls
    {
        public const string ApiSignIn = "api/signin";
        public const string ApiSignOut = "api/signout";
        public const string WinAuth = "winAuth";
        public const string SsoReturn = "ssoReturn";
        public const string AdfsReturn = "adfsReturn";
        public const string ApiSsoReturn = ApiSignIn + "/" + SsoReturn;
        public const string ResetPassword = "api/resetpassword";
    }
}
