using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class UserBuilder : IBuilder<User>
    {
        readonly InMemoryDbContext _db;

        public UserBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public string UserName { get; set; }
        public bool IsExternalUser { get; set; }
        public Profile Profile { get; set; }
        public AccessAccount AccessAccount { get; set; }
        public Name Name { get; set; }
        
        public User Build()
        {
            Name = Name ?? new NameBuilder(_db).Build();
            return new User(
                            UserName ?? Fixture.String(),
                            IsExternalUser,
                            Profile)
            {
                AccessAccount = AccessAccount ?? new AccessAccountBuilder().Build(),
                Name = Name,
                NameId = Name.Id
            };
        }

        public static UserBuilder AsInternalUser(InMemoryDbContext db, string name = null, Profile profile = null)
        {
            return new UserBuilder(db)
            {
                UserName = name,
                IsExternalUser = false
            };
        }

        public static UserBuilder AsExternalUser(InMemoryDbContext db, string name = null, Profile profile = null)
        {
            return new UserBuilder(db)
            {
                UserName = name,
                IsExternalUser = true
            };
        }

        public static UserBuilder AsExternalUser(InMemoryDbContext db, AccessAccount accessAccount = null)
        {
            return new UserBuilder(db) {AccessAccount = accessAccount, IsExternalUser = true};
        }
    }
}