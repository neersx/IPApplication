using System.Security.Claims;

namespace Inprotech.Infrastructure.Security
{
    /// <summary>
    /// Used to access current user.
    /// We should be able to consolidate this with ISecurityContext.
    /// Introduced to remove the dependency on InprotechKaizen.Model assembly.
    /// </summary>
    public interface ICurrentUser
    {
        ClaimsIdentity Identity { get; }
    }

    public class CustomClaimTypes
    {
        public const string DisplayName = "DisplayName";
        public const string Id = "Id";
        public const string IsExternalUser = "IsExternalUser";
        public const string NameId = "NameId";
    }
}