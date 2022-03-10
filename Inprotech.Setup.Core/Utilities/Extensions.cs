namespace Inprotech.Setup.Core.Utilities
{
    public static class Extensions
    {
        public static AdfsSettings Copy(this AdfsSettings source)
        {
            return source == null
                ? null
                : new AdfsSettings
                {
                    ServerUrl = source.ServerUrl,
                    ClientId = source.ClientId,
                    RelyingPartyTrustId = source.RelyingPartyTrustId,
                    Certificate = source.Certificate,
                    ReturnUrls = source.ReturnUrls
                };
        }

        public static IpPlatformSettings Copy(this IpPlatformSettings source)
        {
            return source == null
                ? null
                : new IpPlatformSettings
                {
                    ClientId = source.ClientId,
                    ClientSecret = source.ClientSecret
                };
        }
    }
}