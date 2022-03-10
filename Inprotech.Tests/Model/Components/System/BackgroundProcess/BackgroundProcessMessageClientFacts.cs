using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Tests.Web;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Components.System.BackgroundProcess;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.Model.Components.System.BackgroundProcess
{
    public class BackgroundProcessMessageClientFacts : FactBase
    {
        [Fact]
        public async Task InsertBackgroundProcessForEachMessage()
        {
            var m = new BackgroundProcessMessage
            {
                IdentityId = Fixture.Integer(),
                Message = Fixture.String(),
                ProcessType = Fixture.Enum<BackgroundProcessType>(),
                StatusType = Fixture.Enum<StatusType>(),
                ProcessSubType = Fixture.Enum<BackgroundProcessSubType>()
            };

            await new BackgroundProcessMessageClient(Db, Fixture.Today).SendAsync(m);

            var db = Db.Set<InprotechKaizen.Model.BackgroundProcess.BackgroundProcess>();
            var bg = db.Single();
            Assert.Equal(m.IdentityId, bg.IdentityId);
            Assert.Equal(m.ProcessType.ToString(), bg.ProcessType);
            Assert.Equal((int) m.StatusType, bg.Status);
            Assert.Equal(m.Message, bg.StatusInfo);
            Assert.Equal(Fixture.Today(), bg.StatusDate);
            Assert.Equal(m.ProcessSubType.ToString(), bg.ProcessSubType);
            Assert.Equal(m.ProcessSubType.ToString(), bg.ProcessSubType);
        }

        [Fact]
        public void GetBackgroundNotificationMessageAsync()
        {
            var user1 = new UserBuilder(Db).Build().WithKnownId(Fixture.Integer());
            var user2 = new UserBuilder(Db).Build().WithKnownId(Fixture.Integer());
            var user3 = new UserBuilder(Db).Build().WithKnownId(Fixture.Integer());
            var result = GetBackgroundProcessMessages(user1, user2, user3).ToList();

            Assert.Equal(result.Count, 2);
            Assert.False(result.Any(_ => _.IdentityId == user3.Id));
            var bp1 = result.Single(_ => _.IdentityId == user1.Id);
            Assert.NotNull(bp1);
            Assert.Equal(Fixture.Today(),bp1.StatusDate );
            var bp2 = result.Single(_ => _.IdentityId == user2.Id);
            Assert.NotNull(bp2);
            Assert.Equal(Fixture.Today().AddDays(1),bp2.StatusDate );
        }

        [Fact]
        public void DeleteBackgroundNotificationMessageAsync()
        {
            var user1 = new UserBuilder(Db).Build().WithKnownId(Fixture.Integer());
            var user2 = new UserBuilder(Db).Build().WithKnownId(Fixture.Integer());
            var user3 = new UserBuilder(Db).Build().WithKnownId(Fixture.Integer());
            var result = GetBackgroundProcessMessages(user1, user2, user3);

            var val = new BackgroundProcessMessageClient(Db, Fixture.Today).DeleteBackgroundProcessMessages(result.Select(_ => _.ProcessId).ToArray());
            Assert.True(val);
            Assert.Empty(Db.Set<InprotechKaizen.Model.BackgroundProcess.BackgroundProcess>().Where(_ => _.IdentityId == user1.Id));
            Assert.Empty(Db.Set<InprotechKaizen.Model.BackgroundProcess.BackgroundProcess>().Where(_ => _.IdentityId == user2.Id));
        }

        IEnumerable<BackgroundProcessMessage> GetBackgroundProcessMessages(User user1, User user2, User user3)
        {
           
            Db.Set<User>().Add(user1);
            Db.Set<User>().Add(user2);
            
            var ids = new[] {user1.Id, user2.Id, user3.Id};
            var bp1 = new InprotechKaizen.Model.BackgroundProcess.BackgroundProcess
            {
                IdentityId = user1.Id,
                ProcessType = BackgroundProcessType.GlobalCaseChange.ToString(), 
                Status = (int)StatusType.Completed,
                StatusDate = Fixture.Today(),
            };
            var bp2 = new InprotechKaizen.Model.BackgroundProcess.BackgroundProcess
            {
                IdentityId = user2.Id,
                ProcessType = BackgroundProcessType.CpaXmlExport.ToString(), 
                Status = (int)StatusType.Error,
                StatusDate = Fixture.Today().AddDays(1),
            };
            Db.Set<InprotechKaizen.Model.BackgroundProcess.BackgroundProcess>().Add(bp1);
            Db.Set<InprotechKaizen.Model.BackgroundProcess.BackgroundProcess>().Add(bp2);
            return new BackgroundProcessMessageClient(Db, Fixture.Today).Get(ids);
        }
    }
}