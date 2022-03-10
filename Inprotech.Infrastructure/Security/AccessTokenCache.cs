namespace Inprotech.Infrastructure.Security
{
    public interface IAccessTokenCache
    {
        void Store(string accessToken);
    }
}