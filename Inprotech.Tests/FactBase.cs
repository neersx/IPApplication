using System;
using System.Security.Cryptography;
using System.Text;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;

namespace Inprotech.Tests
{
    public abstract class FactBase : IDisposable
    {
        protected FactBase()
        {
            Db = Substitute.ForPartsOf<InMemoryDbContext>();
        }

        public InMemoryDbContext Db { get; }

        public virtual void Dispose()
        {
            Db?.Dispose();
        }

        protected User CreateUser(string userName, string password, bool passwordMd5, bool isExternal = false)
        {
            var user = new User(userName, isExternal)
            {
                Name = new NameBuilder(Db).Build(),
                IsValid = true
            };

            if (passwordMd5)
            {
                user.PasswordMd5 = new MD5CryptoServiceProvider().ComputeHash(Encoding.UTF8.GetBytes(password));
            }
            else
            {
                var salt = Guid.NewGuid().ToString("N");
                user.PasswordSha = new SHA256CryptoServiceProvider().ComputeHash(Encoding.UTF8.GetBytes(password + salt));
                user.PasswordSalt = salt;
            }

            return user.In(Db);
        }

        protected User UpdateUserPasswordManually(User user, string password, bool passwordMd5, bool isExternal = false)
        {
            if (passwordMd5)
            {
                user.PasswordMd5 = new MD5CryptoServiceProvider().ComputeHash(Encoding.UTF8.GetBytes(password));
            }
            else
            {
                var salt = Guid.NewGuid().ToString("N");
                user.PasswordSha = new SHA256CryptoServiceProvider().ComputeHash(Encoding.UTF8.GetBytes(password + salt));
                user.PasswordSalt = salt;
            }

            Db.SaveChanges();

            return user;
        }
    }
}