
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace Inprotech.Web.Security
{
    public interface IPasswordVerifier
    {
        bool HasPasswordReused(string enteredPassword, string passwordHistory);
        
        void UpdateUserPassword(string enteredPassword, User user);
    }

    public class PasswordVerifier : IPasswordVerifier
    {
        readonly ISiteControlReader _siteControl;
        readonly Func<DateTime> _now;
        readonly IDbContext _dbContext;

        public PasswordVerifier(ISiteControlReader siteControl,  Func<DateTime> now, IDbContext dbContext)
        {
            _siteControl = siteControl;
            _now = now;
            _dbContext = dbContext;
        }

        bool ShouldEnforcePasswordPolicy => _siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy);
        int PasswordUsedHistory => _siteControl.Read<int?>(SiteControls.PasswordUsedHistory) ?? 0;
        int PasswordExpiringDuration => _siteControl.Read<int?>(SiteControls.PasswordExpiryDuration) ?? 0;
        public void UpdateUserPassword(string enteredPassword, User user)
        {
            user.PasswordSalt= Guid.NewGuid().ToString("N");
            user.PasswordSha = new SHA256CryptoServiceProvider().ComputeHash(Encoding.UTF8.GetBytes(enteredPassword + user.PasswordSalt));
            user.PasswordMd5 = null;
            user.PasswordUpdatedDate = _now();
            if (PasswordUsedHistory <= 0 || !ShouldEnforcePasswordPolicy)
            {
                _dbContext.SaveChanges();
                return;
            }

            var usedPasswords = user.PasswordHistory != null ? 
                user.PasswordHistory.Split(Environment.NewLine.ToCharArray(), StringSplitOptions.RemoveEmptyEntries).ToList() : new List<string>();
            usedPasswords.Insert(0, user.PasswordSalt + " " + GetHash(user.PasswordSha));
            user.PasswordHistory = string.Join(Environment.NewLine, usedPasswords.Take(PasswordUsedHistory));

            _dbContext.SaveChanges();

        }

        static string GetHash(byte[] sha)
        {
            var sBuilder = new StringBuilder();
            foreach (var t in sha)
            {
                sBuilder.Append(t.ToString("x2"));
            }

            return sBuilder.ToString();
        }

        public bool HasPasswordReused(string enteredPassword, string passwordHistory)
        {
            if (PasswordUsedHistory <= 0 || string.IsNullOrWhiteSpace(passwordHistory)) return false;

            var usedPasswords = passwordHistory.Split(Environment.NewLine.ToCharArray(), StringSplitOptions.RemoveEmptyEntries);
            return (from up in usedPasswords.Take(PasswordUsedHistory) 
                    select up.Split(' ') into pwd let salt = pwd[0] let sha = pwd[1]  
                    where VerifyHash(enteredPassword + salt, sha) select salt).Any();
        }
        
        // Verify a hash against a string.
        bool VerifyHash(string input, string hash)
        {
            var data = new SHA256CryptoServiceProvider().ComputeHash(Encoding.UTF8.GetBytes(input));
            return StringComparer.OrdinalIgnoreCase.Compare(GetHash(data), hash) == 0;
        }
    }
}
