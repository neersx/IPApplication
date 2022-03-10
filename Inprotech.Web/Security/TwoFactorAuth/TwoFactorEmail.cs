using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using OtpNet;

namespace Inprotech.Web.Security.TwoFactorAuth
{
    public class TwoFactorEmail : ITwoFactorAuth
    {
        readonly IDbContext _dbContext;
        readonly IBus _bus;
        readonly ITwoFactorTotp _twoFactorTotp;
        readonly IUserTwoFactorAuthPreference _authPreference;
        const int Step = 300;
        public TwoFactorEmail(IDbContext dbContext, IBus bus, ITwoFactorTotp twoFactorTotp, IUserTwoFactorAuthPreference authPreference)
        {
            _dbContext = dbContext;
            _bus = bus;
            _twoFactorTotp = twoFactorTotp;
            _authPreference = authPreference;
        }

        public async Task UserCredentialsValidated(User user)
        {

            var name = _dbContext.Set<User>()
                                 .Include(_ => _.Name.Telecoms)
                                 .Single(_ => _.Id == user.Id)
                                 .Name;

            var authCode = _twoFactorTotp.OneTimePassword(Step, await _authPreference.ResolveEmailSecretKey(user.Id)).ComputeTotp();

            var email = name.MainEmailAddress();
            if (string.IsNullOrEmpty(email))
                throw new DataSecurityException($"Email not registered for user {user.UserName}");

            await _bus.PublishAsync(new UserAccount2FaMessage
            {
                IdentityId = user.Id,
                DisplayName = name.Formatted(),
                UserEmail = email,
                Username = user.UserName,
                AuthenticationCode = authCode
            });
        }

        public async Task<bool> VerifyForUser(User user, string authenticationCode)
        {
            return _twoFactorTotp.OneTimePassword(Step, await _authPreference.ResolveEmailSecretKey(user.Id)).VerifyTotp(authenticationCode, out _, new VerificationWindow(3, 1));
        }

    }
}