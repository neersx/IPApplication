using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Integration.DbHelpers
{
    [Flags]
    public enum Allow
    {
        None = 0,
        Select = 1,
        Modify = 2,
        Create = 8,
        Delete = 16,
        Execute = 32
    }

    [Flags]
    public enum Deny
    {
        None = 0,
        Modify = 2,
        Create = 8,
        Delete = 16,
        Execute = 32
    }

    [Flags]
    public enum SubjectAllow
    {
        None = 0,
        Select = 1
    }

    [Flags]
    public enum SubjectDeny
    {
        None = 0,
        Select = 1
    }

    [Flags]
    public enum WebPartAllow
    {
        None = 0,
        Select = 1
    }

    [Flags]
    public enum WebPartDeny
    {
        None = 0,
        Select = 1
    }

    public class TestUser
    {
        public string Username { get; set; }

        public string Password { get; set; }

        public int Id { get; set; }

        public string Email { get; set; }

        public int AccessAccountId { get; set; }
        public int NameId { get; set; }
    }

    public class Users
    {
        const string E2EExternalUserName = "e2e_client";
        const string E2EUserName = "e2e_ken";
        const string E2ERoleName = "e2eRole";
        const string IpPlatformUserEmail = "e2e@inprotechdev.example.com";
        const string IpPlatformUserPassword = "_EndT0endp@ss";
        const string E2EGuk = "12500acd-9a6e-4e50-b60e-3f135de0e775";

        readonly IDbContext _dbContext;
        readonly string AdfsLoginId = "e2e@ssotest.cpaglobal.com";
        readonly string AdfsPassword = "_EndT0endp@ss";
        readonly string AdfsUserName = "SSOTEST\\e2e";

        int _id;

        public Users(IDbContext dbContext = null)
        {
            _dbContext = dbContext ?? new SqlDbContext();
        }

        public Name Name { get; set; }

        public Profile Profile { get; set; }

        public TestUser Create(string name = null, Name nameModel = null)
        {
            var userName = string.IsNullOrWhiteSpace(name) ? E2EUserName : name;
            var user = CreateUser(userName, nameModel);
            return new TestUser
            {
                Username = userName,
                Password = @"password",
                Id = _id,
                NameId = user.NameId
            };
        }

        public TestUser CreateAdfsUser(string name = null)
        {
            var userName = string.IsNullOrWhiteSpace(name) ? AdfsUserName : name;
            CreateUser(userName);
            return new TestUser
            {
                Username = userName,
                Password = AdfsPassword,
                Id = _id,
                Email = AdfsLoginId
            };
        }

        public TestUser CreateIpPlatformUser(bool linkedUser = true, bool professionalProfile = false)
        {
            var name = new NameBuilder(_dbContext).Create("e2e", "User", IpPlatformUserEmail);
            var profile = _dbContext.Set<Profile>().FirstOrDefault(_ => _.Name == "Proffessional");

            CreateUser(IpPlatformUserEmail, name, profile, IpPlatformUserPassword);

            if (linkedUser)
            {
                WithSso(IpPlatformUserEmail);
            }

            return new TestUser
            {
                Username = IpPlatformUserEmail,
                Password = IpPlatformUserPassword,
                Id = _id
            };
        }

        User CreateUser(string userName = null, Name nameModel = null, Profile profile = null, string password = "password")
        {
            userName = string.IsNullOrWhiteSpace(userName) ? E2EUserName : userName;

            var salt = Guid.NewGuid().ToString("N");

            var user = _dbContext.Set<User>()
                                 .Include("Roles")
                                 .SingleOrDefault(u => u.UserName == userName);

            if (user == null)
            {
                var name = nameModel ?? Name ?? _dbContext.Set<Name>().FirstOrDefault(n => n.UsedAs == 3 && n.FirstName != null);
                var accessAccounts = _dbContext.Set<AccessAccount>().Where(a => a.IsInternal);
                var accessAccount = accessAccounts.FirstOrDefault(a => a.Id == accessAccounts.Min(aa => aa.Id));
                var rowAccess = _dbContext.Set<RowAccess>().FirstOrDefault(r => r.Details.Any(rad => rad.Office == null && rad.AccessType == RowAccessType.Case && rad.Office == null));

                user = new User(userName, false)
                {
                    Name = name,
                    PasswordSalt = salt,
                    PasswordSha = new SHA256CryptoServiceProvider().ComputeHash(Encoding.UTF8.GetBytes(password + salt)),
                    AccessAccount = accessAccount,
                    RowAccessPermissions = new List<RowAccess> {rowAccess},
                    IsValid = true,
                    DefaultPortalId = -3,
                    Profile = profile ?? Profile
                };

                _dbContext.Set<User>().Add(user);
                _dbContext.SaveChanges();
            }

            _id = user.Id;

            var roles = _dbContext.Set<Role>();

            var role = roles.SingleOrDefault(r => r.RoleName == "e2eRole")
                       ?? roles.Add(new Role(_dbContext.Set<Role>().Max(r => r.Id) + 1)
                       {
                           Description = "e2e role",
                           IsExternal = false,
                           RoleName = E2ERoleName
                       });

            user.Roles.Add(role);

            _dbContext.SaveChanges();

            return user;
        }

        public Users WithRowLevelAccess(RowAccess rowAccess)
        {
            CreateUser();

            var user = _dbContext.Set<User>().Single(u => u.UserName == E2EUserName);

            user.RowAccessPermissions = new List<RowAccess> {rowAccess};

            _dbContext.SaveChanges();

            return this;
        }

        public Users WithPermission(ApplicationWebPart webPartId, WebPartDeny denyPermission)
        {
            EnsurePermission((int) webPartId, "MODULE", (byte) WebPartAllow.None, (byte) denyPermission);
            return this;
        }

        public Users WithPermission(ApplicationWebPart webPartId, WebPartAllow grantPermission = WebPartAllow.Select)
        {
            EnsurePermission((int) webPartId, "MODULE", (byte) grantPermission, (byte) WebPartDeny.None);
            return this;
        }

        public Users WithPermission(ApplicationTask taskId, Deny denyPermission)
        {
            EnsurePermission((int) taskId, "TASK", null, (byte) denyPermission);
            return this;
        }

        public Users WithPermission(ApplicationTask taskId, Allow grantPermission = Allow.Execute)
        {
            EnsurePermission((int) taskId, "TASK", (byte) grantPermission, null);
            return this;
        }

        public Users WithSubjectPermission(ApplicationSubject subjectId, SubjectAllow grantPermission = SubjectAllow.Select)
        {
            EnsurePermission((int) subjectId, "DATATOPIC", (byte) grantPermission, (byte) SubjectDeny.None);
            return this;
        }

        public Users WithSubjectPermission(ApplicationSubject subjectId, SubjectDeny denyPermission)
        {
            EnsurePermission((int) subjectId, "DATATOPIC", (byte) SubjectAllow.None, (byte) denyPermission);
            return this;
        }

        void EnsurePermission(int objectId, string objectTable, byte? grantPermission, byte? denyPermission)
        {
            CreateUser();

            var roles = _dbContext.Set<Role>();
            var permissions = _dbContext.Set<Permission>();

            var role = roles.SingleOrDefault(r => r.RoleName == "e2eRole")
                       ?? roles.Add(new Role(_dbContext.Set<Role>().Max(r => r.Id) + 1)
                       {
                           Description = "e2e",
                           IsExternal = false,
                           RoleName = E2ERoleName
                       });

            var permission = permissions.SingleOrDefault(
                                                         p =>
                                                             p.LevelKey == role.Id && p.ObjectTable == objectTable && p.LevelTable == "ROLE" &&
                                                             p.ObjectIntegerKey == objectId)
                             ?? permissions.Add(new Permission(objectTable, grantPermission ?? 0, denyPermission ?? 0)
                             {
                                 LevelKey = role.Id,
                                 LevelTable = "ROLE",
                                 ObjectIntegerKey = objectId
                             });

            permission.GrantPermission = grantPermission ?? permission.GrantPermission;
            permission.DenyPermission = denyPermission ?? permission.DenyPermission;

            _dbContext.SaveChanges();
        }

        public Users WithLicense(LicensedModule module)
        {
            CreateUser();

            var user = _dbContext.Set<User>().Single(u => u.UserName == E2EUserName);

            var license = _dbContext.Set<License>().Single(_ => _.Id == (int) module);

            if (user.Licences.All(_ => _.Id != license.Id))
            {
                user.Licences.Add(license);
            }

            _dbContext.SaveChanges();

            return this;
        }

        public Users WithSso(string loginName = null)
        {
            var user = _dbContext.Set<User>().Single(u => u.UserName == loginName);

            user.Guk = E2EGuk;

            _dbContext.SaveChanges();

            return this;
        }

        public void EnsureAccessToCase(Case @case)
        {
            var t = CreateExternalUser();
            var caseId = @case.Id;
            var accId = _dbContext.Set<User>().Single(_ => _.Id == t.Id).AccessAccount.Id;

            var nameTypes = _dbContext.Set<SiteControl>()
                                      .Single(_ => _.ControlId == SiteControls.ClientNameTypes)
                                      .StringValue.Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries)
                                      .Select(_ => _.Trim());

            var missingContacts = (from cn in _dbContext.Set<CaseName>()
                                   where nameTypes.Contains(cn.NameTypeId) && cn.CaseId == caseId
                                   join ca in _dbContext.Set<CaseAccess>()
                                       on new {AccountId = accId, cn.CaseId, cn.NameTypeId, cn.NameId, Sequence = (int) cn.Sequence}
                                       equals new {ca.AccountId, ca.CaseId, NameTypeId = ca.NameType, ca.NameId, ca.Sequence} into ca1
                                   from ca in ca1.DefaultIfEmpty()
                                   where ca == null
                                   select new
                                   {
                                       cn.NameId,
                                       cn.NameTypeId,
                                       cn.Sequence
                                   }).ToArray();

            foreach (var missing in missingContacts)
                _dbContext.Set<CaseAccess>().Add(new CaseAccess(@case, accId, missing.NameTypeId, missing.NameId, missing.Sequence));

            _dbContext.SaveChanges();
        }

        public TestUser CreateExternalUser(string userName = null)
        {
            userName = string.IsNullOrWhiteSpace(userName) ? E2EExternalUserName : userName;
            const string password = @"password";
            var salt = Guid.NewGuid().ToString("N");

            var user = _dbContext.Set<User>()
                                 .Include("Roles")
                                 .SingleOrDefault(u => u.UserName == userName);

            if (user == null)
            {
                var accessAccounts = _dbContext.Set<AccessAccount>().Where(a => !a.IsInternal);
                var accessAccount = accessAccounts.First(a => a.Id == accessAccounts.Min(aa => aa.Id));
                var name = (from n in _dbContext.Set<Name>()
                            join a in _dbContext.Set<AccessAccountName>()
                                on new {NameId = n.Id, AccessAccountId = accessAccount.Id} equals new {a.NameId, a.AccessAccountId}
                            select n).FirstOrDefault() ?? _dbContext.Set<Name>().FirstOrDefault(n => n.UsedAs == 3 && n.FirstName != null);

                user = new User(userName, true)
                {
                    Name = name,
                    PasswordSalt = salt,
                    PasswordSha = new SHA256CryptoServiceProvider().ComputeHash(Encoding.UTF8.GetBytes(password + salt)),
                    AccessAccount = accessAccount,
                    IsValid = true,
                    DefaultPortalId = -2
                };

                _dbContext.Set<User>().Add(user);
                _dbContext.SaveChanges();
            }

            _id = user.Id;

            var roles = _dbContext.Set<Role>();

            var role = roles.SingleOrDefault(r => r.RoleName == "e2eRole")
                       ?? roles.Add(new Role(_dbContext.Set<Role>().Max(r => r.Id) + 1)
                       {
                           Description = "e2e",
                           IsExternal = false,
                           RoleName = E2ERoleName
                       });

            user.Roles.Add(role);

            _dbContext.SaveChanges();

            return new TestUser
            {
                Username = userName,
                Password = password,
                Id = _id,
                AccessAccountId = user.AccessAccount.Id
            };
        }
    }
}