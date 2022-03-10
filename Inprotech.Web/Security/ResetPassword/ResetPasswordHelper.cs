using System;
using System.Data.Entity;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Contracts;
using Inprotech.Contracts.DocItems;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using OtpNet;

namespace Inprotech.Web.Security.ResetPassword
{
    public interface IResetPasswordHelper
    {
        Task SendResetEmail(User user, string url);
        Task<string> ResolveSecretKey(User user);
    }

    public class ResetPasswordHelper : IResetPasswordHelper
    {
        readonly IDbContext _dbContext;
        readonly ICryptoService _cryptoService;
        readonly ILogger<ResetPasswordHelper> _logger;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IStaticTranslator _staticTranslator;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDocItemRunner _docItemRunner;
        readonly IBus _bus;

        public ResetPasswordHelper(IDbContext dbContext, ICryptoService cryptoService, IBus bus,
                          ILogger<ResetPasswordHelper> logger, ITaskSecurityProvider taskSecurityProvider,IStaticTranslator staticTranslator, IPreferredCultureResolver preferredCultureResolver,
                          IDocItemRunner docItemRunner)
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
            _logger = logger;
            _taskSecurityProvider = taskSecurityProvider;
            _staticTranslator = staticTranslator;
            _preferredCultureResolver = preferredCultureResolver;
            _docItemRunner = docItemRunner;
            _bus = bus;
        }

        public async Task SendResetEmail(User user, string url)
        {
            if (!_taskSecurityProvider.UserHasAccessTo(user.Id, ApplicationTask.ChangeMyPassword))
            {
                _logger.Warning("The user is not authorized to change password", new
                {
                    Urls = url,
                    UserId = user.Id
                });
                return;
            }

            var name = _dbContext.Set<User>()
                                 .Include(_ => _.Name.Telecoms)
                                 .Single(_ => _.Id == user.Id)
                                 .Name;
            var email = name.MainEmailAddress();
            if (string.IsNullOrEmpty(email))
            {
                _logger.Warning("User Email not provided", new
                {
                    Urls = url,
                    UserId = user.Id
                });
                return;
            }

            var token = await ResolveSecretKey(user);

            var uri = new Uri(url + "?token=" + HttpUtility.UrlEncode(token));
            var cultureResolver = _preferredCultureResolver.ResolveAll().ToArray();

            await _bus.PublishAsync(new UserResetPasswordMessage
            {
                IdentityId = user.Id,
                UserEmail = email,
                Username = user.UserName,
                EmailBody = GetBody(uri, user),
                UserResetPassword = _staticTranslator.Translate("signin.userResetPasswordRequest", cultureResolver)
            });
        }

        string GetBody(Uri uri, User user)
        {
            var item = _dbContext.Set<DocItem>().FirstOrDefault(_ => _.Name == KnownEmailDocItems.PasswordReset);
            if (item == null) return string.Empty;
            var p = DefaultDocItemParameters.ForDocItemSqlQueries(30, user.Id);
            var body = _docItemRunner.Run(item.Id, p).ScalarValueOrDefault<string>();

            var cultureResolver = _preferredCultureResolver.ResolveAll().ToArray();
            var message = new StringBuilder();
            message.AppendFormat(_staticTranslator.Translate("signin.resetPasswordEmailGreet", cultureResolver), user.Name.FirstName ?? user.Name.LastName);
            message.AppendFormat("<br /><br />");
            message.AppendFormat(body);
            message.AppendFormat("<br />");
            message.AppendFormat("<a href='{0}'>{0}</a>", uri);
            return message.ToString();
        }
        
        public async Task<string> ResolveSecretKey(User user)
        {
            var configuredSetting = await _dbContext.Set<SettingValues>()
                                                    .Where(
                                                           s => s.SettingId == KnownSettingIds.ResetPasswordSecretKey &&
                                                                s.CharacterValue != null &&
                                                                (s.User == null || s.User.Id == user.Id))
                                                    .OrderByDescending(s => s.User.Id)
                                                    .FirstOrDefaultAsync();

            var key = Base32Encoding.ToString(Guid.NewGuid().ToByteArray());
            var configuredKey = _cryptoService.Encrypt(key);

            if (configuredSetting == null)
            {
                var newSetting = new SettingValues
                {
                    SettingId = KnownSettingIds.ResetPasswordSecretKey,
                    CharacterValue = key,
                    User = user
                };
                _dbContext.Set<SettingValues>().Add(newSetting);
            }
            else
            {
                configuredSetting.CharacterValue = key;
            }

            await _dbContext.SaveChangesAsync();

            return configuredKey;
        }
    }
}
