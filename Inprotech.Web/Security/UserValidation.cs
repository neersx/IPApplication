using System;
using System.Data.Entity;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Web.Security.TwoFactorAuth;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

#pragma warning disable 618

namespace Inprotech.Web.Security
{
    public interface IUserValidation
    {
        Task<Response> Validate(User user, string enteredPassword);
        Task<Response> Validate(User user, string enteredPassword, string preference, string code);

        Response HasConfiguredAccess(User user);

        bool IsPasswordExpired(User user);
    }

    public class UserValidation : IUserValidation
    {
        readonly IBus _bus;
        readonly IConfiguredAccess _configuredAccess;
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly ITwoFactorAuthVerify _authVerify;
        readonly ISiteControlReader _siteControls;

        public UserValidation(IDbContext dbContext, IConfiguredAccess configuredAccess, ISiteControlReader siteControls, IBus bus, Func<DateTime> now, ITwoFactorAuthVerify authVerify)
        {
            _dbContext = dbContext;
            _configuredAccess = configuredAccess;
            _siteControls = siteControls;
            _bus = bus;
            _now = now;
            _authVerify = authVerify;
        }

        public Response HasConfiguredAccess(User user)
        {
            if (!_configuredAccess.For(user))
                return new ValidationResponse("user-incomplete");

            return ValidationResponse.Validated();
        }

        public async Task<Response> Validate(User user, string enteredPassword)
        {
            if (user.IsLocked) return new AuthorizationResponse("unauthorised-accounts-locked");

            if (!_configuredAccess.For(user)) return new ValidationResponse("user-incomplete");

            if (IsCredentialValid(user, enteredPassword))
            {
                return await AuthorizationSuccess(user);
            }

            return await AuthorizationFailed(user);
        }

        public async Task<Response> Validate(User user, string enteredPassword, string preference, string code)
        {
            if (user.IsLocked) return new AuthorizationResponse("unauthorised-accounts-locked");

            if (!_configuredAccess.For(user)) return new ValidationResponse("user-incomplete");

            if (!IsCredentialValid(user, enteredPassword))
            {
                return await AuthorizationFailed(user);
            }

            if ((await IsCodeValid(user, code, preference)).Equals(false))
            {
                return await AuthorizationFailed(user, "two-factor-failed");
            }

            return await AuthorizationSuccess(user);
        }

        bool IsCredentialValid(User user, string enteredPassword)
        {
            return user.PasswordSha != null && user.PasswordSha.SequenceEqual(new SHA256CryptoServiceProvider().ComputeHash(Encoding.UTF8.GetBytes(enteredPassword + user.PasswordSalt))) ||
                   user.PasswordSha == null && user.PasswordMd5 != null && user.PasswordMd5.SequenceEqual(new MD5CryptoServiceProvider().ComputeHash(Encoding.UTF8.GetBytes(enteredPassword)));
        }

        async Task<bool?> IsCodeValid(User user, string code, string preference)
        {
            return await _authVerify.Verify(preference, code, user);
        }

        public async Task<AuthorizationResponse> AuthorizationSuccess(User user)
        {
            if (user.InvalidLogins > 0)
            {
                user.InvalidLogins = 0;
                await _dbContext.SaveChangesAsync();
            }

            _bus.Publish(new UserSessionInvalidatedMessage
            {
                IdentityId = user.Id
            });

            return AuthorizationResponse.Authorized();
        }

        public async Task<AuthorizationResponse> AuthorizationFailed(User user, string failedResponseError = "unauthorised-credentials")
        {
            var maxRetries = _siteControls.Read<int>(SiteControls.MaxInvalidLogins);
            if (maxRetries <= 0)
                return new AuthorizationResponse(failedResponseError);

            var wasLocked = user.IsLocked;
            if (user.InvalidLogins + 1 >= maxRetries)
            {
                using (var scope = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
                {
                    user.IsLocked = true;
                    user.InvalidLogins += 1;

                    if (!wasLocked)
                    {
                        var now = _now();
                        var name = _dbContext.Set<User>()
                                             .Include(_ => _.Name.Telecoms)
                                             .Single(_ => _.Id == user.Id)
                                             .Name;

                        await _bus.PublishAsync(new UserAccountLockedMessage
                        {
                            IdentityId = user.Id,
                            DisplayName = name.Formatted(),
                            UserEmail = name.MainEmailAddress(),
                            Username = user.UserName,
                            LockedUtc = now.ToUniversalTime(),
                            LockedLocal = now
                        });
                    }

                    _dbContext.SaveChanges();
                    scope.Complete();
                }
                return new AuthorizationResponse("unauthorised-accounts-just-locked");
            }

            user.InvalidLogins += 1;
            _dbContext.SaveChanges();
            return new AuthorizationResponse(failedResponseError);
        }

        public bool IsPasswordExpired(User user)
        {
            var shouldEnforcePasswordPolicy = _siteControls.Read<bool>(SiteControls.EnforcePasswordPolicy);
            var passwordExpiringDuration = _siteControls.Read<int?>(SiteControls.PasswordExpiryDuration) ?? 0;
            if (!shouldEnforcePasswordPolicy || passwordExpiringDuration <= 0 || user.PasswordUpdatedDate == null) return false;

            var daysBeforePasswordIsUpdated = DbFuncs.DiffDays(DbFuncs.TruncateTime(user.PasswordUpdatedDate), _now().Date);
            return daysBeforePasswordIsUpdated > passwordExpiringDuration;
        }
    }
}