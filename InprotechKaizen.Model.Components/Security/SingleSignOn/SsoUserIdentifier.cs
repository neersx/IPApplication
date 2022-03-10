using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security.SingleSignOn
{
    public interface ISsoUserIdentifier
    {
        bool TryFindUser(Guid identity, out User user);

        bool EnforceEmailValidity(string ssoEmail, User user, out SsoUserLinkResultType result);

        bool TryLinkUserAuto(SsoIdentity identity, out User user, out SsoUserLinkResultType result);

        Task<SsoUserLinkResultType> UnlinkUser(int identityId);
    }

    public enum SsoUserLinkResultType
    {
        Success,
        NoEmail,
        NonUniqueEmail,
        NoMatchingInprotechUser,
        NoMatchingPlatformUser,
        TooManyLinked
    }

    public class SsoUserIdentifier : ISsoUserIdentifier
    {
        readonly IDbContext _dbContext;

        public SsoUserIdentifier(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public bool TryFindUser(Guid ssoGuk, out User user)
        {
            user = _dbContext.Set<User>()
                             .Include(_ => _.Name)
                             .Include(_ => _.Name.Telecoms)
                             .SingleOrDefault(u => u.Guk == ssoGuk.ToString());

            return user != null;
        }

        public bool EnforceEmailValidity(string ssoEmail, User user, out SsoUserLinkResultType result)
        {
            if (user == null) throw new ArgumentNullException(nameof(user));
            result = SsoUserLinkResultType.NoMatchingInprotechUser;

            if (user.Name.Telecoms.Any(t => user.Name.MainEmailId == t.Telecommunication.Id
                                            && string.Compare(t.Telecommunication.TelecomNumber, ssoEmail, StringComparison.OrdinalIgnoreCase) == 0))
            {
                result = SsoUserLinkResultType.NonUniqueEmail;
                if (FindUsers(ssoEmail).Length == 1)
                {
                    result = SsoUserLinkResultType.Success;
                    return true;
                }
            }

            UnlinkGuk(user);
            return false;
        }

        public bool TryLinkUserAuto(SsoIdentity identity, out User user, out SsoUserLinkResultType result)
        {
            user = null;
            result = SsoUserLinkResultType.Success;

            var users = FindUsers(identity.Email);

            if (!users.Any())
            {
                result = SsoUserLinkResultType.NoMatchingInprotechUser;
                return false;
            }

            if (users.Length != 1)
            {
                result = SsoUserLinkResultType.NonUniqueEmail;
                return false;
            }

            user = users.Single();
            LinkGuk(user, identity);

            return true;
        }

        public async Task<SsoUserLinkResultType> UnlinkUser(int identityId)
        {
            var user = await _dbContext.Set<User>().SingleOrDefaultAsync(_ => _.Id == identityId);
            if (user == null) return SsoUserLinkResultType.NoMatchingInprotechUser;

            user.Guk = null;
            _dbContext.SaveChanges();

            return SsoUserLinkResultType.Success;
        }

        void LinkGuk(User user, SsoIdentity identity)
        {
            user.Guk = identity.Guk.ToString();
            _dbContext.SaveChanges();
        }

        void UnlinkGuk(User user)
        {
            user.Guk = null;
            _dbContext.SaveChanges();
        }

        User[] FindUsers(string email)
        {
            return _dbContext.Set<User>()
                             .Include(_ => _.Name)
                             .Include(_ => _.Name.Telecoms)
                             .Where(_ => _.Name.Telecoms.Any(t => t.Telecommunication.TelecomNumber == email && _.Name.MainEmailId == t.Telecommunication.Id))
                             .ToArray();
        }
    }

    public class SsoIdentity
    {
        public string Email { get; set; }

        public string FirstName { get; set; }

        public string LastName { get; set; }

        public Guid Guk { get; set; }
    }
}