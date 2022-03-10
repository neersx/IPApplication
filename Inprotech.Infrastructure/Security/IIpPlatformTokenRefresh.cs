namespace Inprotech.Infrastructure.Security
{
    public interface ITokenRefresh
    {
        (string AccessToken, string RefreshToken) Refresh(string accessToken, string refreshToken, string authMode);
    }
}