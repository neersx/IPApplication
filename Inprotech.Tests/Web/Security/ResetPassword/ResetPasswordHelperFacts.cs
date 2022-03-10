using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Contracts;
using Inprotech.Contracts.DocItems;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Security.ResetPassword;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security.ResetPassword
{
    public class ResetPasswordHelperFacts : FactBase
    {
        public class ResetPasswordHelperFixture : IFixture<ResetPasswordHelper>
        {
            public ICryptoService CryptoService { get; set; }
            public ILogger<ResetPasswordHelper> Logger { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public IStaticTranslator StaticTranslator { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public IBus Bus { get; set; }
            public IDocItemRunner DocItemRunner { get; set; }

            public ResetPasswordHelper Subject { get; set; }

            public ResetPasswordHelperFixture(InMemoryDbContext db)
            {
                CryptoService = Substitute.For<ICryptoService>();
                Logger = Substitute.For<ILogger<ResetPasswordHelper>>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                StaticTranslator = Substitute.For<IStaticTranslator>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Bus = Substitute.For<IBus>();
                DocItemRunner = Substitute.For<IDocItemRunner>();

                Subject = new ResetPasswordHelper(db,CryptoService, Bus, Logger, TaskSecurityProvider, StaticTranslator, PreferredCultureResolver, DocItemRunner);
            }
        }

        public User ReturnsUser(ResetPasswordHelperFixture fixture)
        {
            var user = CreateUser("bob", "dabadee", true);
            fixture.TaskSecurityProvider.UserHasAccessTo(user.Id, ApplicationTask.ChangeMyPassword).Returns(true);
            return user;
        }

        public User ReturnsUserWithEmail(ResetPasswordHelperFixture fixture)
        {
            var user = CreateUser("bob", "dabadee", true);
            fixture.TaskSecurityProvider.UserHasAccessTo(user.Id, ApplicationTask.ChangeMyPassword).Returns(true);
            var tb1 = new TableCodeBuilder {TableCode = (int) KnownTelecomTypes.Email}.For(TableTypes.TelecommunicationsType).Build().In(Db);
            var t1 = new TelecommunicationBuilder {TelecomType = tb1, TelecomNumber = "abc@xyz"}.Build().In(Db);
            var nt = new NameTelecomBuilder(Db){Name = user.Name, Telecommunication = t1}.Build().In(Db);
            user.Name.MainEmailId = t1.Id;
            user.Name.Telecoms.Add(nt);
            return user;
        }

        dynamic SetDocItem()
        {
            var dataItem = new DocItem {Name = KnownEmailDocItems.PasswordReset, Sql = "Select ABC", EntryPointUsage = 1}.In(Db);
            var docItemResult = Fixture.String();
            var result = new DataSet();
            result.Tables.Add(new DataTable());
            result.Tables[0].Columns.Add("Result");
            var row = result.Tables[0].NewRow();
            row["Result"] = docItemResult;
            result.Tables[0].Rows.Add(row);

            return new
            {
                dataItem,
                result,
                docItemResult
            };
        }

        [Fact]
        public async Task LogsWarningWhenChangePasswordTaskNotAssigned()
        {
            var fixture = new ResetPasswordHelperFixture(Db);
            var user = CreateUser("bob", "dabadee", true);
            fixture.TaskSecurityProvider.UserHasAccessTo(user.Id, ApplicationTask.ChangeMyPassword).Returns(false);

            await fixture.Subject.SendResetEmail(user, string.Empty);
            var message = "The user is not authorized to change password";
            fixture.Logger.Received(1).Warning(Arg.Is(message), Arg.Any<object>());
        }

        [Fact]
        public async Task LogsWarningWhenEmailAddressNotFound()
        {
            var fixture = new ResetPasswordHelperFixture(Db);
            var user = CreateUser("bob", "dabadee", true);
            fixture.TaskSecurityProvider.UserHasAccessTo(user.Id, ApplicationTask.ChangeMyPassword).Returns(true);

            await fixture.Subject.SendResetEmail(user, string.Empty);
            var message = "User Email not provided";
            fixture.Logger.Received(1).Warning(Arg.Is(message), Arg.Any<object>());
        }

        [Fact]
        public async Task ResolvesEmailSecretKey()
        {
            var fixture = new ResetPasswordHelperFixture(Db);
            var user = ReturnsUserWithEmail(fixture);
            var url = "http://localhost/resetpassword";
            var encryptedKey = Fixture.String("key");
            fixture.CryptoService.Encrypt(Arg.Any<string>()).Returns(encryptedKey);
            var docItem = SetDocItem();
            fixture.DocItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>()).Returns(docItem.result as DataSet);

            await fixture.Subject.SendResetEmail(user, url);
            fixture.CryptoService.Received(1).Encrypt(Arg.Any<string>());
          
            await fixture.Bus.Received(1).PublishAsync(Arg.Do<UserResetPasswordMessage>(publishedMessage =>
            {
                var item = (DocItem) docItem.dataItem;
                fixture.DocItemRunner.Received(1).Run(item.Id, Arg.Any<Dictionary<string, object>>());
                Assert.True(publishedMessage.EmailBody.Contains(docItem.docItemResult));
                Assert.Equal(user.Id, publishedMessage.IdentityId);
                Assert.Equal(user.Name.MainEmailAddress(), publishedMessage.UserEmail);
                Assert.Equal(user.UserName, publishedMessage.Username);
                Assert.True(publishedMessage.UserEmail.Contains(url + "?token=" + HttpUtility.UrlEncode(encryptedKey)));
              
                Assert.True(Db.Set<SettingValues>()
                                 .Any(_ => _.User.Id == user.Id && _.SettingId == KnownSettingIds.ResetPasswordSecretKey));
            }));
        }

        [Fact]
        public async Task ResolvesEmailSecretKeyWhenSettingExist()
        {
            var fixture = new ResetPasswordHelperFixture(Db);
            var user = ReturnsUserWithEmail(fixture);
            var url = "http://localhost/resetpassword";
            var oldKey = Fixture.String();
            new SettingValues { User = user, SettingId = KnownSettingIds.ResetPasswordSecretKey, CharacterValue = oldKey}.In(Db);
            await fixture.Subject.SendResetEmail(user, url);
            
            await fixture.Bus.Received(1).PublishAsync(Arg.Do<UserResetPasswordMessage>(publishedMessage =>
            {
                Assert.True(Db.Set<SettingValues>()
                              .Any(_ => _.User.Id == user.Id && _.SettingId == KnownSettingIds.ResetPasswordSecretKey && _.CharacterValue != oldKey));
            }));
        }
    }
}
