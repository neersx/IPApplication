using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Security
{
    public interface ITokenExtender
    {
        Task<(bool shouldExtend, bool tokenValid)> ShouldExtend(AuthCookieData cookieData);
    }

    public class TokenExtensionResponse
    {
        public TokenExtensionResponse(bool sessionExtended)
        {
            SessionExtended = sessionExtended;
        }

        public TokenExtensionResponse(bool sessionExtended, int userId, long userIdentityAccessLogId, string authMode)
        {
            SessionExtended = sessionExtended;
            UserId = userId;
            UserIdentityAccessLogId = userIdentityAccessLogId;
            AuthMode = authMode;
        }

        public bool SessionExtended { get; }
        public int UserId { get; }
        public long UserIdentityAccessLogId { get; }

        public string AuthMode { get; }
    }
}