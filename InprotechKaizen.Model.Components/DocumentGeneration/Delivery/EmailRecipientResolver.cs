using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Names.Correspondence;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Delivery
{
    public interface IEmailRecipientResolver
    {
        Task<EmailRecipients> Resolve(int id);
    }

    public class EmailRecipientResolver : IEmailRecipientResolver
    {
        readonly IDbContext _dbContext;
        readonly IEmailStoredProcedureRunner _emailStoredProcedureRunner;

        public EmailRecipientResolver(IDbContext dbContext, IEmailStoredProcedureRunner emailStoredProcedureRunner)
        {
            _dbContext = dbContext;
            _emailStoredProcedureRunner = emailStoredProcedureRunner;
        }

        public async Task<EmailRecipients> Resolve(int id)
        {
            var r = new EmailRecipients();

            var interim = await (from a in _dbContext.Set<CaseActivityRequest>()
                                 join dm in _dbContext.Set<DeliveryMethod>() on a.DeliveryMethodId equals dm.Id into dm1
                                 from dm in dm1.DefaultIfEmpty()
                                 where a.Id == id
                                 select new
                                 {
                                     a.CaseId,
                                     dm.EmailStoredProcedure,
                                     LetterNo = a.AlternateLetter ?? a.LetterNo
                                 }).SingleOrDefaultAsync();

            if (interim == null || interim.LetterNo == null)
            {
                throw new InvalidOperationException($"Requested Activity Request row {id} either does not exist, or it is not configured to return email addresses");
            }

            if (!string.IsNullOrWhiteSpace(interim.EmailStoredProcedure))
            {
                r = await _emailStoredProcedureRunner.Run(id, interim.EmailStoredProcedure);
            }

            if (!r.To.Any() && !r.Cc.Any())
            {
                var to = await (from l in _dbContext.Set<Document>()
                                join c in _dbContext.Set<CorrespondTo>() on l.CorrespondType equals c.Id
                                join cn in _dbContext.Set<CaseName>() on c.NameTypeId equals cn.NameTypeId
                                join t in _dbContext.Set<Telecommunication>() on cn.Name.MainEmailId equals t.Id into t1
                                from t in t1
                                where cn.CaseId == interim.CaseId &&
                                      l.Id == interim.LetterNo
                                select t.TelecomNumber)
                    .ToArrayAsync();

                var cc = await (from l in _dbContext.Set<Document>()
                                join c in _dbContext.Set<CorrespondTo>() on l.CorrespondType equals c.Id
                                join cn in _dbContext.Set<CaseName>() on c.CopiesToNameTypeId equals cn.NameTypeId
                                join t in _dbContext.Set<Telecommunication>() on cn.Name.MainEmailId equals t.Id into t1
                                from t in t1
                                where cn.CaseId == interim.CaseId &&
                                      l.Id == interim.LetterNo
                                select t.TelecomNumber)
                    .ToArrayAsync();

                r.To.AddRange(to);
                r.Cc.AddRange(cc);
            }

            return r;
        }
    }
}