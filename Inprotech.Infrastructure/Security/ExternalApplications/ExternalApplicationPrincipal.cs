using System.Security.Principal;
using static System.String;

namespace Inprotech.Infrastructure.Security.ExternalApplications
{
    public class ExternalApplicationPrincipal : IPrincipal
    {
        public readonly bool HasUserContext;

        public ExternalApplicationPrincipal(string username)
        {
            HasUserContext = !IsNullOrEmpty(username);

            Identity = HasUserContext
                ? (IIdentity)new GenericIdentity(username, AuthenticationTypes.ExternalApplicationWithUserContext)
                : new ExternalApplicationIdentity();
        }

        public bool IsInRole(string role)
        {
            // currently doesn't support role based authorization
            return false;
        }

        public IIdentity Identity { get; }

        public static class AuthenticationTypes
        {
            public const string ExternalApplication = "ExternalApplication";
            public const string ExternalApplicationWithUserContext = "ExternalApplicationWithUserContext";
        }

        class ExternalApplicationIdentity : IIdentity
        {
            public string Name => Empty;

            public string AuthenticationType => AuthenticationTypes.ExternalApplication;

            public bool IsAuthenticated => true;
        }
    }
}