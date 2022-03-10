using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    public class OtherUserBuilder : DbSetup
    {
        readonly NameBuilder _nameBuilder;

        public OtherUserBuilder(IDbContext dbContext) : base(dbContext)
        {
            _nameBuilder = new NameBuilder(dbContext);
        }

        public OtherUser Create()
        {
            /* does not build password and access account link*/
            /* not suitable to be used for logging in */
            return new OtherUser
                   {
                       Mary = GetOrCreate("mary", "mary.smith"),
                       John = GetOrCreate("john", "john.smith")
                   };
        }

        User GetOrCreate(string userName, string namePrefix)
        {
            var users = DbContext.Set<User>();

            var user = users.SingleOrDefault(_ => _.UserName.EndsWith(userName));
            if (user != null) return user;

            var name = _nameBuilder.Create(Fixture.Prefix(namePrefix));

            return Insert(new User(RandomString.Next(6) + userName, false)
                          {
                              Name = name
                          });
        }

        public class OtherUser
        {
            public User Mary { get; set; }

            public User John { get; set; }
        }
    }
}