using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Properties;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public interface IUserPasswordExpiryValidator
    {
        Task <IEnumerable<UserPasswordExpiryDetails>> Resolve(int passwordExpiryDuration);
    }
    public class UserPasswordExpiryValidator : IUserPasswordExpiryValidator
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly IEmailValidator _emailValidator;
        readonly IDocItemRunner _docItemRunner;

        public UserPasswordExpiryValidator(IDbContext dbContext, Func<DateTime> now, IEmailValidator emailValidator, IDocItemRunner docItemRunner)
        {
            _dbContext = dbContext;
            _now = now;
            _emailValidator = emailValidator;
            _docItemRunner = docItemRunner;
        }

        public async Task<IEnumerable<UserPasswordExpiryDetails>> Resolve(int passwordExpiryDuration)
        {
            var today = _now().Date;

            var interim = await (from u in _dbContext.Set<User>()
                   join n in _dbContext.Set<Name>() on u.NameId equals n.Id into n1
                   from n in n1
                   join e in _dbContext.Set<Telecommunication>() on n.MainEmailId equals e.Id into e1
                   from e in e1
                   where u.PasswordUpdatedDate != null && e.TelecomNumber != null
                   let numberOfDaysToExpire = passwordExpiryDuration - DbFuncs.DiffDays(DbFuncs.TruncateTime(u.PasswordUpdatedDate), today)
                   where numberOfDaysToExpire == 7 || numberOfDaysToExpire == 3 || numberOfDaysToExpire <= 1
                   select new 
                   {
                       u.Id,
                       Email = e.TelecomNumber,
                       Name = n.FirstName ?? n.LastName, 
                       DaysToExpire = numberOfDaysToExpire
                   }).ToArrayAsync();

            var docItem = await _dbContext.Set<DocItem>().FirstOrDefaultAsync(_ => _.Name == KnownEmailDocItems.PasswordExpiry);

            return (from i in interim
                    where _emailValidator.IsValid(i.Email)
                    select new UserPasswordExpiryDetails
                    {
                        Id = i.Id,
                        Email = i.Email,
                        EmailBody = GetBody(i, docItem)
                    }).ToArray();
        }

        string GetBody(dynamic user, DocItem item)
        {
            if (item == null) return string.Empty;

            var p = DefaultDocItemParameters.ForDocItemSqlQueries(user.DaysToExpire, user.Id);
            var ds = (DataSet)_docItemRunner.Run(item.Id, p);
            var body = ds.ScalarValueOrDefault<string>();

            var message = new StringBuilder();
            message.AppendFormat(Resources.ExpiringPasswordGreet, user.Name);
            message.AppendFormat(",");
            message.AppendLine();
            message.AppendLine();
            message.AppendLine(body);
            return message.ToString();
        }
    }

    public class UserPasswordExpiryDetails
    {
        public int Id { get; set; }
        public string EmailBody { get; set; }
        public string Email { get; set; }
    }

}
